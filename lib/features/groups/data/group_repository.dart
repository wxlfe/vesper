import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vesper/core/crypto/group_key_service.dart';
import 'package:vesper/core/crypto/key_manager.dart';
import 'package:vesper/core/models/app_models.dart';
import 'package:vesper/features/groups/domain/invite_code_service.dart';
import 'package:vesper/features/groups/domain/group_settings_change_policy.dart';

class CreatedInviteCode {
  const CreatedInviteCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

class GroupRepository {
  GroupRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required KeyManager keyManager,
    required GroupKeyService groupKeyService,
    required InviteCodeService inviteCodeService,
    required GroupSettingsChangePolicy settingsChangePolicy,
  }) : _auth = auth,
       _firestore = firestore,
       _keyManager = keyManager,
       _groupKeyService = groupKeyService,
       _inviteCodeService = inviteCodeService,
       _settingsChangePolicy = settingsChangePolicy;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final KeyManager _keyManager;
  final GroupKeyService _groupKeyService;
  final InviteCodeService _inviteCodeService;
  final GroupSettingsChangePolicy _settingsChangePolicy;

  String get _uid => _auth.currentUser!.uid;

  Stream<List<VesperGroup>> watchMyGroups() {
    return _firestore
        .collection('group_members')
        .where('userId', isEqualTo: _uid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
          final groups = <VesperGroup>[];
          for (final membership in snapshot.docs) {
            final groupId = membership.data()['groupId'] as String?;
            if (groupId == null) continue;
            final groupDoc = await _firestore
                .collection('groups')
                .doc(groupId)
                .get();
            if (groupDoc.exists) groups.add(VesperGroup.fromDoc(groupDoc));
          }
          groups.sort((a, b) => a.name.compareTo(b.name));
          return groups;
        });
  }

  Stream<int> watchRequestCount(String groupId) {
    return _firestore
        .collection('prayer_requests')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Stream<GroupMembership?> watchMyMembership(String groupId) {
    return _firestore
        .collection('group_members')
        .doc('${groupId}_$_uid')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return GroupMembership.fromDoc(doc);
        });
  }

  Stream<List<GroupMembership>> watchMembers(String groupId) {
    return _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(GroupMembership.fromDoc).toList());
  }

  Stream<List<JoinRequest>> watchJoinRequests(String groupId) {
    return _firestore
        .collection('join_requests')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(JoinRequest.fromDoc).toList());
  }

  Future<VesperGroup?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    return doc.exists ? VesperGroup.fromDoc(doc) : null;
  }

  Future<void> createGroup({
    required String name,
    required String description,
  }) async {
    final groupDoc = _firestore.collection('groups').doc();
    final groupKey = _groupKeyService.newGroupKeyBytes();
    final publicKey =
        await _keyManager.readPublicKey(_uid) ??
        await _keyManager.ensureUserKeyPair(_uid);
    final wrappedKey = await _groupKeyService.wrapGroupKey(
      groupKey: groupKey,
      memberPublicKey: publicKey,
    );
    final batch = _firestore.batch();
    batch.set(groupDoc, {
      'name': name.trim(),
      'description': description.trim(),
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'memberCount': 1,
      'activeKeyVersion': 1,
      'settings': {'allowAnonymous': false, 'allowMemberInvites': true},
    });
    batch.set(
      _firestore.collection('group_members').doc('${groupDoc.id}_$_uid'),
      {
        'groupId': groupDoc.id,
        'userId': _uid,
        'role': 'leader',
        'joinedAt': FieldValue.serverTimestamp(),
        'invitedBy': null,
        'status': 'active',
      },
    );
    batch.set(
      _firestore.collection('group_keys').doc('${groupDoc.id}_${_uid}_1'),
      {
        'groupId': groupDoc.id,
        'userId': _uid,
        'keyVersion': 1,
        ...wrappedKey.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _uid,
        'status': 'active',
      },
    );
    await batch.commit();
    await _keyManager.cacheGroupKey(
      groupId: groupDoc.id,
      keyVersion: 1,
      groupKey: groupKey,
    );
  }

  Future<CreatedInviteCode> createInviteCode(String groupId) async {
    final code = _inviteCodeService.generateCode();
    final expiresAt = DateTime.now().add(InviteCodeService.defaultTtl);
    await _firestore.collection('invite_codes').add({
      'groupId': groupId,
      'codeHash': _inviteCodeService.hashCodeForLookup(code),
      'createdBy': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': 'active',
      'useCount': 0,
      'maxUses': null,
    });
    return CreatedInviteCode(code: code, expiresAt: expiresAt);
  }

  Future<void> requestToJoin(String code) async {
    final hash = _inviteCodeService.hashCodeForLookup(code);
    final invites = await _firestore
        .collection('invite_codes')
        .where('codeHash', isEqualTo: hash)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (invites.docs.isEmpty) {
      throw StateError('That invite code was not found.');
    }
    final invite = invites.docs.first;
    final data = invite.data();
    final groupId = data['groupId'] as String;
    await _firestore.collection('join_requests').doc('${groupId}_$_uid').set({
      'groupId': groupId,
      'requestedBy': _uid,
      'invitedBy': data['createdBy'] as String?,
      'inviteCodeId': invite.id,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'decidedAt': null,
      'decidedBy': null,
    });
  }

  Future<void> approveJoinRequest(JoinRequest request) async {
    final group = await getGroup(request.groupId);
    if (group == null) return;
    final requester = await _firestore
        .collection('users')
        .doc(request.requestedBy)
        .get();
    final publicKey = requester.data()?['publicKey'] as String?;
    if (publicKey == null || publicKey.isEmpty) {
      throw StateError('The requester has not registered a public key yet.');
    }
    final groupKey = await loadGroupKey(group.id, group.activeKeyVersion);
    final wrappedKey = await _groupKeyService.wrapGroupKey(
      groupKey: groupKey,
      memberPublicKey: SimplePublicKey(
        base64Decode(publicKey),
        type: KeyPairType.x25519,
      ),
    );
    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection('group_members')
          .doc('${group.id}_${request.requestedBy}'),
      {
        'groupId': group.id,
        'userId': request.requestedBy,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'invitedBy': request.invitedBy,
        'status': 'active',
      },
    );
    batch.set(
      _firestore
          .collection('group_keys')
          .doc('${group.id}_${request.requestedBy}_${group.activeKeyVersion}'),
      {
        'groupId': group.id,
        'userId': request.requestedBy,
        'keyVersion': group.activeKeyVersion,
        ...wrappedKey.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _uid,
        'status': 'active',
      },
    );
    batch.update(_firestore.collection('join_requests').doc(request.id), {
      'status': 'approved',
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': _uid,
    });
    batch.update(_firestore.collection('groups').doc(group.id), {
      'memberCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> rejectJoinRequest(JoinRequest request) async {
    await _firestore.collection('join_requests').doc(request.id).update({
      'status': 'rejected',
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': _uid,
    });
  }

  Future<void> proposeLeaderAddition(
    String groupId,
    String targetUserId,
  ) async {
    final change = _settingsChangePolicy.createAddLeaderChange(
      groupId: groupId,
      targetUserId: targetUserId,
      proposedBy: _uid,
    );
    await _createSettingsChange(change);
  }

  Future<void> proposeMemberRemoval(String groupId, String targetUserId) async {
    final change = _settingsChangePolicy.createRemoveMemberChange(
      groupId: groupId,
      targetUserId: targetUserId,
      proposedBy: _uid,
    );
    await _createSettingsChange(change);
  }

  Future<void> _createSettingsChange(GroupSettingsChange change) async {
    await _firestore.collection('group_settings_changes').doc(change.id).set({
      'groupId': change.groupId,
      'type': _changeTypeName(change.type),
      'proposedBy': change.proposedBy,
      'targetUserId': change.targetUserId,
      'proposedSettings': {},
      'status': 'pending',
      'createdAt': Timestamp.fromDate(change.createdAt),
      'expiresAt': Timestamp.fromDate(change.expiresAt),
      'resolvedAt': null,
      'approvals': {_uid: Timestamp.fromDate(change.createdAt)},
      'disputes': {},
    });
  }

  Future<void> approveSettingsChange(String changeId) async {
    await _firestore.collection('group_settings_changes').doc(changeId).set({
      'approvals': {_uid: FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
  }

  Future<void> disputeSettingsChange(String changeId) async {
    await _firestore.collection('group_settings_changes').doc(changeId).set({
      'status': 'disputed',
      'resolvedAt': FieldValue.serverTimestamp(),
      'disputes': {
        _uid: {'createdAt': FieldValue.serverTimestamp()},
      },
    }, SetOptions(merge: true));
  }

  Future<void> maybeFinalizeSettingsChanges(String groupId) async {
    final leaders = await _firestore
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .where('role', isEqualTo: 'leader')
        .where('status', isEqualTo: 'active')
        .get();
    final leaderIds = leaders.docs
        .map((doc) => doc.data()['userId'] as String)
        .toSet();
    final changes = await _firestore
        .collection('group_settings_changes')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in changes.docs) {
      final data = doc.data();
      final change = GroupSettingsChange(
        id: doc.id,
        groupId: groupId,
        type: _settingsChangeType(data['type'] as String? ?? ''),
        proposedBy: data['proposedBy'] as String,
        targetUserId: data['targetUserId'] as String?,
        status: GroupSettingsChangeStatus.pending,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        expiresAt: (data['expiresAt'] as Timestamp).toDate(),
        approvals: ((data['approvals'] as Map<String, dynamic>?) ?? {}).keys
            .toSet(),
        disputes: ((data['disputes'] as Map<String, dynamic>?) ?? {}).map(
          (key, value) => MapEntry(key, DateTime.now()),
        ),
      );
      final resolved = _settingsChangePolicy.resolve(
        change,
        currentLeaderIds: leaderIds,
      );
      if (resolved.status == GroupSettingsChangeStatus.approved ||
          resolved.status == GroupSettingsChangeStatus.expiredApproved) {
        final batch = _firestore.batch();
        batch.update(
          _firestore.collection('group_settings_changes').doc(doc.id),
          {
            'status': resolved.status == GroupSettingsChangeStatus.approved
                ? 'approved'
                : 'expired_approved',
            'resolvedAt': FieldValue.serverTimestamp(),
          },
        );
        if (resolved.type == GroupSettingsChangeType.addLeader &&
            resolved.targetUserId != null) {
          batch.update(
            _firestore
                .collection('group_members')
                .doc('${groupId}_${resolved.targetUserId}'),
            {'role': 'leader'},
          );
        }
        if (resolved.type == GroupSettingsChangeType.removeMember &&
            resolved.targetUserId != null) {
          batch.update(
            _firestore
                .collection('group_members')
                .doc('${groupId}_${resolved.targetUserId}'),
            {'status': 'removed'},
          );
        }
        await batch.commit();
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSettingsChanges(
    String groupId,
  ) {
    return _firestore
        .collection('group_settings_changes')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  String _changeTypeName(GroupSettingsChangeType type) {
    return switch (type) {
      GroupSettingsChangeType.addLeader => 'add_leader',
      GroupSettingsChangeType.removeMember => 'remove_member',
    };
  }

  GroupSettingsChangeType _settingsChangeType(String value) {
    return switch (value) {
      'remove_member' => GroupSettingsChangeType.removeMember,
      _ => GroupSettingsChangeType.addLeader,
    };
  }

  Future<List<int>> loadGroupKey(String groupId, int keyVersion) async {
    final cached = await _keyManager.readCachedGroupKey(groupId, keyVersion);
    if (cached != null) return cached;
    final memberKeyPair = await _keyManager.readPrivateKeyPair(_uid);
    if (memberKeyPair == null) {
      throw StateError('This device does not have your private key.');
    }
    final doc = await _firestore
        .collection('group_keys')
        .doc('${groupId}_${_uid}_$keyVersion')
        .get();
    final wrapped = WrappedGroupKey.fromFirestore(
      doc.data() ?? const <String, dynamic>{},
    );
    final groupKey = await _groupKeyService.unwrapGroupKey(
      wrappedKey: wrapped,
      memberKeyPair: memberKeyPair,
    );
    await _keyManager.cacheGroupKey(
      groupId: groupId,
      keyVersion: keyVersion,
      groupKey: groupKey,
    );
    return groupKey;
  }
}
