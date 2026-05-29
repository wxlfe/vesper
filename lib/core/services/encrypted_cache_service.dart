import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptedCacheService {
  const EncryptedCacheService();

  String _requestsKey(String groupId) => 'vesper.cache.requests.$groupId';

  Future<void> cacheEncryptedRequests(
    String groupId,
    List<Map<String, dynamic>> records,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _requestsKey(groupId),
      jsonEncode(records.map(_toJsonSafe).toList()),
    );
  }

  Future<List<Map<String, dynamic>>> readEncryptedRequests(
    String groupId,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_requestsKey(groupId));
    if (encoded == null) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_fromJsonSafe)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Map<String, dynamic> _toJsonSafe(Map<String, dynamic> record) {
    return record.map((key, value) => MapEntry(key, _jsonSafeValue(value)));
  }

  Object? _jsonSafeValue(Object? value) {
    if (value is Timestamp) {
      return {
        '__type': 'firestore_timestamp',
        'seconds': value.seconds,
        'nanoseconds': value.nanoseconds,
      };
    }
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _jsonSafeValue(item)),
      );
    }
    if (value is Iterable) {
      return value.map(_jsonSafeValue).toList();
    }
    return value;
  }

  Map<String, dynamic> _fromJsonSafe(Map<String, dynamic> record) {
    return record.map((key, value) => MapEntry(key, _cachedValue(value)));
  }

  Object? _cachedValue(Object? value) {
    if (value is Map) {
      final type = value['__type'];
      if (type == 'firestore_timestamp') {
        return Timestamp(value['seconds'] as int, value['nanoseconds'] as int);
      }
      return value.map(
        (key, item) => MapEntry(key.toString(), _cachedValue(item)),
      );
    }
    if (value is List) {
      return value.map(_cachedValue).toList();
    }
    return value;
  }
}
