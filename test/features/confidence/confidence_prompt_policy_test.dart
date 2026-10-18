import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/features/test_engine/domain/confidence_prompt_policy.dart';

import '../../support/test_question_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrefsService prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrefsService(await SharedPreferences.getInstance());
    prefs.confidenceTrackingEnabled = true;
  });

  ActiveSession session({
    String subject = 'ancient_history',
    String mode = 'exam',
  }) {
    return ActiveSession(
      id: 's',
      mode: mode,
      subject: subject,
      topic: null,
      subTopic: null,
      questionCount: 1,
      isTimed: false,
      timeLimitSecs: null,
      status: 'in_progress',
      language: 'en',
      questions: const [],
    );
  }

  group('ConfidencePromptPolicy.shouldPrompt', () {
    test('returns false when global confidence toggle is off', () {
      prefs.confidenceTrackingEnabled = false;
      final q = buildTestQuestion(uuid: 'q1');
      expect(
        ConfidencePromptPolicy.shouldPrompt(
          prefs: prefs,
          question: q,
          session: session(),
          lifetimeScoredAttempts: 0,
          weakTopicKeys: {},
        ),
        isFalse,
      );
      prefs.confidenceTrackingEnabled = true;
    });

    test('returns true for early learner band regardless of topic', () {
      final q = buildTestQuestion(
        uuid: 'q1',
        questionType: 'direct',
        trapType: null,
        subject: 'ancient_history',
        topic: 'X',
      );
      expect(
        ConfidencePromptPolicy.shouldPrompt(
          prefs: prefs,
          question: q,
          session: session(subject: 'ancient_history'),
          lifetimeScoredAttempts: 124,
          weakTopicKeys: {},
        ),
        isTrue,
      );
    });

    test(
      'after early learner band, routine direct question with no weak topic → false',
      () {
        final q = buildTestQuestion(
          uuid: 'q1',
          questionType: 'direct',
          trapType: null,
          subject: 'ancient_history',
          topic: 'StableTopic',
        );
        expect(
          ConfidencePromptPolicy.shouldPrompt(
            prefs: prefs,
            question: q,
            session: session(subject: 'ancient_history'),
            lifetimeScoredAttempts: 200,
            weakTopicKeys: {},
          ),
          isFalse,
        );
      },
    );

    test('PYQ subject slug triggers prompt after early learner band', () {
      final q = buildTestQuestion(
        uuid: 'q1',
        questionType: 'direct',
        subject: 'history',
        topic: 't',
      );
      expect(
        ConfidencePromptPolicy.shouldPrompt(
          prefs: prefs,
          question: q,
          session: session(subject: 'upsc_pyq_2019'),
          lifetimeScoredAttempts: 500,
          weakTopicKeys: {},
        ),
        isTrue,
      );
    });

    test('revision session triggers prompt', () {
      final q = buildTestQuestion(uuid: 'q1', questionType: 'direct');
      expect(
        ConfidencePromptPolicy.shouldPrompt(
          prefs: prefs,
          question: q,
          session: session(subject: 'revision'),
          lifetimeScoredAttempts: 500,
          weakTopicKeys: {},
        ),
        isTrue,
      );
      expect(
        ConfidencePromptPolicy.shouldPrompt(
          prefs: prefs,
          question: q,
          session: session(subject: 'revision_quick'),
          lifetimeScoredAttempts: 500,
          weakTopicKeys: {},
        ),
        isTrue,
      );
    });

    test('trap type present triggers prompt', () {
      final q = buildTestQuestion(
        uuid: 'q1',
        questionType: 'direct',
        trapType: 'semantic_shift',
      );
      expect(
        ConfidencePromptPolicy.shouldPrompt(
          prefs: prefs,
          question: q,
          session: session(),
          lifetimeScoredAttempts: 500,
          weakTopicKeys: {},
        ),
        isTrue,
      );
    });

    test('negative framing triggers prompt', () {
      final q = buildTestQuestion(
        uuid: 'q1',
        questionType: 'direct',
        negativeFraming: true,
      );
      expect(
        ConfidencePromptPolicy.shouldPrompt(
          prefs: prefs,
          question: q,
          session: session(),
          lifetimeScoredAttempts: 500,
          weakTopicKeys: {},
        ),
        isTrue,
      );
    });

    test('hard question types trigger prompt', () {
      for (final qt in [
        'multi-statement-correct',
        'assertion-reason',
        'match-the-column',
      ]) {
        final q = buildTestQuestion(uuid: 'q-$qt', questionType: qt);
        expect(
          ConfidencePromptPolicy.shouldPrompt(
            prefs: prefs,
            question: q,
            session: session(),
            lifetimeScoredAttempts: 500,
            weakTopicKeys: {},
          ),
          isTrue,
          reason: qt,
        );
      }
    });

    test('weak topic key triggers prompt', () {
      final q = buildTestQuestion(
        uuid: 'q1',
        subject: 'ancient_history',
        topic: 'WeakTopic',
        questionType: 'direct',
      );
      expect(
        ConfidencePromptPolicy.shouldPrompt(
          prefs: prefs,
          question: q,
          session: session(),
          lifetimeScoredAttempts: 500,
          weakTopicKeys: {'ancient_history||WeakTopic'},
        ),
        isTrue,
      );
    });
  });
}
