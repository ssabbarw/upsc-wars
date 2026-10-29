import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_global_dispatch.dart';
import '../../../core/analytics/screen_flow_analytics.dart';
import '../../../core/domain/entities/revision_queue_item.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/presentation/topic_label.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/domain/create_get_started_session_use_case.dart';
import '../../home/domain/demo_diagnostic_ephemeral_store.dart';
import '../../practice_tests/domain/insight_improve.dart';
import '../domain/session_insight_case.dart';
import '../domain/session_insight_metrics.dart';
import '../providers/session_coach_providers.dart';
import '../providers/session_topic_accuracy_provider.dart';
import 'demo_results_review_coach_overlay.dart';
import 'questions_to_review_card.dart';
import 'session_insight_hero_card.dart';
import '../../../l10n/l10n.dart';

void _openSessionHistoryReview(
  BuildContext context,
  String sessionId, {
  bool focusWrong = false,
  String? analyticsFeatureKey,
}) {
  maybeMarkDemoDiagnosticReviewOpened(
    sessionId,
    analyticsFeatureKey: analyticsFeatureKey,
  );
  final loc = focusWrong
      ? '/history/$sessionId?focus=wrong'
      : '/history/$sessionId';
  final path = GoRouter.of(context).state.uri.path;
  if (path.startsWith('/danger-zone/') || path.startsWith('/mistake-review')) {
    context.pushReplacement(loc);
  } else {
    context.push(loc);
  }
}

/// Scales spacing and typography to fit smaller result viewports.
class _SummaryLayoutMetrics {
  const _SummaryLayoutMetrics(this.factor);

  factory _SummaryLayoutMetrics.fromViewportHeight(double height) {
    final factor = (height / 740).clamp(0.72, 1.0);
    return _SummaryLayoutMetrics(factor);
  }

  final double factor;

  bool get compact => factor < 0.88;
  double get sectionGap => AppSpacing.sm * factor;
  double get cardPadding => AppSpacing.md * factor;
  double get scoreFontSize => 32 * factor;
  double get gaugeWidth => 96 * factor;
  double get gaugeHeight => 54 * factor;
  double get gaugeStroke => (7 * factor).clamp(5.0, 7.0);
  double get statIconSize => (16 * factor).clamp(12.0, 16.0);
  double get statSubFontSize => (8 * factor).clamp(7.0, 8.0);
  double get statLabelFontSize => (9 * factor).clamp(8.0, 9.0);
  double get revisionIconSize => (28 * factor).clamp(22.0, 28.0);
  double get buttonHeight => (48 * factor).clamp(40.0, 48.0);
  int get defaultTopicCount => factor < 0.82 ? 2 : 3;
}

/// Compact one-screen session summary (score, insight hero, stats, topics).
class SessionSummaryCompactView extends HookConsumerWidget {
  const SessionSummaryCompactView({
    super.key,
    required this.sessionId,
    required this.result,
    required this.displaySubjectName,
    required this.maxHeight,
  });

  final String sessionId;
  final SessionResult result;
  final String displaySubjectName;
  final double maxHeight;

  bool get _canSubjectScope =>
      result.subject.isNotEmpty && result.subject != 'revision_quick';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = _SummaryLayoutMetrics.fromViewportHeight(maxHeight);
    final bestTopicsExpanded = useState(maxHeight >= 700);
    final worstTopicsExpanded = useState(maxHeight >= 700);
    final moreExpanded = useState(false);
    final insightCaseAsync = ref.watch(_insightCaseProvider(result));
    final topicRowsAsync = ref.watch(sessionTopicAccuracyProvider(sessionId));
    final questionsAsync = ref.watch(_sessionQuestionsProvider(sessionId));
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
    final mistakesCtaKey = useMemoized(GlobalKey.new);
    final reviewAllKey = useMemoized(GlobalKey.new);
    final topicsKey = useMemoized(GlobalKey.new);
    final reviewCoachRequested = useRef(false);
    final isDemo =
        result.analyticsFeatureKey ==
        CreateGetStartedSessionUseCase.analyticsKey;
    final insightCase = insightCaseAsync.asData?.value;
    final highlightMistakes =
        insightCase != null &&
        (usesMistakeReviewFlow(insightCase) ||
            insightCase == SessionInsightCase.d);
    final topicRows = topicRowsAsync.asData?.value;
    final hasTopicLists = topicRows != null && topicRows.isNotEmpty;

