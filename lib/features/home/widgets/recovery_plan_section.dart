import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_global_dispatch.dart';
import '../../../core/constants/timed_exam_debug_constants.dart';
import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/recovery_plan_provider.dart';

class RecoveryPlanSection extends ConsumerWidget {
  const RecoveryPlanSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recoveryPlanProvider);
    final scheme = Theme.of(context).colorScheme;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderLight;

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        if (state.cards.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "TODAY'S PLAN",
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...state.cards.map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _RecoveryCard(
                  model: card,
                  borderColor: borderColor,
                  onTap: () => _handleTap(context, ref, card),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    RecoveryPlanCardModel card,
  ) async {
    logGlobalAnalytics(
      RevisionRecommendationClickedEvent(source: 'recovery_${card.kind.name}'),
    );

    switch (card.kind) {
      case RecoveryPlanCardKind.currentFocus:
        if (card.questionUuids == null || card.subject == null) return;
        final create = await ref.read(createSessionUseCaseProvider.future);
        final id = await create.execute(
          SessionConfig(
            subject: card.subject!,
            mode: 'learning',
            questionCount: card.questionUuids!.length,
            isTimed: false,
            timeLimitSecs: null,
            language: 'en',
            specificQuestionUuids: card.questionUuids,
            analyticsFeatureKey: 'recovery_current_focus',
            dangerReviseHistoryConfidence: AnswerConfidence.verySure,
          ),
        );
        if (context.mounted) context.push('/test/$id');
      case RecoveryPlanCardKind.continueSubject:
        if (card.sessionId != null) {
          context.push('/test/${card.sessionId}');
          return;
        }
        if (card.subject == null) return;
        context.push('/subject/${Uri.encodeComponent(card.subject!)}');
      case RecoveryPlanCardKind.dueForRevision:
        final create = await ref.read(createSessionUseCaseProvider.future);
        final n = card.questionCount ?? 10;
        final id = await create.execute(
          SessionConfig(
            subject: 'revision_quick',
            mode: 'exam',
            questionCount: n,
            isTimed: true,
            timeLimitSecs: n * kDebugSecondsPerQuestion,
            language: 'en',
            analyticsFeatureKey: 'recovery_due_revision',
          ),
        );
        if (context.mounted) context.push('/test/$id');
      case RecoveryPlanCardKind.weakArea:
        if (card.subject == null) return;
        context.push('/subject/${Uri.encodeComponent(card.subject!)}');
    }
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({
    required this.model,
    required this.borderColor,
    required this.onTap,
  });

  final RecoveryPlanCardModel model;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                model.title,
                style: AppTextStyles.labelSm().copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                model.subtitle,
                style: AppTextStyles.bodyMd().copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                model.why,
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  model.ctaLabel,
                  style: AppTextStyles.labelSm().copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
