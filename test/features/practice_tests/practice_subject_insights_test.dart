import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/practice_tests/domain/practice_subject_insights.dart';

PracticeTopicRollup _topic({
  required String topic,
  int sureWrong = 0,
  int sureCorrect = 0,
  int educatedGuessWrong = 0,
  int educatedGuessCorrect = 0,
}) {
  return PracticeTopicRollup(
    topic: topic,
    sureWrong: sureWrong,
    sureCorrect: sureCorrect,
    educatedGuessWrong: educatedGuessWrong,
    educatedGuessCorrect: educatedGuessCorrect,
  );
}

void main() {
  test('attempt more needs 3 educated guesses and 70 percent correct', () {
    expect(
      isAttemptMoreTopic(
        _topic(topic: 'a', educatedGuessCorrect: 2, educatedGuessWrong: 0),
      ),
      isFalse,
    );
    expect(
      isAttemptMoreTopic(
        _topic(topic: 'a', educatedGuessCorrect: 2, educatedGuessWrong: 1),
      ),
      isFalse,
    );
    expect(
      isAttemptMoreTopic(
        _topic(topic: 'a', educatedGuessCorrect: 3, educatedGuessWrong: 0),
      ),
      isTrue,
    );
    expect(
      isAttemptMoreTopic(
        _topic(topic: 'a', educatedGuessCorrect: 7, educatedGuessWrong: 3),
      ),
      isTrue,
    );
  });

  test('sure answers alone do not make a topic attempt-more', () {
    expect(isAttemptMoreTopic(_topic(topic: 'a', sureWrong: 8)), isFalse);
  });

  test('guess-correct needed keeps the 70 percent bar', () {
    expect(guessCorrectNeeded(0), 3);
    expect(guessCorrectNeeded(1), 3);
    expect(guessCorrectNeeded(2), 5);
    expect(guessCorrectNeeded(3), 7);
  });

  test('lists rank mistakes by count and guesses by hit rate', () {
    final insights = assemblePracticeSubjectInsights(
      displayNames: const {'parliament': 'Parliament', 'rights': 'Rights'},
      topics: [
        _topic(
          topic: 'rights',
          sureWrong: 1,
          educatedGuessCorrect: 3,
          educatedGuessWrong: 0,
        ),
        _topic(
          topic: 'parliament',
          sureWrong: 4,
          educatedGuessWrong: 2,
          educatedGuessCorrect: 1,
        ),
      ],
    );

    expect(insights.confidentWrongCount, 7);
    expect(insights.mistakes.map((t) => t.topicKey), ['parliament', 'rights']);
    expect(insights.attemptMore.map((t) => t.topicKey), ['rights']);
    expect(insights.attemptMore.single.guessCorrect, 3);
    expect(insights.attemptMore.single.guessTotal, 3);
    expect(insights.sureWrong, 5);
    expect(insights.rightGuessPercent, closeTo(66.67, 0.01));
    expect(insights.confidentWrongPercent, closeTo(63.64, 0.01));
  });

  test('sure band uses 40 percent wrong and a sample floor', () {
    expect(sureBandFor(correct: 4, wrong: 1, minSample: 6), InsightBand.thin);
    expect(sureBandFor(correct: 6, wrong: 4), InsightBand.bad);
    expect(sureBandFor(correct: 3, wrong: 3), InsightBand.bad);
    expect(sureBandFor(correct: 9, wrong: 1), InsightBand.good);
    expect(sureBandFor(correct: 7, wrong: 3), InsightBand.mixed);
  });

  test('guess band uses 33 and 70 percent, not a 50-50 vote', () {
    expect(guessBandFor(correct: 4, wrong: 6), InsightBand.mixed);
    expect(guessBandFor(correct: 2, wrong: 8), InsightBand.bad);
    expect(guessBandFor(correct: 7, wrong: 3), InsightBand.good);
    expect(guessBandFor(correct: 2, wrong: 1), InsightBand.mixed);
  });

  test('lens lists keep sure and educated-guess separate', () {
    final insights = assemblePracticeSubjectInsights(
      displayNames: const {
        'parliament': 'Parliament',
        'rights': 'Rights',
        'thin': 'Thin',
      },
      topics: [
        _topic(topic: 'parliament', sureCorrect: 2, sureWrong: 6),
        _topic(
          topic: 'rights',
          sureCorrect: 8,
          sureWrong: 1,
          educatedGuessCorrect: 7,
          educatedGuessWrong: 1,
        ),
        _topic(topic: 'thin', sureCorrect: 1, educatedGuessCorrect: 2),
      ],
    );

    expect(insights.sureBand, InsightBand.mixed);
    expect(insights.guessBand, InsightBand.good);
    expect(insights.sureTopics.map((t) => t.topicKey), [
      'parliament',
      'rights',
    ]);
    expect(insights.sureTopics.first.band, InsightBand.bad);
    expect(insights.guessTopics.map((t) => t.topicKey), ['rights']);
    expect(insights.guessTopics.single.band, InsightBand.good);
  });
}
