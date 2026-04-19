import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

String _privacyPolicyBody() => '''
UPSC Wars — Privacy Policy

This describes how UPSC Wars ("we", "the app") handles information when you sign in with Google and use connected features.

What we collect

• Account from Google: Your email address, display name, and profile photo URL (as Google provides to Firebase Auth) so we can identify your account and show you in the app.

• Study & progress data: Practice sessions, scores, streaks, preferences, and related learning activity may be stored on your device and, where the app syncs to the cloud, on Firebase (for example Firestore) so your progress can stay with you across devices.

• Battles & community: If you use multiplayer battles, invites, or community features, we process match and session metadata (such as identifiers, subject, timestamps), display names, game responses/state, and optional profile fields you choose to add—only as needed to run those features.

• Push notifications: We may store a Firebase Cloud Messaging (FCM) device token linked to your account so we can deliver battle invites or other notifications you expect from the product.

How we use it

We use this information to operate UPSC Wars: sign-in, sync and backup where enabled, battles and community, notifications, reliability, security, fraud prevention, and support.

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
    this.isLoading = false,
  });

  final VoidCallback onGoogleTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;

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
              'Sign in to UPSC Wars',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Save your progress, sync stats across devices, and keep your streak safe.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading ? null : onGoogleTap,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3C4043),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: Color(0xFFDADCE0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleGlyph(),
                    const SizedBox(width: 12),
                    Text(
                      isLoading ? 'Signing in...' : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3C4043),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'By continuing, you agree to our Privacy Policy and to authenticate '
              'with Google via Firebase.',
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

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}

Future<void> showGoogleLoginBottomSheet({
  required BuildContext context,
  required VoidCallback onGoogleTap,
  bool isLoading = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        GoogleLoginBottomSheet(onGoogleTap: onGoogleTap, isLoading: isLoading),
  );
}
