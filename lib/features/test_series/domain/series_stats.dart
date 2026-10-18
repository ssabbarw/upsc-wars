import '../../../core/constants/question_source_constants.dart';
import 'test_series_models.dart';

/// Dashboard subject groups. Ancient, Medieval and Art & Culture share one
/// group, matching how the static tests are bucketed.
abstract final class SeriesSubjects {
  static const scienceTech = 'science_tech';
  static const currentAffairs = 'current_affairs';
  static const internationalRelations = 'international_relations';
  static const other = 'other';

  /// Topic label used when a question has no meaningful topic of its own
  /// (empty, `default`, or just the subject name again, as in many PYQs).
  static const mixedTopics = 'Mixed topics';

  /// Display order.
  static const order = [
    ...SeriesBuckets.staticOrder,
    scienceTech,
    currentAffairs,
    internationalRelations,
    other,
  ];

  /// Groups that always get a row on the Subject-wise tab. International
  /// Relations and Other only appear once the user has answered in them.
  static const alwaysListed = [
    ...SeriesBuckets.staticOrder,
    scienceTech,
    currentAffairs,
  ];

  static String label(String id, {bool hindi = false}) {
    switch (id) {
      case scienceTech:
        return hindi ? 'विज्ञान और प्रौद्योगिकी' : 'Science & Technology';
      case currentAffairs:
        return hindi ? 'समसामयिकी' : 'Current Affairs';
      case internationalRelations:
        return hindi ? 'अंतर्राष्ट्रीय संबंध' : 'International Relations';
      case other:
        return hindi ? 'अन्य / मिश्रित' : 'Other / mixed';
      default:
        return SeriesBuckets.label(id, hindi: hindi);
    }
  }

  /// Maps a question's `gs_subject` (static, PYQ or current-affairs label)
  /// to a dashboard subject group id.
  static String groupFor(String? gsSubject) {
    final raw = (gsSubject ?? '').trim();
    if (raw.isEmpty) return other;
    final normalized = QuestionSourceConstants.normalizeGsSubject(raw);
    switch (normalized.toLowerCase()) {
      case 'polity':
        return SeriesBuckets.polity;
      case 'economy':
      case 'economics':
        return SeriesBuckets.economy;
      case 'environment':
        return SeriesBuckets.environment;
      case 'geography':
        return SeriesBuckets.geography;
      case 'modern history':
        return SeriesBuckets.modernHistory;
      case 'ancient history':
      case 'medieval history':
      case 'art and culture':
      case 'ancient history and culture':
      case 'history':
      case 'प्राचीन इतिहास और संस्कृति':
        return SeriesBuckets.historyCulture;
      case 'science & technology':
        return scienceTech;
      case 'current affairs':
        return currentAffairs;
      case 'international relations':
        return internationalRelations;
      default:
        return other;
    }
  }

  /// Group of a question. Anything that came from the current-affairs pool
  /// belongs to Current Affairs regardless of its GS subject; everything else
  /// follows its GS subject.
  static String groupForQuestion({String? gsSubject, String? sourceKind}) {
    if (sourceKind == QuestionSourceConstants.kindCurrentAffairs) {
      return currentAffairs;
    }
    return groupFor(gsSubject);
  }

  /// Topic shown for a question inside its [group].
  ///
  /// Current Affairs questions are grouped by the GS subject they cover (their
  /// own topics are far too granular to be useful). For everything else the
  /// question's topic is used, falling back to [mixedTopics] when it carries
  /// no information.
  static String topicLabel({
    required String group,
    String? gsSubject,
    String? topic,
  }) {
    final gsRaw = (gsSubject ?? '').trim();
    final gs = gsRaw.isEmpty
        ? ''
        : QuestionSourceConstants.normalizeGsSubject(gsRaw);

    if (group == currentAffairs) {
      if (gs.isEmpty || gs.toLowerCase() == 'current affairs')
        return mixedTopics;
      return gs;
    }

    final t = (topic ?? '').trim();
    if (t.isEmpty) return mixedTopics;
    final lower = t.toLowerCase();
    final redundant = {
      'default',
      'current affairs',
      gs.toLowerCase(),
      gsRaw.toLowerCase(),
      label(group).toLowerCase(),
    };
    if (redundant.contains(lower)) return mixedTopics;
    return t;
  }

  /// Case-insensitive key used to merge topics that differ only by casing.
  static String topicKey(String group, String topicLabel) =>
      '$group|${topicLabel.trim().toLowerCase()}';
}

/// One scored (first, completed) attempt of a series test.
class SeriesTestAttempt {
  const SeriesTestAttempt({
    required this.testId,
    required this.sessionId,
    required this.completedAt,
    required this.correct,
    required this.wrong,
    required this.questionCount,
  });