    useEffect(() {
      if (!isDemo || insightCase == null) return null;
      if (topicRowsAsync.isLoading) return null;
      if (reviewCoachRequested.value) return null;
      reviewCoachRequested.value = true;
      var cancelled = false;
      OverlayEntry? entry;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(() async {
          final prefs = await ref.read(prefsServiceProvider.future);
          if (cancelled || !context.mounted) return;
          if (prefs.demoResultsReviewCoachSeen) return;
          prefs.demoResultsReviewCoachSeen = true;
          void dismiss() {
            final current = entry;
            if (current != null && current.mounted) current.remove();
          }

          entry = OverlayEntry(
            builder: (ctx) => DemoResultsReviewCoachOverlay(
              mistakesKey: highlightMistakes ? mistakesCtaKey : null,
              reviewAllKey: reviewAllKey,
              topicsKey: hasTopicLists ? topicsKey : null,
              onDismiss: dismiss,
            ),
          );
          Overlay.of(context).insert(entry!);
        }());
      });
      return () {
        cancelled = true;
        final current = entry;
        if (current != null && current.mounted) current.remove();
      };
    }, [insightCase, topicRowsAsync.isLoading, hasTopicLists]);

    final marksRows = questionsAsync.maybeWhen(
      data: computeTopicMarksLost,
      orElse: () => <TopicMarksLost>[],
    );
    final topRisk = topRiskTopicByMarksLost(marksRows);
    final weak = topicRowsAsync.maybeWhen(
      data: pickWeakestTopicForCoach,
      orElse: () => null,
    );

    final loggedCase = useRef<SessionInsightCase?>(null);

    useEffect(() {
      if (!insightCaseAsync.hasValue) return null;
      final c = insightCaseAsync.requireValue;
      if (loggedCase.value == c) return null;
      loggedCase.value = c;
      logSessionInsightCaseShown(ref, insightCase: c, result: result);
      return null;
    }, [insightCaseAsync]);

    final accuracyRows = topicRowsAsync.asData?.value ?? const [];
    final bestTopics = topicsSortedByAccuracyDesc(accuracyRows);
    final worstTopics = topicsSortedByWorstAccuracy(accuracyRows);
    final attempted = result.correct + result.wrong;
    final showRevisionQueue = result.wrong > 0;
    final showMoreInsights = attempted > 0;

    final bottomSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMoreInsights) ...[
          _MoreInsightsTile(
            expanded: moreExpanded.value,
            onToggle: () => moreExpanded.value = !moreExpanded.value,
            scheme: scheme,
          ),
          if (moreExpanded.value) ...[
            SizedBox(height: metrics.sectionGap),
            _TimeInline(timeAsync: timeAsync, scheme: scheme),
          ],
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CompactScoreRow(
          result: result,
          displaySubjectName: displaySubjectName,
          scheme: scheme,
          isDark: isDark,
          historyAsync: historyAsync,
          canScope: _canSubjectScope,
          metrics: metrics,
        ),
        SizedBox(height: metrics.sectionGap),
        insightCaseAsync.when(
          loading: () => SizedBox(
            height: 120 * metrics.factor,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (insightCase) => SessionInsightHeroCard(
            sessionId: sessionId,
            result: result,
            insightCase: insightCase,
            topRiskTopic: topRisk?.topic,
            topRiskPct: topRisk?.pctOfLoss,
            weakestTopicName: weak?.topic,
            compact: metrics.compact,
            reviewCtaKey: highlightMistakes ? mistakesCtaKey : null,
          ),
        ),
        SizedBox(height: metrics.sectionGap),
        _ReviewAllButton(
          sessionId: sessionId,
          questionCount: result.questionCount,
          metrics: metrics,
          highlightKey: reviewAllKey,
          analyticsFeatureKey: result.analyticsFeatureKey,
        ),
        _BackToHomeButton(
          sessionId: sessionId,
          scheme: scheme,
          analyticsFeatureKey: result.analyticsFeatureKey,
        ),
        if (showRevisionQueue) ...[
          SizedBox(height: metrics.sectionGap),
          _RevisionQueueCard(
            wrongInSession: result.wrong,
            revisionAsync: revisionAsync,
            scheme: scheme,
            isDark: isDark,
            metrics: metrics,
          ),
        ],
        SizedBox(height: metrics.sectionGap),
        _TopTopicsSection(
          key: hasTopicLists ? topicsKey : null,
          bestTopics: bestTopics,
          worstTopics: worstTopics,
          bestExpanded: bestTopicsExpanded.value,
          worstExpanded: worstTopicsExpanded.value,
          onToggleBest: () =>
              bestTopicsExpanded.value = !bestTopicsExpanded.value,
          onToggleWorst: () =>
              worstTopicsExpanded.value = !worstTopicsExpanded.value,
          scheme: scheme,
          defaultVisibleCount: metrics.defaultTopicCount,
        ),
        SizedBox(height: metrics.sectionGap),
        bottomSection,
      ],
    );
  }
}

