import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vesper/core/crypto/encryption_service.dart';
import 'package:vesper/core/crypto/group_key_service.dart';
import 'package:vesper/core/crypto/key_manager.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/core/services/encrypted_cache_service.dart';
import 'package:vesper/features/groups/data/group_repository.dart';

class PrayerRequestRepository {
  PrayerRequestRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required EncryptionService encryptionService,
    required GroupKeyService groupKeyService,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
    required EncryptedCacheService encryptedCache,
  }) : _auth = auth,
       _firestore = firestore,
       _encryptionService = encryptionService,
       _groupKeyService = groupKeyService,
       _keyManager = keyManager,
       _groupRepository = groupRepository,
       _encryptedCache = encryptedCache;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;
  final GroupKeyService _groupKeyService;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;
  final EncryptedCacheService _encryptedCache;

  String get _uid => _auth.currentUser!.uid;

  Stream<List<PrayerRequestSummary>> watchRequests(VesperGroup group) {
    final statuses = groupFeedStatuses();
    var query = _firestore
        .collection('request_shares')
        .where('groupId', isEqualTo: group.id);
    query = statuses.length == 1
        ? query.where('status', isEqualTo: statuses.first)
        : query.where('status', whereIn: statuses);
    query = query.orderBy('sharedAt', descending: true);
    return query.snapshots().asyncMap((snapshot) async {
      return _readSharedRequests(group, snapshot.docs);
    });
  }

  Future<List<PrayerRequestSummary>> readCachedRequests(
    VesperGroup group,
  ) async {
    final cached = await _encryptedCache.readEncryptedRequests(group.id);
    final docs = cached.map(_CachedRequestDoc.new).toList();
    return _decryptRequests(group, docs);
  }

  Stream<List<PrayerRequestSummary>> watchMyRequests() {
    return _firestore
        .collection('prayer_requests')
        .where('createdBy', isEqualTo: _uid)
        .where('status', whereIn: profileRequestStatuses())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = <PrayerRequestSummary>[];
          const personalGroup = VesperGroup(
            id: '',
            name: 'Private',
            description: '',
            createdBy: '',
            activeKeyVersion: 1,
          );
          for (final doc in snapshot.docs) {
            final request = await _decryptRequest(
              personalGroup,
              _DocumentRequestDoc(doc),
            );
            if (request != null) requests.add(request);
          }
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  Future<void> createRequest({
    required VesperGroup group,
    required String title,
    required String body,
    String? bodyDeltaJson,
  }) {
    return createRequestForGroups(
      groups: [group],
      title: title,
      body: body,
      bodyDeltaJson: bodyDeltaJson,
    );
  }

  Future<void> createPrivateRequest({
    required String title,
    required String body,
    String? bodyDeltaJson,
  }) async {
    final doc = _firestore.collection('prayer_requests').doc();
    final requestKey = _groupKeyService.newGroupKeyBytes();
    final payload = await _encryptionService.encryptJson(
      key: SecretKey(requestKey),
      context: EncryptionContext(
        collection: 'prayer_requests',
        documentId: doc.id,
        scopeId: doc.id,
        keyVersion: 1,
        payloadVersion: 3,
      ),
      value: requestContentPayload(
        title: title,
        body: body,
        bodyDeltaJson: bodyDeltaJson ?? plainTextToRichTextDeltaJson(body),
      ),
    );
    final grant = await _requestKeyGrantData(
      requestId: doc.id,
      userId: _uid,
      grantedViaGroupId: null,
      requestKey: requestKey,
    );
    final batch = _firestore.batch();
    batch.set(
      doc,
      canonicalPrayerRequestData(createdBy: _uid, payload: payload),
    );
    batch.set(
      _firestore
          .collection('request_key_grants')
          .doc(requestKeyGrantId(doc.id, _uid)),
      grant,
    );
    await batch.commit();
  }

  Future<void> createRequestForGroups({
    required List<VesperGroup> groups,
    required String title,
    required String body,
    String? bodyDeltaJson,
  }) async {
    final doc = _firestore.collection('prayer_requests').doc();
    final requestKey = _groupKeyService.newGroupKeyBytes();
    final payload = await _encryptionService.encryptJson(
      key: SecretKey(requestKey),
      context: EncryptionContext(
        collection: 'prayer_requests',
        documentId: doc.id,
        scopeId: doc.id,
        keyVersion: 1,
        payloadVersion: 3,
      ),
      value: requestContentPayload(
        title: title,
        body: body,
        bodyDeltaJson: bodyDeltaJson ?? plainTextToRichTextDeltaJson(body),
      ),
    );
    final batch = _firestore.batch();
    batch.set(
      doc,
      canonicalPrayerRequestData(createdBy: _uid, payload: payload),
    );
    batch.set(
      _firestore
          .collection('request_key_grants')
          .doc(requestKeyGrantId(doc.id, _uid)),
      await _requestKeyGrantData(
        requestId: doc.id,
        userId: _uid,
        grantedViaGroupId: null,
        requestKey: requestKey,
      ),
    );
    final grantedUserIds = <String>{_uid};
    for (final group in groups) {
      batch.set(
        _firestore
            .collection('request_shares')
            .doc(requestShareId(doc.id, group.id)),
        requestShareData(requestId: doc.id, groupId: group.id, sharedBy: _uid),
      );
      final members = await _activeMembers(group.id);
      for (final member in members) {
        if (!grantedUserIds.add(member.userId)) continue;
        batch.set(
          _firestore
              .collection('request_key_grants')
              .doc(requestKeyGrantId(doc.id, member.userId)),
          await _requestKeyGrantData(
            requestId: doc.id,
            userId: member.userId,
            grantedViaGroupId: group.id,
            requestKey: requestKey,
          ),
        );
      }
    }
    await batch.commit();
  }

  Future<void> backfillRequestGrantsForMember({
    required VesperGroup group,
    required String memberUserId,
  }) async {
    final shareSnapshot = await _firestore
        .collection('request_shares')
        .where('groupId', isEqualTo: group.id)
        .where('status', isEqualTo: 'active')
        .get();
    final batch = _firestore.batch();
    var hasWrites = false;
    for (final share in shareSnapshot.docs) {
      final requestId = share.data()['requestId'] as String? ?? '';
      if (requestId.isEmpty) continue;
      final existingGrant = await _firestore
          .collection('request_key_grants')
          .doc(requestKeyGrantId(requestId, memberUserId))
          .get();
      if (existingGrant.exists) continue;
      final requestKey = await _loadRequestKey(requestId);
      batch.set(
        _firestore
            .collection('request_key_grants')
            .doc(requestKeyGrantId(requestId, memberUserId)),
        await _requestKeyGrantData(
          requestId: requestId,
          userId: memberUserId,
          grantedViaGroupId: group.id,
          requestKey: requestKey,
        ),
      );
      hasWrites = true;
    }
    if (hasWrites) await batch.commit();
  }

  Future<void> updateRequest({
    required VesperGroup group,
    required PrayerRequestSummary request,
    required String title,
    required String body,
    String? bodyDeltaJson,
  }) async {
    final requestKey = await _loadRequestKey(request.id);
    final payload = await _encryptionService.encryptJson(
      key: SecretKey(requestKey),
      context: EncryptionContext(
        collection: 'prayer_requests',
        documentId: request.id,
        scopeId: request.id,
        keyVersion: 1,
        payloadVersion: 3,
      ),
      value: requestContentPayload(
        title: title,
        body: body,
        bodyDeltaJson: bodyDeltaJson ?? plainTextToRichTextDeltaJson(body),
      ),
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
          'userId': _uid,
          'type': 'prayed',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<Map<String, PrayerActivity>> watchPrayerActivity(String groupId) {
    return _firestore
        .collection('request_shares')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((shares) async {
          final requestIds = shares.docs
              .map((doc) => doc.data()['requestId'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          return _readPrayerActivityForRequestIds(requestIds);
        });
  }

  Stream<Map<String, PrayerActivity>> watchPrayerActivityForRequests(
    Iterable<String> requestIds,
  ) {
    return Stream.fromFuture(_readPrayerActivityForRequestIds(requestIds));
  }

  Future<Map<String, PrayerActivity>> _readPrayerActivityForRequestIds(
    Iterable<String> requestIds,
  ) async {
    final ids = requestIds.toSet();
    if (ids.isEmpty) return const {};
    final actions = <PrayerAction>[];
    for (final requestId in ids) {
      final snapshot = await _firestore
          .collection('prayer_actions')
          .where('requestId', isEqualTo: requestId)
          .where('type', isEqualTo: 'prayed')
          .get();
      actions.addAll(snapshot.docs.map(PrayerAction.fromDoc));
    }
    return prayerActivityFromActions(currentUserId: _uid, actions: actions);
  }

  Stream<Map<String, PrayerActivity>> watchLegacyPrayerActivity(
    String groupId,
  ) {
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
        .doc(
          requestReportId(requestId: requestId, groupId: groupId, userId: _uid),
        )
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

  Future<void> reportRequestForGroups(
    Iterable<VesperGroup> groups,
    String requestId,
  ) async {
    final batch = _firestore.batch();
    for (final group in groups) {
      batch.set(
        _firestore
            .collection('request_reports')
            .doc(
              requestReportId(
                requestId: requestId,
                groupId: group.id,
                userId: _uid,
              ),
            ),
        {
          'groupId': group.id,
          'requestId': requestId,
          'reportedBy': _uid,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'open',
          'resolvedAt': null,
          'resolvedBy': null,
        },
      );
    }
    await batch.commit();
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
      _firestore
          .collection('request_shares')
          .doc(requestShareId(report.requestId, report.groupId)),
      {
        'status': 'removed',
        'removedAt': FieldValue.serverTimestamp(),
        'removedBy': _uid,
      },
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

  Future<List<PrayerRequestSummary>> _readSharedRequests(
    VesperGroup group,
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> shares,
  ) async {
    final requests = <PrayerRequestSummary>[];
    final rawRecords = <Map<String, dynamic>>[];
    for (final share in shares) {
      final requestId = share.data()['requestId'] as String? ?? '';
      if (requestId.isEmpty) continue;
      final doc = await _firestore
          .collection('prayer_requests')
          .doc(requestId)
          .get();
      if (!doc.exists) continue;
      rawRecords.add({'id': doc.id, ...?doc.data()});
      final request = await _decryptRequest(group, _DocumentRequestDoc(doc));
      if (request != null) requests.add(request);
    }
    await _encryptedCache.cacheEncryptedRequests(group.id, rawRecords);
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  Future<PrayerRequestSummary?> _decryptRequest(
    VesperGroup group,
    _RequestDoc doc,
  ) async {
    final data = doc.data();
    try {
      final payload = EncryptedPayload.fromFirestore(data);
      final requestKey = await _loadRequestKey(doc.id);
      final decrypted = await _encryptionService.decryptJson(
        key: SecretKey(requestKey),
        context: EncryptionContext(
          collection: 'prayer_requests',
          documentId: doc.id,
          scopeId: doc.id,
          keyVersion: payload.keyVersion,
          payloadVersion: payload.payloadVersion,
        ),
        payload: payload,
      );
      return PrayerRequestSummary(
        id: doc.id,
        groupId: group.id,
        createdBy: data['createdBy'] as String? ?? '',
        status: data['status'] as String? ?? 'active',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0),
        title: decrypted['title'] as String? ?? 'Prayer request',
        body: decrypted['body'] as String? ?? '',
        bodyDeltaJson: requestBodyDeltaJsonFromPayload(decrypted),
      );
    } on EncryptedPayloadException {
      return null;
    }
  }

  Future<List<PrayerRequestSummary>> _decryptRequests(
    VesperGroup group,
    Iterable<_RequestDoc> docs,
  ) async {
    final groupKeys = <int, List<int>>{};
    final requests = <PrayerRequestSummary>[];
    for (final doc in docs) {
      final data = doc.data();
      try {
        final request = await _decryptRequest(group, doc);
        if (request != null) {
          requests.add(request);
          continue;
        }
        final payload = EncryptedPayload.fromFirestore(data);
        final groupKey = groupKeys[payload.keyVersion] ??=
            await _groupRepository.loadGroupKey(group.id, payload.keyVersion);
        final decrypted = await _encryptionService.decryptJson(
          key: SecretKey(groupKey),
          context: EncryptionContext(
            collection: 'prayer_requests',
            documentId: doc.id,
            groupId: group.id,
            keyVersion: payload.keyVersion,
            payloadVersion: payload.payloadVersion,
          ),
          fallbackContexts: [
            LegacyGroupEncryptionContext(
              collection: 'prayer_requests',
              documentId: doc.id,
              groupId: group.id,
              keyVersion: payload.keyVersion,
              payloadVersion: payload.payloadVersion,
            ),
          ],
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
            bodyDeltaJson: requestBodyDeltaJsonFromPayload(decrypted),
          ),
        );
      } on EncryptedPayloadException {
        continue;
      }
    }
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return requests;
  }

  Future<List<GroupMembership>> _activeMembers(String groupId) async {
    final snapshot = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.map(GroupMembership.fromDoc).toList();
  }

  Future<Map<String, dynamic>> _requestKeyGrantData({
    required String requestId,
    required String userId,
    required String? grantedViaGroupId,
    required List<int> requestKey,
  }) async {
    final publicKey = userId == _uid
        ? await _keyManager.ensureUserKeyPair(userId)
        : await _readUserPublicKey(userId);
    final wrappedKey = await _groupKeyService.wrapGroupKey(
      groupKey: requestKey,
      memberPublicKey: publicKey,
    );
    return requestKeyGrantData(
      requestId: requestId,
      userId: userId,
      grantedBy: _uid,
      grantedViaGroupId: grantedViaGroupId,
      wrappedKey: wrappedKey,
    );
  }

  Future<SimplePublicKey> _readUserPublicKey(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final encoded = doc.data()?['publicKey'] as String? ?? '';
    if (encoded.isEmpty) throw StateError('User public key is missing.');
    return SimplePublicKey(base64Decode(encoded), type: KeyPairType.x25519);
  }

  Future<List<int>> _loadRequestKey(String requestId) async {
    final grantSnapshot = await _firestore
        .collection('request_key_grants')
        .where('requestId', isEqualTo: requestId)
        .where('userId', isEqualTo: _uid)
        .limit(1)
        .get();
    if (grantSnapshot.docs.isEmpty) {
      throw const EncryptedPayloadException('Request key grant is missing.');
    }
    final grantDoc = grantSnapshot.docs.first;
    final privateKeyPair = await _keyManager.readPrivateKeyPair(_uid);
    if (privateKeyPair == null) {
      throw const EncryptedPayloadException('Local private key is missing.');
    }
    return _groupKeyService.unwrapGroupKey(
      wrappedKey: WrappedGroupKey.fromFirestore(grantDoc.data()),
      memberKeyPair: privateKeyPair,
    );
  }
}

String requestShareId(String requestId, String groupId) =>
    '${requestId}_$groupId';

String requestKeyGrantId(String requestId, String userId) =>
    '${requestId}_$userId';

String requestReportId({
  required String requestId,
  required String groupId,
  required String userId,
}) => '${requestId}_${groupId}_$userId';

Map<String, dynamic> canonicalPrayerRequestData({
  required String createdBy,
  required EncryptedPayload payload,
}) {
  return {
    'createdBy': createdBy,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'status': newPrayerRequestStatus(),
    'anonymous': false,
    ...payload.toFirestore(),
    'metadata': {'hasFollowup': false, 'hasReminder': false, 'updateCount': 0},
  };
}

Map<String, dynamic> requestShareData({
  required String requestId,
  required String groupId,
  required String sharedBy,
}) {
  return {
    'requestId': requestId,
    'groupId': groupId,
    'sharedBy': sharedBy,
    'sharedAt': FieldValue.serverTimestamp(),
    'status': 'active',
    'removedAt': null,
    'removedBy': null,
  };
}

Map<String, dynamic> requestKeyGrantData({
  required String requestId,
  required String userId,
  required String grantedBy,
  required String? grantedViaGroupId,
  required WrappedGroupKey wrappedKey,
}) {
  return {
    'requestId': requestId,
    'userId': userId,
    'grantedBy': grantedBy,
    'grantedViaGroupId': grantedViaGroupId,
    'createdAt': FieldValue.serverTimestamp(),
    ...wrappedKey.toFirestore(),
  };
}

String newPrayerRequestStatus() => 'active';

List<String> groupFeedStatuses() {
  return ['active'];
}

List<String> profileRequestStatuses() {
  return ['active', 'answered', 'resolved', 'archived'];
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

class _DocumentRequestDoc implements _RequestDoc {
  _DocumentRequestDoc(this._doc);

  final DocumentSnapshot<Map<String, dynamic>> _doc;

  @override
  String get id => _doc.id;

  @override
  Map<String, dynamic> data() => _doc.data() ?? const {};
}
