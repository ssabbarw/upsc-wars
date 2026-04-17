import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;

      if (auth.idToken == null || auth.idToken!.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing_google_id_token',
          message: 'Unable to get Google ID token. Please try again.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
      return _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (error, stackTrace) {
      debugPrint('Google signInWithGoogle failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      final code = error.code.toString().toLowerCase();
      if (code.contains('canceled') || code.contains('cancelled')) {
        throw FirebaseAuthException(
          code: 'sign_in_cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }

      if (code.contains('network')) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'No internet connection. Please try again.',
        );
      }

      throw FirebaseAuthException(
        code: 'google_sign_in_failed',
        message: 'Google sign-in failed. Please try again.',
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('FirebaseAuth signInWithGoogle failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Google signInWithGoogle failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw FirebaseAuthException(
        code: 'google_sign_in_failed',
        message: 'Google sign-in failed. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (error, stackTrace) {
      debugPrint('signOut failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
