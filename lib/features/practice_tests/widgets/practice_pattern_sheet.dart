import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../subject_detail/domain/subject_mcq_pattern.dart';
import '../providers/practice_subject_insights_provider.dart';

Future<void> showPracticePatternSheet({
  required BuildContext context,
  required String subject,
  required List<SubjectMcqPatternStat> patterns,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, controller) => _PatternSheet(
        subject: subject,
        patterns: patterns,
        controller: controller,
      ),
    ),
  );
}

class _PatternSheet extends HookConsumerWidget {
  const _PatternSheet({
    required this.subject,
    required this.patterns,
    required this.controller,
  });

  final String subject;
  final List<SubjectMcqPatternStat> patterns;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final busyKey = useState<String?>(null);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          context.l10n.practicePatternsTitle,
          style: AppTextStyles.h2().copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.subjWeakPatternScope,
          style: AppTextStyles.bodySm().copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (patterns.isEmpty)
          Text(
            context.l10n.practicePatternsEmpty,
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (final pattern in patterns) ...[
            _PatternCard(
              pattern: pattern,
              busy: busyKey.value == _key(pattern),
              onPractice: busyKey.value != null
                  ? null
                  : () => _practice(
                      context,
                      ref,
                      pattern: pattern,
                      busyKey: busyKey,
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  String _key(SubjectMcqPatternStat pattern) =>
      '${pattern.pattern.name}:${pattern.otherSlug ?? ''}';

  Future<void> _practice(
    BuildContext context,
    WidgetRef ref, {
    required SubjectMcqPatternStat pattern,
    required ValueNotifier<String?> busyKey,
  }) async {
    busyKey.value = _key(pattern);
    try {
      final db = ref.read(userDatabaseProvider);
      final uuids = await loadPatternPracticeUuids(
        db,
        subject: subject,
        pattern: pattern,
      );
      if (!context.mounted) return;
      if (uuids.isEmpty) {
        AppToast.showText(context, context.l10n.practicePatternsNoQuestions);
        return;
      }
      final create = await ref.read(createSessionUseCaseProvider.future);
      final lang = await ref.read(appLanguageProvider.future);
      final id = await create.execute(
        SessionConfig(
          subject: subject,
          mode: 'learning',
          questionCount: uuids.length,
          isTimed: false,
          timeLimitSecs: null,
          language: lang,
          specificQuestionUuids: uuids,
          analyticsFeatureKey: 'practice_pattern_revise',
        ),
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      await context.push('/test/$id');
    } catch (e) {
      if (context.mounted) {
        AppToast.showText(context, context.l10n.dzStartFailed(e.toString()));
      }
    } finally {
      busyKey.value = null;
    }
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.pattern,
    required this.busy,
    required this.onPractice,
  });

  final SubjectMcqPatternStat pattern;
  final bool busy;
  final VoidCallback? onPractice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.wrongTextDark : AppColors.wrongText;
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
          Text(
            pattern.labelFor(context.l10n),
            style: AppTextStyles.label().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.subjWeakPatternStat(
              pattern.wrong,
              pattern.attempted,
              pattern.wrongPercent,
            ),
            style: AppTextStyles.caption().copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            pattern.explainFor(context.l10n),
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onPractice,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wrong,
                foregroundColor: AppColors.onPrimary,
                visualDensity: VisualDensity.compact,
              ),
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Text(context.l10n.practicePatternsPractice),
            ),
          ),
        ],
      ),
    );
  }
}