  final String testId;
  final String sessionId;
  final DateTime? completedAt;
  final int correct;
  final int wrong;
  final int questionCount;

  int get unanswered =>
      (questionCount - correct - wrong).clamp(0, questionCount);

  /// UPSC marking: +2 correct, -2/3 wrong.
  double get netMarks => correct * 2 - wrong * (2 / 3);

  double get maxMarks => questionCount * 2.0;

  double get accuracy {
    final answered = correct + wrong;
    return answered == 0 ? 0 : correct / answered;
  }
}

/// Aggregated answers for one (test, subject, topic, confidence) slice.
class SeriesAnswerRow {
  const SeriesAnswerRow({
    required this.testId,
    required this.gsSubject,
    required this.topic,
    required this.isCorrect,
    required this.confidence,
    required this.count,
    this.sourceKind = QuestionSourceConstants.kindStatic,
  });

  final String testId;
  final String gsSubject;
  final String topic;
  final bool isCorrect;

  /// `static` | `pyq` | `current_affairs` (the question's own pool).
  final String sourceKind;

  /// `very_sure` | `somewhat_sure` | `guessing` | null (not captured).
  final String? confidence;
  final int count;
}

/// One answered question of a completed scored test (for topic revision).
class SeriesQuestionAnswer {
  const SeriesQuestionAnswer({
    required this.uuid,
    required this.gsSubject,
    required this.topic,
    required this.sourceKind,
    required this.status,
    required this.confidence,
  });

  final String uuid;
  final String gsSubject;
  final String topic;
  final String sourceKind;

  /// `correct` | `wrong` | anything else means skipped.
  final String status;
  final String? confidence;

  bool get isCorrect => status == 'correct';
  bool get isWrong => status == 'wrong';
  bool get isConfidentWrong =>
      isWrong && (confidence == 'very_sure' || confidence == 'somewhat_sure');
}

/// Question uuids to revise for one topic: confident mistakes first, then other
/// mistakes, then skipped, then the ones answered correctly. Duplicated
/// questions (the same question in two tests) keep their worst outcome.
List<String> revisionQuestionUuids(
  List<SeriesQuestionAnswer> rows, {
  required String subjectId,
  required String topic,
  int limit = 100,
}) {
  final wantedKey = SeriesSubjects.topicKey(subjectId, topic);
  int rank(SeriesQuestionAnswer a) {
    if (a.isConfidentWrong) return 0;
    if (a.isWrong) return 1;
    if (!a.isCorrect) return 2;
    return 3;
  }

  final best = <String, SeriesQuestionAnswer>{};
  for (final row in rows) {
    final group = SeriesSubjects.groupForQuestion(
      gsSubject: row.gsSubject,
      sourceKind: row.sourceKind,
    );
    if (group != subjectId) continue;
    final label = SeriesSubjects.topicLabel(
      group: group,
      gsSubject: row.gsSubject,
      topic: row.topic,
    );
    if (SeriesSubjects.topicKey(group, label) != wantedKey) continue;
    final prev = best[row.uuid];
    if (prev == null || rank(row) < rank(prev)) best[row.uuid] = row;
  }
  final ordered = best.values.toList()
    ..sort((a, b) => rank(a).compareTo(rank(b)));
  return [for (final a in ordered.take(limit)) a.uuid];
}

class AttemptProgress {
  const AttemptProgress({required this.attempted, required this.total});

  final int attempted;
  final int total;

  double get fraction => total == 0 ? 0 : attempted / total;
}

/// How a topic reads for the learner.
class TopicStat {
  const TopicStat({
    required this.subjectId,
    required this.topic,
    required this.correct,
    required this.wrong,
    required this.confidentWrong,
    required this.mistakes,
    required this.needsRevision,
    required this.isSafe,
  });

  final String subjectId;
  final String topic;
  final int correct;
  final int wrong;

  /// Wrong answers the learner was sure (or fairly sure) about.
  final int confidentWrong;

  /// Mistakes that count towards "Needs revision": confident wrong answers, or
  /// all wrong answers when the learner never marked a confidence level.
  final int mistakes;
  final bool needsRevision;
  final bool isSafe;

  int get answered => correct + wrong;
  double get accuracy => answered == 0 ? 0 : correct / answered;
}

/// Accuracy and topic insights for one subject group.
class SubjectStat {
  const SubjectStat({
    required this.subjectId,
    required this.correct,
    required this.wrong,
    required this.tests,
    required this.topics,
  });

  final String subjectId;
  final int correct;
  final int wrong;

  /// Subject-wise test progress; null for groups with no tests of their own
  /// (Science & Technology, Current Affairs, ...).
  final AttemptProgress? tests;

