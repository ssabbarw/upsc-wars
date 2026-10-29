import 'subject_trap_stat.dart';

export 'subject_trap_stat.dart';

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

  /// Revise tab includes a topic after this many scored answers.
  static const reviseMinTopic = 3;

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
    this.allCorrect,
    this.allWrong,
  });

  final String topic;
  final int sureWrong;
  final int sureCorrect;
  final int educatedGuessWrong;
  final int educatedGuessCorrect;
  final int? allCorrect;
  final int? allWrong;

  int get sureTotal => sureWrong + sureCorrect;

  int get confidentWrong => sureWrong + educatedGuessWrong;

  int get educatedGuessTotal => educatedGuessWrong + educatedGuessCorrect;

  int get overallCorrect => allCorrect ?? sureCorrect + educatedGuessCorrect;

  int get overallWrong => allWrong ?? sureWrong + educatedGuessWrong;

  int get overallTotal => overallCorrect + overallWrong;
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
    this.reviseTopics = const [],
    this.sureTopics = const [],
    this.guessTopics = const [],
    this.sureTraps = const [],
    this.guessTraps = const [],
  });

  final List<ConfidentMistakeTopic> mistakes;
  final List<AttemptMoreTopic> attemptMore;
  final int sureTotal;
  final int sureWrong;
  final int educatedGuessTotal;
  final int educatedGuessCorrect;
  final int educatedGuessWrong;
  final List<LensTopic> reviseTopics;
  final List<LensTopic> sureTopics;
  final List<LensTopic> guessTopics;
  final List<SubjectTrapStat> sureTraps;
  final List<SubjectTrapStat> guessTraps;

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

/// Net Prelims marks from Educated guesses: +2 correct, −2/3 wrong.
enum GuessNetVerdict { negative, positive }

/// Null when there are no guesses, or marks sit at break-even.
GuessNetVerdict? guessNetVerdict({required int correct, required int wrong}) {
  if (correct + wrong <= 0) return null;
  final sign = 3 * correct - wrong;
  if (sign < 0) return GuessNetVerdict.negative;
  if (sign > 0) return GuessNetVerdict.positive;
  return null;
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

int _byWrongRate(LensTopic a, LensTopic b) {
  final byWrong = b.wrongRate.compareTo(a.wrongRate);
  if (byWrong != 0) return byWrong;
  return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
}

/// Builds topic lists from per-topic rollups.
///
/// Revise uses every scored answer. Sure / guess lists stay on that lens.
PracticeSubjectInsights assemblePracticeSubjectInsights({
  required List<PracticeTopicRollup> topics,
  required Map<String, String> displayNames,
  List<SubjectTrapStat> sureTraps = const [],
  List<SubjectTrapStat> guessTraps = const [],
  int sureMinTopic = PracticeInsightRules.sureMinTopic,
  int guessMinTopic = PracticeInsightRules.guessMinTopic,
}) {
  final mistakes = <ConfidentMistakeTopic>[];
  final attemptMore = <AttemptMoreTopic>[];
  final reviseTopics = <LensTopic>[];
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
    if (topic.overallTotal >= PracticeInsightRules.reviseMinTopic) {
      reviseTopics.add(
        LensTopic(
          topicKey: topic.topic,
          displayName: name,
          correct: topic.overallCorrect,
          wrong: topic.overallWrong,
          band: sureBandFor(
            correct: topic.overallCorrect,
            wrong: topic.overallWrong,
          ),
        ),
      );
    }
    if (topic.sureTotal >= sureMinTopic) {
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
    if (topic.educatedGuessTotal >= guessMinTopic) {
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
  reviseTopics.sort(_byWrongRate);
  sureTopics.sort(_byWrongRate);
  guessTopics.sort(_byWrongRate);

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
    reviseTopics: reviseTopics,
    sureTopics: sureTopics,
    guessTopics: guessTopics,
    sureTraps: sureTraps,
    guessTraps: guessTraps,
  );
}
