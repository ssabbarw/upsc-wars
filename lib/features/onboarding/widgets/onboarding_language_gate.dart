import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/app_language_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../mini_games/shared/revision_games_theme.dart';

/// First screen of onboarding. Deliberately bilingual (it is shown before the
/// user has picked a language), so it does not use ARB strings.
///
/// One choice drives the whole app: menus, questions and explanations.
class OnboardingLanguageGate extends ConsumerWidget {
  const OnboardingLanguageGate({super.key, required this.onChosen});

  final VoidCallback onChosen;

  Future<void> _pick(WidgetRef ref, String lang) async {
    await HapticFeedback.selectionClick();
    await persistAppLanguage(ref, lang);
    onChosen();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: RgColors.pageBg,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              bottom + AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.translate_rounded,
                  size: 44,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Choose your language',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1().copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'अपनी भाषा चुनिए',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2().copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'App, questions and explanations will all use it.\n'
                  'ऐप, सवाल और explanation सब इसी भाषा में होंगे।',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm().copyWith(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _LanguageButton(
                  title: 'English',
                  subtitle: 'Continue in English',
                  onTap: () => _pick(ref, 'en'),
                ),
                const SizedBox(height: AppSpacing.md),
                _LanguageButton(
                  title: 'हिन्दी',
                  subtitle: 'हिन्दी में जारी रखें',
                  onTap: () => _pick(ref, 'hi'),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'You can change this anytime in Settings.\n'
                  'आप इसे कभी भी Settings में बदल सकते हैं।',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption().copyWith(
                    color: Colors.black45,
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h2().copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySm().copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.black45),
            ],
          ),
        ),
      ),
    );
  }
}
