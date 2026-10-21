import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/creator_contact.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_toast.dart';
import 'intro/series_tone.dart';

/// Compact support card: Telegram DM or email for Test Series questions.
class SeriesGetHelpCard extends StatelessWidget {
  const SeriesGetHelpCard({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    await HapticFeedback.selectionClick();
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppToast.showText(context, context.l10n.cuOpenFailed);
    }
  }

  Uri _mailtoHelp() => AppConstants.supportMailtoUri(
    subject: '${AppConstants.appDisplayName} — Test Series help',
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blue = seriesToneColors(SeriesTone.blue, isDark: isDark);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: introCardDecoration(context, tone: SeriesTone.blue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ToneIconBadge(
                icon: Icons.support_agent_rounded,
                tone: SeriesTone.blue,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tsGetHelp,
                      style: AppTextStyles.h3().copyWith(
                        color: blue.fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.tsGetHelpBody,
                      style: AppTextStyles.bodySm().copyWith(
                        color: blue.fg.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HelpAction(
                  icon: Icons.send_rounded,
                  label: context.l10n.tsGetHelpTelegram,
                  subtitle: context.l10n.cuTgDirectSub,
                  onTap: () => _launch(
                    context,
                    Uri.parse(CreatorContact.telegramDirectUrl),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HelpAction(
                  icon: Icons.mail_outline_rounded,
                  label: context.l10n.tsGetHelpEmail,
                  subtitle: CreatorContact.email,
                  onTap: () => _launch(context, _mailtoHelp()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpAction extends StatelessWidget {
  const _HelpAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark
          ? scheme.surface.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.info),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.label().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
