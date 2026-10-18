import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/series_stats.dart';
import '../domain/test_series_models.dart';

/// Colour for an accuracy fraction: strong, middling or weak.
Color seriesAccuracyColor(double accuracy) {
  if (accuracy >= 0.7) return AppColors.primary;
  if (accuracy >= 0.5) return AppColors.warning;
  return AppColors.wrong;
}

IconData seriesSubjectIcon(String subjectId) {
  switch (subjectId) {
    case SeriesBuckets.polity:
      return Icons.account_balance_rounded;
    case SeriesBuckets.economy:
      return Icons.bar_chart_rounded;
    case SeriesBuckets.environment:
      return Icons.eco_rounded;
    case SeriesBuckets.geography:
      return Icons.public_rounded;
    case SeriesBuckets.modernHistory:
      return Icons.history_edu_rounded;
    case SeriesBuckets.historyCulture:
      return Icons.museum_rounded;
    case SeriesSubjects.scienceTech:
      return Icons.science_rounded;
    case SeriesSubjects.currentAffairs:
      return Icons.newspaper_rounded;
    case SeriesSubjects.internationalRelations:
      return Icons.language_rounded;
    default:
      return Icons.category_rounded;
  }
}

BoxDecoration _cardDecoration(BuildContext context, {Color? color}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: color ?? Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
      width: 0.8,
    ),
  );
}

/// Section title with an optional "See all" action.
class SeriesSectionHeader extends StatelessWidget {
  const SeriesSectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
    this.trailingText,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Plain muted text on the right (for example "2/6 done").
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.h3())),
          if (trailingText != null)
            Text(
              trailingText!,
              style: AppTextStyles.bodySm().copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Small metric card: tinted icon, big value, caption.
class SeriesStatTile extends StatelessWidget {
  const SeriesStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTextStyles.h2().copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Needs Revision / Safe Areas summary card on the Overview.
class SeriesInsightCard extends StatelessWidget {
  const SeriesInsightCard({
    super.key,
    required this.revise,
    required this.count,
    required this.caption,
    required this.action,
    required this.onTap,
  });

  final bool revise;
  final int count;
  final String caption;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = revise ? AppColors.wrong : AppColors.primary;
    final bg = revise
        ? (isDark ? AppColors.wrongBgDark : AppColors.wrongBg)
        : (isDark ? AppColors.correctBgDark : AppColors.correctBg);
    final fg = revise
        ? (isDark ? AppColors.wrongTextDark : AppColors.wrongText)
        : (isDark ? AppColors.correctTextDark : AppColors.correctText);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    revise
                        ? Icons.error_outline_rounded
                        : Icons.verified_user_outlined,
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      revise ? 'Needs Revision' : 'Safe Areas',
                      style: AppTextStyles.label().copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$count',
                style: AppTextStyles.h1().copyWith(
                  color: fg,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(caption, style: AppTextStyles.bodySm().copyWith(color: fg)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      action,
                      style: AppTextStyles.caption().copyWith(color: fg),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: fg),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-way switch between "Needs Revision" and "Safe Areas".
class SeriesInsightToggle extends StatelessWidget {
  const SeriesInsightToggle({
    super.key,
    required this.revise,
    required this.onChanged,
  });

  final bool revise;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget segment(bool isRevise) {
      final selected = revise == isRevise;
      final accent = isRevise ? AppColors.wrong : AppColors.primary;
      final selectedBg = isRevise
          ? (isDark ? AppColors.wrongBgDark : AppColors.wrongBg)
          : (isDark ? AppColors.correctBgDark : AppColors.correctBg);
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => onChanged(isRevise),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? selectedBg : AppColors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: selected ? Border.all(color: accent, width: 1) : null,
            ),
            child: Text(
              isRevise ? 'Needs Revision' : 'Safe Areas',
              style: AppTextStyles.label().copyWith(
                color: selected
                    ? accent
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md + 3),
      ),
      child: Row(children: [segment(true), segment(false)]),
    );
  }
}

/// One topic: tap to revise its questions.
class SeriesTopicTile extends StatelessWidget {
  const SeriesTopicTile({
    super.key,
    required this.topic,
    required this.revise,
    required this.onTap,
    this.showSubject = false,
    this.isHindi = false,
  });

  final TopicStat topic;
  final bool revise;
  final VoidCallback onTap;
  final bool showSubject;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = revise ? AppColors.wrong : AppColors.primary;
    final bg = revise
        ? (isDark ? AppColors.wrongBgDark : AppColors.wrongBg)
        : (isDark ? AppColors.correctBgDark : AppColors.correctBg);

    final detail = '${topic.correct}/${topic.answered} correct';
    final subtitle = showSubject
        ? '${SeriesSubjects.label(topic.subjectId, hindi: isHindi)} · $detail'
        : detail;
    final trailing = revise
        ? '${topic.mistakes} ${topic.mistakes == 1 ? 'mistake' : 'mistakes'}'
        : '${(topic.accuracy * 100).round()}%';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardListGap),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: _cardDecoration(context),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    revise
                        ? Icons.menu_book_rounded
                        : Icons.check_circle_outline_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.topic,
                        style: AppTextStyles.bodyMd().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySm().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  trailing,
                  style: AppTextStyles.labelSm().copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full list of topics in a draggable bottom sheet.
Future<void> showSeriesTopicsSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required List<TopicStat> topics,
  required bool revise,
  required bool showSubject,
  required bool isHindi,
  required ValueChanged<TopicStat> onTopicTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Text(title, style: AppTextStyles.h2()),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySm().copyWith(
              color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (topics.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('Nothing here yet.')),
            ),
          for (final t in topics)
            SeriesTopicTile(
              topic: t,
              revise: revise,
              showSubject: showSubject,
              isHindi: isHindi,
              onTap: () {
                Navigator.pop(sheetContext);
                onTopicTap(t);
              },
            ),
        ],
      ),
    ),
  );
}

