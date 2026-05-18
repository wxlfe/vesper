import 'package:cloud_firestore/cloud_firestore.dart';

class VesperUserProfile {
  const VesperUserProfile({
    required this.id,
    required this.displayName,
    required this.publicKey,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String publicKey;
  final DateTime createdAt;

  factory VesperUserProfile.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return VesperUserProfile(
      id: doc.id,
      displayName: data['displayName'] as String? ?? 'Someone',
      publicKey: data['publicKey'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class VesperGroup {
  const VesperGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.activeKeyVersion,
    required this.requireApproval,
  });

  final String id;
  final String name;
  final String description;
  final String createdBy;
  final int activeKeyVersion;
  final bool requireApproval;

  factory VesperGroup.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final settings =
        data['settings'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return VesperGroup(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled group',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      activeKeyVersion: data['activeKeyVersion'] as int? ?? 1,
      requireApproval: settings['requireApproval'] as bool? ?? true,
    );
  }
}

class GroupMembership {
  const GroupMembership({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    this.invitedBy,
  });

  final String id;
  final String groupId;
  final String userId;
  final String role;
  final String status;
  final String? invitedBy;

  bool get isLeader => role == 'leader' && status == 'active';

  factory GroupMembership.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return GroupMembership(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      role: data['role'] as String? ?? 'member',
      status: data['status'] as String? ?? 'pending',
      invitedBy: data['invitedBy'] as String?,
    );
  }
}

class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.groupId,
    required this.requestedBy,
    required this.invitedBy,
    required this.status,
  });

  final String id;
  final String groupId;
  final String requestedBy;
  final String? invitedBy;
  final String status;

  factory JoinRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return JoinRequest(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      requestedBy: data['requestedBy'] as String? ?? '',
      invitedBy: data['invitedBy'] as String?,
      status: data['status'] as String? ?? 'pending',
    );
  }
}

class PrayerRequestSummary {
  const PrayerRequestSummary({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.title,
    required this.body,
  });

  final String id;
  final String groupId;
  final String createdBy;
  final String status;
  final DateTime createdAt;
  final String title;
  final String body;
}
