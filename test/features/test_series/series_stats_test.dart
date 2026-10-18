import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/test_series/domain/series_stats.dart';
import 'package:upsc_wars/features/test_series/domain/test_series_models.dart';

SeriesTest _test(String id, String kind, {String bucket = ''}) => SeriesTest(
  id: id,
  seriesId: 's',
  kind: kind,
  bucket: bucket,
  title: id,
  index: 1,
  isFree: false,
  unlockAt: DateTime(2026),
  durationMins: 60,
  questionCount: 10,
  status: 'ready',
  questions: const [],
);

SeriesTestAttempt _attempt(String testId, {int correct = 6, int wrong = 3}) =>
    SeriesTestAttempt(
      testId: testId,
      sessionId: 'sess_$testId',
      completedAt: DateTime(2026, 1, 2),
      correct: correct,
      wrong: wrong,
      questionCount: 10,
    );

SeriesAnswerRow _row(
  String testId,
  String topic, {
  required bool correct,
  int count = 1,
  String gs = 'Polity',
  String? confidence,
  String kind = 'static',
}) => SeriesAnswerRow(
  testId: testId,
  gsSubject: gs,
  topic: topic,
  isCorrect: correct,
  confidence: confidence,
  count: count,
  sourceKind: kind,
);

void main() {
  final bundle = SeriesBundle(
    info: const TestSeriesInfo(
      id: 's',
      title: 'S',
      titleHi: '',
      year: 2027,
      productId: 'p',
      entitlementId: 'e',
    ),
    tests: [
      _test(
        'static_polity_01',
        SeriesTestKind.staticTest,
        bucket: SeriesBuckets.polity,
      ),
      _test(
        'static_polity_02',
        SeriesTestKind.staticTest,
        bucket: SeriesBuckets.polity,
      ),
      _test('flt_01', SeriesTestKind.fullLength),
      _test('flt_02', SeriesTestKind.fullLength),
      _test('pyq_01', SeriesTestKind.pyqMix),
      _test('ca_01', SeriesTestKind.currentAffairs),
    ],
  );

  group('SeriesSubjects', () {
    test('current affairs question goes to its own group by source kind', () {
      expect(
        SeriesSubjects.groupForQuestion(
          gsSubject: 'Polity',
          sourceKind: 'current_affairs',
        ),
        SeriesSubjects.currentAffairs,
      );
      expect(
        SeriesSubjects.groupForQuestion(gsSubject: 'Polity', sourceKind: 'pyq'),
        SeriesBuckets.polity,
      );
      expect(
        SeriesSubjects.groupFor('Current affairs'),
        SeriesSubjects.currentAffairs,
      );
    });

    test('topic label collapses uninformative topics', () {
      String label(String topic, {String gs = 'Polity'}) =>
          SeriesSubjects.topicLabel(
            group: SeriesSubjects.groupFor(gs),
            gsSubject: gs,
            topic: topic,
          );
      expect(label('Parliament'), 'Parliament');
      expect(label(''), SeriesSubjects.mixedTopics);
      expect(label('default'), SeriesSubjects.mixedTopics);
      expect(label('Polity'), SeriesSubjects.mixedTopics);
      expect(
        label('Indian Polity & Governance', gs: 'Indian Polity & Governance'),
        SeriesSubjects.mixedTopics,
      );
    });

    test('current affairs topics are the GS subject they cover', () {
      expect(
        SeriesSubjects.topicLabel(
          group: SeriesSubjects.currentAffairs,
          gsSubject: 'Economy',
          topic: 'RBI repo rate',
        ),
        'Economy',
      );
    });
  });

  group('SeriesStats.compute', () {
    test('overall counts only full-length and subject-wise tests', () {
      final stats = SeriesStats.compute(
        bundle: bundle,
        attemptList: [
          _attempt('flt_01'),
          _attempt('static_polity_01'),
          _attempt('pyq_01'),
          _attempt('ca_01'),
        ],
        answers: [
          _row('flt_01', 'Parliament', correct: true, count: 6),
          _row('static_polity_01', 'Parliament', correct: false, count: 3),
          _row('pyq_01', 'Parliament', correct: false, count: 50),
          _row(
            'ca_01',
            'Parliament',
            correct: false,
            count: 50,
            kind: 'current_affairs',
          ),
        ],
      );
      expect(stats.core.tests.attempted, 2);
      expect(stats.core.tests.total, 4);
      expect(stats.core.correct, 6);
      expect(stats.core.wrong, 3);
      expect(stats.flt.tests.attempted, 1);
      expect(stats.flt.tests.total, 2);
      expect(stats.flt.wrong, 0);
      expect(stats.pyqTests.attempted, 1);
      expect(stats.caTests.attempted, 1);
      expect(stats.overall.attempted, 2);
    });

    test('best score is by percentage of maximum marks', () {
      final stats = SeriesStats.compute(
        bundle: bundle,
        attemptList: [
          _attempt('flt_01', correct: 5, wrong: 5),
          _attempt('flt_02', correct: 9, wrong: 1),
        ],
        answers: const [],
      );
      expect(stats.flt.bestNet, closeTo(9 * 2 - 2 / 3, 1e-9));
      expect(stats.flt.bestMax, 20);
      expect(stats.flt.attemptCount, 2);
    });

    test('without confidence data every wrong answer is a mistake', () {
      final stats = SeriesStats.compute(
        bundle: bundle,
        attemptList: [_attempt('flt_01')],
        answers: [
          _row('flt_01', 'Parliament', correct: true, count: 3),
          _row('flt_01', 'Parliament', correct: false, count: 2),
        ],
      );
      expect(stats.core.useConfidence, isFalse);
      expect(stats.core.needsRevision, hasLength(1));
      expect(stats.core.needsRevision.single.mistakes, 2);
    });

    test('with confidence data only confident wrong answers count', () {
      final stats = SeriesStats.compute(
        bundle: bundle,
        attemptList: [_attempt('flt_01')],
        answers: [
          _row(
            'flt_01',
            'Parliament',
            correct: true,
            count: 3,
            confidence: 'very_sure',
          ),
          _row(
            'flt_01',
            'Parliament',
            correct: false,
            count: 3,
            confidence: 'guessing',
          ),
          _row(
            'flt_01',
            'Federalism',
            correct: false,
            count: 2,
            confidence: 'very_sure',
          ),
        ],
      );
      expect(stats.core.useConfidence, isTrue);
      final names = stats.core.needsRevision.map((t) => t.topic).toList();
      expect(names, ['Federalism']);
      expect(stats.core.needsRevision.single.mistakes, 2);
    });

    test('safe areas need volume and accuracy and no confident mistakes', () {
      final stats = SeriesStats.compute(
        bundle: bundle,
        attemptList: [_attempt('flt_01')],
        answers: [
          _row(
            'flt_01',
            'Parliament',
            correct: true,
            count: 5,
            confidence: 'very_sure',
          ),
          _row(
            'flt_01',
            'Federalism',
            correct: true,
            count: 2,
            confidence: 'very_sure',
          ),
          _row(
            'flt_01',
            'Judiciary',
            correct: true,
            count: 8,
            confidence: 'very_sure',
          ),
          _row(
            'flt_01',
            'Judiciary',
            correct: false,
            count: 1,
            confidence: 'very_sure',
          ),
        ],
      );
      expect(stats.core.safeAreas.map((t) => t.topic), ['Parliament']);
    });

    test(
      'Science & Tech and Current Affairs rows come from full-length answers',
      () {
        final stats = SeriesStats.compute(
          bundle: bundle,
          attemptList: [_attempt('flt_01')],
          answers: [
            _row(
              'flt_01',
              'Space',
              correct: true,
              count: 4,
              gs: 'Science & Technology',
            ),
            _row(
              'flt_01',
              'x',
              correct: false,
              count: 1,
              gs: 'Economy',
              kind: 'current_affairs',
            ),
          ],
        );
        expect(stats.core.subject(SeriesSubjects.scienceTech)!.correct, 4);
        final ca = stats.core.subject(SeriesSubjects.currentAffairs)!;
        expect(ca.wrong, 1);
        expect(ca.topics.single.topic, 'Economy');
        expect(ca.tests, isNull);
        // Polity (subject tests) has 2 tests and none attempted.
        expect(stats.core.subject(SeriesBuckets.polity)!.tests!.total, 2);
      },
    );
  });

  group('revisionQuestionUuids', () {
    SeriesQuestionAnswer q(
      String uuid,
      String status, {
      String topic = 'Parliament',
      String? confidence,
    }) => SeriesQuestionAnswer(
      uuid: uuid,
      gsSubject: 'Polity',
      topic: topic,
      sourceKind: 'static',
      status: status,
      confidence: confidence,
    );

    test('orders confident mistakes first and keeps the worst outcome', () {
      final uuids = revisionQuestionUuids(
        [
          q('a', 'correct'),
          q('b', 'wrong'),
          q('c', 'wrong', confidence: 'very_sure'),
          q('d', 'skipped'),
          q('e', 'wrong', topic: 'Federalism'),
          q('a', 'wrong'), // same question, worse outcome in another test
        ],
        subjectId: SeriesBuckets.polity,
        topic: 'Parliament',
      );
      expect(uuids, ['c', 'a', 'b', 'd']);
    });

    test('respects the limit', () {
      final uuids = revisionQuestionUuids(
        [for (var i = 0; i < 10; i++) q('q$i', 'wrong')],
        subjectId: SeriesBuckets.polity,
        topic: 'Parliament',
        limit: 4,
      );
      expect(uuids, hasLength(4));
    });
  });
}