  /// Every topic with answers, most mistakes first.
  final List<TopicStat> topics;

  int get answered => correct + wrong;
  double get accuracy => answered == 0 ? 0 : correct / answered;
  List<TopicStat> get needsRevision =>
      topics.where((t) => t.needsRevision).toList();
  List<TopicStat> get safeAreas => topics.where((t) => t.isSafe).toList();
}

/// Everything the dashboard shows for one set of tests (all core tests, or
/// full-length tests only).
class ScopeStats {
  const ScopeStats({
    required this.tests,
    required this.attemptCount,
    required this.correct,
    required this.wrong,
    required this.bestNet,
    required this.bestMax,
    required this.avgNet,
    required this.avgMax,
    required this.subjects,
    required this.needsRevision,
    required this.safeAreas,
    required this.useConfidence,
  });

  final AttemptProgress tests;
  final int attemptCount;
  final int correct;
  final int wrong;

  /// Marks of the best attempt (by percentage of its maximum) and that
  /// attempt's maximum. Zero when nothing is attempted.
  final double bestNet;
  final double bestMax;

  /// Average net marks across attempts and the average maximum.
  final double avgNet;
  final double avgMax;

  final List<SubjectStat> subjects;
  final List<TopicStat> needsRevision;
  final List<TopicStat> safeAreas;

  /// True when mistakes were counted from confidence (otherwise all wrong
  /// answers, because the learner never marked a confidence level).
  final bool useConfidence;

  int get answered => correct + wrong;
  double get accuracy => answered == 0 ? 0 : correct / answered;

  SubjectStat? subject(String id) {
    for (final s in subjects) {
      if (s.subjectId == id) return s;
    }
    return null;
  }
}

class SeriesStats {
  const SeriesStats({
    required this.attempts,
    required this.core,
    required this.flt,
    required this.pyqTests,
    required this.caTests,
  });

  /// First scored attempt per test id (every test kind).
  final Map<String, SeriesTestAttempt> attempts;

  /// Full-length plus subject-wise tests: what the Overview and Subject-wise
  /// views are built from.
  final ScopeStats core;

  /// Full-length tests only.
  final ScopeStats flt;

  /// Listed in the "PYQ & Current Affairs" tab; not part of the stats.
  final AttemptProgress pyqTests;
  final AttemptProgress caTests;

  AttemptProgress get overall => core.tests;
  double get overallAccuracy => core.accuracy;
  bool get hasAnyAttempt => attempts.isNotEmpty;

  static const coreKinds = {
    SeriesTestKind.staticTest,
    SeriesTestKind.fullLength,
  };
  static const fltKinds = {SeriesTestKind.fullLength};

  /// Pure computation so it can be unit tested without a database.
  static SeriesStats compute({
    required SeriesBundle bundle,
    required List<SeriesTestAttempt> attemptList,
    required List<SeriesAnswerRow> answers,
  }) {
    // One scored attempt per test: keep the earliest completed one.
    final attempts = <String, SeriesTestAttempt>{};
    for (final a in attemptList) {
      final prev = attempts[a.testId];
      if (prev == null ||
          (a.completedAt != null &&
              (prev.completedAt == null ||
                  a.completedAt!.isBefore(prev.completedAt!)))) {
        attempts[a.testId] = a;
      }
    }

    AttemptProgress progress(Iterable<SeriesTest> tests) {
      var attempted = 0;
      var total = 0;
      for (final t in tests) {
        total += 1;
        if (attempts.containsKey(t.id)) attempted += 1;
      }
      return AttemptProgress(attempted: attempted, total: total);
    }

    return SeriesStats(
      attempts: attempts,
      core: _scope(
        kinds: coreKinds,
        bundle: bundle,
        attempts: attempts,
        answers: answers,
        progress: progress,
      ),
      flt: _scope(
        kinds: fltKinds,
        bundle: bundle,
        attempts: attempts,
        answers: answers,
        progress: progress,
      ),
      pyqTests: progress(bundle.ofKind(SeriesTestKind.pyqMix)),
      caTests: progress(bundle.ofKind(SeriesTestKind.currentAffairs)),
    );
  }

