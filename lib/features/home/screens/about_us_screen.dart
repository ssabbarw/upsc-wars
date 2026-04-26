import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/creator_contact.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const _iosAppStoreId = '1550273627';

  Future<void> _launchExternal(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  Future<void> _openStoreListing(BuildContext context) async {
    // Prefer native store listing when possible.
    final inApp = InAppReview.instance;
    try {
      await inApp.openStoreListing(
        appStoreId: _iosAppStoreId,
        microsoftStoreId: null,
      );
      return;
    } catch (_) {
      // Fall back to external URL.
    }

    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? 'https://apps.apple.com/in/app/upsc-wars/id1550273627'
        : 'https://play.google.com/store/apps/details?id=practice.upsc.indiaapps.com.upscmcqpractice';
    await _launchExternal(context, Uri.parse(url));
  }

  Widget _profileAvatar({
    required BuildContext context,
    required String assetPath,
    required String fallbackLetter,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 54,
      backgroundColor: scheme.surfaceContainerLow,
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: 108,
          height: 108,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              fallbackLetter,
              style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About us')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        _profileAvatar(
                          context: context,
                          assetPath: 'assets/images/dev_pic.jpeg',
                          fallbackLetter: 'S',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Sachin Sabbarwal',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.label().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(Ex-aspirant)',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Why I Built UPSC Wars',
                    style: AppTextStyles.labelSm().copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'I prepared for UPSC myself and realised that most aspirants solve thousands of MCQs but still don’t know where they are actually losing marks.\n\nSometimes the problem is not lack of knowledge — it is overconfidence, risky guessing, weak revision, and repeated mistakes.\n\nAt the same time, preparation is also about knowing where you can safely take smart risks and attempt more with confidence.\n\nThat is why I built UPSC Wars.',
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'It helps you find:',
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodyMd().copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              '• Areas where confident answers or intelligent guesses often go wrong\n',
                        ),
                        TextSpan(
                          text: '  → Avoid taking extra risks here\n\n',
                          style: AppTextStyles.bodyMd().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '• Areas where confident answers or intelligent guesses are usually correct\n',
                        ),
                        TextSpan(
                          text: '  → Take smarter risks here\n\n',
                          style: AppTextStyles.bodyMd().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '• Common UPSC trap patterns and tricky question types\n',
                        ),
                        TextSpan(
                          text: '  → Stay alert and avoid negative marking',
                          style: AppTextStyles.bodyMd().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'So your preparation becomes smarter, not just harder.\n\nMy goal is simple:\n\nHelp aspirants prepare like someone who clears Prelims.\n\nBuilt independently. No coaching institute. No big team. Just a serious attempt to make UPSC preparation better.',
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Connect',
                    style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Your feedback directly improves UPSC Wars.\n\nIf something feels missing, confusing, or useful, please message me. I read every feedback personally.\n\n📩 upscwars@gmail.com',
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Reviews',
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'If UPSC Wars helped your preparation, please leave a review.\n\nYour review helps more serious aspirants discover the app and helps improve the app faster.',
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async => _openStoreListing(context),
                      child: const Text('Rate/Review UPSC Wars'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => _launchExternal(
                        context,
                        Uri.parse('mailto:upscwars@gmail.com?subject=Feedback'),
                      ),
                      child: const Text('Send Feedback on Email'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => _launchExternal(
                        context,
                        Uri.parse(CreatorContact.telegramDirectUrl),
                      ),
                      child: const Text('Send Feedback on Telegram'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
