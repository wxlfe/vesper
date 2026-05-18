import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vesper/core/crypto/key_manager.dart';

class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required KeyManager keyManager,
  }) : _auth = auth,
       _firestore = firestore,
       _keyManager = keyManager;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final KeyManager _keyManager;

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await ensureProfile(
      displayName: registrationDisplayName(
        email: email,
        displayName: credential.user?.displayName,
      ),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final profileName = registrationDisplayName(
      email: email,
      displayName: displayName,
    );
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(profileName);
    await ensureProfile(displayName: profileName);
  }

  Future<void> ensureProfile({String? displayName}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final publicKey = await _keyManager.ensureUserKeyPair(user.uid);
    await _firestore.collection('users').doc(user.uid).set({
      'displayName': registrationDisplayName(
        email: user.email ?? 'vesper',
        displayName: displayName,
      ),
      'publicKey': base64Encode(publicKey.bytes),
      'publicKeyAlgorithm': 'x25519',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
      'notificationPreferences': {'pushEnabled': false, 'emailEnabled': false},
    }, SetOptions(merge: true));
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return;
    await user.updateDisplayName(trimmed);
    await _firestore.collection('users').doc(user.uid).set({
      'displayName': trimmed,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() => _auth.signOut();
}

String registrationDisplayName({required String email, String? displayName}) {
  final trimmed = displayName?.trim() ?? '';
  if (trimmed.isNotEmpty) return trimmed;
  final emailName = email.split('@').first.trim();
  return emailName.isEmpty ? 'Someone' : emailName;
}
