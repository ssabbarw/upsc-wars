import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/activation_journey_constants.dart';

/// State for the 3-step home activation checklist (START HERE).
///
/// Order: (1) demo test → (2) games after step 1 → (3) danger zone at ~50 Q.
class HomeActivationJourneyState {
  const HomeActivationJourneyState({
    required this.demoOrFirstTestDone,
    required this.scoredAttempts,
    required this.confidenceMapOpened,
    required this.gamesOpened,
    required this.topSubjectSlug,
    required this.shouldShowChecklist,
    required this.shouldMuteDailyWar,
  });

  /// Step 1: demo diagnostic submitted, or any completed session.
  final bool demoOrFirstTestDone;

  /// Scored answers (correct + wrong). Demo is ephemeral, so excluded.
  final int scoredAttempts;

  final bool confidenceMapOpened;
  final bool gamesOpened;

  /// Best subject to open for the danger-zone step (most attempts), or null.
  final String? topSubjectSlug;

  /// Show the START HERE card on home.
  final bool shouldShowChecklist;

  /// Collapse Daily War on home until the danger zone unlocks.
  final bool shouldMuteDailyWar;

  int get unlockThreshold =>
      ActivationJourneyConstants.confidenceMapUnlockAttempts;

  bool get todo1Done => demoOrFirstTestDone;

  /// Games unlock after the demo / first test.
  bool get todo2Unlocked => todo1Done;

  bool get todo2Done => gamesOpened;

  bool get todo3Unlocked => scoredAttempts >= unlockThreshold;

  bool get todo3Done => confidenceMapOpened;

  bool get allDone => todo1Done && todo2Done && todo3Done;

  int get completedCount =>
      (todo1Done ? 1 : 0) + (todo2Done ? 1 : 0) + (todo3Done ? 1 : 0);

  int get attemptsTowardUnlock => scoredAttempts.clamp(0, unlockThreshold);

  int get attemptsRemaining =>
      (unlockThreshold - scoredAttempts).clamp(0, unlockThreshold);

  double get unlockProgress =>
      unlockThreshold == 0 ? 1 : attemptsTowardUnlock / unlockThreshold;
}

final homeActivationJourneyProvider =
    FutureProvider.autoDispose<HomeActivationJourneyState>((ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  final db = ref.watch(userDatabaseProvider);

  final scoredAttempts =
      await db.sessionQuestionsDao.countScoredAttempts();
  final completedSessions = await db.sessionsDao.countCompletedSessions();
  final demoDone = prefs.getStartedDiagnosticAttempted;
  final demoOrFirstTestDone = demoDone || completedSessions > 0;

  // Grandfather existing active users so we don't re-gate Daily War.
  if (!prefs.activationJourneyInitialized) {
    prefs.activationJourneyInitialized = true;
    if (scoredAttempts >=
            ActivationJourneyConstants.confidenceMapUnlockAttempts ||
        (prefs.homeActivationComplete && completedSessions >= 3)) {
      prefs.activationJourneyDismissed = true;
      prefs.activationConfidenceMapOpened = true;
    }
  }

  final confidenceMapOpened = prefs.activationConfidenceMapOpened;
  final gamesOpened =
      prefs.activationGamesOpened || prefs.memoryPairsGameDiscovered;
  final dismissed = prefs.activationJourneyDismissed;

  final unlocked = scoredAttempts >=
      ActivationJourneyConstants.confidenceMapUnlockAttempts;

  final allDone = demoOrFirstTestDone && gamesOpened && confidenceMapOpened;
  if (allDone && !dismissed) {
    prefs.activationJourneyDismissed = true;
  }

  // Stay visible until every step is complete, then disappear.
  final shouldShowChecklist = !allDone && !prefs.activationJourneyDismissed;

  final shouldMuteDailyWar = shouldShowChecklist && !unlocked;

  String? topSubjectSlug;
  if (scoredAttempts > 0) {
    final row = await db.customSelect(
      '''
      SELECT q.subject AS subject, COUNT(*) AS c
      FROM attempts a
      INNER JOIN questions q ON q.uuid = a.question_uuid
      WHERE a.status IN ('correct', 'wrong')
      GROUP BY q.subject
      ORDER BY c DESC
      LIMIT 1
      ''',
      readsFrom: {db.sessionQuestions, db.questions},
    ).getSingleOrNull();
    topSubjectSlug = row?.read<String>('subject');
  }

  return HomeActivationJourneyState(
    demoOrFirstTestDone: demoOrFirstTestDone,
    scoredAttempts: scoredAttempts,
    confidenceMapOpened: confidenceMapOpened,
    gamesOpened: gamesOpened,
    topSubjectSlug: topSubjectSlug,
    shouldShowChecklist: shouldShowChecklist,
    shouldMuteDailyWar: shouldMuteDailyWar,
  );
});

/// Marks the danger-zone step opened. Journey hides only when all 3 are done.
Future<void> markActivationConfidenceMapOpened(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.activationConfidenceMapOpened = true;
  ref.invalidate(prefsServiceProvider);
  ref.invalidate(homeActivationJourneyProvider);
}

/// Marks step 2 (games) done. Journey hides only when all 3 are done.
Future<void> markActivationGamesOpened(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  if (prefs.activationGamesOpened) return;
  prefs.activationGamesOpened = true;
  ref.invalidate(prefsServiceProvider);
  ref.invalidate(homeActivationJourneyProvider);
}
