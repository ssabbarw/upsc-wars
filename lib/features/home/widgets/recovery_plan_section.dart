import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import '../../daily_war/domain/daily_war_schedule.dart';
import '../domain/create_daily_drill_session_use_case.dart';
import '../providers/recovery_plan_provider.dart';

class RecoveryPlanSection extends ConsumerWidget {
  const RecoveryPlanSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recoveryPlanProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        if (state.cards.isEmpty) return const SizedBox.shrink();
        // Sunday's Today hub already has the week-review card.
        if (DailyWarSchedule.isSunday(DailyWarSchedule.nowIst())) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'FIX YOUR WEAK AREAS',
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TodayPlanCarousel(
              cards: state.cards,
              borderColor: borderColor,
              isDark: isDark,
              onCardTap: (card) => _handleTap(context, ref, card),
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
        final lang = await ref.read(appLanguageProvider.future);
        final id = await create.execute(
          SessionConfig(
            subject: card.subject!,
            mode: 'learning',
            questionCount: card.questionUuids!.length,
            isTimed: false,
            timeLimitSecs: null,
            language: lang,
            specificQuestionUuids: card.questionUuids,
            analyticsFeatureKey: 'recovery_current_focus',
            dangerReviseHistoryConfidence: AnswerConfidence.verySure,
          ),
        );
        if (context.mounted) context.push('/test/$id');
      case RecoveryPlanCardKind.dueForRevision:
        final create = await ref.read(createSessionUseCaseProvider.future);
        final lang = await ref.read(appLanguageProvider.future);
        final n = card.questionCount ?? 10;
        final id = await create.execute(
          SessionConfig(
            subject: 'revision_quick',
            mode: 'exam',
            questionCount: n,
            isTimed: true,
            timeLimitSecs: n * kDebugSecondsPerQuestion,
            language: lang,
            analyticsFeatureKey: 'recovery_due_revision',
          ),
        );
        if (context.mounted) context.push('/test/$id');
      case RecoveryPlanCardKind.weakArea:
        if (card.subject == null) return;
        final uc = await ref.read(createDailyDrillSessionUseCaseProvider.future);
        final id = await uc.execute(
          subject: card.subject!,
          analyticsFeatureKey: 'recovery_weak_area',
        );
        if (context.mounted) context.push('/test/$id');
    }
  }
}

class _TodayPlanCarousel extends HookWidget {
  const _TodayPlanCarousel({
    required this.cards,
    required this.borderColor,
    required this.isDark,
    required this.onCardTap,
  });

  static const _carouselHeight = 168.0;

  final List<RecoveryPlanCardModel> cards;
  final Color borderColor;
  final bool isDark;
  final void Function(RecoveryPlanCardModel card) onCardTap;

  @override
  Widget build(BuildContext context) {
    final hasMultiple = cards.length > 1;
    final pageController = usePageController(
      viewportFraction: hasMultiple ? 0.92 : 1.0,
    );
    final currentPage = useState(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _carouselHeight,
          child: PageView.builder(
            controller: pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => currentPage.value = index,
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: hasMultiple ? AppSpacing.sm : 0,
                ),
                child: _RecoveryCard(
                  model: card,
                  borderColor: borderColor,
                  onTap: () => onCardTap(card),
                ),
              );
            },
          ),
        ),
        if (hasMultiple) ...[
          const SizedBox(height: AppSpacing.sm),
          _PlanCarouselDots(
            index: currentPage.value,
            count: cards.length,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

class _PlanCarouselDots extends StatelessWidget {
  const _PlanCarouselDots({
    required this.index,
    required this.count,
    required this.isDark,
  });

  final int index;
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: on ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: on
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.onSurfaceDark.withValues(alpha: 0.25)
                        : AppColors.gray200),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
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
          height: double.infinity,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm().copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                model.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd().copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: Text(
                  model.why,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                model.ctaLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSm().copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
