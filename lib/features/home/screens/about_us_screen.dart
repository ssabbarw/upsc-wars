import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/creator_contact.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const _iosAppStoreId = '1550273627';

  Future<void> _launchExternal(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(context.l10n.aboutLinkFailed)));
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
      appBar: AppBar(title: const Text(context.l10n.settingsAboutUs)),
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
                          context.l10n.aboutExAspirant,
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
                    context.l10n.aboutWhyTitle,
                    style: AppTextStyles.labelSm().copyWith(
                      color: scheme.primary,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.aboutWhyBody,
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.aboutHelpsFind,
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
                              context.l10n.aboutBullet1,
                        ),
                        TextSpan(
                          text: context.l10n.aboutArrow1,
                          style: AppTextStyles.bodyMd().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(
                          text:
                              context.l10n.aboutBullet2,
                        ),
                        TextSpan(
                          text: context.l10n.aboutArrow2,
                          style: AppTextStyles.bodyMd().copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const TextSpan(
                          text:
                              context.l10n.aboutBullet3,
                        ),
                        TextSpan(
                          text: context.l10n.aboutArrow3,
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
                    context.l10n.aboutGoalBody,
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.aboutConnect,
                    style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.aboutConnectBody,
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.aboutReviews,
                    style: AppTextStyles.bodyMd().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.aboutReviewBody,
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
                      child: const Text(context.l10n.aboutRateReview),
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
                      child: const Text(context.l10n.aboutFeedbackEmail),
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
                      child: Text(context.l10n.aboutFeedbackTelegram),
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
