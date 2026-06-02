import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vesper/core/crypto/group_key_service.dart';

class KeyManager {
  KeyManager({FlutterSecureStorage? storage, GroupKeyService? groupKeyService})
    : _storage = storage ?? const FlutterSecureStorage(),
      _groupKeyService = groupKeyService ?? GroupKeyService();

  final FlutterSecureStorage _storage;
  final GroupKeyService _groupKeyService;

  String _privateKeyKey(String userId) => 'vesper.user.$userId.privateKey';
  String _publicKeyKey(String userId) => 'vesper.user.$userId.publicKey';
  String _userContentKeyKey(String userId) => 'vesper.user.$userId.contentKey';
  String _groupKeyKey(String groupId, int keyVersion) =>
      'vesper.group.$groupId.key.$keyVersion';

  Future<SimplePublicKey> ensureUserKeyPair(String userId) async {
    final existingPublicKey = await readPublicKey(userId);
    if (existingPublicKey != null && await readPrivateKeyPair(userId) != null) {
      return existingPublicKey;
    }

    final memberKeyPair = await _groupKeyService.newMemberKeyPair();
    final privateKeyData = await memberKeyPair.keyPair.extract();
    await _storage.write(
      key: _privateKeyKey(userId),
      value: base64Encode(privateKeyData.bytes),
    );
    await _storage.write(
      key: _publicKeyKey(userId),
      value: base64Encode(memberKeyPair.publicKey.bytes),
    );
    return memberKeyPair.publicKey;
  }

  Future<SimplePublicKey?> readPublicKey(String userId) async {
    final encoded = await _storage.read(key: _publicKeyKey(userId));
    if (encoded == null) return null;
    return SimplePublicKey(base64Decode(encoded), type: KeyPairType.x25519);
  }

  Future<MemberKeyPair?> readPrivateKeyPair(String userId) async {
    final privateKey = await _storage.read(key: _privateKeyKey(userId));
    final publicKey = await readPublicKey(userId);
    if (privateKey == null || publicKey == null) return null;
    return MemberKeyPair(
      keyPair: SimpleKeyPairData(
        base64Decode(privateKey),
        publicKey: publicKey,
        type: KeyPairType.x25519,
      ),
      publicKey: publicKey,
    );
  }

  Future<void> cacheGroupKey({
    required String groupId,
    required int keyVersion,
    required List<int> groupKey,
  }) async {
    await _storage.write(
      key: _groupKeyKey(groupId, keyVersion),
      value: base64Encode(groupKey),
    );
  }

  Future<List<int>?> readCachedGroupKey(String groupId, int keyVersion) async {
    final encoded = await _storage.read(key: _groupKeyKey(groupId, keyVersion));
    return encoded == null ? null : base64Decode(encoded);
  }

  Future<List<int>> ensureUserContentKey(String userId) async {
    final existing = await _storage.read(key: _userContentKeyKey(userId));
    if (existing != null) return base64Decode(existing);
    final key = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    await _storage.write(
      key: _userContentKeyKey(userId),
      value: base64Encode(key),
    );
    return key;
  }
}
