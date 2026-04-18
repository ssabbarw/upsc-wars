import 'package:upsc_wars/core/database/user_db.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart'
    show AnswerConfidence;
import 'package:upsc_wars/core/domain/entities/session_result.dart';
import 'package:upsc_wars/core/domain/entities/session_summary.dart';
import 'package:upsc_wars/core/domain/errors/app_errors.dart';
import 'package:upsc_wars/features/history/domain/repositories/session_history_repository.dart';

class SessionHistoryRepositoryImpl implements SessionHistoryRepository {
  const SessionHistoryRepositoryImpl(this._userDb);
  final UserDatabase _userDb;

  @override
  Future<SessionResult> getSessionResult(String sessionId) async {
    final session = await _userDb.sessionsDao.getSessionById(sessionId);
    if (session == null) throw const SessionNotFoundException();
    final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(sessionId);
    var correct = 0, wrong = 0, unattempted = 0, timedOut = 0;
    var attemptedTimeSum = 0, attemptedTimeCount = 0;
    var totalTimeSecs = 0;
    for (final r in rows) {
      if (r.timeSpentSecs != null) {
        totalTimeSecs += r.timeSpentSecs!;
      }
      if (r.status == 'correct') {
        correct++;
        if (r.timeSpentSecs != null) {
          attemptedTimeSum += r.timeSpentSecs!;
          attemptedTimeCount++;
        }
      } else if (r.status == 'wrong') {
        wrong++;
        if (r.timeSpentSecs != null) {
          attemptedTimeSum += r.timeSpentSecs!;
          attemptedTimeCount++;
        }
      } else if (r.status == 'timed_out') {
        timedOut++;
      } else {
        unattempted++;
      }
    }
    final attempted = correct + wrong;
    final accuracy = attempted == 0 ? 0.0 : (correct / attempted) * 100;
    final avg = attemptedTimeCount == 0 ? null : (attemptedTimeSum / attemptedTimeCount);

    var dangerZoneWrong = 0;
    for (final r in rows) {
      if (r.status == 'wrong' &&
          AnswerConfidence.isDangerouslyConfident(r.confidence)) {
        dangerZoneWrong++;
      }
    }
    final dangerMarks = dangerZoneWrong * 0.66;

    var sureT = 0, sureC = 0, intelT = 0, intelC = 0, pureT = 0, pureC = 0;
    for (final r in rows) {
      if (r.status != 'correct' && r.status != 'wrong') continue;
      final c = r.confidence;
      if (c == AnswerConfidence.verySure) {
        sureT++;
        if (r.status == 'correct') sureC++;
      } else if (c == AnswerConfidence.somewhatSure) {
        intelT++;
        if (r.status == 'correct') intelC++;
      } else if (c == AnswerConfidence.guessing) {
        pureT++;
        if (r.status == 'correct') pureC++;
      }
    }

    var graduatedCount = 0;
    if (session.subject == 'revision_quick') {
      for (final r in rows) {
        if (r.status == 'correct') {
          final rqItem = await _userDb.revisionQueueDao
              .getRevisionQueueItemByQuestionUuid(r.questionUuid);
          if (rqItem != null &&
              rqItem.hasGraduatedFromQueue &&
              rqItem.dateGraduated != null &&
              !rqItem.dateGraduated!.isBefore(session.createdAt)) {
            graduatedCount++;
          }
        }
      }
    }

    return SessionResult(
      sessionId: session.id,
      subject: session.subject,
      topic: session.topic,
      subTopic: session.subTopic,
      mode: session.mode,
      createdAt: session.createdAt,
      completedAt: session.completedAt,
      timeLimitSecs: session.timeLimitSecs,
      questionCount: session.questionCount,
      correct: correct,
      wrong: wrong,
      unattempted: unattempted,
      timedOut: timedOut,
      accuracy: accuracy,
      netScore: (correct * 2) - (wrong * 0.66),
      avgTimeSpentSecs: avg,
      totalTimeSpentSecs: totalTimeSecs,
      accuracyTier: _tierFor(attempted, accuracy),
      language: session.language,
      graduatedCount: graduatedCount,
      dangerZoneWrongCount: dangerZoneWrong,
      dangerZoneMarksEstimate: dangerMarks,
      confidenceSureTotal: sureT,
      confidenceSureCorrect: sureC,
      confidenceIntelligentTotal: intelT,
      confidenceIntelligentCorrect: intelC,
      confidencePureTotal: pureT,
      confidencePureCorrect: pureC,
    );
  }

  @override
  Future<List<SessionSummary>> getSessionList({String? subject, String? mode}) async {
    var sessions = await _userDb.sessionsDao.getAllSessionsOrderedByCreatedAtDesc();
    if (subject != null) sessions = sessions.where((s) => s.subject == subject).toList();
    if (mode != null) sessions = sessions.where((s) => s.mode == mode).toList();
    final out = <SessionSummary>[];
    for (final s in sessions) {
      final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(s.id);
      if (s.status == 'in_progress') {
        out.add(SessionSummary(sessionId: s.id, subject: s.subject, topic: s.topic, mode: s.mode, status: s.status, createdAt: s.createdAt, questionCount: s.questionCount, correct: null, wrong: null, accuracy: null, accuracyTier: null, netScore: null, avgTimeSpentSecs: null));
        continue;
      }
      if (s.status == 'abandoned') {
        out.add(SessionSummary(
          sessionId: s.id,
          subject: s.subject,
          topic: s.topic,
          mode: s.mode,
          status: s.status,
          createdAt: s.createdAt,
          questionCount: s.questionCount,
          correct: null,
          wrong: null,
          accuracy: null,
          accuracyTier: null,
          netScore: null,
          avgTimeSpentSecs: null,
        ));
        continue;
      }
      var correct = 0, wrong = 0, timeSum = 0, timeCount = 0;
      for (final r in rows) {
        if (r.status == 'correct') {correct++; if (r.timeSpentSecs != null) {timeSum += r.timeSpentSecs!; timeCount++;}}
        if (r.status == 'wrong') {wrong++; if (r.timeSpentSecs != null) {timeSum += r.timeSpentSecs!; timeCount++;}}
      }
      final attempted = correct + wrong;
      out.add(SessionSummary(
        sessionId: s.id,
        subject: s.subject,
        topic: s.topic,
        mode: s.mode,
        status: s.status,
        createdAt: s.createdAt,
        questionCount: s.questionCount,
        correct: correct,
        wrong: wrong,
        accuracy: attempted == 0 ? 0.0 : (correct / attempted) * 100,
        netScore: (correct * 2) - (wrong * 0.66),
        avgTimeSpentSecs: timeCount == 0 ? null : (timeSum / timeCount),
        accuracyTier: _tierFor(attempted, attempted == 0 ? 0.0 : (correct / attempted) * 100),
      ));
    }
    return out;
  }

  @override
  Future<int> getDailyProgressCount(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final sessions = await _userDb.sessionsDao.getAllSessionsOrderedByCreatedAtDesc();
    final ids = sessions.where((s) => !s.createdAt.isBefore(start) && s.createdAt.isBefore(end)).map((s) => s.id);
    var count = 0;
    for (final id in ids) {
      final rows = await _userDb.sessionQuestionsDao.getSessionQuestionsOrdered(id);
      count += rows.where((r) => r.status != 'unattempted').length;
    }
    return count;
  }
}


String _tierFor(int attempted, double accuracy) {
  if (attempted == 0) return 'dash';
  if (attempted < 10) return 'muted';
  if (accuracy >= 70) return 'high';
  if (accuracy >= 55) return 'medium';
  return 'low';
}
