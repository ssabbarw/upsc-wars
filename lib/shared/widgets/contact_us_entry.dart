import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/creator_contact.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Opens a bottom sheet with Telegram DM, email, and Telegram group.
Future<void> showContactUsSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      final bottom = MediaQuery.paddingOf(sheetContext).bottom;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg + bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Get in touch',
                style: AppTextStyles.h3().copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'If something is unclear, you have a feature idea, or any feedback — '
                'pick what works best for you.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SheetTile(
                icon: Icons.send_rounded,
                iconBg: AppColors.infoBg,
                iconColor: AppColors.info,
                title: 'Telegram (direct message)',
                subtitle: 'Quick questions & updates',
                onTap: () => _launchAndPop(
                  sheetContext,
                  Uri.parse(CreatorContact.telegramDirectUrl),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SheetTile(
                icon: Icons.mail_outline_rounded,
                iconBg: AppColors.infoBg,
                iconColor: AppColors.info,
                title: 'Email',
                subtitle: CreatorContact.email,
                onTap: () => _launchAndPop(
                  sheetContext,
                  CreatorContact.mailtoFeedbackUri(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SheetTile(
                icon: Icons.groups_outlined,
                iconBg: AppColors.primaryLight,
                iconColor: AppColors.primaryDark,
                title: 'Telegram group',
                subtitle: 'Community & discussion',
                onTap: () => _launchAndPop(
                  sheetContext,
                  Uri.parse(CreatorContact.telegramGroupUrl),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _launchAndPop(BuildContext sheetContext, Uri uri) async {
  final messenger = ScaffoldMessenger.maybeOf(sheetContext);
  final navigator = Navigator.maybeOf(sheetContext);
  await HapticFeedback.selectionClick();
  navigator?.pop();
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && messenger != null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open link.')),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle inline control that opens [showContactUsSheet].
class ContactUsTextButton extends StatelessWidget {
  const ContactUsTextButton({
    super.key,
    this.leadingText,
    this.linkLabel = 'Contact us',
  });

  /// Shown before the link, e.g. `'Want further clarity? '` (include trailing space).
  final String? leadingText;

  /// Visible link text. Defaults to `Contact us`; subject detail uses `Get in touch`.
  final String linkLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final linkStyle = AppTextStyles.labelSm().copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: scheme.primary,
    );

    if (leadingText != null && leadingText!.isNotEmpty) {
      return Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
          children: [
            TextSpan(text: leadingText),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => showContactUsSheet(context),
                child: Text(linkLabel, style: linkStyle),
              ),
            ),
          ],
        ),
      );
    }

    return TextButton(
      onPressed: () => showContactUsSheet(context),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: scheme.primary,
      ),
      child: Text(
        linkLabel,
        style: AppTextStyles.labelSm().copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
