import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsc_wars/core/analytics/analytics_service.dart';
import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/features/test_engine/data/repositories/test_engine_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserDatabase db;
  late PrefsService prefs;
  late TestEngineRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsService(await SharedPreferences.getInstance());
    db = UserDatabase(NativeDatabase.memory());
    repo = TestEngineRepositoryImpl(
      userDb: db,
      prefsService: prefs,
      analytics: AnalyticsService(const []),
    );

    await db
        .into(db.questions)
        .insert(
          QuestionsCompanion.insert(
            uuid: 'qu1',
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

    const sessionId = 'se1';
    await db
        .into(db.sessions)
        .insert(
          SessionsCompanion.insert(
            id: sessionId,
            createdAt: DateTime.utc(2026, 2, 1),
            subject: 'ancient_history',
            mode: 'exam',
            status: 'in_progress',
            questionCount: 1,
            isTimed: false,
          ),
        );
    await db
        .into(db.sessionQuestions)
        .insert(
          SessionQuestionsCompanion.insert(
            id: 'att1',
            sessionId: sessionId,
            questionUuid: 'qu1',
            position: 1,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('updateQuestionAttempt persists confidence and attemptedAt', () async {
    await repo.updateQuestionAttempt(
      sessionId: 'se1',
      questionUuid: 'qu1',
      selectedOption: 'b',
      confidence: AnswerConfidence.somewhatSure,
      analytics: null,
    );

    final rows = await db.sessionQuestionsDao.getSessionQuestionsOrdered('se1');
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.status, 'wrong');
    expect(row.confidence, AnswerConfidence.somewhatSure);
    expect(row.attemptedAt, isNotNull);
    expect(row.selectedOption, 'b');
  });

  test('updateQuestionAttempt ignores invalid confidence string', () async {
    await repo.updateQuestionAttempt(
      sessionId: 'se1',
      questionUuid: 'qu1',
      selectedOption: 'b',
      confidence: 'not_a_real_level',
      analytics: null,
    );

    final row = (await db.sessionQuestionsDao.getSessionQuestionsOrdered(
      'se1',
    )).single;
    expect(row.confidence, isNull);
  });
}
