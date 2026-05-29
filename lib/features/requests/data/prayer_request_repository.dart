import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vesper/core/crypto/encryption_service.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/core/services/encrypted_cache_service.dart';
import 'package:vesper/features/groups/data/group_repository.dart';

class PrayerRequestRepository {
  PrayerRequestRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required EncryptionService encryptionService,
    required GroupRepository groupRepository,
    required EncryptedCacheService encryptedCache,
  }) : _auth = auth,
       _firestore = firestore,
       _encryptionService = encryptionService,
       _groupRepository = groupRepository,
       _encryptedCache = encryptedCache;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;
  final GroupRepository _groupRepository;
  final EncryptedCacheService _encryptedCache;

  String get _uid => _auth.currentUser!.uid;

  Stream<List<PrayerRequestSummary>> watchRequests(VesperGroup group) {
    final statuses = groupFeedStatuses();
    var query = _firestore
        .collection('prayer_requests')
        .where('groupId', isEqualTo: group.id);
    query = statuses.length == 1
        ? query.where('status', isEqualTo: statuses.first)
        : query.where('status', whereIn: statuses);
    query = query.orderBy('createdAt', descending: true);
    return query.snapshots().asyncMap((snapshot) async {
      final rawRecords = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      await _encryptedCache.cacheEncryptedRequests(group.id, rawRecords);
      return _decryptRequests(
        group,
        snapshot.docs.map(_FirestoreRequestDoc.new),
      );
    });
  }

  Future<List<PrayerRequestSummary>> readCachedRequests(
    VesperGroup group,
  ) async {
    final cached = await _encryptedCache.readEncryptedRequests(group.id);
    final docs = cached.map(_CachedRequestDoc.new).toList();
    return _decryptRequests(group, docs);
  }

  Future<void> createRequest({
    required VesperGroup group,
    required String title,
    required String body,
  }) async {
    final doc = _firestore.collection('prayer_requests').doc();
    final groupKey = await _groupRepository.loadGroupKey(
      group.id,
      group.activeKeyVersion,
    );
    final payload = await _encryptionService.encryptJson(
      key: SecretKey(groupKey),
      context: EncryptionContext(
        collection: 'prayer_requests',
        documentId: doc.id,
        groupId: group.id,
        keyVersion: group.activeKeyVersion,
        payloadVersion: 1,
      ),
      value: {'title': title.trim(), 'body': body.trim()},
    );
    await doc.set({
      'groupId': group.id,
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': newPrayerRequestStatus(),
      'anonymous': false,
      ...payload.toFirestore(),
      'metadata': {
        'hasFollowup': false,
        'hasReminder': false,
        'updateCount': 0,
      },
    });
  }

  Future<void> updateRequest({
    required VesperGroup group,
    required PrayerRequestSummary request,
    required String title,
    required String body,
  }) async {
    final groupKey = await _groupRepository.loadGroupKey(
      group.id,
      group.activeKeyVersion,
    );
    final payload = await _encryptionService.encryptJson(
      key: SecretKey(groupKey),
      context: EncryptionContext(
        collection: 'prayer_requests',
        documentId: request.id,
        groupId: group.id,
        keyVersion: group.activeKeyVersion,
        payloadVersion: 1,
      ),
      value: {'title': title.trim(), 'body': body.trim()},
    );
    await _firestore.collection('prayer_requests').doc(request.id).update({
      'updatedAt': FieldValue.serverTimestamp(),
      ...payload.toFirestore(),
      'metadata.updateCount': FieldValue.increment(1),
    });
  }

  Future<void> setStatus(String requestId, String status) async {
    await _firestore.collection('prayer_requests').doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeRequest(String requestId) async {
    await setStatus(requestId, 'deleted');
  }

  Future<void> markPrayed(String groupId, String requestId) async {
    await _firestore
        .collection('prayer_actions')
        .doc('${requestId}_${_uid}_prayed')
        .set({
          'requestId': requestId,
          'groupId': groupId,
          'userId': _uid,
          'type': 'prayed',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<Map<String, PrayerActivity>> watchPrayerActivity(String groupId) {
    return _firestore
        .collection('prayer_actions')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map(
          (snapshot) => prayerActivityFromActions(
            currentUserId: _uid,
            actions: snapshot.docs.map(PrayerAction.fromDoc),
          ),
        );
  }

  Future<void> reportRequest(String groupId, String requestId) async {
    await _firestore
        .collection('request_reports')
        .doc('${requestId}_$_uid')
        .set({
          'groupId': groupId,
          'requestId': requestId,
          'reportedBy': _uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'open',
          'resolvedAt': null,
          'resolvedBy': null,
        });
  }

  Stream<List<RequestReport>> watchRequestReports(String groupId) {
    return _firestore
        .collection('request_reports')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(RequestReport.fromDoc).toList());
  }

  Future<void> dismissRequestReport(String reportId) async {
    await _firestore.collection('request_reports').doc(reportId).update({
      'status': 'dismissed',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': _uid,
    });
  }

  Future<void> removeReportedRequest(RequestReport report) async {
    final batch = _firestore.batch();
    batch.update(
      _firestore.collection('prayer_requests').doc(report.requestId),
      {'status': 'deleted', 'updatedAt': FieldValue.serverTimestamp()},
    );
    batch.update(_firestore.collection('request_reports').doc(report.id), {
      'status': 'removed',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': _uid,
    });
    await batch.commit();
  }

  Future<void> setFollowUpReminder(
    String requestId,
    DateTime reminderAt,
  ) async {
    await _firestore.collection('prayer_requests').doc(requestId).update({
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata.hasReminder': true,
      'metadata.followUpAt': Timestamp.fromDate(reminderAt),
    });
  }

  Future<List<PrayerRequestSummary>> _decryptRequests(
    VesperGroup group,
    Iterable<_RequestDoc> docs,
  ) async {
    final groupKey = await _groupRepository.loadGroupKey(
      group.id,
      group.activeKeyVersion,
    );
    final requests = <PrayerRequestSummary>[];
    for (final doc in docs) {
      final data = doc.data();
      try {
        final payload = EncryptedPayload.fromFirestore(data);
        final decrypted = await _encryptionService.decryptJson(
          key: SecretKey(groupKey),
          context: EncryptionContext(
            collection: 'prayer_requests',
            documentId: doc.id,
            groupId: group.id,
            keyVersion: payload.keyVersion,
            payloadVersion: payload.payloadVersion,
          ),
          payload: payload,
        );
        requests.add(
          PrayerRequestSummary(
            id: doc.id,
            groupId: group.id,
            createdBy: data['createdBy'] as String? ?? '',
            status: data['status'] as String? ?? 'active',
            createdAt:
                (data['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0),
            title: decrypted['title'] as String? ?? 'Prayer request',
            body: decrypted['body'] as String? ?? '',
          ),
        );
      } on EncryptedPayloadException {
        continue;
      }
    }
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }
}

String newPrayerRequestStatus() => 'active';

List<String> groupFeedStatuses() {
  return ['active'];
}

abstract class _RequestDoc {
  String get id;
  Map<String, dynamic> data();
}

class _CachedRequestDoc implements _RequestDoc {
  _CachedRequestDoc(this._data);

  final Map<String, dynamic> _data;

  @override
  String get id => _data['id'] as String;

  @override
  Map<String, dynamic> data() => _data;
}

class _FirestoreRequestDoc implements _RequestDoc {
  _FirestoreRequestDoc(this._doc);

  final QueryDocumentSnapshot<Map<String, dynamic>> _doc;

  @override
  String get id => _doc.id;

  @override
  Map<String, dynamic> data() => _doc.data();
}
