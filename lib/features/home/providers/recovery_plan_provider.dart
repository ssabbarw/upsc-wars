import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';
import '../domain/home_recommendation_snapshot.dart';
import '../providers/home_activation_provider.dart';

enum RecoveryPlanCardKind {
  currentFocus,
  dueForRevision,
  weakArea,
}

class RecoveryPlanCardModel {
  const RecoveryPlanCardModel({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.why,
    required this.ctaLabel,
    this.subject,
    this.topic,
    this.questionCount,
    this.questionUuids,
  });

  final RecoveryPlanCardKind kind;
  final String title;
  final String subtitle;
  final String why;
  final String ctaLabel;
  final String? subject;
  final String? topic;
  final int? questionCount;
  final List<String>? questionUuids;
}

class RecoveryPlanState {
  const RecoveryPlanState({required this.cards});

  final List<RecoveryPlanCardModel> cards;
}

final recoveryPlanProvider = FutureProvider.autoDispose<RecoveryPlanState>((
  ref,
) async {
  final activation = await ref.watch(homeActivationProvider.future);
  if (!activation.activationComplete) {
    return const RecoveryPlanState(cards: []);
  }

  final snapshot = await ref.watch(homeRecommendationSnapshotProvider.future);
  final cards = <RecoveryPlanCardModel>[];

  // F1: Current Focus — confident mistakes in recent subject.
  if (snapshot.hasCurrentFocus) {
    final focusSubject = snapshot.currentFocusSubject!;
    final uuids = snapshot.currentFocusMistakeUuids;
    final take = uuids.length.clamp(1, 10);
    cards.add(
      RecoveryPlanCardModel(
        kind: RecoveryPlanCardKind.currentFocus,
        title: 'Current focus',
        subtitle:
            'Review $take confident mistake${take == 1 ? '' : 's'} in $focusSubject',
        why: 'You have been practicing $focusSubject recently.',
        ctaLabel: 'Review now',
        subject: focusSubject,
        questionCount: take,
        questionUuids: uuids.take(take).toList(),
      ),
    );
  }

  // F2: Due for revision — show when queue has any active items (> 0).
  if (snapshot.revisionQueueCount > 0) {
    final queue = await ref.watch(revisionQueueItemsProvider.future);
    if (queue.isNotEmpty) {
      cards.add(
        RecoveryPlanCardModel(
          kind: RecoveryPlanCardKind.dueForRevision,
          title: 'Due for revision',
          subtitle:
              '${queue.length.clamp(1, 99)} unmastered question${queue.length == 1 ? '' : 's'}',
          why: 'These mistakes have been waiting in your queue.',
          ctaLabel: 'Revise now',
          subject: 'revision_quick',
          questionCount: queue.length.clamp(1, 10),
        ),
      );
    }
  }

  // F3: Weak area — lowest accuracy subject, skip if same as current focus.
  final weakest = snapshot.weakestSubject;
  if (snapshot.hasDistinctWeakArea && weakest != null) {
    cards.add(
      RecoveryPlanCardModel(
        kind: RecoveryPlanCardKind.weakArea,
        title: 'Weak area',
        subtitle: weakest.displayName,
        why:
            '${weakest.accuracyPercent!.round()}% accuracy — worth extra practice.',
        ctaLabel: 'Open subject',
        subject: weakest.subject,
      ),
    );
  }

  return RecoveryPlanState(cards: cards.take(3).toList());
});