/// Needs Revision / Safe Areas switch with the first few topics and a
/// "See all topics" button. Used on the Full-Length tab and subject screen.
class SeriesTopicsPanel extends HookWidget {
  const SeriesTopicsPanel({
    super.key,
    required this.needsRevision,
    required this.safeAreas,
    required this.useConfidence,
    required this.reviseTitle,
    required this.onTopicTap,
    required this.isHindi,
    this.showSubject = false,
    this.limit = 3,
  });

  final List<TopicStat> needsRevision;
  final List<TopicStat> safeAreas;
  final bool useConfidence;
  final String reviseTitle;
  final ValueChanged<TopicStat> onTopicTap;
  final bool isHindi;
  final bool showSubject;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final revise = useState(true);
    final scheme = Theme.of(context).colorScheme;
    final list = revise.value ? needsRevision : safeAreas;
    final title = revise.value ? reviseTitle : 'Safe areas';
    final subtitle = revise.value
        ? (useConfidence
              ? 'Questions you got wrong despite high confidence.'
              : 'Questions you got wrong. Tap a topic to read them again.')
        : 'Topics you answer reliably. Keep practising to stay sharp.';
    final emptyText = revise.value
        ? 'No weak topics yet. Finish a test and they will show up here.'
        : 'No safe areas yet. A topic becomes safe at 80% accuracy over 4+ questions.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SeriesInsightToggle(
          revise: revise.value,
          onChanged: (v) => revise.value = v,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTextStyles.h3()),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: _cardDecoration(context),
            child: Text(
              emptyText,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          for (final t in list.take(limit))
            SeriesTopicTile(
              topic: t,
              revise: revise.value,
              showSubject: showSubject,
              isHindi: isHindi,
              onTap: () => onTopicTap(t),
            ),
          if (list.length > limit)
            OutlinedButton(
              onPressed: () => showSeriesTopicsSheet(
                context: context,
                title: title,
                subtitle: subtitle,
                topics: list,
                revise: revise.value,
                showSubject: showSubject,
                isHindi: isHindi,
                onTopicTap: onTopicTap,
              ),
              child: Text('See all topics (${list.length})'),
            ),
        ],
      ],
    );
  }
}

/// Subject row: icon, name, accuracy and a progress bar.
class SeriesSubjectRow extends StatelessWidget {
  const SeriesSubjectRow({
    super.key,
    required this.stat,
    required this.isHindi,
    required this.onTap,
  });

  final SubjectStat stat;
  final bool isHindi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasData = stat.answered > 0;
    final color = hasData
        ? seriesAccuracyColor(stat.accuracy)
        : scheme.onSurfaceVariant;
    final tests = stat.tests;
    final String caption;
    if (tests != null) {
      caption = '${tests.attempted}/${tests.total} tests completed';
    } else if (hasData) {
      caption = '${stat.answered} questions answered in full-length tests';
    } else {
      caption = 'From full-length tests';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardListGap),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: _cardDecoration(context),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    seriesSubjectIcon(stat.subjectId),
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              SeriesSubjects.label(
                                stat.subjectId,
                                hindi: isHindi,
                              ),
                              style: AppTextStyles.bodyMd().copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            hasData ? '${(stat.accuracy * 100).round()}%' : '—',
                            style: AppTextStyles.label().copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: hasData ? stat.accuracy : 0,
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        caption,
                        style: AppTextStyles.caption().copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
