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
import 'confidence_insights_section.dart';
import 'session_insight_hero_card.dart';

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
    final topicsExpanded = useState(maxHeight >= 700);
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

    final topicDisplay = topicRowsAsync.maybeWhen(
      data: (rows) => topTopicsForDisplay(marksRows, rows),
      orElse: () => marksRows.take(3).toList(),
    );

    final bottomSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ReviewAllButton(
          sessionId: sessionId,
          questionCount: result.questionCount,
        ),
        const SizedBox(height: AppSpacing.sm),
        _MoreInsightsTile(
          expanded: moreExpanded.value,
          onToggle: () => moreExpanded.value = !moreExpanded.value,
          scheme: scheme,
        ),
        if (moreExpanded.value) ...[
          const SizedBox(height: AppSpacing.sm),
          if (ConfidenceInsightsSection.shouldShow(result))
            ConfidenceInsightsSection(
              sessionId: sessionId,
              result: result,
            ),
          const SizedBox(height: AppSpacing.sm),
          _TimeInline(timeAsync: timeAsync, scheme: scheme),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompactScoreRow(
          result: result,
          displaySubjectName: displaySubjectName,
          scheme: scheme,
          isDark: isDark,
          historyAsync: historyAsync,
          canScope: _canSubjectScope,
          compact: maxHeight < 640,
        ),
        const SizedBox(height: AppSpacing.sm),
        insightCaseAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (insightCase) => SessionInsightHeroCard(
            sessionId: sessionId,
            result: result,
            insightCase: insightCase,
            topRiskTopic: topRisk?.topic,
            topRiskPct: topRisk?.pctOfLoss,
            weakestTopicName: weak?.topic,
            compact: maxHeight < 640,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickStatsRow(
          result: result,
          scheme: scheme,
          isDark: isDark,
          timeAsync: timeAsync,
        ),
        const SizedBox(height: AppSpacing.sm),
        _RevisionQueueCard(
          wrongInSession: result.wrong,
          revisionAsync: revisionAsync,
          scheme: scheme,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _TopTopicsSection(
          topics: topicDisplay,
          accuracyRows: topicRowsAsync.asData?.value ?? const [],
          expanded: topicsExpanded.value,
          onToggle: () => topicsExpanded.value = !topicsExpanded.value,
          scheme: scheme,
        ),
        if (moreExpanded.value)
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: bottomSection,
            ),
          )
        else ...[
          const Spacer(),
          bottomSection,
        ],
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
    required this.compact,
  });

  final SessionResult result;
  final String displaySubjectName;
  final ColorScheme scheme;
  final bool isDark;
  final AsyncValue<SessionCoachHistory> historyAsync;
  final bool canScope;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final net = result.netScore;
    final netColor = net >= 0 ? AppColors.coachTrendEmerald : AppColors.wrong;
    final attempted = result.correct + result.wrong;
    final accLabel = attempted == 0 ? '—' : '${result.accuracy.round()}%';

    Widget? trend;
    if (!compact && canScope) {
      trend = historyAsync.when(
        data: (h) {
          if (h.vsImmediatePrevious == null) return null;
          final d = h.vsImmediatePrevious!;
          final rounded = d.round();
          final sign = rounded > 0 ? '+' : '';
          return Text(
            '$sign$rounded% vs your last test',
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          );
        },
        loading: () => null,
        error: (_, _) => null,
      );
    }

    final positiveMarks = result.correct * 2.0;
    final negativeMarks = result.wrong * 0.66;
    final accColor = attempted == 0
        ? scheme.onSurfaceVariant
        : result.accuracy >= 50
        ? AppColors.coachTrendEmerald
        : AppColors.wrong;

    return _SummarySurfaceCard(
      scheme: scheme,
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Score',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        net.toStringAsFixed(2),
                        style: AppTextStyles.h2().copyWith(
                          fontSize: compact ? 28 : 32,
                          fontWeight: FontWeight.w900,
                          color: netColor,
                          height: 1.05,
                          fontFeatures: const [
                            ui.FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      Text(
                        '${result.correct} / ${result.questionCount} correct',
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (trend != null) ...[
                        const SizedBox(height: 2),
                        trend,
                      ],
                    ],
                  ),
                ),
                _SemiCircularAccuracyGauge(
                  accuracy: result.accuracy,
                  attempted: attempted,
                  accLabel: accLabel,
                  accColor: accColor,
                  positiveMarks: positiveMarks,
                  negativeMarks: negativeMarks,
                  scheme: scheme,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SemiCircularAccuracyGauge extends StatelessWidget {
  const _SemiCircularAccuracyGauge({
    required this.accuracy,
    required this.attempted,
    required this.accLabel,
    required this.accColor,
    required this.positiveMarks,
    required this.negativeMarks,
    required this.scheme,
    required this.isDark,
  });

  final double accuracy;
  final int attempted;
  final String accLabel;
  final Color accColor;
  final double positiveMarks;
  final double negativeMarks;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final trackColor = isDark
        ? AppColors.gray600.withValues(alpha: 0.35)
        : AppColors.gray200;
    final progress = attempted == 0 ? 0.0 : (accuracy / 100).clamp(0.0, 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 54,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              'Accuracy',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 54,
              child: CustomPaint(
                painter: _SemiArcPainter(
                  progress: progress,
                  progressColor: accColor,
                  trackColor: trackColor,
                  strokeWidth: 7,
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
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                style: AppTextStyles.caption().copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(
                    text: '(+${positiveMarks.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.coachTrendEmerald),
                  ),
                  const TextSpan(
                    text: ' / ',
                    style: TextStyle(color: AppColors.gray400),
                  ),
                  TextSpan(
                    text: negativeMarks == 0
                        ? '0)'
                        : '−${negativeMarks.toStringAsFixed(2)})',
                    style: const TextStyle(color: AppColors.wrong),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
    required this.timeAsync,
  });

  final SessionResult result;
  final ColorScheme scheme;
  final bool isDark;
  final AsyncValue<({int avgSecs, int minSecs, int maxSecs})> timeAsync;

  @override
  Widget build(BuildContext context) {
    final surePct = result.confidenceSureTotal == 0
        ? '—'
        : '${(100 * result.confidenceSureCorrect / result.confidenceSureTotal).round()}%';
    final eduPct = result.confidenceIntelligentTotal == 0
        ? '—'
        : '${(100 * result.confidenceIntelligentCorrect / result.confidenceIntelligentTotal).round()}%';
    final avgTime = result.avgTimeSpentSecs?.round() ?? 0;
    final timeSub = timeAsync.maybeWhen(
      data: (t) => 'Fastest ${t.minSecs}s / Slowest ${t.maxSecs}s',
      orElse: () => null,
    );
    final dividerColor = isDark
        ? AppColors.borderDark
        : AppColors.borderLight;

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
                    label: 'Confident',
                    value: surePct,
                    sub: result.confidenceSureTotal > 0
                        ? '(${result.confidenceSureCorrect} / ${result.confidenceSureTotal})'
                        : null,
                    scheme: scheme,
                    icon: Icons.check_circle_outline,
                    color: AppColors.correct,
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                Expanded(
                  child: _StatTile(
                    label: 'Educated Guess',
                    value: eduPct,
                    sub: result.confidenceIntelligentTotal > 0
                        ? '(${result.confidenceIntelligentCorrect} / ${result.confidenceIntelligentTotal})'
                        : null,
                    scheme: scheme,
                    icon: Icons.help_outline,
                    color: AppColors.warning,
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                Expanded(
                  child: _StatTile(
                    label: 'Avg. Time / Q',
                    value: '${avgTime}s',
                    sub: timeSub,
                    scheme: scheme,
                    icon: Icons.schedule_outlined,
                    color: AppColors.info,
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: dividerColor),
                Expanded(
                  child: _StatTile(
                    label: 'Questions',
                    value: '${result.questionCount}',
                    sub: 'Completed',
                    scheme: scheme,
                    icon: Icons.emoji_events_outlined,
                    color: AppColors.primary,
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
  });

  final String label;
  final String value;
  final String? sub;
  final ColorScheme scheme;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelSm().copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 1),
            Text(
              sub!,
              style: AppTextStyles.caption().copyWith(
                fontSize: 8,
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption().copyWith(
              fontSize: 9,
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
  });

  final int wrongInSession;
  final AsyncValue<List<RevisionQueueItem>> revisionAsync;
  final ColorScheme scheme;
  final bool isDark;

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
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 28,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wrongInSession > 0)
                  Text(
                    '+ $wrongInSession question${wrongInSession == 1 ? '' : 's'} '
                    'from this test added (incorrect)',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.coachTrendEmerald,
                      fontWeight: FontWeight.w600,
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
                    '$due question${due == 1 ? '' : 's'} in your queue',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.summaryOrange,
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
              'Go to Queue',
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
    required this.topics,
    required this.accuracyRows,
    required this.expanded,
    required this.onToggle,
    required this.scheme,
  });

  final List<TopicMarksLost> topics;
  final List<({String topic, int correct, int attempted})> accuracyRows;
  final bool expanded;
  final VoidCallback onToggle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (topics.isEmpty) return const SizedBox.shrink();

    final visible = expanded ? topics : topics.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Top topics (this test)',
              style: AppTextStyles.labelSm().copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            if (topics.length > 3)
              TextButton(
                onPressed: onToggle,
                child: Text(expanded ? 'Show less' : 'View all'),
              ),
          ],
        ),
        ...visible.map((t) {
          final pct = topicAccuracyPercent(accuracyRows, t.topic);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    t.topic,
                    style: AppTextStyles.caption(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: pct >= 50 ? AppColors.correct : AppColors.wrong,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${pct.round()}%',
                  style: AppTextStyles.caption().copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
  });

  final String sessionId;
  final int questionCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
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
        icon: const Icon(Icons.menu_book_outlined, size: 20),
        label: Text(
          'Review all questions ($questionCount)',
          style: AppTextStyles.label().copyWith(fontWeight: FontWeight.w700),
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
        style: AppTextStyles.caption().copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
