import 'package:firebase_auth/firebase_auth.dart';

/// Distinguishes silent anonymous Firebase sessions from real account sign-in.
abstract final class AuthSession {
  static bool isAccountSignedIn(User? user) =>
      user != null && !user.isAnonymous;
}
