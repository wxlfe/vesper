import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class MemberKeyPair {
  const MemberKeyPair({required this.keyPair, required this.publicKey});

  final SimpleKeyPair keyPair;
  final SimplePublicKey publicKey;
}

class WrappedGroupKey {
  const WrappedGroupKey({
    required this.encryptedGroupKey,
    required this.nonce,
    required this.ephemeralPublicKey,
    required this.algorithm,
  });

  factory WrappedGroupKey.fromFirestore(Map<String, dynamic> data) {
    return WrappedGroupKey(
      encryptedGroupKey: data['encryptedGroupKey'] as String? ?? '',
      nonce: data['nonce'] as String? ?? '',
      ephemeralPublicKey: data['ephemeralPublicKey'] as String? ?? '',
      algorithm: data['algorithm'] as String? ?? GroupKeyService.algorithmName,
    );
  }

  final String encryptedGroupKey;
  final String nonce;
  final String ephemeralPublicKey;
  final String algorithm;

  Map<String, dynamic> toFirestore() {
    return {
      'encryptedGroupKey': encryptedGroupKey,
      'nonce': nonce,
      'ephemeralPublicKey': ephemeralPublicKey,
      'algorithm': algorithm,
    };
  }
}

class GroupKeyService {
  GroupKeyService({Random? random}) : _random = random ?? Random.secure();

  static const algorithmName = 'x25519-xchacha20-poly1305';

  final Random _random;
  final X25519 _keyExchange = X25519();
  final Cipher _cipher = Xchacha20.poly1305Aead();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  List<int> newGroupKeyBytes() => _randomBytes(32);

  Future<MemberKeyPair> newMemberKeyPair() async {
    final keyPair = await _keyExchange.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final keyPairData = await keyPair.extract();
    return MemberKeyPair(
      keyPair: SimpleKeyPairData(
        keyPairData.bytes,
        publicKey: publicKey,
        type: KeyPairType.x25519,
      ),
      publicKey: publicKey,
    );
  }

  Future<WrappedGroupKey> wrapGroupKey({
    required List<int> groupKey,
    required SimplePublicKey memberPublicKey,
  }) async {
    final ephemeralKeyPair = await _keyExchange.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();
    final sharedSecret = await _keyExchange.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: memberPublicKey,
    );
    final salt = _randomBytes(16);
    final wrappingKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: salt,
      info: utf8.encode('vesper-group-key-wrap-v1'),
    );
    final nonce = _randomBytes(24);
    final secretBox = await _cipher.encrypt(
      groupKey,
      secretKey: wrappingKey,
      nonce: nonce,
      aad: utf8.encode(algorithmName),
    );

    return WrappedGroupKey(
      encryptedGroupKey: base64Encode([
        ...salt,
        ...secretBox.concatenation(nonce: false),
      ]),
      nonce: base64Encode(nonce),
      ephemeralPublicKey: base64Encode(ephemeralPublicKey.bytes),
      algorithm: algorithmName,
    );
  }

  Future<List<int>> unwrapGroupKey({
    required WrappedGroupKey wrappedKey,
    required MemberKeyPair memberKeyPair,
  }) async {
    final encrypted = base64Decode(wrappedKey.encryptedGroupKey);
    final salt = encrypted.sublist(0, 16);
    final secretBoxBytes = encrypted.sublist(16);
    final ephemeralPublicKey = SimplePublicKey(
      base64Decode(wrappedKey.ephemeralPublicKey),
      type: KeyPairType.x25519,
    );
    final sharedSecret = await _keyExchange.sharedSecretKey(
      keyPair: memberKeyPair.keyPair,
      remotePublicKey: ephemeralPublicKey,
    );
    final wrappingKey = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: salt,
      info: utf8.encode('vesper-group-key-wrap-v1'),
    );
    final secretBox = SecretBox(
      secretBoxBytes.sublist(0, secretBoxBytes.length - 16),
      nonce: base64Decode(wrappedKey.nonce),
      mac: Mac(secretBoxBytes.sublist(secretBoxBytes.length - 16)),
    );

    return _cipher.decrypt(
      secretBox,
      secretKey: wrappingKey,
      aad: utf8.encode(algorithmName),
    );
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }
}
