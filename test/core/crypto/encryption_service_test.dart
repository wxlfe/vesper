import 'dart:convert';

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
}
