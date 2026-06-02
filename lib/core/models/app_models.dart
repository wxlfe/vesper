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
  });

  final String id;
  final String name;
  final String description;
  final String createdBy;
  final int activeKeyVersion;

  factory VesperGroup.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return VesperGroup(
      id: doc.id,
      name: data['name'] as String? ?? 'Untitled group',
      description: data['description'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      activeKeyVersion: data['activeKeyVersion'] as int? ?? 1,
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

class PrayerAction {
  const PrayerAction({
    required this.requestId,
    required this.userId,
    required this.type,
  });

  final String requestId;
  final String userId;
  final String type;

  factory PrayerAction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PrayerAction(
      requestId: data['requestId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      type: data['type'] as String? ?? '',
    );
  }
}

class PrayerActivity {
  const PrayerActivity({
    required this.prayedCount,
    required this.hasCurrentUserPrayed,
  });

  final int prayedCount;
  final bool hasCurrentUserPrayed;
}

Map<String, PrayerActivity> prayerActivityFromActions({
  required String currentUserId,
  required Iterable<PrayerAction> actions,
}) {
  final prayedByRequest = <String, Set<String>>{};
  for (final action in actions) {
    if (action.type != 'prayed' ||
        action.requestId.isEmpty ||
        action.userId.isEmpty) {
      continue;
    }
    prayedByRequest
        .putIfAbsent(action.requestId, () => <String>{})
        .add(action.userId);
  }
  return prayedByRequest.map(
    (requestId, userIds) => MapEntry(
      requestId,
      PrayerActivity(
        prayedCount: userIds.length,
        hasCurrentUserPrayed: userIds.contains(currentUserId),
      ),
    ),
  );
}

class RequestReport {
  const RequestReport({
    required this.id,
    required this.groupId,
    required this.requestId,
    required this.reportedBy,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  final String id;
  final String groupId;
  final String requestId;
  final String reportedBy;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  factory RequestReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return RequestReport(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      requestId: data['requestId'] as String? ?? '',
      reportedBy: data['reportedBy'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: data['resolvedBy'] as String?,
    );
  }
}

enum RoutineSectionType {
  customText,
  requestFeed,
  heading,
  silence,
  readingPlaceholder,
}

RoutineSectionType routineSectionTypeFromString(String value) {
  return switch (value) {
    'request_feed' => RoutineSectionType.requestFeed,
    'heading' => RoutineSectionType.heading,
    'silence' => RoutineSectionType.silence,
    'reading_placeholder' => RoutineSectionType.readingPlaceholder,
    _ => RoutineSectionType.customText,
  };
}

String routineSectionTypeToString(RoutineSectionType value) {
  return switch (value) {
    RoutineSectionType.customText => 'custom_text',
    RoutineSectionType.requestFeed => 'request_feed',
    RoutineSectionType.heading => 'heading',
    RoutineSectionType.silence => 'silence',
    RoutineSectionType.readingPlaceholder => 'reading_placeholder',
  };
}

class PrayerSession {
  const PrayerSession({
    required this.id,
    required this.userId,
    required this.status,
    required this.sortOrder,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String status;
  final int sortOrder;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class RoutineSection {
  const RoutineSection({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.type,
    required this.sortOrder,
    required this.status,
    required this.title,
    required this.text,
  });

  final String id;
  final String sessionId;
  final String userId;
  final RoutineSectionType type;
  final int sortOrder;
  final String status;
  final String title;
  final String text;
}

List<RoutineSection> sortedRoutineSections(Iterable<RoutineSection> sections) {
  return [...sections]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

Map<String, dynamic> privateRoutineDocumentMetadata({
  required String userId,
  required String status,
  required int sortOrder,
  required String ciphertext,
  required String nonce,
}) {
  return {
    'userId': userId,
    'createdAt': null,
    'updatedAt': null,
    'status': status,
    'sortOrder': sortOrder,
    'payloadVersion': 1,
    'algorithm': 'xchacha20-poly1305',
    'ciphertext': ciphertext,
    'nonce': nonce,
  };
}
