import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesper/core/crypto/encryption_service.dart';
import 'package:vesper/core/crypto/group_key_service.dart';
import 'package:vesper/core/crypto/key_manager.dart';
import 'package:vesper/core/services/encrypted_cache_service.dart';
import 'package:vesper/features/auth/data/auth_repository.dart';
import 'package:vesper/features/groups/data/group_repository.dart';
import 'package:vesper/features/groups/data/pinned_group_service.dart';
import 'package:vesper/features/groups/domain/invite_code_service.dart';
import 'package:vesper/features/groups/domain/group_settings_change_policy.dart';
import 'package:vesper/features/prayer/data/prayer_session_repository.dart';
import 'package:vesper/features/profile/data/user_profile_repository.dart';
import 'package:vesper/features/requests/data/prayer_request_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final encryptionServiceProvider = Provider<EncryptionService>(
  (ref) => EncryptionService(),
);
final groupKeyServiceProvider = Provider<GroupKeyService>(
  (ref) => GroupKeyService(),
);
final keyManagerProvider = Provider<KeyManager>(
  (ref) => KeyManager(groupKeyService: ref.watch(groupKeyServiceProvider)),
);
final inviteCodeServiceProvider = Provider<InviteCodeService>(
  (ref) => InviteCodeService(),
);
final groupSettingsChangePolicyProvider = Provider<GroupSettingsChangePolicy>(
  (ref) => GroupSettingsChangePolicy(),
);
final encryptedCacheProvider = Provider<EncryptedCacheService>(
  (ref) => const EncryptedCacheService(),
);
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return FirestoreUserProfileRepository(
    firestore: ref.watch(firestoreProvider),
  );
});
final pinnedGroupServiceProvider = Provider<PinnedGroupService>(
  (ref) => const PinnedGroupService(),
);
final pinnedGroupIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(pinnedGroupServiceProvider).readPinnedGroupIds();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupKeyService: ref.watch(groupKeyServiceProvider),
    inviteCodeService: ref.watch(inviteCodeServiceProvider),
    settingsChangePolicy: ref.watch(groupSettingsChangePolicyProvider),
  );
});

final prayerRequestRepositoryProvider = Provider<PrayerRequestRepository>((
  ref,
) {
  return PrayerRequestRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
    groupKeyService: ref.watch(groupKeyServiceProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    encryptedCache: ref.watch(encryptedCacheProvider),
  );
});

final prayerSessionRepositoryProvider = Provider<PrayerSessionRepository>((
  ref,
) {
  return PrayerSessionRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
});

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);
