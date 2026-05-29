import 'package:uuid/uuid.dart';

enum GroupSettingsChangeType { addLeader, removeMember }

enum GroupSettingsChangeStatus {
  pending,
  approved,
  disputed,
  expiredApproved,
  cancelled,
}

class GroupSettingsChange {
  const GroupSettingsChange({
    required this.id,
    required this.groupId,
    required this.type,
    required this.proposedBy,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.approvals,
    required this.disputes,
    this.targetUserId,
  });

  final String id;
  final String groupId;
  final GroupSettingsChangeType type;
  final String proposedBy;
  final GroupSettingsChangeStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Set<String> approvals;
  final Map<String, DateTime> disputes;
  final String? targetUserId;

  GroupSettingsChange copyWith({
    GroupSettingsChangeStatus? status,
    Set<String>? approvals,
    Map<String, DateTime>? disputes,
  }) {
    return GroupSettingsChange(
      id: id,
      groupId: groupId,
      type: type,
      proposedBy: proposedBy,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      approvals: approvals ?? this.approvals,
      disputes: disputes ?? this.disputes,
      targetUserId: targetUserId,
    );
  }
}

class GroupSettingsChangePolicy {
  GroupSettingsChangePolicy({DateTime Function()? clock, Uuid? uuid})
    : _clock = clock ?? DateTime.now,
      _uuid = uuid ?? const Uuid();

  final DateTime Function() _clock;
  final Uuid _uuid;

  GroupSettingsChange createAddLeaderChange({
    required String groupId,
    required String targetUserId,
    required String proposedBy,
  }) {
    return _create(
      groupId: groupId,
      type: GroupSettingsChangeType.addLeader,
      proposedBy: proposedBy,
      targetUserId: targetUserId,
    );
  }

  GroupSettingsChange createRemoveMemberChange({
    required String groupId,
    required String targetUserId,
    required String proposedBy,
  }) {
    return _create(
      groupId: groupId,
      type: GroupSettingsChangeType.removeMember,
      proposedBy: proposedBy,
      targetUserId: targetUserId,
    );
  }

  GroupSettingsChange resolve(
    GroupSettingsChange change, {
    required Set<String> currentLeaderIds,
  }) {
    if (change.status != GroupSettingsChangeStatus.pending) return change;
    if (change.disputes.isNotEmpty) {
      return change.copyWith(status: GroupSettingsChangeStatus.disputed);
    }
    if (currentLeaderIds.isNotEmpty &&
        change.approvals.containsAll(currentLeaderIds)) {
      return change.copyWith(status: GroupSettingsChangeStatus.approved);
    }
    if (!_clock().isBefore(change.expiresAt)) {
      return change.copyWith(status: GroupSettingsChangeStatus.expiredApproved);
    }
    return change;
  }

  GroupSettingsChange _create({
    required String groupId,
    required GroupSettingsChangeType type,
    required String proposedBy,
    String? targetUserId,
  }) {
    final now = _clock();
    return GroupSettingsChange(
      id: _uuid.v4(),
      groupId: groupId,
      type: type,
      proposedBy: proposedBy,
      status: GroupSettingsChangeStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      approvals: {proposedBy},
      disputes: const {},
      targetUserId: targetUserId,
    );
  }
}
