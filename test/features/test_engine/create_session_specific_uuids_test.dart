import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/session_config.dart';
import 'package:upsc_wars/features/test_engine/data/repositories/create_session_repository_impl.dart';

/// The Daily War is scored server-side against the full answer key, so a paper
/// the local question bank can only partly supply must fail loudly rather than
/// run short and earn an unfair all-India rank.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserDatabase db;
  late CreateSessionRepositoryImpl repo;

  setUp(() async {
    db = UserDatabase(NativeDatabase.memory());
    repo = CreateSessionRepositoryImpl(userDatabase: db);
    for (final uuid in ['qu1', 'qu2']) {
      await db
          .into(db.questions)
          .insert(
            QuestionsCompanion.insert(
              uuid: uuid,
              subject: 'ancient_history',
              topic: 't',
              subTopic: 'st',
              questionType: 'direct',
              correctOption: 'a',
              conceptAnchor: 'c',
              conceptsUsed: '[]',
              enDisplayText: const Value('Stem'),
            ),
          );
    }
  });

  tearDown(() async => db.close());

  SessionConfig configFor(List<String> uuids, {required bool requireAll}) {
    return SessionConfig(
      subject: 'daily_war',
      mode: 'exam',
      questionCount: uuids.length,
      isTimed: true,
      timeLimitSecs: 1200,
      language: 'en',
      specificQuestionUuids: uuids,
      requireAllSpecificUuids: requireAll,
    );
  }

  test('throws when the bank is missing a requested UUID', () async {
    expect(
      () => repo.createSession(
        configFor(['qu1', 'missing', 'qu2'], requireAll: true),
      ),
      throwsA(
        isA<MissingQuestionsException>()
            .having((e) => e.wanted, 'wanted', 3)
            .having((e) => e.found, 'found', 2),
      ),
    );
  });

  test('builds the session when every UUID resolves', () async {
    final sessionId = await repo.createSession(
      configFor(['qu1', 'qu2'], requireAll: true),
    );
    final rows = await db.select(db.sessionQuestions).get();
    expect(rows, hasLength(2));
    expect(rows.map((r) => r.questionUuid), containsAll(['qu1', 'qu2']));
    expect(sessionId, isNotEmpty);
  });

  test('other features still get the shortened paper', () async {
    await repo.createSession(
      configFor(['qu1', 'missing', 'qu2'], requireAll: false),
    );
    final rows = await db.select(db.sessionQuestions).get();
    expect(rows, hasLength(2));
  });
}
