import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

typedef RandomBytes = List<int> Function(int length);

class InviteCodeService {
  InviteCodeService({RandomBytes? randomBytes})
    : _randomBytes = randomBytes ?? _secureRandomBytes;

  static const defaultTtl = Duration(days: 7);
  static const _alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  final RandomBytes _randomBytes;

  String generateCode() {
    final bytes = _randomBytes(6);
    final suffix = bytes
        .map((byte) => _alphabet[byte % _alphabet.length])
        .join();
    return 'VESPER-$suffix';
  }

  bool isValidCode(String code) {
    return RegExp(r'^VESPER-[2-9A-HJ-NP-Z]{4,8}$').hasMatch(_normalize(code));
  }

  String hashCodeForLookup(String code) {
    return base64Encode(sha256.convert(utf8.encode(_normalize(code))).bytes);
  }

  String _normalize(String code) => code.trim().toUpperCase();

  static List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