final _insightCaseProvider = FutureProvider.autoDispose
    .family<SessionInsightCase, SessionResult>((ref, result) async {
      final prefs = await ref.watch(prefsServiceProvider.future);
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
    });

final _sessionQuestionsProvider = FutureProvider.autoDispose
    .family<List<TestQuestion>, String>((ref, sessionId) async {
      final load = await ref.watch(loadSessionUseCaseProvider.future);
      final active = await load.execute(sessionId);
      return active.questions;
    });

class _CompactScoreRow extends StatelessWidget {
  const _CompactScoreRow({
    required this.result,
    required this.displaySubjectName,
    required this.scheme,
    required this.isDark,
    required this.historyAsync,
    required this.canScope,
    required this.metrics,
  });

  final SessionResult result;
  final String displaySubjectName;
  final ColorScheme scheme;
  final bool isDark;
  final AsyncValue<SessionCoachHistory> historyAsync;
  final bool canScope;
  final _SummaryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final net = result.netScore;
    final netColor = net >= 0 ? AppColors.coachTrendEmerald : AppColors.wrong;
    final attempted = result.correct + result.wrong;
    final accLabel = attempted == 0 ? '—' : '${result.accuracy.round()}%';
    final positiveMarks = result.correct * 2.0;
    final negativeMarks = result.wrong * 0.66;
    final accColor = attempted == 0
        ? scheme.onSurfaceVariant
        : result.accuracy >= 50
        ? AppColors.coachTrendEmerald
        : AppColors.wrong;

    Widget? trend;
    if (!metrics.compact && canScope) {
      trend = historyAsync.when(
        data: (h) {
          if (h.vsImmediatePrevious == null) return null;
          final d = h.vsImmediatePrevious!;
          final rounded = d.round();
          final sign = rounded > 0 ? '+' : '';
          return Text(
            context.l10n.resultsAccuracyVsLast(sign, rounded),
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          );
        },
        loading: () => null,
        error: (_, _) => null,
      );
    }

    final marksBreakdown = attempted == 0
        ? context.l10n.resultsAttemptToEarn
        : context.l10n.resultsMarksBreakdown(
            positiveMarks.toStringAsFixed(2),
            negativeMarks == 0
                ? context.l10n.resultsZeroLost
                : context.l10n.resultsMarksLost(
                    negativeMarks.toStringAsFixed(2),
                  ),
          );

