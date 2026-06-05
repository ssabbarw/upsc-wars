import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/create_did_you_know_explanations_session_use_case.dart';
import '../domain/did_you_know_cards.dart';
import '../providers/home_activation_provider.dart';

class DidYouKnowCard extends HookConsumerWidget {
  const DidYouKnowCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activationAsync = ref.watch(homeActivationProvider);
    final scheme = Theme.of(context).colorScheme;
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderLight;
    final loggedShown = useRef<String?>(null);

    return activationAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (state) {
        if (!state.shouldShowDidYouKnow || state.nextDidYouKnowCardId == null) {
          return const SizedBox.shrink();
        }
        final card = didYouKnowCardById(state.nextDidYouKnowCardId!);
        if (card == null) return const SizedBox.shrink();

        if (loggedShown.value != card.id) {
          loggedShown.value = card.id;
          unawaited(Analytics.track(ref, DidYouKnowShownEvent(cardId: card.id)));
          unawaited(
            ref.read(homeActivationProvider.notifier).markDidYouKnowShown(card.id),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'DID YOU KNOW',
                      style: AppTextStyles.caption().copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
                    onPressed: () async {
                      unawaited(
                        Analytics.track(
                          ref,
                          DidYouKnowDismissedEvent(cardId: card.id),
                        ),
                      );
                      await ref
                          .read(homeActivationProvider.notifier)
                          .dismissDidYouKnowCard(card.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                card.title,
                style: AppTextStyles.label().copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                card.body,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => _onCta(context, ref, card),
                child: Text(card.ctaLabel),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onCta(
    BuildContext context,
    WidgetRef ref,
    DidYouKnowCardDef card,
  ) async {
    unawaited(
      Analytics.track(ref, DidYouKnowCtaTappedEvent(cardId: card.id)),
    );
    await ref.read(homeActivationProvider.notifier).dismissDidYouKnowCard(card.id);
    if (!context.mounted) return;

    switch (card.action) {
      case DidYouKnowAction.openWeakAreasHub:
        context.push('/weak-areas');
      case DidYouKnowAction.openRevisionQueue:
        context.push('/revision-queue');
      case DidYouKnowAction.openCommunityBattles:
        context.push('/community');
      case DidYouKnowAction.showExplanationsSheet:
        try {
          final uc = await ref.read(
            createDidYouKnowExplanationsSessionUseCaseProvider.future,
          );
          final id = await uc.execute();
          if (context.mounted) context.push('/test/$id');
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not start example: $e')),
            );
          }
        }
    }
  }
}
