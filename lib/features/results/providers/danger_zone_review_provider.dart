import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';

final dangerZoneQuestionsProvider = FutureProvider.autoDispose
    .family<List<TestQuestion>, String>((ref, sessionId) async {
      final load = await ref.watch(loadSessionUseCaseProvider.future);
      final active = await load.execute(sessionId);
      final questions = active.questions
          .where(
            (q) =>
                q.status == 'wrong' &&
                AnswerConfidence.isDangerouslyConfident(q.confidence),
          )
          .toList()
        ..sort((a, b) {
          int tierRank(String? c) {
            if (c == AnswerConfidence.verySure) return 0;
            if (c == AnswerConfidence.somewhatSure) return 1;
            return 2;
          }

          final ta = tierRank(a.confidence);
          final tb = tierRank(b.confidence);
          if (ta != tb) return ta.compareTo(tb);
          return a.position.compareTo(b.position);
        });
      return questions;
    });
