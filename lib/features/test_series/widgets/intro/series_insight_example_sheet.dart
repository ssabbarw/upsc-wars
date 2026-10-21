import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../series_dashboard_widgets.dart';
import 'series_tone.dart';
import '../../../../l10n/l10n.dart';

/// Opens "what your analysis looks like" with sample numbers.
Future<bool> showSeriesInsightExampleSheet(BuildContext context) async {
  final unlock = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => _InsightExampleBody(controller: controller),
    ),
  );
  return unlock ?? false;
}

class _TopicSample {
  const _TopicSample(this.name, this.correct, this.answered);

  final String name;
  final int correct;
  final int answered;

  double get accuracy => correct / answered;
}

/// Subject the example below is about (sample data, shown in English).
const _exampleSubject = 'Modern History';

/// Illustrative numbers only (clearly labelled as such in the sheet).
const _modernHistoryTopics = [
  _TopicSample('Freedom Movement', 15, 24),
  _TopicSample('Social reform movements', 7, 12),
  _TopicSample('Governor-Generals and Acts', 4, 13),
  _TopicSample('Revolutionary movements', 3, 12),
  _TopicSample('INC sessions', 2, 10),
];

class _InsightExampleBody extends StatelessWidget {
  const _InsightExampleBody({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final red = seriesToneColors(SeriesTone.red, isDark: isDark);

    final totalCorrect = _modernHistoryTopics.fold<int>(
      0,
      (a, t) => a + t.correct,
    );
    final totalAnswered = _modernHistoryTopics.fold<int>(
      0,
      (a, t) => a + t.answered,
    );
    final overall = totalCorrect / totalAnswered;
    final weakest = [..._modernHistoryTopics]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        TonePill(
          label: context.l10n.tsExampleNums,
          tone: SeriesTone.purple,
          icon: Icons.insights_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '$_exampleSubject: ${context.l10n.tsAccuracyPct((overall * 100).round())}',
          style: AppTextStyles.h1().copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.tsQsCorrectOf(totalCorrect, totalAnswered),
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: red.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_rounded, color: red.accent, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.tsLowScoreStory(
                    _exampleSubject,
                    weakest.first.name,
                  ),
                  style: AppTextStyles.bodySm().copyWith(color: red.fg),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(context.l10n.tsTopicByTopic, style: AppTextStyles.h3()),
        const SizedBox(height: AppSpacing.md),
        for (final t in _modernHistoryTopics) _TopicBar(topic: t),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.tsTapTopicHint,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
          child: Text(context.l10n.tsUnlockAll),
        ),
      ],
    );
  }
}

class _TopicBar extends StatelessWidget {
  const _TopicBar({required this.topic});

  final _TopicSample topic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = seriesAccuracyColor(topic.accuracy);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic.name,
                  style: AppTextStyles.bodyMd().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${topic.correct}/${topic.answered}',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 40,
                child: Text(
                  '${(topic.accuracy * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.label().copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: topic.accuracy,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
