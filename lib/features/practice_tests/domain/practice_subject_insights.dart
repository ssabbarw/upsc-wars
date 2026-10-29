import '../../subject_detail/domain/subject_mcq_pattern.dart';

export '../../subject_detail/domain/subject_mcq_pattern.dart';

/// Rules for the practice subject snapshot and the screen it opens.
abstract final class PracticeInsightRules {
  /// Educated-guess answers a topic needs before it can be "attempt more".
  static const attemptMoreMinGuesses = 3;

  /// Share of those guesses that must be correct, 0–100.
  static const attemptMoreMinPercent = 70;

  /// Subject-level verdict needs this many Sure answers.
  static const sureMinSubject = 6;

  /// Topic list includes Sure after this many.
  static const sureMinTopic = 3;

  /// Subject-level guess verdict needs this many Educated guesses.
  static const guessMinSubject = 6;

  /// Topic list includes Educated guesses after this many.
  static const guessMinTopic = 3;

  /// Sure is "often false" at or above this wrong share, 0–100.
  static const sureBadWrongPercent = 40;

  /// Sure is "holding" below this wrong share, 0–100.
  static const sureGoodWrongPercent = 20;

  /// Educated guesses are not paying off below this right share, 0–100.
  static const guessBadRightPercent = 33;
}

/// Thin = not enough answers yet.
enum InsightBand { thin, bad, mixed, good }

/// One topic's Sure wrongs and Educated-guess results for the season.
class PracticeTopicRollup {
  const PracticeTopicRollup({
    required this.topic,
    required this.sureWrong,
    this.sureCorrect = 0,
    required this.educatedGuessWrong,
    required this.educatedGuessCorrect,
  });

  final String topic;
  final int sureWrong;
  final int sureCorrect;
  final int educatedGuessWrong;
  final int educatedGuessCorrect;

  int get sureTotal => sureWrong + sureCorrect;

  int get confidentWrong => sureWrong + educatedGuessWrong;

  int get educatedGuessTotal => educatedGuessWrong + educatedGuessCorrect;
}

/// Topic where Sure or Educated-guess answers were wrong.
class ConfidentMistakeTopic {
  const ConfidentMistakeTopic({
    required this.topicKey,
    required this.displayName,
    required this.sureWrong,
    required this.educatedGuessWrong,
  });

  final String topicKey;
  final String displayName;
  final int sureWrong;
  final int educatedGuessWrong;

  int get total => sureWrong + educatedGuessWrong;
}

/// Topic where Educated guesses are right often enough to attempt more.
class AttemptMoreTopic {
  const AttemptMoreTopic({
    required this.topicKey,
    required this.displayName,
    required this.guessCorrect,
    required this.guessTotal,
  });

  final String topicKey;
  final String displayName;
  final int guessCorrect;
  final int guessTotal;

  double get ratePercent =>
      guessTotal == 0 ? 0 : (100 * guessCorrect / guessTotal);
}

/// One topic inside a Sure or Educated-guess lens.
class LensTopic {
  const LensTopic({
    required this.topicKey,
    required this.displayName,
    required this.correct,
    required this.wrong,
    required this.band,
  });

  final String topicKey;
  final String displayName;
  final int correct;
  final int wrong;
  final InsightBand band;

  int get total => correct + wrong;

  double get rightRate => total == 0 ? 0 : 100 * correct / total;

  double get wrongRate => total == 0 ? 0 : 100 * wrong / total;
}

/// Season insights for one practice subject.
class PracticeSubjectInsights {
  const PracticeSubjectInsights({
    required this.mistakes,
    required this.attemptMore,
    this.sureTotal = 0,
    this.sureWrong = 0,
    this.educatedGuessTotal = 0,
    this.educatedGuessCorrect = 0,
    this.educatedGuessWrong = 0,
    this.sureTopics = const [],
    this.guessTopics = const [],
    this.surePatterns = const [],
    this.guessPatterns = const [],
  });