  static ScopeStats _scope({
    required Set<String> kinds,
    required SeriesBundle bundle,
    required Map<String, SeriesTestAttempt> attempts,
    required List<SeriesAnswerRow> answers,
    required AttemptProgress Function(Iterable<SeriesTest>) progress,
  }) {
    final tests = bundle.tests.where((t) => kinds.contains(t.kind)).toList();
    final testIds = {for (final t in tests) t.id};

    final scoped = [
      for (final a in attempts.values)
        if (testIds.contains(a.testId)) a,
    ];
    var bestNet = 0.0;
    var bestMax = 0.0;
    var bestRatio = -1.0;
    var sumNet = 0.0;
    var sumMax = 0.0;
    for (final a in scoped) {
      sumNet += a.netMarks;
      sumMax += a.maxMarks;
      final ratio = a.maxMarks == 0 ? 0.0 : a.netMarks / a.maxMarks;
      if (ratio > bestRatio) {
        bestRatio = ratio;
        bestNet = a.netMarks;
        bestMax = a.maxMarks;
      }
    }

    // Aggregate answers per (group, topic).
    final accs = <String, _TopicAcc>{};
    var useConfidence = false;
    var correct = 0;
    var wrong = 0;
    for (final row in answers) {
      if (!testIds.contains(row.testId)) continue;
      final group = SeriesSubjects.groupForQuestion(
        gsSubject: row.gsSubject,
        sourceKind: row.sourceKind,
      );
      final label = SeriesSubjects.topicLabel(
        group: group,
        gsSubject: row.gsSubject,
        topic: row.topic,
      );
      final acc = accs.putIfAbsent(
        SeriesSubjects.topicKey(group, label),
        () => _TopicAcc(group, label),
      );
      final conf = row.confidence;
      final isConfident = conf == 'very_sure' || conf == 'somewhat_sure';
      if (isConfident || conf == 'guessing') useConfidence = true;
      acc.add(row, isConfident: isConfident);
      if (row.isCorrect) {
        correct += row.count;
      } else {
        wrong += row.count;
      }
    }

    final topicStats = [for (final a in accs.values) a.toStat(useConfidence)]
      ..sort(_byMistakes);

    final subjects = <SubjectStat>[];
    for (final id in SeriesSubjects.order) {
      final subjectTopics = topicStats.where((t) => t.subjectId == id).toList();
      var c = 0;
      var w = 0;
      for (final t in subjectTopics) {
        c += t.correct;
        w += t.wrong;
      }
      final isBucket = SeriesBuckets.staticOrder.contains(id);
      final bucketTests = isBucket
          ? tests.where(
              (t) => t.kind == SeriesTestKind.staticTest && t.bucket == id,
            )
          : const <SeriesTest>[];
      subjects.add(
        SubjectStat(
          subjectId: id,
          correct: c,
          wrong: w,
          tests: bucketTests.isEmpty ? null : progress(bucketTests),
          topics: subjectTopics,
        ),
      );
    }

    return ScopeStats(
      tests: progress(tests),
      attemptCount: scoped.length,
      correct: correct,
      wrong: wrong,
      bestNet: bestNet,
      bestMax: bestMax,
      avgNet: scoped.isEmpty ? 0 : sumNet / scoped.length,
      avgMax: scoped.isEmpty ? 0 : sumMax / scoped.length,
      subjects: subjects,
      needsRevision: topicStats.where((t) => t.needsRevision).toList(),
      safeAreas: topicStats.where((t) => t.isSafe).toList()
        ..sort((a, b) {
          final byAcc = b.accuracy.compareTo(a.accuracy);
          return byAcc != 0 ? byAcc : b.answered.compareTo(a.answered);
        }),
      useConfidence: useConfidence,
    );
  }

  static int _byMistakes(TopicStat a, TopicStat b) {
    final m = b.mistakes.compareTo(a.mistakes);
    if (m != 0) return m;
    final acc = a.accuracy.compareTo(b.accuracy);
    if (acc != 0) return acc;
    return b.answered.compareTo(a.answered);
  }
}

class _TopicAcc {
  _TopicAcc(this.subjectId, this.topic);

  final String subjectId;
  final String topic;
  int correct = 0;
  int wrong = 0;
  int confidentWrong = 0;

  void add(SeriesAnswerRow row, {required bool isConfident}) {
    if (row.isCorrect) {
      correct += row.count;
    } else {
      wrong += row.count;
      if (isConfident) confidentWrong += row.count;
    }
  }

  TopicStat toStat(bool useConfidence) {
    final mistakes = useConfidence ? confidentWrong : wrong;
    final answered = correct + wrong;
    final accuracy = answered == 0 ? 0.0 : correct / answered;
    final needsRevision = mistakes >= 2 || (mistakes >= 1 && accuracy < 0.6);
    final isSafe =
        answered >= 4 &&
        accuracy >= 0.8 &&
        !needsRevision &&
        (!useConfidence || confidentWrong == 0);
    return TopicStat(
      subjectId: subjectId,
      topic: topic,
      correct: correct,
      wrong: wrong,
      confidentWrong: confidentWrong,
      mistakes: mistakes,
      needsRevision: needsRevision,
      isSafe: isSafe,
    );
  }
}
