import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/trap_descriptions_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../weak_areas/widgets/trap_info_button.dart';
import '../../weak_areas/widgets/trap_pattern_visual.dart';
import '../domain/subject_trap_stat.dart';
import '../open_insight_practice.dart';
import '../providers/practice_catalog_provider.dart';
import '../providers/practice_subject_insights_provider.dart';

/// Content traps behind Sure mistakes.
class PracticeConfidenceTrapsScreen extends ConsumerWidget {
  const PracticeConfidenceTrapsScreen({
    super.key,
    required this.subject,
    this.topic,
  });

  final String subject;
  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalog = ref.watch(practiceCatalogProvider);
    final displayName = topic == null
        ? (SubjectConstants.bySlug(subject)?.displayName ?? subject)
        : (catalog.asData?.value.topicDisplayNames[topic] ?? topic!);
    final insights = topic == null
        ? ref.watch(practiceSubjectInsightsProvider(subject))
        : ref.watch(
            practiceTopicInsightsProvider((subject: subject, topic: topic!)),
          );

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(context.l10n.practiceTrapsScreenTitle),
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: AppColors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: insights.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () {
              if (topic == null) {
                ref.invalidate(practiceSubjectInsightsProvider(subject));
              } else {
                ref.invalidate(
                  practiceTopicInsightsProvider((
                    subject: subject,
                    topic: topic!,
                  )),
                );
              }
            },
            child: Text(context.l10n.commonRetry),
          ),
        ),
        data: (value) {
          final patterns = value.sureTraps;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.warningBgDark.withValues(alpha: 0.55)
                      : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.track_changes_rounded,
                          size: 22,
                          color: isDark
                              ? AppColors.warningTextDark
                              : AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.l10n.practiceTrapsBannerKicker(displayName),
                            style: AppTextStyles.caption().copyWith(
                              color: isDark
                                  ? AppColors.warningTextDark
                                  : AppColors.warningText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.l10n.practiceTrapsBannerTitle(patterns.length),
                      style: AppTextStyles.h2().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.practiceTrapsBannerBody,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (patterns.isEmpty)
                Text(
                  context.l10n.practiceTrapsEmpty,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                )
              else
                for (final trap in patterns) ...[
                  _TrapDetailCard(subject: subject, topic: topic, trap: trap),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          );
        },
      ),
    );
  }
}

void _showInfo(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.l10n.practiceTrapsInfoTitle),
      content: Text(context.l10n.practiceTrapsInfoBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.commonGotIt),
        ),
      ],
    ),
  );
}

class _TrapDetailCard extends ConsumerWidget {
  const _TrapDetailCard({
    required this.subject,
    this.topic,
    required this.trap,
  });

  final String subject;
  final String? topic;
  final SubjectTrapStat trap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catalog = ref.watch(trapDescriptionsProvider).asData?.value;
    final language = watchAppLanguage(ref);
    final entry = catalog?[trap.trapType];
    final name = entry?.displayName ?? trap.title;
    final blurb = entry?.blurbFor(language) ?? '';
    final visual = TrapPatternVisual.of(trap.trapType);
    final fill = visual.accent.withValues(alpha: isDark ? 0.22 : 0.1);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(visual.icon, size: 20, color: visual.accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: AppTextStyles.label().copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TrapInfoButton(
                            trapType: trap.trapType,
                            tooltip: name,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.practiceTrapsErrors(trap.wrong),
                      style: AppTextStyles.caption().copyWith(
                        color: visual.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (blurb.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              blurb,
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.subjWeakPatternStat(
              trap.wrong,
              trap.attempted,
              trap.wrongPercent,
            ),
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => showInsightDrillSheet(
                    context,
                    target: InsightDrillTarget.trap(
                      subject: subject,
                      topicKey: topic,
                      trap: trap,
                      title: name,
                    ),
                    intent: InsightDrillIntent.revise,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  child: Text(context.l10n.practiceReviseIncorrects),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () => showInsightDrillSheet(
                    context,
                    target: InsightDrillTarget.trap(
                      subject: subject,
                      topicKey: topic,
                      trap: trap,
                      title: name,
                    ),
                    intent: InsightDrillIntent.improve,
                  ),
                  child: Text(context.l10n.practiceImproveScore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
