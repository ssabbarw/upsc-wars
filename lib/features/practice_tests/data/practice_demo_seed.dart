import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/database/user_db.dart';
import '../domain/practice_scope.dart';
import '../domain/practice_season.dart';
import '../domain/practice_subject_insights.dart';
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
          plantGuessCorrect: topicRates[i] >= 0.7,
        );
      }
    }
  });
  return true;
}

/// Turns a few existing Sure-correct answers into Educated-guess correct so
/// every subject has an "attempt more" topic in a debug build. Skips subjects
/// that already qualify. Real new submits are left alone.
Future<bool> backfillEducatedGuessCorrect(UserDatabase db) async {
  if (!kDebugMode) return false;
  var changed = false;
  await db.transaction(() async {
    for (final def in SubjectConstants.ordered) {
      final topicRows = await db
          .customSelect(
            '''
            SELECT
              q.topic AS topic,
              COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' AND a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS guess_c,
              COALESCE(SUM(CASE WHEN a.confidence = 'somewhat_sure' AND a.is_correct = 0 THEN 1 ELSE 0 END), 0) AS guess_w,
              COALESCE(SUM(CASE WHEN a.confidence = 'very_sure' AND a.is_correct != 0 THEN 1 ELSE 0 END), 0) AS sure_c
            FROM attempts a
            INNER JOIN questions q ON q.uuid = a.question_uuid
            INNER JOIN sessions s ON s.id = a.session_id
            WHERE q.subject = ?
              AND s.status = 'completed'
              AND a.status IN ('correct', 'wrong')
            GROUP BY q.topic
            ''',
            variables: [Variable.withString(def.slug)],
            readsFrom: {db.sessionQuestions, db.questions, db.sessions},
          )
          .get();

      final alreadyQualifies = topicRows.any((row) {
        final guessCorrect = row.read<int>('guess_c');
        final guessWrong = row.read<int>('guess_w');
        final total = guessCorrect + guessWrong;
        return total >= PracticeInsightRules.attemptMoreMinGuesses &&
            guessCorrect * 100 >=
                total * PracticeInsightRules.attemptMoreMinPercent;
      });
      if (alreadyQualifies) continue;

      final picks = <({String topic, int need, int guessWrong})>[];
      for (final row in topicRows) {
        final topic = (row.read<String?>('topic') ?? '').trim();
        if (topic.isEmpty) continue;
        final guessWrong = row.read<int>('guess_w');
        final sureCorrect = row.read<int>('sure_c');
        final need = guessCorrectNeeded(guessWrong);
        if (sureCorrect < need) continue;
        picks.add((topic: topic, need: need, guessWrong: guessWrong));
      }
      picks.sort((a, b) => a.guessWrong.compareTo(b.guessWrong));

      var planted = 0;
      for (final pick in picks.take(2)) {
        final updated = await db.customUpdate(
          '''
          UPDATE attempts
          SET confidence = 'somewhat_sure'
          WHERE id IN (
            SELECT a.id
            FROM attempts a
            INNER JOIN questions q ON q.uuid = a.question_uuid
            WHERE q.subject = ?
              AND q.topic = ?
              AND a.status = 'correct'
              AND a.confidence = 'very_sure'
            LIMIT ${pick.need}
          )
          ''',
          variables: [
            Variable.withString(def.slug),
            Variable.withString(pick.topic),
          ],
          updates: {db.sessionQuestions},
          updateKind: UpdateKind.update,
        );
        if (updated > 0) planted++;
      }
      if (planted > 0) changed = true;
    }
  });
  return changed;
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
  bool plantGuessCorrect = false,
}) async {
  if (test.uuids.isEmpty) return;
  final sessionId = _uuid.v4();
  var correct = 0;
  final rows = <SessionQuestionsCompanion>[];
  for (var i = 0; i < test.uuids.length; i++) {
    final isCorrect = ((i * 17) % 100) < (accuracy * 100).round();
    if (isCorrect) correct++;
    final String confidence;
    if (isCorrect) {
      confidence = plantGuessCorrect && correct <= 4
          ? 'somewhat_sure'
          : 'very_sure';
    } else if (plantGuessCorrect) {
      // Keep this topic clean so Educated-guess hits stay above 70%.
      confidence = 'very_sure';
    } else {
      confidence = i % 2 == 0 ? 'very_sure' : 'somewhat_sure';
    }
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
