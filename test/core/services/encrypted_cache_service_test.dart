import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vesper/core/services/encrypted_cache_service.dart';

void main() {
  test(
    'stores encrypted request records without adding plaintext fields',
    () async {
      SharedPreferences.setMockInitialValues({});
      const service = EncryptedCacheService();

      await service.cacheEncryptedRequests('group-1', const [
        {
          'id': 'request-1',
          'groupId': 'group-1',
          'ciphertext': 'ciphertext-base64',
          'nonce': 'nonce-base64',
          'keyVersion': 1,
          'payloadVersion': 1,
          'algorithm': 'xchacha20-poly1305',
        },
      ]);

      final cached = await service.readEncryptedRequests('group-1');
      final encoded = jsonEncode(cached);

      expect(cached, hasLength(1));
      expect(cached.single['ciphertext'], 'ciphertext-base64');
      expect(encoded, isNot(contains('title')));
      expect(encoded, isNot(contains('body')));
    },
  );

  test('returns an empty list for malformed cached data', () async {
    SharedPreferences.setMockInitialValues({
      'vesper.cache.requests.group-1': '{not-json',
    });
    const service = EncryptedCacheService();

    expect(await service.readEncryptedRequests('group-1'), isEmpty);
  });
}