  final List<ConfidentMistakeTopic> mistakes;
  final List<AttemptMoreTopic> attemptMore;
  final int sureTotal;
  final int sureWrong;
  final int educatedGuessTotal;
  final int educatedGuessCorrect;
  final int educatedGuessWrong;
  final List<LensTopic> sureTopics;
  final List<LensTopic> guessTopics;
  final List<SubjectMcqPatternStat> surePatterns;
  final List<SubjectMcqPatternStat> guessPatterns;

  int get sureCorrect => (sureTotal - sureWrong).clamp(0, sureTotal);

  InsightBand get sureBand => sureBandFor(
    correct: sureCorrect,
    wrong: sureWrong,
    minSample: PracticeInsightRules.sureMinSubject,
  );

  InsightBand get guessBand => guessBandFor(
    correct: educatedGuessCorrect,
    wrong: educatedGuessWrong,
    minSample: PracticeInsightRules.guessMinSubject,
  );

  /// Sure + Educated-guess answers that were wrong, across every topic.
  int get confidentWrongCount => sureWrong + educatedGuessWrong;

  int get confidentTotal => sureTotal + educatedGuessTotal;

  /// Share of Sure / Educated-guess answers that were wrong, 0–100.
  double? get confidentWrongPercent =>
      confidentTotal == 0 ? null : 100 * confidentWrongCount / confidentTotal;

  /// Share of Educated guesses that were right, 0–100.
  double? get rightGuessPercent => educatedGuessTotal == 0
      ? null
      : 100 * educatedGuessCorrect / educatedGuessTotal;

  double? get sureRightPercent =>
      sureTotal == 0 ? null : 100 * sureCorrect / sureTotal;

  static const empty = PracticeSubjectInsights(mistakes: [], attemptMore: []);
}

InsightBand sureBandFor({
  required int correct,
  required int wrong,
  int minSample = PracticeInsightRules.sureMinTopic,
}) {
  final total = correct + wrong;
  if (total < minSample) return InsightBand.thin;
  final wrongRate = 100 * wrong / total;
  if (wrongRate >= PracticeInsightRules.sureBadWrongPercent ||
      wrong >= correct) {
    return InsightBand.bad;
  }
  if (wrongRate < PracticeInsightRules.sureGoodWrongPercent) {
    return InsightBand.good;
  }
  return InsightBand.mixed;
}

InsightBand guessBandFor({
  required int correct,
  required int wrong,
  int minSample = PracticeInsightRules.guessMinTopic,
}) {
  final total = correct + wrong;
  if (total < minSample) return InsightBand.thin;
  final rightRate = 100 * correct / total;
  if (rightRate < PracticeInsightRules.guessBadRightPercent) {
    return InsightBand.bad;
  }
  if (rightRate >= PracticeInsightRules.attemptMoreMinPercent) {
    return InsightBand.good;
  }
  return InsightBand.mixed;
}

/// True when Educated guesses in [topic] clear the attempt-more bar.
bool isAttemptMoreTopic(PracticeTopicRollup topic) {
  return guessBandFor(
        correct: topic.educatedGuessCorrect,
        wrong: topic.educatedGuessWrong,
      ) ==
      InsightBand.good;
}

/// Fewest Educated-guess correct answers so [guessWrong] still clears 70%.
int guessCorrectNeeded(int guessWrong) {
  final band = 100 - PracticeInsightRules.attemptMoreMinPercent;
  final forRate =
      (guessWrong * PracticeInsightRules.attemptMoreMinPercent + band - 1) ~/
      band;
  return forRate < PracticeInsightRules.attemptMoreMinGuesses
      ? PracticeInsightRules.attemptMoreMinGuesses
      : forRate;
}

int _bandRank(InsightBand band) {
  switch (band) {
    case InsightBand.bad:
      return 0;
    case InsightBand.mixed:
      return 1;
    case InsightBand.good:
      return 2;
    case InsightBand.thin:
      return 3;
  }
}

