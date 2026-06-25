import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../supabase_media_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  Stream<AppUser?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
      (document) {
        if (!document.exists) return null;
        return AppUser.fromDocument(document);
      },
    );
  }

  Future<AppUser?> getUser(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();
    return document.exists ? AppUser.fromDocument(document) : null;
  }

  Future<void> register({
    required String fullName,
    required String username,
    required String phone,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim();
    final usernameLower = normalizeUsername(cleanUsername);

    if (!RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(usernameLower)) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message:
            'Username must contain 3-30 letters, numbers, dots or underscores.',
      );
    }

    final usernameReference =
        _firestore.collection('usernames').doc(usernameLower);

    // Do this check outside runTransaction. Throwing a Dart exception from a
    // Firestore web transaction callback can become a boxed JavaScript error.
    final existingUsername = await usernameReference.get();
    if (existingUsername.exists) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'This username is already in use.',
      );
    }

    UserCredential? credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'The account could not be created.',
        );
      }

      // Ensure Firestore receives a fresh authenticated token on web.
      await user.getIdToken(true);

      final userReference = _firestore.collection('users').doc(user.uid);
      final batch = _firestore.batch();

      batch.set(userReference, {
        'uid': user.uid,
        'fullName': fullName.trim(),
        'username': cleanUsername,
        'usernameLower': usernameLower,
        'phone': phone.trim(),
        'email': cleanEmail,
        'role': 'client',
        'profileImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(usernameReference, {
        'uid': user.uid,
        'email': cleanEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      await user.updateDisplayName(fullName.trim());
    } catch (error) {
      final user = credential?.user;

      if (user != null) {
        try {
          await user.delete();
        } catch (_) {
          try {
            await _auth.signOut();
          } catch (_) {
            // Preserve the original registration error.
          }
        }
      }

      rethrow;
    }
  }

  Future<void> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final identifier = emailOrUsername.trim().toLowerCase();
    String email = identifier;

    if (!identifier.contains('@')) {
      final usernameDocument =
          await _firestore.collection('usernames').doc(identifier).get();

      if (!usernameDocument.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account was found for that username.',
        );
      }

      email = usernameDocument.data()?['email']?.toString() ?? '';
      if (email.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No account was found for that username.',
        );
      }
    }

    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> updateProfile({
    required AppUser currentUser,
    required String fullName,
    required String username,
    required String phone,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
  }) async {
    final cleanUsername = username.trim();
    final usernameLower = normalizeUsername(cleanUsername);

    if (!RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(usernameLower)) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message:
            'Username must contain 3-30 letters, numbers, dots or underscores.',
      );
    }

    final oldUsernameLower = normalizeUsername(currentUser.username);
    final userReference = _firestore.collection('users').doc(currentUser.uid);
    final oldUsernameReference =
        _firestore.collection('usernames').doc(oldUsernameLower);
    final newUsernameReference =
        _firestore.collection('usernames').doc(usernameLower);

    if (usernameLower != oldUsernameLower) {
      final existingUsername = await newUsernameReference.get();
      if (existingUsername.exists) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'This username is already in use.',
        );
      }
    }

    String? profileImageUrl;
    if (profileImageBytes != null && profileImageFileName != null) {
      profileImageUrl = await SupabaseMediaService.instance.uploadUserProfileImage(
        imageBytes: profileImageBytes,
        userUid: currentUser.uid,
        originalFileName: profileImageFileName,
      );
    }

    final batch = _firestore.batch();

    final updateData = <String, Object?>{
      'fullName': fullName.trim(),
      'username': cleanUsername,
      'usernameLower': usernameLower,
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (profileImageUrl != null) {
      updateData['profileImageUrl'] = profileImageUrl;
    }

    batch.update(userReference, updateData);

    if (usernameLower != oldUsernameLower) {
      batch.delete(oldUsernameReference);
      batch.set(newUsernameReference, {
        'uid': currentUser.uid,
        'email': currentUser.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    await _auth.currentUser?.updateDisplayName(fullName.trim());
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> signOut() => _auth.signOut();
}
