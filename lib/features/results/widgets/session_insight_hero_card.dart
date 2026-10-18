import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/domain/demo_diagnostic_ephemeral_store.dart';
import '../domain/session_insight_case.dart';
import 'questions_to_review_card.dart';
import '../../../l10n/l10n.dart';

/// Hero insight card for session summary (cases A–G).
class SessionInsightHeroCard extends ConsumerWidget {
  const SessionInsightHeroCard({
    super.key,
    required this.sessionId,
    required this.result,
    required this.insightCase,
    required this.topRiskTopic,
    required this.topRiskPct,
    required this.weakestTopicName,
    this.compact = false,
    this.reviewCtaKey,
  });

  final String sessionId;
  final SessionResult result;
  final SessionInsightCase insightCase;
  final String? topRiskTopic;
  final int? topRiskPct;
  final String? weakestTopicName;
  final bool compact;
  final GlobalKey? reviewCtaKey;

  static const _getStartedKey = 'get_started_diagnostic';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sureWrong = sessionSureWrongCount(result);
    final eduWrong = sessionEduWrongCount(result);

    if (usesMistakeReviewFlow(insightCase)) {
      return QuestionsToReviewCard(
        sessionId: sessionId,
        insightCase: insightCase,
        sureWrong: sureWrong,
        eduWrong: eduWrong,
        compact: compact,
        reviewCtaKey: reviewCtaKey,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highRisk = sureWrong + eduWrong;
    final marks = sessionTierMarksLost(highRisk > 0 ? highRisk : result.wrong);

    final style = _caseStyle(insightCase, isDark);
    final titleText = insightCase == SessionInsightCase.gIncomplete
        ? _incompleteTitle(result)
        : style.title(
            sureWrong: sureWrong,
            eduWrong: eduWrong,
            wrong: result.wrong,
          );
    final subtitleText = insightCase == SessionInsightCase.gIncomplete
        ? _incompleteSubtitle(result)
        : style.subtitle;

    return Container(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: style.border, width: 2),
      ),
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (style.eyebrow.isNotEmpty) ...[
            Text(
              style.eyebrow,
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: style.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            titleText,
            style: AppTextStyles.h2().copyWith(
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.w900,
              color: style.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitleText,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.35,
            ),
          ),
          if (insightCase == SessionInsightCase.c) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _Pill(
                  label: '$sureWrong Confident',
                  color: AppColors.wrong,
                  isDark: isDark,
                ),
                _Pill(
                  label: '$eduWrong Educated guess',
                  color: AppColors.summaryOrange,
                  isDark: isDark,
                ),
              ],
            ),
          ],
          if (marks > 0 &&
              insightCase != SessionInsightCase.e &&
              insightCase != SessionInsightCase.gIncomplete &&
              insightCase != SessionInsightCase.fLockedSettings &&
              insightCase != SessionInsightCase.fLockedSkipped &&
              insightCase != SessionInsightCase.fNoAttempts) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: AppColors.wrong,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  context.l10n.resultsRealExamCost(marks.toStringAsFixed(2)),
                  style: AppTextStyles.labelSm().copyWith(
                    color: AppColors.wrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (topRiskTopic != null &&
              (insightCase == SessionInsightCase.a ||
                  insightCase == SessionInsightCase.b ||
                  insightCase == SessionInsightCase.c)) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              (topRiskPct != null
                  ? context.l10n.resultsTopRiskPct(topRiskTopic!, topRiskPct!)
                  : context.l10n.resultsTopRisk(topRiskTopic!)),
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (insightCase != SessionInsightCase.fNoAttempts) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              key: reviewCtaKey,
              height: 44,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: style.ctaBackground,
                  foregroundColor: style.ctaForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                onPressed: () => _onCta(context, ref),
                icon: const Icon(Icons.adjust, size: 20),
                label: Text(
                  style.ctaLabel(
                    sureWrong: sureWrong,
                    eduWrong: eduWrong,
                    wrong: result.wrong,
                    weakestTopic: weakestTopicName,
                  ),
                  style: AppTextStyles.label().copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onCta(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    unawaited(
      Analytics.track(
        ref,
        UspSessionCoachCtaTappedEvent(
          action: 'insight_${sessionInsightCaseAnalyticsName(insightCase)}',
        ),
      ),
    );

    switch (insightCase) {
      case SessionInsightCase.a:
      case SessionInsightCase.b:
      case SessionInsightCase.c:
        context.push('/mistake-review-intro/$sessionId');
      case SessionInsightCase.d:
        _openHistory(context, focusWrong: true);
      case SessionInsightCase.e:
        _goHome(context);
      case SessionInsightCase.gIncomplete:
        if (result.subject.isNotEmpty && result.subject != 'revision_quick') {
          context.go('/subject/${Uri.encodeComponent(result.subject)}');
        } else {
          _goHome(context);
        }
      case SessionInsightCase.fLockedSettings:
        context.push('/settings');
      case SessionInsightCase.fLockedSkipped:
        if (result.subject.isNotEmpty && result.subject != 'revision_quick') {
          context.go('/subject/${Uri.encodeComponent(result.subject)}');
        } else {
          _goHome(context);
        }
      case SessionInsightCase.fNoAttempts:
        if (result.subject.isNotEmpty && result.subject != 'revision_quick') {
          context.go('/subject/${Uri.encodeComponent(result.subject)}');
        } else {
          _goHome(context);
        }
    }
  }

  void _goHome(BuildContext context) {
    if (result.analyticsFeatureKey == _getStartedKey) {
      clearDemoDiagnosticEphemeral(sessionId);
    }
    context.go('/');
  }

  void _openHistory(BuildContext context, {bool focusWrong = false}) {
    maybeMarkDemoDiagnosticReviewOpened(
      sessionId,
      analyticsFeatureKey: result.analyticsFeatureKey,
    );
    final loc = focusWrong
        ? '/history/$sessionId?focus=wrong'
        : '/history/$sessionId';
    final path = GoRouter.of(context).state.uri.path;
    if (path.startsWith('/danger-zone/') ||
        path.startsWith('/mistake-review')) {
      context.pushReplacement(loc);
    } else {
      context.push(loc);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.isDark});

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
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption().copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CaseStyle {
  const _CaseStyle({
    required this.eyebrow,
    required this.subtitle,
    required this.background,
    required this.border,
    required this.accent,
    required this.ctaBackground,
    required this.ctaForeground,
    required this.title,
    required this.ctaLabel,
  });

  final String eyebrow;
  final String subtitle;
  final Color background;
  final Color border;
  final Color accent;
  final Color ctaBackground;
  final Color ctaForeground;
  final String Function({
    required int sureWrong,
    required int eduWrong,
    required int wrong,
  })
  title;
  final String Function({
    required int sureWrong,
    required int eduWrong,
    required int wrong,
    required String? weakestTopic,
  })
  ctaLabel;
}

_CaseStyle _caseStyle(SessionInsightCase c, bool isDark) {
  switch (c) {
    case SessionInsightCase.a:
      return _CaseStyle(
        eyebrow: '',
        subtitle: appL10n.resultsCaseASubtitle,
        background: isDark
            ? AppColors.wrongBgDark.withValues(alpha: 0.65)
            : AppColors.coachDangerSurfaceLight,
        border: AppColors.coachDangerBorder,
        accent: isDark
            ? AppColors.wrongTextDark
            : AppColors.coachDangerTitleText,
        ctaBackground: AppColors.wrong,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            appL10n.resultsConfidentMistakesTitle(sureWrong),
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) => appL10n.resultsReviewConfidentCta(sureWrong),
      );
    case SessionInsightCase.b:
      return _CaseStyle(
        eyebrow: '',
        subtitle: appL10n.resultsCaseBSubtitle,
        background: isDark
            ? AppColors.warningBgDark.withValues(alpha: 0.5)
            : AppColors.warningBg.withValues(alpha: 0.35),
        border: AppColors.warning.withValues(alpha: 0.45),
        accent: isDark ? AppColors.warningTextDark : AppColors.warningText,
        ctaBackground: AppColors.warning,
        ctaForeground: Colors.white,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            appL10n.resultsEduMistakesTitle(eduWrong),
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) => appL10n.resultsReviewEduCta(eduWrong),
      );
    case SessionInsightCase.c:
      return _CaseStyle(
        eyebrow: '',
        subtitle: appL10n.resultsCaseCSubtitle,
        background: isDark
            ? AppColors.wrongBgDark.withValues(alpha: 0.65)
            : AppColors.coachDangerSurfaceLight,
        border: AppColors.coachDangerBorder,
        accent: isDark
            ? AppColors.wrongTextDark
            : AppColors.coachDangerTitleText,
        ctaBackground: AppColors.wrong,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) {
          if (sureWrong > 0 && eduWrong > 0) {
            return appL10n.resultsMixedMistakesTitle(sureWrong, eduWrong);
          }
          if (sureWrong > 0) {
            return appL10n.resultsConfidentMistakesTitle(sureWrong);
          }
          return appL10n.resultsEduMistakesTitle(eduWrong);
        },
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) {
              final n = sureWrong + eduWrong;
              return appL10n.resultsReviewConfidentCta(n);
            },
      );
    case SessionInsightCase.d:
      return _CaseStyle(
        eyebrow: '',
        subtitle: appL10n.resultsCaseDSubtitle,
        background: isDark
            ? AppColors.infoBgDark.withValues(alpha: 0.45)
            : AppColors.infoBg.withValues(alpha: 0.35),
        border: AppColors.info.withValues(alpha: 0.4),
        accent: isDark ? AppColors.infoTextDark : AppColors.infoText,
        ctaBackground: AppColors.info,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            appL10n.resultsNoConfidentMistakes,
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) => appL10n.resultsReviewYourMistakes,
      );
    case SessionInsightCase.e:
      return _CaseStyle(
        eyebrow: appL10n.resultsExcellentEyebrow,
        subtitle: appL10n.resultsCaseESubtitle,
        background: isDark
            ? AppColors.correctBgDark.withValues(alpha: 0.45)
            : AppColors.correctBg.withValues(alpha: 0.35),
        border: AppColors.correct.withValues(alpha: 0.4),
        accent: isDark ? AppColors.correctTextDark : AppColors.correctText,
        ctaBackground: AppColors.correct,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            appL10n.resultsExcellentTitle,
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) => appL10n.resultsPracticeMore,
      );
    case SessionInsightCase.gIncomplete:
      return _CaseStyle(
        eyebrow: '',
        subtitle: appL10n.resultsCaseFSubtitle,
        background: _schemeNeutralBg(isDark),
        border: AppColors.borderLight,
        accent: AppColors.primaryDark,
        ctaBackground: AppColors.primary,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            appL10n.resultsIncompleteTitle,
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) => appL10n.resultsPracticeMore,
      );
    case SessionInsightCase.fLockedSettings:
      return _CaseStyle(
        eyebrow: appL10n.resultsLockedEyebrow,
        subtitle: appL10n.resultsCaseGSubtitle,
        background: _schemeNeutralBg(isDark),
        border: AppColors.borderLight,
        accent: AppColors.primaryDark,
        ctaBackground: AppColors.primary,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            appL10n.resultsLockedTitle,
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) => appL10n.resultsEnableTracking,
      );
    case SessionInsightCase.fLockedSkipped:
      return _CaseStyle(
        eyebrow: '',
        subtitle: appL10n.resultsCaseHSubtitle,
        background: _schemeNeutralBg(isDark),
        border: AppColors.borderLight,
        accent: AppColors.primaryDark,
        ctaBackground: AppColors.primary,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            appL10n.resultsInsightsUnavailable,
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) => appL10n.resultsRetryWithConfidence,
      );
    case SessionInsightCase.fNoAttempts:
      return _CaseStyle(
        eyebrow: '',
        subtitle: appL10n.resultsCaseISubtitle,
        background: _schemeNeutralBg(isDark),
        border: AppColors.borderLight,
        accent: AppColors.primaryDark,
        ctaBackground: AppColors.primary,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            appL10n.resultsNoQuestionsAttempted,
        ctaLabel:
            ({
              required sureWrong,
              required eduWrong,
              required wrong,
              required weakestTopic,
            }) => appL10n.resultsRetryTest,
      );
  }
}

