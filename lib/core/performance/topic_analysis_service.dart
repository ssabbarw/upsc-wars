import 'package:drift/drift.dart';

import '../database/user_db.dart';
import '../domain/entities/answer_confidence.dart';
import 'mentor_performance_models.dart';

class TopicAnalysisService {
  TopicAnalysisService(this._db);
  final UserDatabase _db;

  Future<TopicMentorAnalysis> load(String subject, String topic) async {
    final zoneRow = await _db
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(CASE WHEN a.confidence = ? AND a.status = 'wrong' THEN 1 ELSE 0 END), 0) AS sw,
            COALESCE(SUM(CASE WHEN a.confidence = ? AND a.status = 'wrong' THEN 1 ELSE 0 END), 0) AS ew,
            COALESCE(SUM(CASE WHEN a.confidence = ? AND a.status = 'correct' THEN 1 ELSE 0 END), 0) AS sc,
            COALESCE(SUM(CASE WHEN a.confidence = ? AND a.status = 'correct' THEN 1 ELSE 0 END), 0) AS ec,
            COALESCE(SUM(CASE WHEN a.confidence = ? AND a.status = 'correct' THEN 1 ELSE 0 END), 0) AS pgc,
            COALESCE(SUM(CASE WHEN a.confidence = ? AND a.status = 'wrong' THEN 1 ELSE 0 END), 0) AS pgw
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ?
            AND q.topic = ?
            AND a.attempted_at IS NOT NULL
            AND a.status IN ('correct', 'wrong')
          ''',
          variables: [
            Variable.withString(AnswerConfidence.verySure),
            Variable.withString(AnswerConfidence.somewhatSure),
            Variable.withString(AnswerConfidence.verySure),
            Variable.withString(AnswerConfidence.somewhatSure),
            Variable.withString(AnswerConfidence.guessing),
            Variable.withString(AnswerConfidence.guessing),
            Variable.withString(subject),
            Variable.withString(topic),
          ],
          readsFrom: {_db.sessionQuestions, _db.questions},
        )
        .getSingle();

    final z = TopicZones(
      sureWrong: zoneRow.read<int>('sw'),
      educatedWrong: zoneRow.read<int>('ew'),
      sureCorrect: zoneRow.read<int>('sc'),
      educatedCorrect: zoneRow.read<int>('ec'),
      pureGuessCorrect: zoneRow.read<int>('pgc'),
      pureGuessWrong: zoneRow.read<int>('pgw'),
    );

    final since = DateTime.now().subtract(const Duration(days: 14));
    final trendRows = await _db
        .customSelect(
          '''
          SELECT
            SUM(CASE WHEN a.status = 'correct' THEN 1.0 ELSE 0.0 END) AS c,
            COUNT(*) AS n
          FROM attempts a
          INNER JOIN questions q ON q.uuid = a.question_uuid
          WHERE q.subject = ? AND q.topic = ?
            AND a.attempted_at IS NOT NULL
            AND a.status IN ('correct', 'wrong')
            AND a.attempted_at >= ?
          ''',
          variables: [
            Variable.withString(subject),
            Variable.withString(topic),
            Variable.withDateTime(since),
          ],
          readsFrom: {_db.sessionQuestions, _db.questions},
        )
        .getSingle();
    final c = trendRows.read<num>('c').toDouble();
    final n = trendRows.read<int>('n');
    final rate = n == 0 ? 0.0 : c / n;
    // Single aggregate for 14d window; show as flat “recent” line (14 points).
    final points = List.generate(14, (_) => TrendPoint(rate));

    final total = z.sureWrong +
        z.educatedWrong +
        z.sureCorrect +
        z.educatedCorrect +
        z.pureGuessCorrect +
        z.pureGuessWrong;
    final head = total < 3
        ? 'Not enough attempts yet in this topic'
        : (z.sureWrong + z.educatedWrong > z.sureCorrect + z.educatedCorrect
            ? 'Confident side needs calibration'
            : 'Solid signal on confident answers');
    final reasons = <String>[];
    if (z.sureWrong > 0) {
      reasons.add('Very-sure wrongs: ${z.sureWrong}');
    }
    if (z.educatedWrong > 0) {
      reasons.add('Educated-guess wrongs: ${z.educatedWrong}');
    }
    if (reasons.isEmpty) {
      reasons.add('No confident wrongs logged — or keep practising for signal.');
    }

    return TopicMentorAnalysis(
      statusHeadline: head,
      riskReasonLines: reasons,
      whyCopy: total < 3
          ? 'Take a 10-question test so we can split strength vs risky patterns.'
          : 'Patterns reflect how you mark confidence when answers go wrong. '
                'Tighten concepts where sure wrongs show up first.',
      zones: z,
      recommendedAction: total < 3
          ? 'Start a short topic test, then re-open this screen.'
          : 'Schedule revision on traps, then re-check this topic after 20+ new attempts.',
      correctWrongTrend14d: points,
    );
  }
}
