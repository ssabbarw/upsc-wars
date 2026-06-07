import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

enum MistakeReviewCarouselKind { sureWrong, eduGuessWrong }

class MistakeReviewCarouselCard extends StatelessWidget {
  const MistakeReviewCarouselCard({
    super.key,
    required this.kind,
    required this.count,
  });

  final MistakeReviewCarouselKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    final isSure = kind == MistakeReviewCarouselKind.sureWrong;
    final style = isSure ? _sureStyle() : _eduStyle();
    final questionLabel = '$count question${count == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.border.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, size: 22, color: style.accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  style.eyebrow,
                  style: AppTextStyles.caption().copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: style.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            questionLabel,
            style: AppTextStyles.h2().copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: style.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            style.description,
            style: AppTextStyles.bodySm().copyWith(
              color: style.accent,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Watch out for:',
            style: AppTextStyles.label().copyWith(
              fontWeight: FontWeight.w800,
              color: style.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: style.bulletBoxBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final bullet in style.bullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•  ',
                          style: AppTextStyles.bodySm().copyWith(
                            color: style.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            bullet,
                            style: AppTextStyles.bodySm().copyWith(
                              color: style.accent,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselCardStyle {
  const _CarouselCardStyle({
    required this.surface,
    required this.border,
    required this.accent,
    required this.iconBg,
    required this.icon,
    required this.eyebrow,
    required this.description,
    required this.bullets,
    required this.bulletBoxBg,
  });

  final Color surface;
  final Color border;
  final Color accent;
  final Color iconBg;
  final IconData icon;
  final String eyebrow;
  final String description;
  final List<String> bullets;
  final Color bulletBoxBg;
}

_CarouselCardStyle _sureStyle() {
  return const _CarouselCardStyle(
    surface: Color(0xFFFDF2F2),
    border: AppColors.coachDangerBorder,
    accent: AppColors.coachDangerTitleText,
    iconBg: Color(0xFFFECACA),
    icon: Icons.psychology_outlined,
    eyebrow: 'CONFIDENT · WRONG',
    description:
        'You were sure — and lost marks anyway. \n\nGo through these carefully '
        'and check whether you misread the question or your understanding has a gap.',
    bullets: [
      'Concepts that feel familiar but aren\'t fully clear',
      'Topics where the detail matters and you missed it',
      'Traps that feel obvious in hindsight',
      'Avoidable exam-day mistakes',
    ],
    bulletBoxBg: Colors.white,
  );
}

_CarouselCardStyle _eduStyle() {
  return const _CarouselCardStyle(
    surface: AppColors.warningBg,
    border: AppColors.warning,
    accent: AppColors.warningText,
    iconBg: Color(0xFFF5D495),
    icon: Icons.help_outline,
    eyebrow: 'EDUCATED GUESS · WRONG',
    description:
        'You had some idea but not enough. These are clean gaps — easier to fix '
        'than confident mistakes. You know you need to revise these.',
    bullets: [
      'Topics that need focused revision',
      'Concepts partially encountered but not fully absorbed',
      'Areas where elimination logic needs strengthening',
    ],
    bulletBoxBg: Colors.white,
  );
}
