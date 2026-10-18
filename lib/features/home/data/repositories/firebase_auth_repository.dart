import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../../core/domain/repositories/auth_repository.dart';
import '../../../../core/services/anonymous_auth_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  // serverClientId (web client ID) is required on Android for Google Sign-In
  // to include an idToken in the auth response, which Firebase Auth needs.
  static const _serverClientId =
      '468016404938-50s9phccd2d80mecnqv0tul8kqtp8fmd.apps.googleusercontent.com';

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  Stream<User?> userChanges() => _firebaseAuth.userChanges();

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
      final current = _firebaseAuth.currentUser;
      if (current != null && current.isAnonymous) {
        try {
          return await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (linkError) {
          if (linkError.code != 'credential-already-in-use' &&
              linkError.code != 'email-already-in-use') {
            rethrow;
          }
        }
      }
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

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<UserCredential> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing_apple_identity_token',
          message: 'Unable to get Apple identity token. Please try again.',
        );
      }

      final oauthProvider = OAuthProvider('apple.com');
      final credential = oauthProvider.credential(
        idToken: idToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final current = _firebaseAuth.currentUser;
      if (current != null && current.isAnonymous) {
        try {
          return await current.linkWithCredential(credential);
        } on FirebaseAuthException catch (linkError) {
          if (linkError.code != 'credential-already-in-use' &&
              linkError.code != 'email-already-in-use') {
            rethrow;
          }
        }
      }
      return _firebaseAuth.signInWithCredential(credential);
    } on SignInWithAppleAuthorizationException catch (error, stackTrace) {
      debugPrint('Apple signInWithApple failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (error.code == AuthorizationErrorCode.canceled) {
        throw FirebaseAuthException(
          code: 'sign_in_cancelled',
          message: 'Apple sign-in was cancelled.',
        );
      }

      throw FirebaseAuthException(
        code: 'apple_sign_in_failed',
        message: 'Apple sign-in failed. Please try again.',
      );
    } on FirebaseAuthException catch (error, stackTrace) {
      debugPrint('FirebaseAuth signInWithApple failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Apple signInWithApple failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw FirebaseAuthException(
        code: 'apple_sign_in_failed',
        message: 'Apple sign-in failed. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await AnonymousAuthService.ensureSignedIn();
    } catch (error, stackTrace) {
      debugPrint('signOut failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
