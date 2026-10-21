import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/database/user_db.dart';
import '../domain/practice_scope.dart';
import '../domain/practice_season.dart';
import '../providers/practice_catalog_provider.dart';

const _uuid = Uuid();

/// Fills a few numbered tests with submitted answers so Stats has something
/// to draw in a debug build. Runs once; real submits are left alone.
Future<bool> seedPracticeDemoAttempts(
  UserDatabase db, {
  required DateTime prelimsDate,
}) async {
  if (!kDebugMode) return false;
  final season = practiceSeasonAt(prelimsDate, DateTime.now());
  final already = await db.sessionsDao.hasCompletedPracticeTestsForSeason(
    season.year,
  );
  if (already) return false;
  final catalog = await loadPracticeCatalog(db, season: season, language: 'en');
  final now = DateTime.now();

  await db.transaction(() async {
    for (var s = 0; s < SubjectConstants.ordered.length; s++) {
      final slug = SubjectConstants.ordered[s].slug;
      final subjectRate = _subjectRate(s);
      final subjectTests = catalog.subjectTests[slug] ?? const <PracticeTest>[];
      final take = 3 + (s % 3);
      for (final test in subjectTests.take(take)) {
        await _submit(
          db,
          subject: slug,
          topic: null,
          test: test,
          accuracy: subjectRate,
          now: now,
        );
      }

      final topics = (catalog.topicTests[slug] ?? const {}).entries
          .where((e) => e.value.isNotEmpty && e.value.first.questionCount >= 4)
          .take(3)
          .toList();
      const topicRates = [0.38, 0.7, 0.91];
      for (var i = 0; i < topics.length; i++) {
        await _submit(
          db,
          subject: slug,
          topic: topics[i].key,
          test: topics[i].value.first,
          accuracy: topicRates[i],
          now: now,
        );
      }
    }
  });
  return true;
}

double _subjectRate(int index) {
  const rates = [0.44, 0.66, 0.88, 0.52, 0.74, 0.41, 0.83, 0.61];
  return rates[index % rates.length];
}

Future<void> _submit(
  UserDatabase db, {
  required String subject,
  required String? topic,
  required PracticeTest test,
  required double accuracy,
  required DateTime now,
}) async {
  if (test.uuids.isEmpty) return;
  final sessionId = _uuid.v4();
  var correct = 0;
  final rows = <SessionQuestionsCompanion>[];
  for (var i = 0; i < test.uuids.length; i++) {
    final isCorrect = ((i * 17) % 100) < (accuracy * 100).round();
    if (isCorrect) correct++;
    final confidence = isCorrect
        ? 'very_sure'
        : (i % 2 == 0 ? 'very_sure' : 'somewhat_sure');
    rows.add(
      SessionQuestionsCompanion.insert(
        id: _uuid.v4(),
        sessionId: sessionId,
        questionUuid: test.uuids[i],
        position: i + 1,
        selectedOption: Value(isCorrect ? 'a' : 'c'),
        isCorrect: Value(isCorrect),
        status: Value(isCorrect ? 'correct' : 'wrong'),
        attemptedAt: Value(now),
        confidence: Value(confidence),
      ),
    );
  }
  await db.sessionsDao.insertSession(
    SessionsCompanion.insert(
      id: sessionId,
      createdAt: now,
      completedAt: Value(now),
      subject: subject,
      topic: Value(topic),
      mode: 'learning',
      status: 'completed',
      questionCount: test.uuids.length,
      score: Value(correct),
      isTimed: false,
      language: const Value('en'),
      analyticsFeatureKey: const Value('practice_demo_seed'),
      practiceTestId: Value(test.testId),
      synced: const Value(true),
      backedUpAt: Value(now),
    ),
  );
  for (final row in rows) {
    await db.sessionQuestionsDao.insertSessionQuestion(row);
  }
}
