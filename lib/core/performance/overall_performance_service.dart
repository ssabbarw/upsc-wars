import 'package:drift/drift.dart';

import '../database/user_db.dart';
import '../domain/entities/answer_confidence.dart';
import 'mentor_performance_models.dart';
import 'performance_queries.dart';

class OverallPerformanceService {
  OverallPerformanceService(this._db);
  final UserDatabase _db;

  Future<OverallPerformanceView> load() async {
    final scored = await _db
        .customSelect(
          '''
          SELECT
            COALESCE(COUNT(*), 0) AS n,
            COALESCE(SUM(CASE WHEN a.status = 'correct' THEN 1 ELSE 0 END), 0) AS c
          FROM attempts a
          WHERE a.attempted_at IS NOT NULL
            AND a.status IN ('correct', 'wrong')
          ''',
          readsFrom: {_db.sessionQuestions},
        )
        .getSingle();
    final n = scored.read<int>('n');
    final c = scored.read<int>('c');
    final acc = n == 0 ? 0.0 : 100.0 * c / n;

    final danger = await _db
        .customSelect(
          '''
          SELECT COALESCE(COUNT(*), 0) AS d
          FROM attempts a
          WHERE a.attempted_at IS NOT NULL
            AND a.status = 'wrong'
            AND a.confidence IN (?, ?)
          ''',
          variables: [
            Variable.withString(AnswerConfidence.verySure),
            Variable.withString(AnswerConfidence.somewhatSure),
          ],
          readsFrom: {_db.sessionQuestions},
        )
        .getSingle();
    final dangerCount = danger.read<int>('d');

    final guess = await _db
        .customSelect(
          '''
          SELECT
            COALESCE(COUNT(*), 0) AS n2,
            COALESCE(SUM(CASE WHEN a.status = 'correct' THEN 1 ELSE 0 END), 0) AS c2
          FROM attempts a
          WHERE a.attempted_at IS NOT NULL
            AND a.status IN ('correct', 'wrong')
            AND a.confidence = ?
          ''',
          variables: [Variable.withString(AnswerConfidence.somewhatSure)],
          readsFrom: {_db.sessionQuestions},
        )
        .getSingle();
    final gn = guess.read<int>('n2');
    final gc = guess.read<int>('c2');
    final guessAcc = gn == 0 ? 0.0 : 100.0 * gc / gn;

    final revN = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM revision_queue WHERE has_graduated_from_queue = 0',
          readsFrom: {_db.revisionQueue},
        )
        .getSingle();
    final revisionPending = revN.read<int>('c');

    final subjAcc = await _db
        .customSelect(
          '''
          SELECT
            q.subject AS s,
            COALESCE(COUNT(*), 0) AS n3,
            COALESCE(SUM(CASE WHEN a.status = 'correct' THEN 1 ELSE 0 END), 0) AS c3
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE a.attempted_at IS NOT NULL
            AND a.status IN ('correct', 'wrong')
          GROUP BY q.subject
          ''',
          readsFrom: {_db.sessionQuestions, _db.questions},
        )
        .get();
    String? strongest;
    String? weakest;
    double? bestA;
    double? worstA;
    for (final r in subjAcc) {
      final sn = r.read<int>('n3');
      if (sn < 3) continue;
      final scor = r.read<int>('c3');
      final a = 100.0 * scor / sn;
      final sname = r.read<String>('s');
      if (bestA == null || a > bestA) {
        bestA = a;
        strongest = sname;
      }
      if (worstA == null || a < worstA) {
        worstA = a;
        weakest = sname;
      }
    }

    var score = (acc * 0.45 + (n == 0 ? 40.0 : (100 - (dangerCount / n * 100).clamp(0, 100)) * 0.5))
        .round()
        .clamp(0, 100);
    if (n < 5) score = 45;

    ReadinessBand band;
    if (score < 40) {
      band = ReadinessBand.critical;
    } else if (score < 55) {
      band = ReadinessBand.needsWork;
    } else if (score < 70) {
      band = ReadinessBand.improving;
    } else if (score < 85) {
      band = ReadinessBand.strong;
    } else {
      band = ReadinessBand.examReady;
    }

    final bySubject = <String, int>{for (final r in subjAcc) r.read<String>('s'): 0};
    var cards = <SubjectMentorCard>[];
    for (final e in bySubject.keys) {
      final health = (score * 0.7 + 20).round().clamp(0, 100);
      cards.add(
        SubjectMentorCard(
          subject: e,
          statusLine: n < 10 ? 'Building sample' : 'Track weekly',
          healthScore: health,
          oneLineInsight: n < 10
              ? 'Answer more items for a stable subject read.'
              : 'Compare topic tests vs mocks this week.',
        ),
      );
    }
    cards.sort((a, b) => a.subject.compareTo(b.subject));

    final focusTopics = <RevisionTopicRow>[];
    for (final sub in bySubject.keys.take(3)) {
      final roll = await topicRollupsForSubject(_db, sub);
      roll.sort((a, b) => b.sureWrong.compareTo(a.sureWrong));
      for (final r in roll.take(2)) {
        if (r.sureWrong >= 1) {
          focusTopics.add(RevisionTopicRow(topic: r.topic, subject: sub));
        }
      }
    }

    return OverallPerformanceView(
      readiness: ReadinessSnapshot(
        score: score,
        band: band,
        scoreChangeReasons: const [],
      ),
      quick: QuickSnapshot(
        overallAccuracyPercent: acc,
        dangerousMistakesCount: dangerCount,
        smartGuessAccuracyPercent: guessAcc,
        smartGuessAttempted: gn,
        revisionPendingCount: revisionPending,
        strongestSubject: strongest,
        weakestSubject: weakest,
      ),
      focusThisWeek: focusTopics.isEmpty
          ? null
          : 'Tighten confident mistakes in: ${focusTopics.map((e) => e.topic).toSet().take(2).join(', ')}',
      subjectCards: cards,
      focusRevisionTopics: focusTopics.take(6).toList(),
    );
  }
}
