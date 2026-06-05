import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import 'create_did_you_know_explanations_session_use_case.dart';
import 'did_you_know_cards.dart';
import '../providers/home_activation_provider.dart';

Future<void> runDidYouKnowCta(
  BuildContext context,
  WidgetRef ref,
  DidYouKnowCardDef card, {
  bool dismissCard = true,
}) async {
  unawaited(
    Analytics.track(ref, DidYouKnowCtaTappedEvent(cardId: card.id)),
  );
  if (dismissCard) {
    await ref.read(homeActivationProvider.notifier).dismissDidYouKnowCard(card.id);
  }
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
