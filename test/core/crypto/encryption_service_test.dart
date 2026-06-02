import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/core/crypto/encryption_service.dart';

void main() {
  test('encrypts and decrypts JSON payload with matching context', () async {
    final service = EncryptionService();
    final key = service.newGroupKey();
    final context = EncryptionContext(
      collection: 'prayer_requests',
      documentId: 'request-1',
      groupId: 'group-1',
      keyVersion: 1,
      payloadVersion: 1,
    );

    final payload = await service.encryptJson(
      key: key,
      context: context,
      value: const {'title': 'Please pray', 'body': 'Private request body'},
    );

    expect(payload.ciphertext, isNot(contains('Please pray')));
    expect(payload.ciphertext, isNot(contains('Private request body')));

    final decrypted = await service.decryptJson(
      key: key,
      context: context,
      payload: payload,
    );

    expect(decrypted['title'], 'Please pray');
    expect(decrypted['body'], 'Private request body');
  });

  test('rejects ciphertext when authenticated context changes', () async {
    final service = EncryptionService();
    final key = service.newGroupKey();
    final payload = await service.encryptJson(
      key: key,
      context: const EncryptionContext(
        collection: 'prayer_requests',
        documentId: 'request-1',
        groupId: 'group-1',
        keyVersion: 1,
        payloadVersion: 1,
      ),
      value: const {'title': 'Private'},
    );

    expect(
      () => service.decryptJson(
        key: key,
        context: const EncryptionContext(
          collection: 'prayer_requests',
          documentId: 'request-2',
          groupId: 'group-1',
          keyVersion: 1,
          payloadVersion: 1,
        ),
        payload: payload,
      ),
      throwsA(isA<EncryptedPayloadException>()),
    );
  });

  test('encrypted payload serializes without plaintext fields', () async {
    final service = EncryptionService();
    final key = service.newGroupKey();
    final payload = await service.encryptJson(
      key: key,
      context: const EncryptionContext(
        collection: 'prayer_requests',
        documentId: 'request-1',
        groupId: 'group-1',
        keyVersion: 1,
        payloadVersion: 1,
      ),
      value: const {'title': 'Sensitive title', 'body': 'Sensitive body'},
    );

    final encoded = jsonEncode(payload.toFirestore());

    expect(encoded, isNot(contains('Sensitive title')));
    expect(encoded, isNot(contains('Sensitive body')));
    expect(payload.toFirestore().keys, containsAll(['ciphertext', 'nonce']));
  });

  test('rejects routine ciphertext when owner context changes', () async {
    final service = EncryptionService();
    final key = service.newGroupKey();
    final payload = await service.encryptJson(
      key: key,
      context: const EncryptionContext(
        collection: 'prayer_sessions',
        documentId: 'session-1',
        scopeId: 'user-1',
        keyVersion: 1,
        payloadVersion: 1,
      ),
      value: const {'name': 'Morning Prayer'},
    );

    expect(
      () => service.decryptJson(
        key: key,
        context: const EncryptionContext(
          collection: 'prayer_sessions',
          documentId: 'session-1',
          scopeId: 'user-2',
          keyVersion: 1,
          payloadVersion: 1,
        ),
        payload: payload,
      ),
      throwsA(isA<EncryptedPayloadException>()),
    );
  });

  test('decrypts prayer requests encrypted with legacy groupId AAD', () async {
    final service = EncryptionService();
    final key = service.newGroupKey();
    final payload = await _encryptWithLegacyGroupIdAad(
      key: key,
      collection: 'prayer_requests',
      documentId: 'request-1',
      groupId: 'group-1',
      value: const {'title': 'Legacy request', 'body': 'Still visible'},
    );

    final decrypted = await service.decryptJson(
      key: key,
      context: const EncryptionContext(
        collection: 'prayer_requests',
        documentId: 'request-1',
        groupId: 'group-1',
        keyVersion: 1,
        payloadVersion: 1,
      ),
      fallbackContexts: const [
        LegacyGroupEncryptionContext(
          collection: 'prayer_requests',
          documentId: 'request-1',
          groupId: 'group-1',
          keyVersion: 1,
          payloadVersion: 1,
        ),
      ],
      payload: payload,
    );

    expect(decrypted['title'], 'Legacy request');
    expect(decrypted['body'], 'Still visible');
  });
}

Future<EncryptedPayload> _encryptWithLegacyGroupIdAad({
  required SecretKey key,
  required String collection,
  required String documentId,
  required String groupId,
  required Map<String, dynamic> value,
}) async {
  final nonce = List<int>.generate(24, (index) => index + 1);
  final secretBox = await Xchacha20.poly1305Aead().encrypt(
    utf8.encode(jsonEncode(value)),
    secretKey: key,
    nonce: nonce,
    aad: utf8.encode(
      jsonEncode({
        'collection': collection,
        'documentId': documentId,
        'groupId': groupId,
        'keyVersion': 1,
        'payloadVersion': 1,
      }),
    ),
  );

  return EncryptedPayload(
    ciphertext: base64Encode(secretBox.concatenation(nonce: false)),
    nonce: base64Encode(nonce),
    keyVersion: 1,
    payloadVersion: 1,
    algorithm: EncryptionService.algorithmName,
  );
}