    return _SummarySurfaceCard(
      scheme: scheme,
      isDark: isDark,
      child: Padding(
        padding: EdgeInsets.all(metrics.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.resultsNetMarks,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        net.toStringAsFixed(2),
                        style: AppTextStyles.h2().copyWith(
                          fontSize: metrics.scoreFontSize,
                          fontWeight: FontWeight.w900,
                          color: netColor,
                          height: 1.05,
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        marksBreakdown,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                _SemiCircularAccuracyGauge(
                  accuracy: result.accuracy,
                  correct: result.correct,
                  attempted: attempted,
                  accLabel: accLabel,
                  accColor: accColor,
                  scheme: scheme,
                  isDark: isDark,
                  metrics: metrics,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md * metrics.factor),
            _SessionAttemptBar(
              correct: result.correct,
              wrong: result.wrong,
              skipped: result.unattempted,
              total: result.questionCount,
              scheme: scheme,
              isDark: isDark,
              metrics: metrics,
            ),
            if (trend != null) ...[
              SizedBox(height: AppSpacing.sm * metrics.factor),
              trend,
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionAttemptBar extends StatelessWidget {
  const _SessionAttemptBar({
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.total,
    required this.scheme,
    required this.isDark,
    required this.metrics,
  });

  final int correct;
  final int wrong;
  final int skipped;
  final int total;
  final ColorScheme scheme;
  final bool isDark;
  final _SummaryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    final attempted = correct + wrong;
    final trackColor = isDark
        ? AppColors.gray600.withValues(alpha: 0.35)
        : AppColors.gray200;

    Widget segment({required int flex, required Color color}) {
      if (flex <= 0) return const SizedBox.shrink();
      return Expanded(
        flex: flex,
        child: Container(height: 8, color: color),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              context.l10n.resultsAllQuestions(total),
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              attempted == 0
                  ? context.l10n.resultsNoneAttempted
                  : context.l10n.resultsAttemptedSkipped(attempted, skipped),
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Row(
            children: [
              segment(flex: correct, color: AppColors.correct),
              segment(flex: wrong, color: AppColors.wrong),
              segment(flex: skipped, color: trackColor),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _AttemptLegendItem(
              color: AppColors.correct,
              label: context.l10n.resultsCountCorrect(correct),
            ),
            _AttemptLegendItem(
              color: AppColors.wrong,
              label: context.l10n.resultsCountWrong(wrong),
            ),
            _AttemptLegendItem(
              color: trackColor,
              label: context.l10n.resultsCountSkipped(skipped),
            ),
          ],
        ),
      ],
    );
  }
}

class _AttemptLegendItem extends StatelessWidget {
  const _AttemptLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption()),
      ],
    );
  }
}

class _SemiCircularAccuracyGauge extends StatelessWidget {
  const _SemiCircularAccuracyGauge({
    required this.accuracy,
    required this.correct,
    required this.attempted,
    required this.accLabel,
    required this.accColor,
    required this.scheme,
    required this.isDark,
    required this.metrics,
  });

