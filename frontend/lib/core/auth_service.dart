import 'package:firebase_auth/firebase_auth.dart'; // Untuk mengelola user di Firebase
import 'package:google_sign_in/google_sign_in.dart'; // Untuk memunculkan pop-up pilih akun Google
import 'package:cloud_firestore/cloud_firestore.dart';

// Menggunakan Firestore langsung dari klien sesuai Data Contract

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
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
      final UserCredential result = await _auth.signInWithCredential(credential);

      // Pastikan dokumen profil dibuat sesuai Data Contract
      await _createUserProfileIfMissing(result.user);

      return result;
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
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

      await _createUserProfileIfMissing(
        createdCredential.user,
        firstName: firstName,
        lastName: lastName,
      );

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

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _createUserProfileIfMissing(result.user);
      return result;
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('FirebaseAuthException during email sign-in: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
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

  Future<void> _createUserProfileIfMissing(
    User? user, {
    String? firstName,
    String? lastName,
  }) async {
    if (user == null) return;

    final docRef = _firestore.collection('userProfiles').doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) return;

    final displayName = user.displayName ?? '';
    final parts = displayName.split(' ');
    final computedFirstName = firstName ?? (parts.isNotEmpty ? parts.first : '');
    final computedLastName = lastName ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');

    await docRef.set({
      'userId': user.uid,
      'firstName': computedFirstName,
      'lastName': computedLastName,
      'email': user.email ?? '',
      'calendarConnected': false,
      'onboardingCompleted': false,
      'settingsCompleted': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}