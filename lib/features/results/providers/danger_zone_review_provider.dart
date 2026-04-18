import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';

final dangerZoneQuestionsProvider =
    FutureProvider.autoDispose.family<List<TestQuestion>, String>(
  (ref, sessionId) async {
    final load = await ref.watch(loadSessionUseCaseProvider.future);
    final active = await load.execute(sessionId);
    return active.questions
        .where(
          (q) =>
              q.status == 'wrong' &&
              AnswerConfidence.isDangerouslyConfident(q.confidence),
        )
        .toList();
  },
);