  final double accuracy;
  final int correct;
  final int attempted;
  final String accLabel;
  final Color accColor;
  final ColorScheme scheme;
  final bool isDark;
  final _SummaryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final trackColor = isDark
        ? AppColors.gray600.withValues(alpha: 0.35)
        : AppColors.gray200;
    final progress = attempted == 0 ? 0.0 : (accuracy / 100).clamp(0.0, 1.0);
    final attemptedLabel = attempted == 0
        ? context.l10n.resultsNoAttemptsYet
        : context.l10n.resultsCorrectOfAttempted(correct, attempted);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          context.l10n.resultsAttemptAccuracy,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: (11 * metrics.factor).clamp(10.0, 11.0),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: metrics.gaugeWidth,
          height: metrics.gaugeHeight,
          child: CustomPaint(
            painter: _SemiArcPainter(
              progress: progress,
              progressColor: accColor,
              trackColor: trackColor,
              strokeWidth: metrics.gaugeStroke,
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  accLabel,
                  style: AppTextStyles.labelSm().copyWith(
                    fontWeight: FontWeight.w800,
                    color: accColor,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          attemptedLabel,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: (10 * metrics.factor).clamp(9.0, 10.0),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SemiArcPainter extends CustomPainter {
  _SemiArcPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final diameter = size.width - strokeWidth;
    final arcRect = Rect.fromLTWH(
      strokeWidth / 2,
      size.height - diameter / 2,
      diameter,
      diameter,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        startAngle,
        sweepAngle * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SemiArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor ||
      oldDelegate.trackColor != trackColor;
}

class _RevisionQueueCard extends StatelessWidget {
  const _RevisionQueueCard({
    required this.wrongInSession,
    required this.revisionAsync,
    required this.scheme,
    required this.isDark,
    required this.metrics,
  });

  final int wrongInSession;
  final AsyncValue<List<RevisionQueueItem>> revisionAsync;
  final ColorScheme scheme;
  final bool isDark;
  final _SummaryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final due = revisionAsync.maybeWhen(data: (l) => l.length, orElse: () => 0);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warningBgDark.withValues(alpha: 0.25)
            : AppColors.warningBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      padding: EdgeInsets.all(metrics.cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: metrics.revisionIconSize,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wrongInSession > 0)
                  Text(
                    context.l10n.resultsAddedToQueue(wrongInSession),
                    style: AppTextStyles.labelSm().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    context.l10n.resultsNoneAddedToQueue,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (due > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.resultsTotalInQueue(due),
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.coachTrendEmerald,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.summaryCtaBlue,
              side: const BorderSide(color: AppColors.summaryCtaBlue),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              logGlobalAnalytics(
                const UspSessionCoachCtaTappedEvent(
                  action: 'results_revision_queue_nudge_tap',
                ),
              );
              logGlobalAnalytics(
                const RevisionRecommendationClickedEvent(
                  source: 'results_revision_queue_nudge',
                ),
              );
              context.push('/revision-queue');
            },
            child: Text(
              context.l10n.resultsGoToQueue,
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySurfaceCard extends StatelessWidget {
  const _SummarySurfaceCard({
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: child,
    );
  }
}

class _TopTopicsSection extends StatelessWidget {
  const _TopTopicsSection({
    super.key,
    required this.bestTopics,
    required this.worstTopics,
    required this.bestExpanded,
    required this.worstExpanded,
    required this.onToggleBest,
    required this.onToggleWorst,
    required this.scheme,
    this.defaultVisibleCount = 3,
  });

  final List<({String topic, int correct, int attempted})> bestTopics;
  final List<({String topic, int correct, int attempted})> worstTopics;
  final bool bestExpanded;
  final bool worstExpanded;
  final VoidCallback onToggleBest;
  final VoidCallback onToggleWorst;
  final ColorScheme scheme;
  final int defaultVisibleCount;

  @override
  Widget build(BuildContext context) {
    if (bestTopics.isEmpty && worstTopics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (worstTopics.isNotEmpty) ...[
          _TopicAccuracyList(
            title: context.l10n.resultsWorstTopics,
            topics: worstTopics,
            expanded: worstExpanded,
            onToggle: onToggleWorst,
            scheme: scheme,
            defaultVisibleCount: defaultVisibleCount,
            showInaccuracy: true,
          ),
          if (bestTopics.isNotEmpty) const SizedBox(height: AppSpacing.md),
        ],
        if (bestTopics.isNotEmpty)
          _TopicAccuracyList(
            title: context.l10n.resultsBestTopics,
            topics: bestTopics,
            expanded: bestExpanded,
            onToggle: onToggleBest,
            scheme: scheme,
            defaultVisibleCount: defaultVisibleCount,
          ),
      ],
    );
  }
}

class _TopicAccuracyList extends StatelessWidget {
  const _TopicAccuracyList({
    required this.title,
    required this.topics,
    required this.expanded,
    required this.onToggle,
    required this.scheme,
    required this.defaultVisibleCount,
    this.showInaccuracy = false,
  });

  final String title;
  final List<({String topic, int correct, int attempted})> topics;
  final bool expanded;
  final VoidCallback onToggle;
  final ColorScheme scheme;
  final int defaultVisibleCount;
  final bool showInaccuracy;

  @override
  Widget build(BuildContext context) {
    final visible = expanded
        ? topics
        : topics.take(defaultVisibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              title,
              style: AppTextStyles.labelSm().copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            if (topics.length > defaultVisibleCount)
              TextButton(
                onPressed: onToggle,
                child: Text(
                  expanded
                      ? context.l10n.commonShowLess
                      : context.l10n.commonViewAll,
                ),
              ),
          ],
        ),
        ...visible.map((row) {
          final accuracyPct = topicRowAccuracyPercent(row);
          final wrongCount = row.attempted - row.correct;
          final barFill = showInaccuracy
              ? (wrongCount / row.attempted).clamp(0.0, 1.0)
              : (accuracyPct / 100).clamp(0.0, 1.0);
          final barColor = showInaccuracy
              ? AppColors.wrong
              : (accuracyPct >= 50 ? AppColors.correct : AppColors.wrong);
          final statLabel = showInaccuracy
              ? context.l10n.resultsPctWrong(
                  (100 - accuracyPct).round(),
                  wrongCount,
                  row.attempted,
                )
              : '${accuracyPct.round()}% (${row.correct}/${row.attempted})';
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizedTopicName(
                    row.topic,
                    language: Localizations.localeOf(context).languageCode,
                  ),
                  style: AppTextStyles.caption(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: barFill,
                          minHeight: 6,
                          color: barColor,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      statLabel,
                      style: AppTextStyles.caption().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _BackToHomeButton extends ConsumerWidget {
  const _BackToHomeButton({
    required this.sessionId,
    required this.scheme,
    this.analyticsFeatureKey,
  });

  final String sessionId;
  final ColorScheme scheme;
  final String? analyticsFeatureKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returnToCaller =
        isInsightImproveFeature(analyticsFeatureKey) && context.canPop();
    return TextButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        logGlobalAnalytics(
          const UspSessionCoachCtaTappedEvent(action: 'back_to_home'),
        );
        ScreenFlow.logAction(
          ref,
          screenName: ScreenFlow.sessionResults,
          actionId: returnToCaller ? 'back_to_caller_cta' : 'back_to_home_cta',
          actionKind: 'back',
        );
        clearDemoDiagnosticEphemeral(sessionId);
        if (returnToCaller) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Text(
        returnToCaller
            ? context.l10n.commonDone
            : context.l10n.resultsBackToHome,
        style: AppTextStyles.label().copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ReviewAllButton extends StatelessWidget {
  const _ReviewAllButton({
    required this.sessionId,
    required this.questionCount,
    required this.metrics,
    this.highlightKey,
    this.analyticsFeatureKey,
  });

  final String sessionId;
  final int questionCount;
  final _SummaryLayoutMetrics metrics;
  final GlobalKey? highlightKey;
  final String? analyticsFeatureKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: highlightKey,
      height: metrics.buttonHeight,
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.summaryCtaBlue,
          side: const BorderSide(color: AppColors.summaryCtaBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          logGlobalAnalytics(
            const UspSessionCoachCtaTappedEvent(action: 'review_all'),
          );
          _openSessionHistoryReview(
            context,
            sessionId,
            analyticsFeatureKey: analyticsFeatureKey,
          );
        },
        icon: Icon(Icons.menu_book_outlined, size: 20 * metrics.factor),
        label: Text(
          context.l10n.resultsReviewAll(questionCount),
          style: AppTextStyles.label().copyWith(
            fontWeight: FontWeight.w700,
            fontSize: (14 * metrics.factor).clamp(12.0, 14.0),
          ),
        ),
      ),
    );
  }
}

class _MoreInsightsTile extends StatelessWidget {
  const _MoreInsightsTile({
    required this.expanded,
    required this.onToggle,
    required this.scheme,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Text(
              context.l10n.resultsMoreInsights,
              style: AppTextStyles.labelSm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: scheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeInline extends StatelessWidget {
  const _TimeInline({required this.timeAsync, required this.scheme});

  final AsyncValue<({int avgSecs, int minSecs, int maxSecs})> timeAsync;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return timeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (t) => Text(
        context.l10n.resultsTimingLine(t.avgSecs, t.minSecs, t.maxSecs),
        style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
