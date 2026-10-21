import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/prelims_countdown.dart';
import '../../../core/database/user_db.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prelims_date_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/practice_scope.dart';
import '../domain/practice_season.dart';
import '../domain/practice_test_splitter.dart';

class PracticeCatalog {
  const PracticeCatalog({
    required this.season,
    required this.subjectTests,
    required this.topicTests,
    required this.subjectProgress,
    required this.topicProgress,
    required this.topicDisplayNames,
  });

  final PracticeSeason season;
  final Map<String, List<PracticeTest>> subjectTests;
  final Map<String, Map<String, List<PracticeTest>>> topicTests;
  final Map<String, PracticeScopeProgress> subjectProgress;
  final Map<String, Map<String, PracticeScopeProgress>> topicProgress;

  /// English topic name → name in the current app language.
  final Map<String, String> topicDisplayNames;

  List<PracticeTest> testsFor(PracticeScope scope) {
    if (scope.topic == null) {
      return subjectTests[scope.subject] ?? const [];
    }
    return topicTests[scope.subject]?[scope.topic] ?? const [];
  }

  PracticeScopeProgress progressFor(PracticeScope scope) {
    if (scope.topic == null) {
      return subjectProgress[scope.subject] ?? PracticeScopeProgress.empty;
    }
    return topicProgress[scope.subject]?[scope.topic] ??
        PracticeScopeProgress.empty;
  }
}

final practiceCatalogProvider = FutureProvider<PracticeCatalog>((ref) async {
  final prelims =
      ref.watch(prelimsDateProvider).value ?? PrelimsCountdown.prelimsDate;
  final season = practiceSeasonAt(prelims, DateTime.now());
  final db = ref.watch(userDatabaseProvider);
  final language = await ref.watch(appLanguageProvider.future);
  return loadPracticeCatalog(db, season: season, language: language);
});

Future<PracticeCatalog> loadPracticeCatalog(
  UserDatabase db, {
  required PracticeSeason season,
  required String language,
}) async {
  final locations = await db.questionsDao.getStaticQuestionLocations();
  final bySubject = <String, List<String>>{};
  final byTopic = <String, Map<String, List<String>>>{};
  for (final loc in locations) {
    bySubject.putIfAbsent(loc.subject, () => []).add(loc.uuid);
    byTopic
        .putIfAbsent(loc.subject, () => {})
        .putIfAbsent(loc.topic, () => [])
        .add(loc.uuid);
  }

  final prefix = '${season.year}/';
  final done = await db.sessionsDao.latestCompletedByPracticeTestIdPrefix(
    prefix,
  );
  final running = await db.sessionsDao.inProgressByPracticeTestIdPrefix(prefix);
  final coverage = await db.sessionQuestionsDao.getSeasonCoverage(season.start);
  final correctByUuid = {
    for (final row in coverage) row.questionUuid: row.isCorrect,
  };

  final names = <String, String>{};
  if (language == 'hi') {
    final translations = await db.select(db.topicTranslations).get();
    for (final row in translations) {
      names[row.englishName] = row.hindiName;
    }
  }

  List<PracticeTest> buildTests(
    String scope,
    List<String> uuids, {
    required int maxTests,
  }) {
    final groups = splitIntoTests(
      season: season.year,
      scope: scope,
      uuids: uuids,
      maxTests: maxTests,
    );
    return [
      for (var i = 0; i < groups.length; i++)
        _test(
          season: season.year,
          scope: scope,
          number: i + 1,
          uuids: groups[i],
          done: done,
          running: running,
        ),
    ];
  }

  PracticeScopeProgress progressOf(
    List<PracticeTest> tests,
    List<String> uuids,
  ) {
    var answered = 0;
    var correct = 0;
    for (final id in uuids) {
      final hit = correctByUuid[id];
      if (hit == null) continue;
      answered++;
      if (hit) correct++;
    }
    return PracticeScopeProgress(
      testsDone: tests.where((t) => t.isDone).length,
      testsTotal: tests.length,
      poolSize: uuids.length,
      answered: answered,
      correct: correct,
    );
  }

  final subjectTests = <String, List<PracticeTest>>{};
  final subjectProgress = <String, PracticeScopeProgress>{};
  for (final entry in bySubject.entries) {
    final scope = PracticeScope.subject(entry.key).key;
    final tests = buildTests(
      scope,
      entry.value,
      maxTests: maxSubjectPracticeTests,
    );
    subjectTests[entry.key] = tests;
    subjectProgress[entry.key] = progressOf(tests, [
      for (final test in tests) ...test.uuids,
    ]);
  }

  final topicTests = <String, Map<String, List<PracticeTest>>>{};
  final topicProgress = <String, Map<String, PracticeScopeProgress>>{};
  for (final subjectEntry in byTopic.entries) {
    final testsForSubject = <String, List<PracticeTest>>{};
    final progressForSubject = <String, PracticeScopeProgress>{};
    for (final topicEntry in subjectEntry.value.entries) {
      final scope = PracticeScope.topic(subjectEntry.key, topicEntry.key).key;
      final tests = buildTests(
        scope,
        topicEntry.value,
        maxTests: maxTopicPracticeTests,
      );
      testsForSubject[topicEntry.key] = tests;
      progressForSubject[topicEntry.key] = progressOf(tests, [
        for (final test in tests) ...test.uuids,
      ]);
      names.putIfAbsent(topicEntry.key, () => topicEntry.key);
    }
    topicTests[subjectEntry.key] = testsForSubject;
    topicProgress[subjectEntry.key] = progressForSubject;
  }

  return PracticeCatalog(
    season: season,
    subjectTests: subjectTests,
    topicTests: topicTests,
    subjectProgress: subjectProgress,
    topicProgress: topicProgress,
    topicDisplayNames: names,
  );
}

PracticeTest _test({
  required int season,
  required String scope,
  required int number,
  required List<String> uuids,
  required Map<String, PracticeTestCompletionRow> done,
  required Map<String, String> running,
}) {
  final id = practiceTestId(season, scope, number);
  final completion = done[id];
  return PracticeTest(
    number: number,
    testId: id,
    uuids: uuids,
    inProgressSessionId: running[id],
    lastCompleted: completion == null
        ? null
        : PracticeCompletion(
            sessionId: completion.sessionId,
            score: completion.score,
            questionCount: completion.questionCount,
            completedAt: completion.completedAt,
          ),
  );
}
