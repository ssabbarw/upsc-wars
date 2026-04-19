import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';

/// Questions in a session where the user logged this confidence tier (scored only).
///
/// [outcomeFilter]: `correct`, `wrong`, or null for both.
final confidenceTierQuestionsProvider =
    FutureProvider.autoDispose
        .family<List<TestQuestion>, ({
          String sessionId,
          String tier,
          String? outcomeFilter,
        })>(
  (ref, arg) async {
    if (!AnswerConfidence.values.contains(arg.tier)) return [];
    final load = await ref.watch(loadSessionUseCaseProvider.future);
    final active = await load.execute(arg.sessionId);
    final out = active.questions.where((q) {
      if (q.confidence != arg.tier) return false;
      if (q.status != 'correct' && q.status != 'wrong') return false;
      final f = arg.outcomeFilter;
      if (f == null) return true;
      if (f == 'correct') return q.status == 'correct';
      if (f == 'wrong') return q.status == 'wrong';
      return true;
    }).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return out;
  },
);
