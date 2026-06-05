import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/topic_test/providers/topic_test_ui_providers.dart';
import '../domain/session_insight_case.dart';

/// Hero insight card for session summary (cases A–F).
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
  });

  final String sessionId;
  final SessionResult result;
  final SessionInsightCase insightCase;
  final String? topRiskTopic;
  final int? topRiskPct;
  final String? weakestTopicName;
  final bool compact;

  static const _getStartedKey = 'get_started_diagnostic';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sureWrong = sessionSureWrongCount(result);
    final eduWrong = sessionEduWrongCount(result);
    final highRisk = sureWrong + eduWrong;
    final marks = sessionTierMarksLost(highRisk > 0 ? highRisk : result.wrong);

    final style = _caseStyle(insightCase, isDark);
    final footnote = result.analyticsFeatureKey == _getStartedKey
        ? 'Full 25-question tests unlock richer topic patterns.'
        : null;

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
          Text(
            style.eyebrow,
            style: AppTextStyles.caption().copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: style.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            style.title(
              sureWrong: sureWrong,
              eduWrong: eduWrong,
              wrong: result.wrong,
            ),
            style: AppTextStyles.h2().copyWith(
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.w900,
              color: style.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            style.subtitle,
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
              insightCase != SessionInsightCase.fLockedSettings &&
              insightCase != SessionInsightCase.fLockedSkipped) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Real exam cost: −${marks.toStringAsFixed(2)} marks',
              style: AppTextStyles.labelSm().copyWith(
                color: AppColors.wrong,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (topRiskTopic != null &&
              (insightCase == SessionInsightCase.a ||
                  insightCase == SessionInsightCase.b ||
                  insightCase == SessionInsightCase.c)) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Top risk area: $topRiskTopic'
              '${topRiskPct != null ? ' ($topRiskPct% of your loss)' : ''}',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (footnote != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              footnote,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: style.ctaBackground,
                foregroundColor: style.ctaForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              onPressed: () => _onCta(context, ref),
              child: Text(
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
        context.push(
          '/session-confidence-review/$sessionId/${AnswerConfidence.verySure}?outcome=wrong',
        );
      case SessionInsightCase.b:
        context.push(
          '/session-confidence-review/$sessionId/${AnswerConfidence.somewhatSure}?outcome=wrong',
        );
      case SessionInsightCase.c:
        context.push('/danger-zone/$sessionId');
      case SessionInsightCase.d:
        _openHistory(context, focusWrong: true);
      case SessionInsightCase.e:
        if (weakestTopicName != null && result.subject.isNotEmpty) {
          ref
              .read(topicTestSelectedSubjectSlugProvider.notifier)
              .setSlug(result.subject);
          ref
              .read(topicTestSearchQueryProvider.notifier)
              .setQuery(weakestTopicName!);
        }
        context.push('/topic-test');
      case SessionInsightCase.fLockedSettings:
        context.push('/settings');
      case SessionInsightCase.fLockedSkipped:
        if (result.subject.isNotEmpty && result.subject != 'revision_quick') {
          context.go('/subject/${Uri.encodeComponent(result.subject)}');
        } else {
          context.go('/');
        }
    }
  }

  void _openHistory(BuildContext context, {bool focusWrong = false}) {
    final loc = focusWrong
        ? '/history/$sessionId?focus=wrong'
        : '/history/$sessionId';
    final path = GoRouter.of(context).state.uri.path;
    if (path.startsWith('/danger-zone/')) {
      context.pushReplacement(loc);
    } else {
      context.push(loc);
    }
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.isDark,
  });

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
        eyebrow: 'BIGGEST INSIGHT',
        subtitle: 'You were sure, but incorrect. These are rank killers.',
        background: isDark
            ? AppColors.wrongBgDark.withValues(alpha: 0.65)
            : AppColors.coachDangerSurfaceLight,
        border: AppColors.coachDangerBorder,
        accent: isDark ? AppColors.wrongTextDark : AppColors.coachDangerTitleText,
        ctaBackground: AppColors.wrong,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            '$sureWrong Confident Mistake${sureWrong == 1 ? '' : 's'}',
        ctaLabel: ({
          required sureWrong,
          required eduWrong,
          required wrong,
          required weakestTopic,
        }) =>
            'Review $sureWrong confident mistake${sureWrong == 1 ? '' : 's'}',
      );
    case SessionInsightCase.b:
      return _CaseStyle(
        eyebrow: 'BIGGEST INSIGHT',
        subtitle:
            'Your elimination strategy failed more often than it worked.',
        background: isDark
            ? AppColors.warningBgDark.withValues(alpha: 0.5)
            : AppColors.warningBg.withValues(alpha: 0.35),
        border: AppColors.warning.withValues(alpha: 0.45),
        accent: isDark ? AppColors.warningTextDark : AppColors.warningText,
        ctaBackground: AppColors.warning,
        ctaForeground: Colors.white,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            '$eduWrong Educated Guess Mistake${eduWrong == 1 ? '' : 's'}',
        ctaLabel: ({
          required sureWrong,
          required eduWrong,
          required wrong,
          required weakestTopic,
        }) =>
            'Review $eduWrong educated guess${eduWrong == 1 ? '' : 'es'}',
      );
    case SessionInsightCase.c:
      return _CaseStyle(
        eyebrow: 'BIGGEST INSIGHT',
        subtitle:
            'You lost marks from both overconfidence and risky elimination.',
        background: isDark
            ? AppColors.primaryDeep.withValues(alpha: 0.35)
            : AppColors.primaryLight.withValues(alpha: 0.35),
        border: AppColors.primary.withValues(alpha: 0.45),
        accent: isDark ? AppColors.primary : AppColors.primaryDark,
        ctaBackground: AppColors.primary,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) {
          final n = sureWrong + eduWrong;
          return '$n High-Risk Mistake${n == 1 ? '' : 's'}';
        },
        ctaLabel: ({
          required sureWrong,
          required eduWrong,
          required wrong,
          required weakestTopic,
        }) {
          final n = sureWrong + eduWrong;
          return 'Review $n high-risk mistake${n == 1 ? '' : 's'}';
        },
      );
    case SessionInsightCase.d:
      return _CaseStyle(
        eyebrow: 'INSIGHT',
        subtitle:
            'No high-risk mistakes — wrong answers were pure guesses. '
            'You still lost marks worth reviewing.',
        background: isDark
            ? AppColors.infoBgDark.withValues(alpha: 0.45)
            : AppColors.infoBg.withValues(alpha: 0.35),
        border: AppColors.info.withValues(alpha: 0.4),
        accent: isDark ? AppColors.infoTextDark : AppColors.infoText,
        ctaBackground: AppColors.info,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            'No high-risk mistakes',
        ctaLabel: ({
          required sureWrong,
          required eduWrong,
          required wrong,
          required weakestTopic,
        }) =>
            'Review $wrong wrong answer${wrong == 1 ? '' : 's'}',
      );
    case SessionInsightCase.e:
      return _CaseStyle(
        eyebrow: 'EXCELLENT SESSION',
        subtitle:
            'When you were confident, you stayed accurate. Keep the momentum.',
        background: isDark
            ? AppColors.correctBgDark.withValues(alpha: 0.45)
            : AppColors.correctBg.withValues(alpha: 0.35),
        border: AppColors.correct.withValues(alpha: 0.4),
        accent: isDark ? AppColors.correctTextDark : AppColors.correctText,
        ctaBackground: AppColors.correct,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            'No high-risk mistakes',
        ctaLabel: ({
          required sureWrong,
          required eduWrong,
          required wrong,
          required weakestTopic,
        }) =>
            weakestTopic != null
                ? 'Practice $weakestTopic'
                : 'Explore more topics',
      );
    case SessionInsightCase.fLockedSettings:
      return _CaseStyle(
        eyebrow: 'INSIGHTS LOCKED',
        subtitle:
            'Enable confidence tracking to unlock personalised insights.',
        background: _schemeNeutralBg(isDark),
        border: AppColors.borderLight,
        accent: AppColors.primaryDark,
        ctaBackground: AppColors.primary,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            'Insights locked',
        ctaLabel: ({
          required sureWrong,
          required eduWrong,
          required wrong,
          required weakestTopic,
        }) =>
            'Enable confidence tracking',
      );
    case SessionInsightCase.fLockedSkipped:
      return _CaseStyle(
        eyebrow: 'INSIGHTS LOCKED',
        subtitle:
            'Mark how sure you are on each question to unlock danger-zone insights.',
        background: _schemeNeutralBg(isDark),
        border: AppColors.borderLight,
        accent: AppColors.primaryDark,
        ctaBackground: AppColors.primary,
        ctaForeground: AppColors.onPrimary,
        title: ({required sureWrong, required eduWrong, required wrong}) =>
            'Insights locked',
        ctaLabel: ({
          required sureWrong,
          required eduWrong,
          required wrong,
          required weakestTopic,
        }) =>
            'Retry with confidence labels',
      );
  }
}

Color _schemeNeutralBg(bool isDark) => isDark
    ? AppColors.surfaceSecondaryDark
    : AppColors.surfaceSecondaryLight;

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
