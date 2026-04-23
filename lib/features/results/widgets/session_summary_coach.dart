import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_global_dispatch.dart';
import '../../../core/domain/entities/revision_queue_item.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/services/deferred_push_permission_coordinator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/topic_test/providers/topic_test_ui_providers.dart';
import '../providers/session_coach_providers.dart';
import '../providers/session_topic_accuracy_provider.dart';

/// Opens session question review. When the user is already on Danger Zone for
/// this session, [Navigator] page keys from stacked `/history/...` routes can
/// collide; replacing that route avoids the duplicate-key assert.
void _logUspSessionCoach(String action) {
  logGlobalAnalytics(UspSessionCoachCtaTappedEvent(action: action));
}

void _openSessionHistoryReview(
  BuildContext context,
  String sessionId, {
  bool focusWrong = false,
}) {
  final loc =
      focusWrong ? '/history/$sessionId?focus=wrong' : '/history/$sessionId';
  final path = GoRouter.of(context).state.uri.path;
  if (path.startsWith('/danger-zone/')) {
    context.pushReplacement(loc);
  } else {
    context.push(loc);
  }
}

/// Post-test “coach” summary: score, danger zone, next action, trend, revision, advanced.
class SessionSummaryCoachContent extends ConsumerWidget {
  const SessionSummaryCoachContent({
    super.key,
    required this.sessionId,
    required this.result,
    required this.displaySubjectName,
  });

  final String sessionId;
  final SessionResult result;
  final String displaySubjectName;

  bool get _canSubjectScope =>
      result.subject.isNotEmpty && result.subject != 'revision_quick';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final attempted = result.correct + result.wrong;
    final topicRowsAsync = ref.watch(sessionTopicAccuracyProvider(sessionId));
    final historyArg = (
      sessionId: sessionId,
      subject: result.subject,
      topic: result.topic,
    );
    final historyAsync = _canSubjectScope
        ? ref.watch(sessionCoachHistoryProvider(historyArg))
        : const AsyncValue<SessionCoachHistory>.data(
            SessionCoachHistory(chartPoints: []),
          );
    final timeAsync = ref.watch(sessionCoachTimeStatsProvider(sessionId));
    final revisionAsync = ref.watch(revisionQueueItemsProvider);

    final weak = topicRowsAsync.maybeWhen(
      data: (rows) => _pickWeakestTopic(rows),
      orElse: () => null,
    );

