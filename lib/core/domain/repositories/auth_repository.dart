import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();

  /// Emits on sign-in/out, token refresh, and profile updates (e.g. photoURL).
  Stream<User?> userChanges();

  User? get currentUser;
  Future<UserCredential> signInWithGoogle();
  Future<void> signOut();
}
