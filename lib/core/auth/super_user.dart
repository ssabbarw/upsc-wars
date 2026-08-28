import 'package:firebase_auth/firebase_auth.dart';

import '../constants/super_user_emails.dart';
import 'auth_session.dart';

/// Signed-in account whose email is listed in [SuperUserEmails].
abstract final class SuperUser {
  SuperUser._();

  static bool isEmail(String? email) => SuperUserEmails.contains(email);

  static bool isSignedIn(User? user) =>
      AuthSession.isAccountSignedIn(user) && isEmail(AuthSession.emailOf(user));
}
