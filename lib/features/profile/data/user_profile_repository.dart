import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserProfileRepository {
  Future<Map<String, String>> displayNamesFor(Iterable<String> userIds);
}

class FirestoreUserProfileRepository implements UserProfileRepository {
  const FirestoreUserProfileRepository({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, String>> displayNamesFor(Iterable<String> userIds) async {
    final ids = userIds.where((id) => id.trim().isNotEmpty).toSet();
    final names = <String, String>{};
    for (final id in ids) {
      final doc = await _firestore.collection('users').doc(id).get();
      final name = doc.data()?['displayName'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        names[id] = name.trim();
      }
    }
    return names;
  }
}

String displayNameFor(Map<String, String> names, String userId) {
  final name = names[userId];
  return name == null || name.trim().isEmpty ? 'Someone' : name.trim();
}
