import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/auth/auth_session.dart';
import '../../features/home/providers/auth_providers.dart';
import '../widgets/google_login_bottom_sheet.dart';

/// Prompts Google/Apple sign-in when the user is anonymous or signed out.
///
/// Returns `true` only when a real (non-anonymous) account is available.
Future<bool> ensureAccountSignedIn({
  required BuildContext context,
  required WidgetRef ref,
  String reason = 'Sign in to continue.',
}) async {
  if (AuthSession.isAccountSignedIn(FirebaseAuth.instance.currentUser)) {
    return true;
  }
  if (!context.mounted) return false;

  String? provider;
  await showGoogleLoginBottomSheet(
    context: context,
    onGoogleTap: () {
      provider = 'google';
      Navigator.of(context).pop();
    },
    onAppleTap: () {
      provider = 'apple';
      Navigator.of(context).pop();
    },
  );
  if (!context.mounted) return false;
  if (provider == null) return false;

  final actions = ref.read(authActionsProvider.notifier);
  if (provider == 'google') {
    await actions.signInWithGoogle();
  } else {
    await actions.signInWithApple();
  }

  if (AuthSession.isAccountSignedIn(FirebaseAuth.instance.currentUser)) {
    return true;
  }

  if (!context.mounted) return false;
  final err = ref.read(authActionsProvider).error;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(err?.toString() ?? reason)),
  );
  return false;
}
