import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class EncryptionContext {
  const EncryptionContext({
    required this.collection,
    required this.documentId,
    required this.groupId,
    required this.keyVersion,
    required this.payloadVersion,
  });

  final String collection;
  final String documentId;
  final String groupId;
  final int keyVersion;
  final int payloadVersion;

  List<int> toAad() {
    return utf8.encode(
      jsonEncode({
        'collection': collection,
        'documentId': documentId,
        'groupId': groupId,
        'keyVersion': keyVersion,
        'payloadVersion': payloadVersion,
      }),
    );
  }
}

class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.keyVersion,
    required this.payloadVersion,
    required this.algorithm,
  });

  factory EncryptedPayload.fromFirestore(Map<String, dynamic> data) {
    return EncryptedPayload(
      ciphertext: data['ciphertext'] as String? ?? '',
      nonce: data['nonce'] as String? ?? '',
      keyVersion: data['keyVersion'] as int? ?? 1,
      payloadVersion: data['payloadVersion'] as int? ?? 1,
      algorithm:
          data['algorithm'] as String? ?? EncryptionService.algorithmName,
    );
  }

  final String ciphertext;
  final String nonce;
  final int keyVersion;
  final int payloadVersion;
  final String algorithm;

  Map<String, dynamic> toFirestore() {
    return {
      'ciphertext': ciphertext,
      'nonce': nonce,
      'keyVersion': keyVersion,
      'payloadVersion': payloadVersion,
      'algorithm': algorithm,
    };
  }
}

class EncryptedPayloadException implements Exception {
  const EncryptedPayloadException(this.message);

  final String message;

  @override
  String toString() => 'EncryptedPayloadException: $message';
}

class EncryptionService {
  EncryptionService({Random? random}) : _random = random ?? Random.secure();

  static const algorithmName = 'xchacha20-poly1305';

  final Random _random;
  final Cipher _cipher = Xchacha20.poly1305Aead();

  SecretKey newGroupKey() {
    return SecretKey(_randomBytes(32));
  }

  Future<EncryptedPayload> encryptJson({
    required SecretKey key,
    required EncryptionContext context,
    required Map<String, dynamic> value,
  }) async {
    final nonce = _randomBytes(24);
    final clearText = utf8.encode(jsonEncode(value));
    final secretBox = await _cipher.encrypt(
      clearText,
      secretKey: key,
      nonce: nonce,
      aad: context.toAad(),
    );

    return EncryptedPayload(
      ciphertext: base64Encode(secretBox.concatenation(nonce: false)),
      nonce: base64Encode(nonce),
      keyVersion: context.keyVersion,
      payloadVersion: context.payloadVersion,
      algorithm: algorithmName,
    );
  }

  Future<Map<String, dynamic>> decryptJson({
    required SecretKey key,
    required EncryptionContext context,
    required EncryptedPayload payload,
  }) async {
    if (payload.algorithm != algorithmName) {
      throw const EncryptedPayloadException(
        'Unsupported encrypted payload version.',
      );
    }

    try {
      final encryptedBytes = base64Decode(payload.ciphertext);
      final secretBox = SecretBox(
        encryptedBytes.sublist(0, encryptedBytes.length - 16),
        nonce: base64Decode(payload.nonce),
        mac: Mac(encryptedBytes.sublist(encryptedBytes.length - 16)),
      );
      final clearText = await _cipher.decrypt(
        secretBox,
        secretKey: key,
        aad: context.toAad(),
      );
      final decoded = jsonDecode(utf8.decode(clearText));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw const EncryptedPayloadException(
        'Encrypted payload did not decode to an object.',
      );
    } on SecretBoxAuthenticationError catch (_) {
      throw const EncryptedPayloadException(
        'Encrypted payload could not be opened.',
      );
    } on FormatException catch (_) {
      throw const EncryptedPayloadException('Encrypted payload is malformed.');
    }
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }
}
