import 'package:drift/drift.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/user_db.dart';
import '../../../core/domain/entities/answer_confidence.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../subject_detail/domain/subject_overview_row.dart';
import '../../subject_detail/providers/all_subjects_overview_provider.dart';
import '../../subject_detail/providers/subject_danger_zone_revise_uuids.dart';

/// Shared signals for Did You Know and Today's Plan relevance.
class HomeRecommendationSnapshot {
  const HomeRecommendationSnapshot({
    required this.revisionQueueCount,
    required this.confidentMistakeCount,
    required this.completedSessionCount,
    required this.wrongAnswerCount,
    this.weakestSubject,
    this.currentFocusSubject,
    this.currentFocusMistakeUuids = const [],
  });

  final int revisionQueueCount;
  final int confidentMistakeCount;
  final int completedSessionCount;
  final int wrongAnswerCount;
  final SubjectOverviewRow? weakestSubject;
  final String? currentFocusSubject;
  final List<String> currentFocusMistakeUuids;

  bool get hasCurrentFocus =>
      currentFocusSubject != null &&
      currentFocusSubject!.isNotEmpty &&
      currentFocusSubject != 'revision_quick' &&
      currentFocusMistakeUuids.isNotEmpty;

  bool get hasWeakAreaCandidate {
    final w = weakestSubject;
    return w != null &&
        w.totalAttempted >= kWeakAreaMinAttempts &&
        w.accuracyPercent != null &&
        w.accuracyPercent! < kWeakAreaMaxAccuracyPercent;
  }

  /// Weak area is redundant when Today's Plan already targets the same subject.
  bool get hasDistinctWeakArea {
    if (!hasWeakAreaCandidate) return false;
    if (currentFocusSubject == null) return true;
    return weakestSubject!.subject != currentFocusSubject;
  }
}

const kDidYouKnowRevisionQueueMinCount = 10;
const kWeakAreaMinAttempts = 5;
const kWeakAreaMaxAccuracyPercent = 50;
const kDidYouKnowBattlesMinCompletedSessions = 2;

final homeRecommendationSnapshotProvider =
    FutureProvider.autoDispose<HomeRecommendationSnapshot>((ref) async {
      final db = ref.watch(userDatabaseProvider);
      final home = await ref.watch(homeStateProvider.future);
      final overview = await ref.watch(allSubjectsOverviewProvider.future);

      final completedSessionCount = await db.sessionsDao.countCompletedSessions();
      final revisionQueueCount =
          await db.revisionQueueDao.watchActiveQueueCount().first;
      final confidentMistakeCount = await _countConfidentMistakes(db);
      final wrongAnswerCount = await _countWrongAnswers(db);

      SubjectOverviewRow? weakest;
      for (final row in overview) {
        if (!row.hasAttempts) continue;
        if (row.accuracyPercent == null) continue;
        if (row.accuracyPercent! >= kWeakAreaMaxAccuracyPercent) continue;
        if (weakest == null || row.accuracyPercent! < weakest.accuracyPercent!) {
          weakest = row;
        }
      }

      String? currentFocusSubject;
      List<String> currentFocusMistakeUuids = const [];
      final focusSubject = home.lastSession?.subject;
      if (focusSubject != null &&
          focusSubject.isNotEmpty &&
          focusSubject != 'revision_quick') {
        final uuids = await querySubjectDangerZoneReviseUuids(
          db,
          subject: focusSubject,
          confidence: AnswerConfidence.verySure,
        );
        if (uuids.isNotEmpty) {
          currentFocusSubject = focusSubject;
          currentFocusMistakeUuids = uuids;
        }
      }

      return HomeRecommendationSnapshot(
        revisionQueueCount: revisionQueueCount,
        confidentMistakeCount: confidentMistakeCount,
        completedSessionCount: completedSessionCount,
        wrongAnswerCount: wrongAnswerCount,
        weakestSubject: weakest,
        currentFocusSubject: currentFocusSubject,
        currentFocusMistakeUuids: currentFocusMistakeUuids,
      );
    });

Future<int> _countConfidentMistakes(UserDatabase db) async {
  final row = await db
      .customSelect(
        '''
        SELECT COUNT(DISTINCT a.question_uuid) AS c
        FROM attempts a
        WHERE a.is_correct = 0
          AND a.attempted_at IS NOT NULL
          AND a.confidence = ?
        ''',
        variables: [Variable.withString(AnswerConfidence.verySure)],
        readsFrom: {db.sessionQuestions},
      )
      .getSingle();
  return row.read<int?>('c') ?? 0;
}

Future<int> _countWrongAnswers(UserDatabase db) async {
  final row = await db
      .customSelect(
        '''
        SELECT COUNT(*) AS c
        FROM attempts
        WHERE is_correct = 0
          AND status IN ('correct', 'wrong')
        ''',
        readsFrom: {db.sessionQuestions},
      )
      .getSingle();
  return row.read<int?>('c') ?? 0;
}
