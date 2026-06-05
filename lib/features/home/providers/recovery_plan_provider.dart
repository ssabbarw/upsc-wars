import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../subject_detail/domain/subject_overview_row.dart';
import '../../subject_detail/providers/all_subjects_overview_provider.dart';
import '../../subject_detail/providers/subject_danger_zone_revise_uuids.dart';
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
  if (activation.shouldShowDidYouKnow) {
    return const RecoveryPlanState(cards: []);
  }

  final home = await ref.watch(homeStateProvider.future);
  final db = ref.watch(userDatabaseProvider);
  final cards = <RecoveryPlanCardModel>[];

  // F1: Current Focus — confident mistakes in recent subject.
  final focusSubject = home.lastSession?.subject;
  if (focusSubject != null &&
      focusSubject.isNotEmpty &&
      focusSubject != 'revision_quick') {
    final uuids = await querySubjectDangerZoneReviseUuids(
      db,
      subject: focusSubject,
      confidence: AnswerConfidence.verySure,
    );
    if (uuids.isNotEmpty) {
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
  }

  // F2: Due for revision — oldest queue items (proxy).
  if (home.revisionQueueCount > 0) {
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

  // F3: Weak area — lowest accuracy subject with attempts.
  final overview = await ref.watch(allSubjectsOverviewProvider.future);
  SubjectOverviewRow? weakest;
  for (final row in overview) {
    if (!row.hasAttempts) continue;
    if (row.accuracyPercent == null) continue;
    if (row.accuracyPercent! >= 50) continue;
    if (weakest == null || row.accuracyPercent! < weakest.accuracyPercent!) {
      weakest = row;
    }
  }
  if (weakest != null &&
      weakest.totalAttempted >= 5 &&
      weakest.accuracyPercent != null) {
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
