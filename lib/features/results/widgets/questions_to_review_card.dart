import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/session_insight_case.dart';
import '../../../l10n/l10n.dart';

/// Session summary hero for sure-wrong / educated-guess-wrong (cases A–C).
class QuestionsToReviewCard extends ConsumerWidget {
  const QuestionsToReviewCard({
    super.key,
    required this.sessionId,
    required this.insightCase,
    required this.sureWrong,
    required this.eduWrong,
    this.compact = false,
    this.reviewCtaKey,
  });

  final String sessionId;
  final SessionInsightCase insightCase;
  final int sureWrong;
  final int eduWrong;
  final bool compact;
  final GlobalKey? reviewCtaKey;

  int get _total => sureWrong + eduWrong;

  String get _headline {
    if (sureWrong > 0 && eduWrong > 0) {
      return appL10n.resultsQrMixed(_total);
    }
    if (sureWrong > 0) {
      return appL10n.resultsQrSure(sureWrong);
    }
    return appL10n.resultsQrEdu(eduWrong);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark
        ? AppColors.wrongBgDark.withValues(alpha: 0.65)
        : AppColors.coachDangerSurfaceLight;
    final border = AppColors.coachDangerBorder;
    final accent = isDark
        ? AppColors.wrongTextDark
        : AppColors.coachDangerTitleText;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 2),
      ),
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  context.l10n.resultsQrTitle,
                  style: AppTextStyles.caption().copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: accent,
                  ),
                ),
              ),
              Icon(Icons.warning_amber_rounded, color: accent, size: 22),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _headline,
            style: AppTextStyles.h3().copyWith(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w800,
              color: accent,
              height: 1.25,
            ),
          ),
          if (sureWrong > 0 || eduWrong > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (sureWrong > 0)
                  _MistakePill(
                    icon: Icons.psychology_outlined,
                    label: '$sureWrong sure · wrong',
                    color: AppColors.wrong,
                    isDark: isDark,
                  ),
                if (eduWrong > 0)
                  _MistakePill(
                    icon: Icons.help_outline,
                    label: '$eduWrong guess · wrong',
                    color: AppColors.summaryOrange,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.resultsQrReveal,
            style: AppTextStyles.bodySm().copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final bullet in [
            context.l10n.resultsQrBullet1,
            context.l10n.resultsQrBullet2,
            context.l10n.resultsQrBullet3,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: AppTextStyles.bodySm().copyWith(color: accent),
                  ),
                  Expanded(
                    child: Text(
                      bullet,
                      style: AppTextStyles.bodySm().copyWith(
                        color: accent,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            key: reviewCtaKey,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                backgroundColor: isDark
                    ? scheme.surface.withValues(alpha: 0.5)
                    : Colors.white,
                side: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.summaryButtonBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: () => _onReviewMistakes(context, ref),
              icon: const Icon(Icons.medical_services_outlined, size: 20),
              label: Text(
                context.l10n.resultsReviewYourMistakes,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onReviewMistakes(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    unawaited(
      Analytics.track(
        ref,
        UspSessionCoachCtaTappedEvent(
          action: 'insight_${sessionInsightCaseAnalyticsName(insightCase)}',
        ),
      ),
    );
    context.push('/mistake-review-intro/$sessionId');
  }
}

class _MistakePill extends StatelessWidget {
  const _MistakePill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

bool usesMistakeReviewFlow(SessionInsightCase insightCase) {
  return insightCase == SessionInsightCase.a ||
      insightCase == SessionInsightCase.b ||
      insightCase == SessionInsightCase.c;
}
