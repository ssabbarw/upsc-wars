import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/did_you_know_actions.dart';
import '../domain/did_you_know_cards.dart';
import '../providers/home_activation_provider.dart';

/// Compact 1–2 line Did You Know strip: copy on the left, CTA on the right.
class DidYouKnowStrip extends HookConsumerWidget {
  const DidYouKnowStrip({super.key});

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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Did you know',
                      style: AppTextStyles.caption().copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm().copyWith(
                        color: scheme.onSurface,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () async {
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
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => runDidYouKnowCta(context, ref, card),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.primary,
                      textStyle: AppTextStyles.caption().copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(card.ctaLabel),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
