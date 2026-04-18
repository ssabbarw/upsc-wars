import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';

/// Questions in a session where the user logged this confidence tier (scored only).
final confidenceTierQuestionsProvider =
    FutureProvider.autoDispose.family<List<TestQuestion>, ({String sessionId, String tier})>(
  (ref, arg) async {
    if (!AnswerConfidence.values.contains(arg.tier)) return [];
    final load = await ref.watch(loadSessionUseCaseProvider.future);
    final active = await load.execute(arg.sessionId);
    final out = active.questions
        .where(
          (q) =>
              (q.status == 'correct' || q.status == 'wrong') &&
              q.confidence == arg.tier,
        )
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return out;
  },
);
