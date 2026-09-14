import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Explains open challenges.
///
/// When [showSignInCta] is true, returns `true` if the user taps
/// “Sign in to join” (caller should run the sign-in flow). Otherwise returns
/// `null` / `false` on dismiss or “Got it” / “Not now”.
Future<bool?> showOpenChallengeWhatIsSheet(
  BuildContext context, {
  bool showSignInCta = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.paddingOf(ctx).bottom + AppSpacing.lg,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? scheme.surfaceContainerHigh : scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What is an open challenge?',
                style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A warrior posts their 10-question exam for everyone to try.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _Bullet(
                scheme: scheme,
                text: 'Same 10 questions for every challenger.',
              ),
              _Bullet(
                scheme: scheme,
                text: 'Beat the top score on the leaderboard.',
              ),
              _Bullet(
                scheme: scheme,
                text: 'Each challenge stays live for 24 hours.',
              ),
              if (showSignInCta) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sign in to join a challenge and post your own.',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurface,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, showSignInCta),
                child: Text(showSignInCta ? 'Sign in to join' : 'Got it'),
              ),
              if (showSignInCta) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Not now'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.scheme, required this.text});

  final ColorScheme scheme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