/// Builds the two lists from per-topic rollups.
///
/// Sure topics use Sure right vs Sure wrong. Guess topics use Educated guess
/// only: pure guesses are luck, not a reason to attempt more in the exam.
PracticeSubjectInsights assemblePracticeSubjectInsights({
  required List<PracticeTopicRollup> topics,
  required Map<String, String> displayNames,
  List<SubjectMcqPatternStat> surePatterns = const [],
  List<SubjectMcqPatternStat> guessPatterns = const [],
}) {
  final mistakes = <ConfidentMistakeTopic>[];
  final attemptMore = <AttemptMoreTopic>[];
  final sureTopics = <LensTopic>[];
  final guessTopics = <LensTopic>[];

  for (final topic in topics) {
    final name = displayNames[topic.topic] ?? topic.topic;
    if (topic.confidentWrong > 0) {
      mistakes.add(
        ConfidentMistakeTopic(
          topicKey: topic.topic,
          displayName: name,
          sureWrong: topic.sureWrong,
          educatedGuessWrong: topic.educatedGuessWrong,
        ),
      );
    }
    if (isAttemptMoreTopic(topic)) {
      attemptMore.add(
        AttemptMoreTopic(
          topicKey: topic.topic,
          displayName: name,
          guessCorrect: topic.educatedGuessCorrect,
          guessTotal: topic.educatedGuessTotal,
        ),
      );
    }
    if (topic.sureTotal >= PracticeInsightRules.sureMinTopic) {
      sureTopics.add(
        LensTopic(
          topicKey: topic.topic,
          displayName: name,
          correct: topic.sureCorrect,
          wrong: topic.sureWrong,
          band: sureBandFor(correct: topic.sureCorrect, wrong: topic.sureWrong),
        ),
      );
    }
    if (topic.educatedGuessTotal >= PracticeInsightRules.guessMinTopic) {
      guessTopics.add(
        LensTopic(
          topicKey: topic.topic,
          displayName: name,
          correct: topic.educatedGuessCorrect,
          wrong: topic.educatedGuessWrong,
          band: guessBandFor(
            correct: topic.educatedGuessCorrect,
            wrong: topic.educatedGuessWrong,
          ),
        ),
      );
    }
  }

  mistakes.sort((a, b) {
    final byCount = b.total.compareTo(a.total);
    if (byCount != 0) return byCount;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  attemptMore.sort((a, b) {
    final byRate = (b.guessCorrect * a.guessTotal).compareTo(
      a.guessCorrect * b.guessTotal,
    );
    if (byRate != 0) return byRate;
    final byVolume = b.guessTotal.compareTo(a.guessTotal);
    if (byVolume != 0) return byVolume;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  sureTopics.sort((a, b) {
    final byBand = _bandRank(a.band).compareTo(_bandRank(b.band));
    if (byBand != 0) return byBand;
    final byWrong = b.wrongRate.compareTo(a.wrongRate);
    if (byWrong != 0) return byWrong;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  guessTopics.sort((a, b) {
    final byBand = _bandRank(a.band).compareTo(_bandRank(b.band));
    if (byBand != 0) return byBand;
    final byRight = a.rightRate.compareTo(b.rightRate);
    if (byRight != 0) return byRight;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });

  var sureTotal = 0;
  var sureWrong = 0;
  var guessTotal = 0;
  var guessCorrect = 0;
  var guessWrong = 0;
  for (final topic in topics) {
    sureTotal += topic.sureTotal;
    sureWrong += topic.sureWrong;
    guessTotal += topic.educatedGuessTotal;
    guessCorrect += topic.educatedGuessCorrect;
    guessWrong += topic.educatedGuessWrong;
  }

  return PracticeSubjectInsights(
    mistakes: mistakes,
    attemptMore: attemptMore,
    sureTotal: sureTotal,
    sureWrong: sureWrong,
    educatedGuessTotal: guessTotal,
    educatedGuessCorrect: guessCorrect,
    educatedGuessWrong: guessWrong,
    sureTopics: sureTopics,
    guessTopics: guessTopics,
    surePatterns: surePatterns,
    guessPatterns: guessPatterns,
  );
}
