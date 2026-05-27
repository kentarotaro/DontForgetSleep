import 'package:firebase_auth/firebase_auth.dart'; // Untuk mengelola user di Firebase
import 'package:google_sign_in/google_sign_in.dart'; // Untuk memunculkan pop-up pilih akun Google
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:cloud_firestore/cloud_firestore.dart';

// Auth ditangani di client; pembuatan profil user ditangani di client sekarang (sesuai kontrak data baru).

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _createUserProfileIfNeeded(User? user, {String? firstName, String? lastName}) async {
    if (user == null) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('userProfiles').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        String resolvedFirstName = firstName ?? '';
        String resolvedLastName = lastName ?? '';
        if (resolvedFirstName.isEmpty && resolvedLastName.isEmpty && user.displayName != null) {
          final parts = user.displayName!.split(' ');
          resolvedFirstName = parts.first;
          resolvedLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }
        await docRef.set({
          'userId': user.uid,
          'firstName': resolvedFirstName,
          'lastName': resolvedLastName,
          'name': '$resolvedFirstName $resolvedLastName'.trim(),
          'email': user.email ?? '',
          'calendarConnected': false,
          'onboardingCompleted': false,
          'settingsCompleted': false,
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error creating user profile in Firestore: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux)) {
        throw UnsupportedError(
          'Login with Google is not supported on this desktop target in the current setup. Run on Android/iOS/web or add a desktop Firebase/Google Sign-In configuration.',
        );
      }

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google user credentials
      final userCredential = await _auth.signInWithCredential(credential);
      await _createUserProfileIfNeeded(userCredential.user);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _cleanupAfterAuthFailure();
      // ignore: avoid_print
      print('FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      await _cleanupAfterAuthFailure();
      // ignore: avoid_print
      print('Error during Google Sign-In: $e');
      rethrow;
    }
  }

  Future<UserCredential?> registerWithEmail({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    UserCredential? createdCredential;

    try {
      createdCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await createdCredential.user?.updateDisplayName('$firstName $lastName'.trim());
      await createdCredential.user?.sendEmailVerification();
      await _createUserProfileIfNeeded(createdCredential.user, firstName: firstName, lastName: lastName);

      return createdCredential;
    } on FirebaseAuthException catch (e) {
      await _cleanupPartialRegistration(createdCredential?.user);
      // ignore: avoid_print
      print('FirebaseAuthException during email registration: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      await _cleanupPartialRegistration(createdCredential?.user);
      // ignore: avoid_print
      print('Error during email registration: $e');
      rethrow;
    }
  }

  Future<void> _cleanupPartialRegistration(User? createdUser) async {
    try {
      if (createdUser != null) {
        await createdUser.delete();
      }
    } catch (_) {
      // If delete fails for any reason, at least clear auth session.
    }

    try {
      await _auth.signOut();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> _cleanupAfterAuthFailure() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Ignore cleanup failures.
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // ignore: avoid_print
      print('Error signing out from Firebase Auth: $e');
      rethrow;
    }

    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // ignore: avoid_print
      print('Error signing out from Google Sign-In: $e');
    }
  }

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      await _cleanupAfterAuthFailure();
      // ignore: avoid_print
      print('FirebaseAuthException during email sign-in: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      await _cleanupAfterAuthFailure();
      // ignore: avoid_print
      print('Error during email sign-in: $e');
      rethrow;
    }
  }

  Future<void> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error resending email verification: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      // ignore: avoid_print
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<bool> reloadAndCheckEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      // ignore: avoid_print
      print('Error checking email verification status: $e');
      return false;
    }
  }

}