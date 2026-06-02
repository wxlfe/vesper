import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vesper/core/crypto/encryption_service.dart';
import 'package:vesper/core/crypto/key_manager.dart';
import 'package:vesper/core/models/app_models.dart';

class PrayerSessionRepository {
  PrayerSessionRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required EncryptionService encryptionService,
    required KeyManager keyManager,
  }) : _auth = auth,
       _firestore = firestore,
       _encryptionService = encryptionService,
       _keyManager = keyManager;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final EncryptionService _encryptionService;
  final KeyManager _keyManager;

  String get _uid => _auth.currentUser!.uid;

  Stream<List<PrayerSession>> watchSessions() {
    return _firestore
        .collection('prayer_sessions')
        .where('userId', isEqualTo: _uid)
        .where('status', isEqualTo: 'active')
        .orderBy('sortOrder')
        .snapshots()
        .asyncMap((snapshot) async {
          final sessions = <PrayerSession>[];
          for (final doc in snapshot.docs) {
            final session = await _decryptSession(doc);
            if (session != null) sessions.add(session);
          }
          return sessions;
        });
  }

  Stream<List<RoutineSection>> watchSections(String sessionId) {
    return _firestore
        .collection('routine_sections')
        .where('userId', isEqualTo: _uid)
        .where('sessionId', isEqualTo: sessionId)
        .where('status', isEqualTo: 'active')
        .orderBy('sortOrder')
        .snapshots()
        .asyncMap((snapshot) async {
          final sections = <RoutineSection>[];
          for (final doc in snapshot.docs) {
            final section = await _decryptSection(doc);
            if (section != null) sections.add(section);
          }
          return sortedRoutineSections(sections);
        });
  }

  Future<PrayerSession> createSession(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw StateError('Routine name is required.');
    final doc = _firestore.collection('prayer_sessions').doc();
    final key = await _userContentSecretKey();
    final payload = await _encryptionService.encryptJson(
      key: key,
      context: EncryptionContext(
        collection: 'prayer_sessions',
        documentId: doc.id,
        scopeId: _uid,
        keyVersion: 1,
        payloadVersion: 1,
      ),
      value: {'name': trimmed},
    );
    await doc.set({
      'userId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'sortOrder': DateTime.now().millisecondsSinceEpoch,
      'reminder': {'enabled': false},
      ...payload.toFirestore(),
    });
    return PrayerSession(
      id: doc.id,
      userId: _uid,
      status: 'active',
      sortOrder: DateTime.now().millisecondsSinceEpoch,
      name: trimmed,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> updateSessionName(PrayerSession session, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw StateError('Routine name is required.');
    final key = await _userContentSecretKey();
    final payload = await _encryptionService.encryptJson(
      key: key,
      context: EncryptionContext(
        collection: 'prayer_sessions',
        documentId: session.id,
        scopeId: _uid,
        keyVersion: 1,
        payloadVersion: 1,
      ),
      value: {'name': trimmed},
    );
    await _firestore.collection('prayer_sessions').doc(session.id).update({
      'updatedAt': FieldValue.serverTimestamp(),
      ...payload.toFirestore(),
    });
  }

  Future<void> archiveSession(String sessionId) async {
    await _firestore.collection('prayer_sessions').doc(sessionId).update({
      'status': 'archived',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addSection({
    required String sessionId,
    required RoutineSectionType type,
    required String title,
    required String text,
  }) async {
    final doc = _firestore.collection('routine_sections').doc();
    final key = await _userContentSecretKey();
    final payload = await _encryptionService.encryptJson(
      key: key,
      context: EncryptionContext(
        collection: 'routine_sections',
        documentId: doc.id,
        scopeId: _uid,
        keyVersion: 1,
        payloadVersion: 1,
      ),
      value: {
        'title': title.trim(),
        'text': text.trim(),
        'type': routineSectionTypeToString(type),
      },
    );
    await doc.set({
      'userId': _uid,
      'sessionId': sessionId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'sortOrder': DateTime.now().millisecondsSinceEpoch,
      'type': routineSectionTypeToString(type),
      'status': 'active',
      ...payload.toFirestore(),
    });
  }

  Future<void> updateSection(RoutineSection section) async {
    final key = await _userContentSecretKey();
    final payload = await _encryptionService.encryptJson(
      key: key,
      context: EncryptionContext(
        collection: 'routine_sections',
        documentId: section.id,
        scopeId: _uid,
        keyVersion: 1,
        payloadVersion: 1,
      ),
      value: {
        'title': section.title.trim(),
        'text': section.text.trim(),
        'type': routineSectionTypeToString(section.type),
      },
    );
    await _firestore.collection('routine_sections').doc(section.id).update({
      'updatedAt': FieldValue.serverTimestamp(),
      'sortOrder': section.sortOrder,
      'type': routineSectionTypeToString(section.type),
      ...payload.toFirestore(),
    });
  }

  Future<void> removeSection(String sectionId) async {
    await _firestore.collection('routine_sections').doc(sectionId).update({
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<SecretKey> _userContentSecretKey() async {
    final key = await _keyManager.ensureUserContentKey(_uid);
    return SecretKey(key);
  }

  Future<PrayerSession?> _decryptSession(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = doc.data();
      final payload = EncryptedPayload.fromFirestore(data);
      final decrypted = await _encryptionService.decryptJson(
        key: await _userContentSecretKey(),
        context: EncryptionContext(
          collection: 'prayer_sessions',
          documentId: doc.id,
          scopeId: _uid,
          keyVersion: payload.keyVersion,
          payloadVersion: payload.payloadVersion,
        ),
        payload: payload,
      );
      return PrayerSession(
        id: doc.id,
        userId: data['userId'] as String? ?? _uid,
        status: data['status'] as String? ?? 'active',
        sortOrder: data['sortOrder'] as int? ?? 0,
        name: decrypted['name'] as String? ?? 'Prayer routine',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime(1970),
      );
    } on EncryptedPayloadException {
      return null;
    }
  }

  Future<RoutineSection?> _decryptSection(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final data = doc.data();
      final payload = EncryptedPayload.fromFirestore(data);
      final decrypted = await _encryptionService.decryptJson(
        key: await _userContentSecretKey(),
        context: EncryptionContext(
          collection: 'routine_sections',
          documentId: doc.id,
          scopeId: _uid,
          keyVersion: payload.keyVersion,
          payloadVersion: payload.payloadVersion,
        ),
        payload: payload,
      );
      return RoutineSection(
        id: doc.id,
        sessionId: data['sessionId'] as String? ?? '',
        userId: data['userId'] as String? ?? _uid,
        type: routineSectionTypeFromString(
          decrypted['type'] as String? ?? data['type'] as String? ?? '',
        ),
        sortOrder: data['sortOrder'] as int? ?? 0,
        status: data['status'] as String? ?? 'active',
        title: decrypted['title'] as String? ?? '',
        text: decrypted['text'] as String? ?? '',
      );
    } on EncryptedPayloadException {
      return null;
    }
  }
}
