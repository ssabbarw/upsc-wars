import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_global_dispatch.dart';
import '../../../core/domain/entities/revision_queue_item.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/session_insight_case.dart';
import '../domain/session_insight_metrics.dart';
import '../providers/session_coach_providers.dart';
import '../providers/session_topic_accuracy_provider.dart';
import 'session_insight_hero_card.dart';

void _openSessionHistoryReview(
  BuildContext context,
  String sessionId, {
  bool focusWrong = false,
}) {
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
          ),
        ),
        SizedBox(height: metrics.sectionGap),
        _QuickStatsRow(
          result: result,
          scheme: scheme,
          isDark: isDark,
          metrics: metrics,
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
        _ReviewAllButton(
          sessionId: sessionId,
          questionCount: result.questionCount,
          metrics: metrics,
        ),
        SizedBox(height: metrics.sectionGap),
        _TopTopicsSection(
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
            '$sign$rounded% accuracy vs your last test',
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
        ? 'Attempt questions to earn marks'
        : '+${positiveMarks.toStringAsFixed(2)} earned · '
              '${negativeMarks == 0 ? '0 lost' : '−${negativeMarks.toStringAsFixed(2)} lost'}';

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
                        'Net marks',
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
              'All $total questions',
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              attempted == 0
                  ? 'None attempted'
                  : '$attempted attempted · $skipped skipped',
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
              label: '$correct correct',
            ),
            _AttemptLegendItem(color: AppColors.wrong, label: '$wrong wrong'),
            _AttemptLegendItem(color: trackColor, label: '$skipped skipped'),
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
        ? 'No attempts yet'
        : '$correct of $attempted correct';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Attempt accuracy',
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

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.result,
    required this.scheme,
    required this.isDark,
    required this.metrics,
  });

  final SessionResult result;
  final ColorScheme scheme;
  final bool isDark;
  final _SummaryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final surePct = result.confidenceSureTotal == 0
        ? '—'
        : '${(100 * result.confidenceSureCorrect / result.confidenceSureTotal).round()}%';
    final eduPct = result.confidenceIntelligentTotal == 0
        ? '—'
        : '${(100 * result.confidenceIntelligentCorrect / result.confidenceIntelligentTotal).round()}%';
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quick Stats',
          style: AppTextStyles.labelSm().copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _SummarySurfaceCard(
          scheme: scheme,
          isDark: isDark,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Sure accuracy',
                    value: surePct,
                    sub: result.confidenceSureTotal > 0
                        ? '(${result.confidenceSureCorrect} / ${result.confidenceSureTotal})'
                        : null,
                    scheme: scheme,
                    icon: Icons.check_circle_outline,
                    color: AppColors.correct,
                    metrics: metrics,
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                Expanded(
                  child: _StatTile(
                    label: 'Educated guess accuracy',
                    value: eduPct,
                    sub: result.confidenceIntelligentTotal > 0
                        ? '(${result.confidenceIntelligentCorrect} / ${result.confidenceIntelligentTotal})'
                        : null,
                    scheme: scheme,
                    icon: Icons.help_outline,
                    color: AppColors.warning,
                    metrics: metrics,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.scheme,
    required this.icon,
    required this.color,
    required this.metrics,
  });

  final String label;
  final String value;
  final String? sub;
  final ColorScheme scheme;
  final IconData icon;
  final Color color;
  final _SummaryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xs * metrics.factor,
        vertical: AppSpacing.sm * metrics.factor,
      ),
      child: Column(
        children: [
          Icon(icon, size: metrics.statIconSize, color: color),
          SizedBox(height: 2 * metrics.factor),
          Text(
            value,
            style: AppTextStyles.labelSm().copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              fontSize: (13 * metrics.factor).clamp(11.0, 13.0),
            ),
          ),
          if (sub != null) ...[
            SizedBox(height: 1 * metrics.factor),
            Text(
              sub!,
              style: AppTextStyles.caption().copyWith(
                fontSize: metrics.statSubFontSize,
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
          SizedBox(height: 2 * metrics.factor),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontSize: metrics.statLabelFontSize,
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
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
                    '$wrongInSession question${wrongInSession == 1 ? '' : 's'} '
                    'added to revision queue',
                    style: AppTextStyles.labelSm().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    'No incorrect answers added from this test.',
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (due > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$due total in queue',
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
              'Go to queue',
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
        if (bestTopics.isNotEmpty) ...[
          _TopicAccuracyList(
            title: 'Top topic accuracy',
            topics: bestTopics,
            expanded: bestExpanded,
            onToggle: onToggleBest,
            scheme: scheme,
            defaultVisibleCount: defaultVisibleCount,
          ),
          if (worstTopics.isNotEmpty) const SizedBox(height: AppSpacing.md),
        ],
        if (worstTopics.isNotEmpty)
          _TopicAccuracyList(
            title: 'Most inaccurate topics',
            topics: worstTopics,
            expanded: worstExpanded,
            onToggle: onToggleWorst,
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
  });

  final String title;
  final List<({String topic, int correct, int attempted})> topics;
  final bool expanded;
  final VoidCallback onToggle;
  final ColorScheme scheme;
  final int defaultVisibleCount;

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
                child: Text(expanded ? 'Show less' : 'View all'),
              ),
          ],
        ),
        ...visible.map((row) {
          final pct = topicRowAccuracyPercent(row);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  row.topic,
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
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 6,
                          color: pct >= 50
                              ? AppColors.correct
                              : AppColors.wrong,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${pct.round()}% (${row.correct}/${row.attempted})',
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

class _ReviewAllButton extends StatelessWidget {
  const _ReviewAllButton({
    required this.sessionId,
    required this.questionCount,
    required this.metrics,
  });

  final String sessionId;
  final int questionCount;
  final _SummaryLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
          _openSessionHistoryReview(context, sessionId);
        },
        icon: Icon(Icons.menu_book_outlined, size: 20 * metrics.factor),
        label: Text(
          'Review all questions ($questionCount)',
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
              'More insights',
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
        'Avg ${t.avgSecs}s per question · '
        'Fastest ${t.minSecs}s · Slowest ${t.maxSecs}s',
        style: AppTextStyles.caption().copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
