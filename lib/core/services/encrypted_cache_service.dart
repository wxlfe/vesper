import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EncryptedCacheService {
  const EncryptedCacheService();

  String _requestsKey(String groupId) => 'vesper.cache.requests.$groupId';

  Future<void> cacheEncryptedRequests(
    String groupId,
    List<Map<String, dynamic>> records,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_requestsKey(groupId), jsonEncode(records));
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
          .toList();
    } on FormatException {
      return const [];
    }
  }
}
