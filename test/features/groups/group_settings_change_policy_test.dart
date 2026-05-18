import 'package:flutter_test/flutter_test.dart';
import 'package:vesper/features/groups/domain/group_settings_change_policy.dart';

void main() {
  test('proposing leader counts as an approval automatically', () {
    final policy = GroupSettingsChangePolicy(
      clock: () => DateTime.utc(2026, 5, 18),
    );

    final change = policy.createAddLeaderChange(
      groupId: 'group-1',
      targetUserId: 'member-1',
      proposedBy: 'leader-1',
    );

    expect(change.type, GroupSettingsChangeType.addLeader);
    expect(change.approvals, contains('leader-1'));
    expect(change.status, GroupSettingsChangeStatus.pending);
  });

  test('proposing member removal counts as an approval automatically', () {
    final policy = GroupSettingsChangePolicy(
      clock: () => DateTime.utc(2026, 5, 18),
    );

    final change = policy.createRemoveMemberChange(
      groupId: 'group-1',
      targetUserId: 'member-1',
      proposedBy: 'leader-1',
    );

    expect(change.type, GroupSettingsChangeType.removeMember);
    expect(change.approvals, contains('leader-1'));
    expect(change.status, GroupSettingsChangeStatus.pending);
  });

  test('publishing policy changes use the same approval window', () {
    final createdAt = DateTime.utc(2026, 5, 18);
    var now = createdAt;
    final policy = GroupSettingsChangePolicy(clock: () => now);

    final change = policy.createPublishingPolicyChange(
      groupId: 'group-1',
      requireApproval: false,
      proposedBy: 'leader-1',
    );
    now = createdAt.add(const Duration(hours: 24));

    final resolved = policy.resolve(
      change,
      currentLeaderIds: const {'leader-1', 'leader-2'},
    );

    expect(resolved.status, GroupSettingsChangeStatus.expiredApproved);
  });

  test('all leader approval resolves any settings change immediately', () {
    final policy = GroupSettingsChangePolicy(
      clock: () => DateTime.utc(2026, 5, 18),
    );
    final change = policy.createPublishingPolicyChange(
      groupId: 'group-1',
      requireApproval: true,
      proposedBy: 'leader-1',
    );

    final resolved = policy.resolve(
      change.copyWith(approvals: {...change.approvals, 'leader-2'}),
      currentLeaderIds: const {'leader-1', 'leader-2'},
    );

    expect(resolved.status, GroupSettingsChangeStatus.approved);
  });

  test('any dispute cancels a settings change', () {
    final policy = GroupSettingsChangePolicy(
      clock: () => DateTime.utc(2026, 5, 18),
    );
    final change = policy.createAddLeaderChange(
      groupId: 'group-1',
      targetUserId: 'member-1',
      proposedBy: 'leader-1',
    );

    final resolved = policy.resolve(
      change.copyWith(disputes: {'leader-2': DateTime.utc(2026, 5, 18, 2)}),
      currentLeaderIds: const {'leader-1', 'leader-2'},
    );

    expect(resolved.status, GroupSettingsChangeStatus.disputed);
  });
}
