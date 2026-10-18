import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';

class ReviewSessionState {
  const ReviewSessionState({
    required this.questions,
    required this.currentIndex,
    required this.bookmarkedByUuid,
    required this.queuedByUuid,
  });

  final List<TestQuestion> questions;
  final int currentIndex;
  final Map<String, bool> bookmarkedByUuid;
  final Map<String, bool> queuedByUuid;

  int get total => questions.length;
  TestQuestion get currentQuestion => questions[currentIndex];

  ReviewSessionState copyWith({
    int? currentIndex,
    Map<String, bool>? bookmarkedByUuid,
    Map<String, bool>? queuedByUuid,
  }) {
    return ReviewSessionState(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      bookmarkedByUuid: bookmarkedByUuid ?? this.bookmarkedByUuid,
      queuedByUuid: queuedByUuid ?? this.queuedByUuid,
    );
  }
}

typedef ReviewSessionParams = ({String sessionId, bool focusWrong});

final reviewSessionProvider =
    FutureProvider.family<ReviewSessionState, ReviewSessionParams>((
      ref,
      arg,
    ) async {
      final load = await ref.read(loadSessionUseCaseProvider.future);
      final active = await load.execute(arg.sessionId);
      final sorted = [...active.questions]
        ..sort((a, b) => a.position.compareTo(b.position));
      final repo = await ref.read(testEngineRepositoryProvider.future);
      final userDb = ref.read(userDatabaseProvider);

      final bm = <String, bool>{};
      final queue = <String, bool>{};
      for (final q in sorted) {
        bm[q.uuid] = await repo.isBookmarked(q.uuid);
        final queued = await userDb.revisionQueueDao
            .getRevisionQueueItemByQuestionUuid(q.uuid);
        queue[q.uuid] = queued != null;
      }

      var startIndex = 0;
      if (arg.focusWrong) {
        final i = sorted.indexWhere((q) => q.status == 'wrong');
        if (i >= 0) startIndex = i;
      }

      return ReviewSessionState(
        questions: sorted,
        currentIndex: startIndex,
        bookmarkedByUuid: bm,
        queuedByUuid: queue,
      );
    });

const reviewSessionUuid = Uuid();