    final plan = _CoachNextPlan.build(result: result, weak: weak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (attempted == 0) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'You didn\'t attempt any questions in this session. '
              'Try again when you are ready.',
              style: AppTextStyles.bodyMd().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        _ScoreTrendCard(
          sessionId: sessionId,
          result: result,
          displaySubjectName: displaySubjectName,
          scheme: scheme,
          isDark: isDark,
          historyAsync: historyAsync,
          canScope: _canSubjectScope,
        ),
        if (attempted > 0) ...[
          const SizedBox(height: AppSpacing.md),
          _DangerZoneCard(
            result: result,
            sessionId: sessionId,
            scheme: scheme,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _NextActionCard(
            plan: plan,
            result: result,
            sessionId: sessionId,
            scheme: scheme,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _ProgressWeakCard(
            displaySubjectName: displaySubjectName,
            result: result,
            historyAsync: historyAsync,
            weakTopic: weak,
            scheme: scheme,
            isDark: isDark,
            canScope: _canSubjectScope,
            ref: ref,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _RevisionNudgeCard(
          wrongInSession: result.wrong,
          revisionAsync: revisionAsync,
          scheme: scheme,
        ),
        const SizedBox(height: AppSpacing.md),
        _AdvancedInsightsExpansion(
          result: result,
          topicRowsAsync: topicRowsAsync,
          timeAsync: timeAsync,
          scheme: scheme,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

({String name, int correct, int attempted})? _pickWeakestTopic(
  List<({String topic, int correct, int attempted})> rows,
) {
  if (rows.length < 2) return null;
  ({String name, int correct, int attempted})? worst;
  for (final r in rows) {
    if (r.attempted < 3) continue;
    final acc = r.correct / r.attempted;
    if (acc >= 0.5) continue;
    if (worst == null) {
      worst = (name: r.topic, correct: r.correct, attempted: r.attempted);
      continue;
    }
    final wAcc = worst.correct / worst.attempted;
    if (acc < wAcc) {
      worst = (name: r.topic, correct: r.correct, attempted: r.attempted);
    }
  }
  return worst;
}

class _CoachNextPlan {
  _CoachNextPlan({required this.steps, required this.primaryKind});

  final List<({String title, String? subtitle})> steps;
  final _CoachPrimaryKind primaryKind;

  static _CoachNextPlan build({
    required SessionResult result,
    required ({String name, int correct, int attempted})? weak,
  }) {
    final steps = <({String title, String? subtitle})>[];
    _CoachPrimaryKind primary = _CoachPrimaryKind.home;

    if (result.dangerZoneWrongCount > 0) {
      steps.add((
        title: 'Review Danger Zone questions',
        subtitle:
            '(${result.dangerZoneWrongCount} confident mistake${result.dangerZoneWrongCount == 1 ? '' : 's'})',
      ));
      primary = _CoachPrimaryKind.dangerZone;
    } else if (result.wrong > 0) {
      steps.add((
        title: 'Review wrong answers',
        subtitle: '(${result.wrong} question${result.wrong == 1 ? '' : 's'})',
      ));
      primary = _CoachPrimaryKind.reviewWrong;
    } else {
      steps.add((
        title: 'Great! All correct in this session.',
        subtitle: 'Move on when you are ready.',
      ));
      primary = _CoachPrimaryKind.browseTopics;
    }

    if (weak != null) {
      final pct = (100 * weak.correct / weak.attempted).round();
      steps.add((
        title: 'Practice your weakest topic: ${weak.name}',
        subtitle: '($pct% accuracy · ${weak.correct}/${weak.attempted})',
      ));
    } else if (result.wrong > 0 && result.accuracy < 70) {
      steps.add((
        title: 'Retry wrong answers to reinforce learning',
        subtitle: 'Short session with mistakes only',
      ));
    }

    if (result.correct + result.wrong > 0 &&
        result.accuracy >= 75 &&
        result.wrong == 0) {
      steps.add((
        title: 'Then explore the next topic in this subject',
        subtitle: 'Open topic list from your subject page',
      ));
    }

    return _CoachNextPlan(steps: steps, primaryKind: primary);
  }
}

enum _CoachPrimaryKind { dangerZone, reviewWrong, browseTopics, home }

TextStyle _advancedInsightsSectionHeading(ColorScheme scheme) =>
    AppTextStyles.bodySm().copyWith(
      fontWeight: FontWeight.bold,
      color: scheme.onSurface,
    );

class _ScoreTrendCard extends ConsumerWidget {
  const _ScoreTrendCard({
    required this.sessionId,
    required this.result,
    required this.displaySubjectName,
    required this.scheme,
    required this.isDark,
    required this.historyAsync,
    required this.canScope,
  });

  final String sessionId;
  final SessionResult result;
  final String displaySubjectName;
  final ColorScheme scheme;
  final bool isDark;
  final AsyncValue<SessionCoachHistory> historyAsync;
  final bool canScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attempted = result.correct + result.wrong;
    final net = result.netScore;
    final netColor = net >= 0 ? AppColors.coachTrendEmerald : AppColors.wrong;

    Widget trendChild = Text(
      canScope
          ? 'Complete more tests to see improvement trends'
          : 'Progress trends are available for subject practice sessions.',
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
    );

    if (canScope) {
      trendChild = historyAsync.when(
        loading: () => const SizedBox(
          height: 20,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => trendChild,
        data: (h) {
          if (h.vsImmediatePrevious == null) {
            return Text(
              'First test in $displaySubjectName — complete more to see trends',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            );
          }
          final d = h.vsImmediatePrevious!;
          final label = _formatVsLast(d, displaySubjectName);
          final color = d > 0.5
              ? AppColors.coachTrendEmerald
              : d < -0.5
              ? AppColors.wrong
              : scheme.onSurfaceVariant;
          return Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm().copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          );
        },
      );
    }

    final accLabel = attempted == 0 ? '—' : '${result.accuracy.round()}%';

    return _CoachSurfaceCard(
      scheme: scheme,
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You have scored',
              textAlign: TextAlign.center,
              style: AppTextStyles.label().copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                constraints: const BoxConstraints(minWidth: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 32,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      netColor.withValues(alpha: isDark ? 0.14 : 0.10),
                      scheme.surfaceContainerHighest.withValues(
                        alpha: isDark ? 0.45 : 0.65,
                      ),
                    ],
                  ),
                  border: Border.all(color: netColor.withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(
                        alpha: isDark ? 0.35 : 0.08,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  net.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2().copyWith(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: netColor,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: AppTextStyles.bodySm().copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: '('),
                  TextSpan(
                    text: '+${result.correct * 2}',
                    style: TextStyle(color: AppColors.coachTrendEmerald),
                  ),
                  const TextSpan(text: ' / '),
                  TextSpan(
                    text: result.wrong == 0
                        ? '0'
                        : '-${(result.wrong * 0.66).toStringAsFixed(2)}',
                    style: TextStyle(color: AppColors.wrong),
                  ),
                  const TextSpan(text: ')'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(
                  alpha: isDark ? 0.35 : 0.55,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: AppTextStyles.bodySm().copyWith(height: 1.35),
                  children: [
                    TextSpan(
                      text: 'Accuracy: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(
                      text: accLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' (${result.correct}/${result.questionCount})',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            trendChild,
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.onSurface,
                  side: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await DeferredPushPermissionCoordinator.tryOfferFromResultsUserAction(
                    context,
                    ref,
                  );
                  if (!context.mounted) return;
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                child: Text(
                  'Go back',
                  style: AppTextStyles.label().copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.summaryCtaBlue,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await DeferredPushPermissionCoordinator.tryOfferFromResultsUserAction(
                    context,
                    ref,
                  );
                  if (context.mounted) {
                    _openSessionHistoryReview(context, sessionId);
                  }
                },
                child: Text(
                  'Review explanations',
                  style: AppTextStyles.label().copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatVsLast(double deltaPoints, String subjectLabel) {
  final rounded = deltaPoints.round();
  final sign = rounded > 0 ? '+' : '';
  final emoji = rounded > 0
      ? '📈 '
      : rounded < 0
      ? '📉 '
      : '→ ';
  return '$emoji$sign$rounded% vs your last $subjectLabel test';
}

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({
    required this.result,
    required this.sessionId,
    required this.scheme,
    required this.isDark,
  });

  final SessionResult result;
  final String sessionId;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final n = result.dangerZoneWrongCount;
    final marks = result.dangerZoneMarksEstimate;
    if (n <= 0) {
      return _CoachSurfaceCard(
        scheme: scheme,
        isDark: isDark,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.correct,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No Danger Zone questions! When you were confident, you stayed accurate.',
                  style: AppTextStyles.bodyMd().copyWith(
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bg = isDark
        ? AppColors.wrongBgDark
        : AppColors.coachDangerSurfaceLight;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coachDangerBorder, width: 3),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '⚠️  DANGER ZONE',
            style: AppTextStyles.label().copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.wrongTextDark
                  : AppColors.coachDangerTitleText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$n Confident Mistake${n == 1 ? '' : 's'}',
            style: AppTextStyles.h2().copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? AppColors.wrongTextDark
                  : AppColors.coachDangerTitleText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real exam cost: -${marks.toStringAsFixed(2)} marks',
            style: AppTextStyles.bodyMd().copyWith(
              fontSize: 14,
              color: AppColors.wrong,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'These are rank killers. You thought you knew, but didn\'t.',
            style: AppTextStyles.bodySm().copyWith(
              fontSize: 14,
              color: isDark
                  ? AppColors.wrongTextDark
                  : AppColors.coachDangerTitleText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coachDangerCtaFill,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                _logUspSessionCoach('results_review_danger_zone_tap');
                context.push('/danger-zone/$sessionId');
              },
              child: Text(
                'Review Danger Zone',
                style: AppTextStyles.label().copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextActionCard extends ConsumerWidget {
  const _NextActionCard({
    required this.plan,
    required this.result,
    required this.sessionId,
    required this.scheme,
    required this.isDark,
  });

  final _CoachNextPlan plan;
  final SessionResult result;
  final String sessionId;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = isDark
        ? AppColors.infoBgDark
        : AppColors.coachNextActionSurfaceLight;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.summaryChartBlue),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recommended Next Step',
            style: AppTextStyles.label().copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < plan.steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: AppTextStyles.bodySm().copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.summaryCtaBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.steps[i].title,
                        style: AppTextStyles.bodySm().copyWith(
                          fontSize: 14,
                          color: scheme.onSurface,
                          height: 1.35,
                        ),
                      ),
                      if (plan.steps[i].subtitle != null)
                        Text(
                          plan.steps[i].subtitle!,
                          style: AppTextStyles.caption().copyWith(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.summaryCtaBlue,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _logUspSessionCoach('results_coach_start_next_step_tap');
                unawaited(
                  _runPrimaryCoachAction(
                    context,
                    ref,
                    plan.primaryKind,
                    sessionId,
                    result,
                  ),
                );
              },
              child: Text(
                'Start Next Step',
                style: AppTextStyles.label().copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _runPrimaryCoachAction(
  BuildContext context,
  WidgetRef ref,
  _CoachPrimaryKind kind,
  String sessionId,
  SessionResult result,
) async {
  HapticFeedback.lightImpact();
  switch (kind) {
    case _CoachPrimaryKind.dangerZone:
      if (context.mounted) context.push('/danger-zone/$sessionId');
      break;
    case _CoachPrimaryKind.reviewWrong:
      if (context.mounted) {
        _openSessionHistoryReview(context, sessionId, focusWrong: true);
      }
      break;
    case _CoachPrimaryKind.browseTopics:
      if (result.subject.isNotEmpty && result.subject != 'revision_quick') {
        if (context.mounted) {
          context.go('/subject/${Uri.encodeComponent(result.subject)}/topics');
        }
      } else if (context.mounted) {
        await DeferredPushPermissionCoordinator.tryOfferFromResultsUserAction(
          context,
          ref,
        );
        if (context.mounted) context.go('/');
      }
      break;
    case _CoachPrimaryKind.home:
      if (context.mounted) {
        await DeferredPushPermissionCoordinator.tryOfferFromResultsUserAction(
          context,
          ref,
        );
        if (context.mounted) context.go('/');
      }
      break;
  }
}

class _ProgressWeakCard extends StatelessWidget {
  const _ProgressWeakCard({
    required this.displaySubjectName,
    required this.result,
    required this.historyAsync,
    required this.weakTopic,
    required this.scheme,
    required this.isDark,
    required this.canScope,
    required this.ref,
  });

  final String displaySubjectName;
  final SessionResult result;
  final AsyncValue<SessionCoachHistory> historyAsync;
  final ({String name, int correct, int attempted})? weakTopic;
  final ColorScheme scheme;
  final bool isDark;
  final bool canScope;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return _CoachSurfaceCard(
      scheme: scheme,
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              displaySubjectName,
              style: AppTextStyles.label().copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your progress: Last 10 tests',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (!canScope)
              Text(
                'Open a subject practice test to track accuracy over time.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              historyAsync.when(
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Text(
                  'Could not load trend',
                  style: AppTextStyles.bodySm().copyWith(color: scheme.error),
                ),
                data: (h) {
                  if (h.chartPoints.length < 2) {
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'Complete 2+ tests to see your trend',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: CustomPaint(
                          painter: _CoachTestsLinePainter(
                            points: h.chartPoints,
                            lineColor: AppColors.summaryChartBlue,
                            gridColor: scheme.outlineVariant.withValues(
                              alpha: 0.4,
                            ),
                            labelColor: scheme.onSurfaceVariant,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (h.firstVsLastInWindow != null)
                        Text(
                          _windowTrendLabel(h.firstVsLastInWindow!),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySm().copyWith(
                            fontWeight: FontWeight.w600,
                            color: _windowTrendColor(
                              h.firstVsLastInWindow!,
                              scheme,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            if (weakTopic != null) ...[
              const SizedBox(height: 16),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
              const SizedBox(height: 12),
              Text(
                'Weakest Topic: ${weakTopic!.name}',
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                '${(100 * weakTopic!.correct / weakTopic!.attempted).round()}% accuracy '
                '(${weakTopic!.correct}/${weakTopic!.attempted} questions)',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _logUspSessionCoach('results_weak_topic_practice_tap');
                  ref
                      .read(topicTestSelectedSubjectSlugProvider.notifier)
                      .setSlug(result.subject);
                  ref
                      .read(topicTestSearchQueryProvider.notifier)
                      .setQuery(weakTopic!.name);
                  context.push('/topic-test');
                },
                child: Text('Practice ${weakTopic!.name}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _windowTrendLabel(double delta) {
  if (delta > 5) {
    return '📈 Improving: +${delta.round()}% since test 1 in this window';
  }
  if (delta < -5) {
    return '📉 Declining: ${delta.round()}% since test 1 in this window';
  }
  return '→ Stable: similar to test 1 in this window';
}

Color _windowTrendColor(double delta, ColorScheme scheme) {
  if (delta > 5) return AppColors.coachTrendEmerald;
  if (delta < -5) return AppColors.wrong;
  return scheme.onSurfaceVariant;
}

class _RevisionNudgeCard extends StatelessWidget {
  const _RevisionNudgeCard({
    required this.wrongInSession,
    required this.revisionAsync,
    required this.scheme,
  });

  final int wrongInSession;
  final AsyncValue<List<RevisionQueueItem>> revisionAsync;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final due = revisionAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);
    return _CoachSurfaceCard(
      scheme: scheme,
      isDark: Theme.of(context).brightness == Brightness.dark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Revision Queue',
              style: AppTextStyles.label().copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            Text(
              "(Collection of MCQs that you mark wrong, for later revision)",
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 10),
            if (wrongInSession > 0)
              Text(
                '➕ $wrongInSession question${wrongInSession == 1 ? '' : 's'} '
                'from this session were sent to revision (incorrect)',
                style: AppTextStyles.bodySm().copyWith(
                  color: AppColors.coachTrendEmerald,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'No incorrect answers in this session — nothing new added to revision.',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            if (due > 0) ...[
              const SizedBox(height: 8),
              Text(
                '📚 $due question${due == 1 ? '' : 's'} in your revision queue',
                style: AppTextStyles.bodySm().copyWith(
                  color: AppColors.summaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.summaryCtaBlue,
                side: const BorderSide(color: AppColors.summaryCtaBlue),
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () {
                _logUspSessionCoach('results_revision_queue_nudge_tap');
                context.push('/revision-queue');
              },
              child: const Text('Go to Revision Queue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedInsightsExpansion extends ConsumerWidget {
  const _AdvancedInsightsExpansion({
    required this.result,
    required this.topicRowsAsync,
    required this.timeAsync,
    required this.scheme,
  });

  final SessionResult result;
  final AsyncValue<List<({String topic, int correct, int attempted})>>
  topicRowsAsync;
  final AsyncValue<({int avgSecs, int minSecs, int maxSecs})> timeAsync;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          'View detailed performance breakdown',
          style: AppTextStyles.label().copyWith(
            color: AppColors.summaryCtaBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confidence accuracy',
                  style: _advancedInsightsSectionHeading(scheme),
                ),
                const SizedBox(height: 6),
                _confLine(
                  'Confident',
                  result.confidenceSureTotal,
                  result.confidenceSureCorrect,
                ),
                _confLine(
                  'Educated guess',
                  result.confidenceIntelligentTotal,
                  result.confidenceIntelligentCorrect,
                ),
                _confLine(
                  'Pure guess',
                  result.confidencePureTotal,
                  result.confidencePureCorrect,
                ),
                const SizedBox(height: 14),
                Text(
                  'Time analysis',
                  style: _advancedInsightsSectionHeading(scheme),
                ),
                timeAsync.when(
                  loading: () => const Text('…'),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (t) {
                    if (t.avgSecs <= 0) {
                      return Text(
                        'No per-question timing captured.',
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      );
                    }
                    return Text(
                      'Avg ${t.avgSecs}s per question · '
                      'fastest ${t.minSecs}s · slowest ${t.maxSecs}s',
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                      ),
                    );
                  },
                ),
                topicRowsAsync.maybeWhen(
                  data: (rows) {
                    if (rows.length <= 1) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 14),
                        Text(
                          'Topic-wise accuracy from this test',
                          style: _advancedInsightsSectionHeading(scheme),
                        ),
                        const SizedBox(height: 6),
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${r.topic}: ${(100 * r.correct / r.attempted).round()}% '
                              '(${r.correct}/${r.attempted})',
                              style: AppTextStyles.bodySm().copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confLine(String label, int total, int correct) {
    if (total <= 0) {
      return Text(
        '$label: —',
        style: AppTextStyles.bodySm().copyWith(color: scheme.onSurfaceVariant),
      );
    }
    final acc = (100 * correct / total).round();
    return Text(
      '$label: $acc% accurate ($correct/$total)',
      style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
    );
  }
}

class _CoachSurfaceCard extends StatelessWidget {
  const _CoachSurfaceCard({
    required this.scheme,
    required this.isDark,
    required this.child,
  });

  final ColorScheme scheme;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}

class _CoachTestsLinePainter extends CustomPainter {
  _CoachTestsLinePainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<SessionCoachPoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 32.0;
    const padR = 8.0;
    const padT = 8.0;
    const padB = 22.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    for (var g = 0.0; g <= 100; g += 25) {
      final y = padT + h * (1 - g / 100);
      canvas.drawLine(
        Offset(padL, y),
        Offset(padL + w, y),
        Paint()
          ..color = gridColor
          ..strokeWidth = 1,
      );
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      final x = padL + w / 2;
      final y = padT + h * (1 - points.first.accuracyPct / 100);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
      return;
    }

    final n = points.length;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final x = padL + w * (i / (n - 1));
      final y = padT + h * (1 - points[i].accuracyPct.clamp(0, 100) / 100);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 0; i < n; i++) {
      final x = padL + w * (i / (n - 1));
      final y = padT + h * (1 - points[i].accuracyPct.clamp(0, 100) / 100);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
    }

    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    final step = n > 8 ? (n / 4).ceil() : 1;
    for (var i = 0; i < n; i += step) {
      tp.text = TextSpan(
        text: '${points[i].testNumber}',
        style: TextStyle(color: labelColor, fontSize: 10),
      );
      tp.layout();
      final x = padL + w * (i / (n - 1)) - tp.width / 2;
      tp.paint(canvas, Offset(x, padT + h + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _CoachTestsLinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}
