import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:upsc_wars/core/database/question_db.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/core/domain/repositories/create_session_repository.dart';

class CreateSessionRepositoryImpl implements CreateSessionRepository {
  CreateSessionRepositoryImpl({
    required QuestionDb questionDb,
    required UserDatabase userDatabase,
  })  : _questionDb = questionDb,
        _userDatabase = userDatabase;

  final QuestionDb _questionDb;
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

    final List<QuestionRow> picked;
    final topic = config.topicSlug;
    if (config.subjectSlug == 'revision') {
      final uuids = await _userDatabase.revisionQueueDao.getActiveRevisionQuestionUuids();
      final take = uuids.take(config.questionCount).toList();
      picked = await _questionDb.getQuestionsByUuids(take);
    } else if (topic != null) {
      picked = await _questionDb.getNUnseenQuestionsForTopic(
        config.subjectSlug,
        topic,
        want,
        attempted,
      );
    } else {
      picked = await _questionDb.getNUnseenQuestionsForSubject(
        config.subjectSlug,
        want,
        attempted,
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
          subjectSlug: config.subjectSlug,
          topicSlug: Value(config.topicSlug),
          subTopicSlug: Value(config.subTopicSlug),
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
