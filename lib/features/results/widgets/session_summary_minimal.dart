import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/prelims_countdown.dart';
import '../../../core/constants/prelims_motivation_quotes.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/top_snack_bar.dart';
import '../providers/subject_accuracy_trend_provider.dart';

/// Minimalist post-session summary (scroll content only).
class SessionSummaryMinimalContent extends HookConsumerWidget {
  const SessionSummaryMinimalContent({
    super.key,
    required this.sessionId,
    required this.result,
    required this.displaySubjectName,
  });

  final String sessionId;
  final SessionResult result;
  final String displaySubjectName;

  String get _insightsTitle =>
      (result.topic != null && result.topic!.isNotEmpty)
      ? result.topic!
      : displaySubjectName;

  bool get _canSubjectNav =>
      result.subject.isNotEmpty && result.subject != 'revision_quick';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.sizeOf(context);
    final wide = mq.width >= 600;

    final attempted = result.correct + result.wrong;
    final skipped = result.unattempted + result.timedOut;
    final qc = result.questionCount;

    final backLabel = !_canSubjectNav
        ? 'Home'
        : (result.topic != null && result.topic!.isNotEmpty)
        ? 'Back to ${result.topic}'
        : 'Back to $displaySubjectName';

    void onBack() {
      if (!_canSubjectNav) {
        context.go('/');
        return;
      }
      if (result.topic != null && result.topic!.isNotEmpty) {
        context.go('/subject/${Uri.encodeComponent(result.subject)}/topics');
      } else {
        context.go('/subject/${Uri.encodeComponent(result.subject)}');
      }
    }

