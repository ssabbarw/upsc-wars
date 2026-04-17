import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/domain/repositories/create_session_repository.dart';

class CreateSessionRepositoryImpl implements CreateSessionRepository {
  CreateSessionRepositoryImpl({
    required UserDatabase userDatabase,
  }) : _userDatabase = userDatabase;

  final UserDatabase _userDatabase;

  static const _uuid = Uuid();

  @override
  Future<String> createSession(SessionConfig config) async {
    final attempted = await _userDatabase.sessionQuestionsDao
        .getAllAttemptedQuestionUuids();
    final want = config.questionCount;
    if (want <= 0) {
      throw StateError('Invalid question count');
    }

    final List<Question> picked;
    final topic = config.topic;
    if (config.specificQuestionUuids != null) {
      picked = await _userDatabase.questionsDao
          .getByUuidsInOrder(config.specificQuestionUuids!);
    } else if (config.subject == 'revision') {
      final active = await _userDatabase.revisionQueueDao.fetchActiveQueue();
      final uuids = active.take(config.questionCount).map((e) => e.questionUuid).toList();
      picked = await _userDatabase.questionsDao.getByUuidsInOrder(uuids);
    } else if (config.subject == 'revision_quick') {
      final uuids = await _userDatabase.revisionQueueDao
          .fetchActiveQueueRandomized(config.questionCount);
      picked = await _userDatabase.questionsDao.getByUuidsInOrder(uuids);
    } else if (config.subject == 'bookmarks') {
      final uuids = await _userDatabase.bookmarksDao
          .getRandomBookmarkUuids(config.questionCount);
      picked = await _userDatabase.questionsDao.getByUuidsInOrder(uuids);
    } else if (topic != null) {
      picked = await _userDatabase.questionsDao.getUnseenFirstByTopic(
        subject: config.subject,
        topic: topic,
        limit: want,
        attemptedQuestionUuids: attempted,
      );
    } else {
      picked = await _userDatabase.questionsDao.getUnseenFirstBySubject(
        subject: config.subject,
        limit: want,
        attemptedQuestionUuids: attempted,
      );
    }

    final n = picked.length;
    if (n == 0) {
      throw StateError('No questions available');
    }

    final sessionId = _uuid.v4();

    await _userDatabase.transaction(() async {
      await _userDatabase.sessionsDao.insertSession(
        SessionsCompanion.insert(
          id: sessionId,
          createdAt: DateTime.now(),
          subject: config.subject,
          topic: Value(config.topic),
          subTopic: Value(config.subTopic),
          mode: config.mode,
          status: 'in_progress',
          questionCount: n,
          isTimed: config.mode == 'exam' ? config.isTimed : true,
          timeLimitSecs: Value(config.timeLimitSecs),
          examRemainingSecs: (config.mode == 'exam' &&
                  config.isTimed &&
                  config.timeLimitSecs != null)
              ? Value(config.timeLimitSecs)
              : const Value.absent(),
          language: Value(config.language),
        ),
      );
      for (var i = 0; i < n; i++) {
        await _userDatabase.sessionQuestionsDao.insertSessionQuestion(
          SessionQuestionsCompanion.insert(
            id: _uuid.v4(),
            sessionId: sessionId,
            questionUuid: picked[i].uuid,
            position: i + 1,
          ),
        );
      }
    });

    return sessionId;
  }
}
