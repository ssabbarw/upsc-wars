import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../domain/mistake_review_bundle.dart';

final mistakeReviewBundleProvider = FutureProvider.autoDispose
    .family<MistakeReviewBundle, String>((ref, sessionId) async {
      final load = await ref.watch(loadSessionUseCaseProvider.future);
      final active = await load.execute(sessionId);
      final sureWrong = <TestQuestion>[];
      final eduGuessWrong = <TestQuestion>[];
      for (final q in active.questions) {
        if (q.status != 'wrong') continue;
        if (q.confidence == AnswerConfidence.verySure) {
          sureWrong.add(q);
        } else if (q.confidence == AnswerConfidence.somewhatSure) {
          eduGuessWrong.add(q);
        }
      }
      int byPosition(TestQuestion a, TestQuestion b) =>
          a.position.compareTo(b.position);
      sureWrong.sort(byPosition);
      eduGuessWrong.sort(byPosition);
      return MistakeReviewBundle(
        sureWrong: sureWrong,
        eduGuessWrong: eduGuessWrong,
      );
    });