    final rangeDays = useState(14);
    final trendArg = (
      subject: result.subject,
      topic: result.topic,
      rangeDays: rangeDays.value,
    );
    final trendAsync = _canSubjectNav
        ? ref.watch(subjectAccuracyTrendProvider(trendArg))
        : AsyncValue<List<({DateTime day, double accuracyPct})>>.data(
            const <({DateTime day, double accuracyPct})>[],
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final avail = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mq.width;
        final targetMain = wide ? 150.0 : 120.0;
        final targetConf = wide ? 96.0 : 80.0;
        final pieMain = math.min(
          targetMain,
          math.max(72.0, (avail - 16) / 2 - 8),
        );
        final pieConf = math.min(targetConf, math.max(48.0, (avail - 48) / 2));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PrelimsCountdownCard(isDark: isDark),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.summaryCtaBlue,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/history/$sessionId');
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Review Questions',
                    style: AppTextStyles.label().copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.summaryButtonText,
                  side: const BorderSide(color: AppColors.summaryButtonBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onBack();
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: isDark
                              ? scheme.onSurface
                              : AppColors.summaryButtonText,
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.max(120.0, avail - 72),
                          ),
                          child: Text(
                            backLabel,
                            style: AppTextStyles.label().copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? scheme.onSurface
                                  : AppColors.summaryButtonText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _FullBleedDivider(scheme: scheme),
            const SizedBox(height: 16),
            _SectionTitle(text: 'Your Test Result', scheme: scheme),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PieColumn(
                    size: pieMain,
                    lines: _pie1Labels(
                      qc: qc,
                      attempted: attempted,
                      skipped: skipped,
                    ),
                    scheme: scheme,
                    child: CustomPaint(
                      size: Size(pieMain, pieMain),
                      painter: _TwoSlicePiePainter(
                        aColor: AppColors.summaryChartBlue,
                        bColor: AppColors.gray200,
                        aFraction: qc == 0 ? 0 : attempted / qc,
                        bFraction: qc == 0 ? 0 : skipped / qc,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PieColumn(
                    size: pieMain,
                    lines: attempted == 0
                        ? ['No attempts', 'You didn\'t attempt any questions']
                        : ['${result.correct} correct, ${result.wrong} incorrect'],
                    scheme: scheme,
                    child: attempted == 0
                        ? SizedBox(
                            width: pieMain,
                            height: pieMain,
                            child: Center(
                              child: Text(
                                '—',
                                style: AppTextStyles.h2().copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : CustomPaint(
                            size: Size(pieMain, pieMain),
                            painter: _TwoSlicePiePainter(
                              aColor: AppColors.correct,
                              bColor: AppColors.wrong,
                              aFraction: result.correct / attempted,
                              bFraction: result.wrong / attempted,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            if (attempted == 0)
              Text(
                'You didn\'t attempt any questions',
                textAlign: TextAlign.center,
                softWrap: true,
                style: AppTextStyles.bodyMd().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else ...[
              Text(
                'You were ${result.accuracy.toStringAsFixed(0)}% accurate',
                textAlign: TextAlign.center,
                softWrap: true,
                style: AppTextStyles.bodyMd().copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _accuracyTrafficColor(result.accuracy),
                ),
              ),
              if (result.wrong == 0) ...[
                const SizedBox(height: 8),
                Text(
                  '🎉 Perfect score! Well done!',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: AppTextStyles.bodySm().copyWith(
                    color: AppColors.correct,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            _FullBleedDivider(scheme: scheme),
            if (attempted > 0) ...[
              const SizedBox(height: 16),
              _SectionTitle(text: 'Confidence Analysis', scheme: scheme),
              const SizedBox(height: 16),
              ..._confidenceRows(
                result: result,
                pieConf: pieConf,
                scheme: scheme,
              ),
            ],
            const SizedBox(height: 16),
            _FullBleedDivider(scheme: scheme),
            const SizedBox(height: 16),
            _SectionTitle(text: 'Insights: $_insightsTitle', scheme: scheme),
            const SizedBox(height: 12),
            ..._insightBullets(result, displaySubjectName, scheme),
            const SizedBox(height: 16),
            Divider(color: scheme.outlineVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              'Progress in $_insightsTitle',
              softWrap: true,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (_canSubjectNav)
              _ProgressBlock(
                scheme: scheme,
                rangeDays: rangeDays.value,
                onRangeDaysChanged: (v) => rangeDays.value = v,
                trendAsync: trendAsync,
              )
            else
              Text(
                'Progress charts are available for subject practice sessions.',
                softWrap: true,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.summaryCtaBlue,
                  side: const BorderSide(color: AppColors.summaryCtaBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await _startRetryWrongSession(context, ref, sessionId);
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Retry Wrong Answers',
                    style: AppTextStyles.label().copyWith(
                      color: AppColors.summaryCtaBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

List<String> _pie1Labels({
  required int qc,
  required int attempted,
  required int skipped,
}) {
  if (qc == 0) return ['0 questions', ''];
  if (skipped == 0) {
    return ['$qc questions', 'All attempted'];
  }
  if (attempted == 0) {
    return ['$qc questions', 'All skipped'];
  }
  return ['$qc questions', '$attempted attempted, $skipped skipped'];
}

Color _accuracyTrafficColor(double accuracyPct) {
  if (accuracyPct >= 75) return AppColors.correct;
  if (accuracyPct >= 50) return AppColors.warning;
  return AppColors.wrong;
}

List<Widget> _confidenceRows({
  required SessionResult result,
  required double pieConf,
  required ColorScheme scheme,
}) {
  final rows = <Widget>[];

  void addRow(Widget w) {
    if (rows.isNotEmpty) {
      rows.add(const SizedBox(height: 24));
    }
    rows.add(w);
  }

  if (result.confidenceSureTotal > 0) {
    addRow(
      _ConfidenceRow(
        label: 'Confident (${result.confidenceSureTotal} questions)',
        labelColor: AppColors.primaryDeep,
        count: result.confidenceSureTotal,
        correct: result.confidenceSureCorrect,
        wrong: result.confidenceSureTotal - result.confidenceSureCorrect,
        leftColor: AppColors.primaryDeep,
        pieSize: pieConf,
        scheme: scheme,
        trailingIfWrong:
            (result.confidenceSureTotal - result.confidenceSureCorrect) > 0
            ? '⚠️'
            : null,
        lucky: false,
      ),
    );
  }
  if (result.confidenceIntelligentTotal > 0) {
    addRow(
      _ConfidenceRow(
        label:
            'Intelligent Guess (${result.confidenceIntelligentTotal} questions)',
        labelColor: AppColors.summaryOrange,
        count: result.confidenceIntelligentTotal,
        correct: result.confidenceIntelligentCorrect,
        wrong:
            result.confidenceIntelligentTotal -
            result.confidenceIntelligentCorrect,
        leftColor: AppColors.summaryOrange,
        pieSize: pieConf,
        scheme: scheme,
        trailingIfWrong: null,
        lucky: false,
      ),
    );
  }
  if (result.confidencePureTotal > 0) {
    final pureW = result.confidencePureTotal - result.confidencePureCorrect;
    addRow(
      _ConfidenceRow(
        label: 'Pure Guess (${result.confidencePureTotal} questions)',
        labelColor: AppColors.gray600,
        count: result.confidencePureTotal,
        correct: result.confidencePureCorrect,
        wrong: pureW,
        leftColor: AppColors.gray600,
        pieSize: pieConf,
        scheme: scheme,
        trailingIfWrong: null,
        lucky: result.confidencePureCorrect > pureW,
      ),
    );
  }
  return rows;
}

List<Widget> _insightBullets(
  SessionResult r,
  String displaySubjectName,
  ColorScheme scheme,
) {
  final lines = <String>[];
  final sureT = r.confidenceSureTotal;
  final sureW = sureT - r.confidenceSureCorrect;
  if (sureT > 0 && sureW / sureT > 0.25) {
    final scope = (r.topic != null && r.topic!.isNotEmpty)
        ? 'in ${r.topic}'
        : 'in $displaySubjectName';
    lines.add(
      '⚠️  You\'re marking questions incorrectly with high confidence $scope.',
    );
  }
  if (lines.isEmpty) {
    lines.add('✅ Keep practicing consistently!');
  }
  return lines
      .map(
        (t) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            t,
            softWrap: true,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.35,
            ),
          ),
        ),
      )
      .toList();
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.scheme,
    required this.rangeDays,
    required this.onRangeDaysChanged,
    required this.trendAsync,
  });

  final ColorScheme scheme;
  final int rangeDays;
  final ValueChanged<int> onRangeDaysChanged;
  final AsyncValue<List<({DateTime day, double accuracyPct})>> trendAsync;

  static const _ranges = <(int, String)>[
    (14, '2 Weeks'),
    (30, '1 Month'),
    (60, '2 Months'),
    (90, '3 Months'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: rangeDays,
              items: _ranges
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.$1,
                      child: Text(e.$2, style: AppTextStyles.bodySm()),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onRangeDaysChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: trendAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Text(
                'Could not load progress',
                style: AppTextStyles.bodySm().copyWith(color: scheme.error),
              ),
            ),
            data: (points) {
              if (points.isEmpty) {
                return Center(
                  child: Text(
                    'No data yet\nComplete more tests to see your progress',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                );
              }
              return CustomPaint(
                painter: _AccuracyLineChartPainter(
                  points: points,
                  lineColor: AppColors.summaryCtaBlue,
                  gridColor: scheme.outlineVariant.withValues(alpha: 0.4),
                  labelColor: scheme.onSurfaceVariant,
                ),
                child: points.length == 1
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Complete more tests to see trend',
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PrelimsCountdownCard extends HookWidget {
  const _PrelimsCountdownCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tick = useState(0);
    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        tick.value++;
      });
      return t.cancel;
    }, const []);

    final now = DateTime.now();
    final diff = PrelimsCountdown.remaining(now: now);
    final days = diff.inDays;
    final h = diff.inHours.remainder(24);
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);
    String two(int v) => v.toString().padLeft(2, '0');
    final timerText = '$days:${two(h)}:${two(m)}:${two(s)}';
    final quote = PrelimsMotivationQuotes.quoteForDate(now);
    final year = PrelimsCountdown.prelimsDate.year;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.infoBgDark.withValues(alpha: 0.5),
                  AppColors.surfaceSecondaryDark,
                ]
              : [
                  AppColors.infoBg.withValues(alpha: 0.55),
                  AppColors.primaryLight.withValues(alpha: 0.35),
                ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Hello Aspirant! 👋',
            style: AppTextStyles.bodyMd().copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'UPSC Prelims $year',
            style: AppTextStyles.label().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                timerText,
                style: GoogleFonts.robotoMono(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                  height: 1.1,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                'DAYS   HRS   MIN   SEC',
                style: AppTextStyles.caption().copyWith(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '"$quote"',
            textAlign: TextAlign.center,
            softWrap: true,
            style: AppTextStyles.bodySm().copyWith(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullBleedDivider extends StatelessWidget {
  const _FullBleedDivider({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: scheme.outlineVariant.withValues(alpha: 0.55),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, required this.scheme});

  final String text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      softWrap: true,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.label().copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
    );
  }
}

class _PieColumn extends StatelessWidget {
  const _PieColumn({
    required this.size,
    required this.lines,
    required this.scheme,
    required this.child,
  });

  final double size;
  final List<String> lines;
  final ColorScheme scheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(width: size, height: size, child: child),
        ),
        const SizedBox(height: 8),
        Text(
          lines.isNotEmpty ? lines.first : '',
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption().copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (lines.length > 1 && lines[1].isNotEmpty)
          Text(
            lines[1],
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption().copyWith(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ConfidenceRow extends StatelessWidget {
  const _ConfidenceRow({
    required this.label,
    required this.labelColor,
    required this.count,
    required this.correct,
    required this.wrong,
    required this.leftColor,
    required this.pieSize,
    required this.scheme,
    required this.trailingIfWrong,
    required this.lucky,
  });

  final String label;
  final Color labelColor;
  final int count;
  final int correct;
  final int wrong;
  final Color leftColor;
  final double pieSize;
  final ColorScheme scheme;
  final String? trailingIfWrong;
  final bool lucky;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowW = constraints.maxWidth;
        final pie = math.min(pieSize, math.max(40.0, (rowW - 44) / 2));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: pie,
                  height: pie,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(pie, pie),
                        painter: _SolidPiePainter(color: leftColor),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$count',
                          style: AppTextStyles.h2().copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: pie * 0.28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '→',
                  style: AppTextStyles.h2().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: pie,
                  height: pie,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(pie, pie),
                        painter: _TwoSlicePiePainter(
                          aColor: AppColors.correct,
                          bColor: AppColors.wrong,
                          aFraction: count == 0 ? 0 : correct / count,
                          bFraction: count == 0 ? 0 : wrong / count,
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$correct/$wrong',
                          style: GoogleFonts.robotoMono(
                            fontSize: pie * 0.18,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: AppTextStyles.bodySm().copyWith(color: scheme.onSurface),
                children: [
                  TextSpan(text: '$correct right, $wrong wrong'),
                  if (trailingIfWrong != null)
                    TextSpan(text: ' $trailingIfWrong'),
                  if (lucky) const TextSpan(text: ' 🍀'),
                ],
              ),
              softWrap: true,
            ),
          ],
        );
      },
    );
  }
}

class _TwoSlicePiePainter extends CustomPainter {
  _TwoSlicePiePainter({
    required this.aColor,
    required this.bColor,
    required this.aFraction,
    required this.bFraction,
  });

  final Color aColor;
  final Color bColor;
  final double aFraction;
  final double bFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 1;
    final rect = Rect.fromCircle(center: c, radius: r);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = bColor.withValues(alpha: 0.35);

    final af = aFraction.clamp(0.0, 1.0);
    final bf = bFraction.clamp(0.0, 1.0);
    var start = -math.pi / 2;
    if (af > 0) {
      final sweep = 2 * math.pi * af;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = aColor);
      start += sweep;
    }
    if (bf > 0) {
      final sweep = 2 * math.pi * bf;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = bColor);
    }
    canvas.drawCircle(c, r, stroke);
  }

  @override
  bool shouldRepaint(covariant _TwoSlicePiePainter oldDelegate) {
    return oldDelegate.aFraction != aFraction ||
        oldDelegate.bFraction != bFraction ||
        oldDelegate.aColor != aColor ||
        oldDelegate.bColor != bColor;
  }
}

class _SolidPiePainter extends CustomPainter {
  _SolidPiePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 1;
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _SolidPiePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AccuracyLineChartPainter extends CustomPainter {
  _AccuracyLineChartPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<({DateTime day, double accuracyPct})> points;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 36.0;
    const padR = 8.0;
    const padT = 8.0;
    const padB = 28.0;
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
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < n; i++) {
      final x = padL + w * (i / (n - 1));
      final y = padT + h * (1 - points[i].accuracyPct.clamp(0, 100) / 100);
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = lineColor);
    }

    final tp = TextPainter(
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    final step = n > 8 ? (n / 4).ceil() : 1;
    for (var i = 0; i < n; i += step) {
      tp.text = TextSpan(
        text: DateFormat.Md().format(points[i].day),
        style: TextStyle(color: labelColor, fontSize: 10),
      );
      tp.layout();
      final x = padL + w * (i / (n - 1)) - tp.width / 2;
      tp.paint(canvas, Offset(x, padT + h + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _AccuracyLineChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor;
}

Future<void> _startRetryWrongSession(
  BuildContext context,
  WidgetRef ref,
  String sessionId,
) async {
  try {
    final load = await ref.read(loadSessionUseCaseProvider.future);
    final session = await load.execute(sessionId);
    final wrongIds = session.questions
        .where((q) => q.status == 'wrong')
        .map((q) => q.uuid)
        .toList();
    if (wrongIds.isEmpty) {
      if (context.mounted) {
        showTopSnackBar(
          context,
          content: const Text('No wrong answers in this session.'),
        );
      }
      return;
    }
    final create = await ref.read(createSessionUseCaseProvider.future);
    final newId = await create.execute(
      SessionConfig(
        subject: session.subject,
        topic: session.topic,
        subTopic: session.subTopic,
        mode: session.mode,
        questionCount: wrongIds.length,
        isTimed: session.isTimed,
        timeLimitSecs: session.timeLimitSecs,
        language: session.language,
        specificQuestionUuids: wrongIds,
        analyticsFeatureKey: session.analyticsFeatureKey,
      ),
    );
    if (context.mounted) {
      context.push('/test/$newId');
    }
  } catch (_) {
    if (context.mounted) {
      showTopSnackBar(
        context,
        content: const Text('Could not start retry session.'),
      );
    }
  }
}
