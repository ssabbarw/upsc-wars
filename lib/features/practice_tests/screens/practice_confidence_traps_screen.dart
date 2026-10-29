import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../subject_detail/domain/subject_mcq_pattern.dart';
import '../domain/practice_pattern_visual.dart';
import '../open_pattern_practice.dart';
import '../providers/practice_subject_insights_provider.dart';

/// Question-type patterns behind Sure mistakes.
class PracticeConfidenceTrapsScreen extends ConsumerWidget {
  const PracticeConfidenceTrapsScreen({super.key, required this.subject});

  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName =
        SubjectConstants.bySlug(subject)?.displayName ?? subject;
    final insights = ref.watch(practiceSubjectInsightsProvider(subject));

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
            onPressed: () =>
                ref.invalidate(practiceSubjectInsightsProvider(subject)),
            child: Text(context.l10n.commonRetry),
          ),
        ),
        data: (value) {
          final patterns = value.surePatterns;
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
                            context.l10n.practiceTrapsBannerKicker(
                              displayName,
                            ),
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
                for (var i = 0; i < patterns.length; i++) ...[
                  _TrapDetailCard(
                    index: i,
                    subject: subject,
                    pattern: patterns[i],
                  ),
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

class _TrapDetailCard extends ConsumerStatefulWidget {
  const _TrapDetailCard({
    required this.index,
    required this.subject,
    required this.pattern,
  });

  final int index;
  final String subject;
  final SubjectMcqPatternStat pattern;

  @override
  ConsumerState<_TrapDetailCard> createState() => _TrapDetailCardState();
}

class _TrapDetailCardState extends ConsumerState<_TrapDetailCard> {
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = practicePatternVisual(
      widget.pattern,
      isDark: isDark,
      index: widget.index,
    );
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
              CircleAvatar(
                radius: 12,
                backgroundColor: fill,
                child: Text(
                  '${widget.index + 1}',
                  style: AppTextStyles.caption().copyWith(
                    color: visual.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
                      child: Text(
                        widget.pattern.labelFor(context.l10n),
                        style: AppTextStyles.label().copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.practiceTrapsErrors(widget.pattern.wrong),
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
          const SizedBox(height: AppSpacing.md),
          Text(
            widget.pattern.explainFor(context.l10n),
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.subjWeakPatternStat(
              widget.pattern.wrong,
              widget.pattern.attempted,
              widget.pattern.wrongPercent,
            ),
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        await openPatternPractice(
                          context,
                          ref,
                          subject: widget.subject,
                          pattern: widget.pattern,
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.l10n.practiceTrapsPractise),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
