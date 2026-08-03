import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/activation_journey_constants.dart';

/// State for the 3-step home activation checklist.
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

  /// Todo 1: demo diagnostic submitted, or any completed session.
  final bool demoOrFirstTestDone;

  /// Scored answers (correct + wrong). Demo is ephemeral, so excluded.
  final int scoredAttempts;

  final bool confidenceMapOpened;
  final bool gamesOpened;

  /// Best subject to open for Todo 2 (most attempts), or null.
  final String? topSubjectSlug;

  /// Show the checklist block on home.
  final bool shouldShowChecklist;

  /// Collapse Daily War / hide prepare dock + daily drill on home.
  final bool shouldMuteDailyWar;

  int get unlockThreshold =>
      ActivationJourneyConstants.confidenceMapUnlockAttempts;

  bool get todo1Done => demoOrFirstTestDone;

  bool get todo2Unlocked => scoredAttempts >= unlockThreshold;

  bool get todo2Done => confidenceMapOpened;

  bool get todo3Done => gamesOpened;

  int get attemptsTowardUnlock =>
      scoredAttempts.clamp(0, unlockThreshold);

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

  final shouldShowChecklist = !dismissed &&
      (!unlocked || !confidenceMapOpened);

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

/// Marks Todo 2 opened and dismisses the journey once unlocked.
Future<void> markActivationConfidenceMapOpened(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.activationConfidenceMapOpened = true;
  prefs.activationJourneyDismissed = true;
  ref.invalidate(prefsServiceProvider);
  ref.invalidate(homeActivationJourneyProvider);
}

/// Marks Todo 3 (games) as done — checklist may still show until Todo 2.
Future<void> markActivationGamesOpened(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  if (prefs.activationGamesOpened) return;
  prefs.activationGamesOpened = true;
  ref.invalidate(prefsServiceProvider);
  ref.invalidate(homeActivationJourneyProvider);
}