Color _schemeNeutralBg(bool isDark) =>
    isDark ? AppColors.surfaceSecondaryDark : AppColors.surfaceSecondaryLight;

String _incompleteTitle(SessionResult result) {
  final attempted = sessionAnsweredScored(result);
  return appL10n.resultsIncompleteHeadline(attempted, result.questionCount);
}

String _incompleteSubtitle(SessionResult result) {
  final remaining = sessionRemainingCount(result);
  if (remaining > 0) {
    return appL10n.resultsLeftUnanswered(remaining);
  }
  return appL10n.resultsFinishMore;
}

void logSessionInsightCaseShown(
  WidgetRef ref, {
  required SessionInsightCase insightCase,
  required SessionResult result,
}) {
  unawaited(
    Analytics.track(
      ref,
      SessionInsightCaseShownEvent(
        caseName: sessionInsightCaseAnalyticsName(insightCase),
        sureWrong: sessionSureWrongCount(result),
        eduWrong: sessionEduWrongCount(result),
      ),
    ),
  );
}

Future<SessionInsightCase> resolveInsightCase(
  WidgetRef ref,
  SessionResult result,
) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  final base = classifySessionInsight(
    result: result,
    confidenceTrackingEnabled: prefs.confidenceTrackingEnabled,
  );
  if (base == SessionInsightCase.fLockedSettings ||
      base == SessionInsightCase.fLockedSkipped) {
    if (!prefs.confidenceTrackingEnabled) {
      return SessionInsightCase.fLockedSettings;
    }
    return SessionInsightCase.fLockedSkipped;
  }
  return base;
}
