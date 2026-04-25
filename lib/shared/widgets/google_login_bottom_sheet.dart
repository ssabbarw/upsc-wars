import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/constants/app_constants.dart';

String _privacyPolicyBody() => '''
${AppConstants.appDisplayName} — Privacy Policy

This describes how ${AppConstants.appDisplayName} ("we", "the app") handles information when you sign in with Google and use connected features.

What we collect

• Account from Google: Your email address, display name, and profile photo URL (as Google provides to Firebase Auth) so we can identify your account and show you in the app.

• Study & progress data: Practice sessions, scores, streaks, preferences, and related learning activity may be stored on your device and, where the app syncs to the cloud, on Firebase (for example Firestore) so your progress can stay with you across devices.

• Battles & community: If you use multiplayer battles, invites, or community features, we process match and session metadata (such as identifiers, subject, timestamps), display names, game responses/state, and optional profile fields you choose to add—only as needed to run those features.

• Push notifications: We may store a Firebase Cloud Messaging (FCM) device token linked to your account so we can deliver battle invites or other notifications you expect from the product.

How we use it

We use this information to operate ${AppConstants.appDisplayName}: sign-in, sync and backup where enabled, battles and community, notifications, reliability, security, fraud prevention, and support.

Email from us

We may use your email address to contact you about the product in the future—for example meaningful releases, important account or security notices, or occasional tips that respect your time. We are not in the business of flooding inboxes: think a well-timed postcard, not a flyer stack on your windshield. If you ever want fewer non-essential product emails, reply to any message and ask us to adjust, or write to ${AppConstants.supportEmail}.

Third-party services

Google Sign-In, Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging, and related Google/Firebase services process data under their own terms and privacy policies; we use them to provide secure sign-in and cloud features.

Security & retention

We rely on industry-standard encryption in transit and reasonable safeguards. We retain data only as long as needed to run the service or meet legal obligations.

Children

The app is not directed at children under 13. Please do not sign up if you are below the age your region requires for this kind of service without appropriate guardian consent.

Changes

We may update this policy from time to time. When we do, we will reflect the latest version here in the app where practical.

Questions

Privacy questions: ${AppConstants.supportEmail}.
''';

Future<void> showUpscWarsPrivacyPolicyDialog(BuildContext context) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Privacy policy', style: theme.textTheme.titleLarge),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              _privacyPolicyBody().trim(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class GoogleLoginBottomSheet extends StatelessWidget {
  const GoogleLoginBottomSheet({
    super.key,
    required this.onGoogleTap,
    this.onAppleTap,
    this.isLoading = false,
  });

  final VoidCallback onGoogleTap;
  final VoidCallback? onAppleTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canShowApple =
        onAppleTap != null &&
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to ${AppConstants.appDisplayName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Save your progress, sync stats across devices, and keep your streak safe.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            if (canShowApple) ...[
              FutureBuilder<bool>(
                future: SignInWithApple.isAvailable(),
                builder: (context, snapshot) {
                  final available = snapshot.data ?? false;
                  if (!available) return const SizedBox.shrink();
                  return SizedBox(
                    width: double.infinity,
                    child: SignInWithAppleButton(
                      onPressed: isLoading ? null : onAppleTap,
                      style: isDark
                          ? SignInWithAppleButtonStyle.white
                          : SignInWithAppleButtonStyle.black,
                      borderRadius: BorderRadius.circular(8),
                      height: 48,
                      text: isLoading ? 'Signing in...' : 'Continue with Apple',
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: IgnorePointer(
                ignoring: isLoading,
                child: Opacity(
                  opacity: isLoading ? 0.6 : 1,
                  child: SizedBox(
                    height: 48,
                    child: SignInButton(
                      Buttons.google,
                      onPressed: onGoogleTap,
                      text: isLoading ? 'Signing in...' : 'Continue with Google',
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'By continuing, you agree to our Privacy Policy and to authenticate '
              'with Apple or Google via Firebase.',
              style: small,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showUpscWarsPrivacyPolicyDialog(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: scheme.primary,
                ),
                child: Text(
                  'Read full privacy policy',
                  style: small?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showGoogleLoginBottomSheet({
  required BuildContext context,
  required VoidCallback onGoogleTap,
  VoidCallback? onAppleTap,
  bool isLoading = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        GoogleLoginBottomSheet(
          onGoogleTap: onGoogleTap,
          onAppleTap: onAppleTap,
          isLoading: isLoading,
        ),
  );
}
