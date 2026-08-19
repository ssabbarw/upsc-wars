import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/activation_journey_constants.dart';

String _todayYyyyMmDd() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String _tomorrowYyyyMmDd() {
  final t = DateTime.now().add(const Duration(days: 1));
  return '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}

/// Home activation: START HERE until the demo (or any test) is done.
class HomeActivationJourneyState {
  const HomeActivationJourneyState({
    required this.demoOrFirstTestDone,
    required this.scoredAttempts,
    required this.shouldShowChecklist,
    required this.canSnoozeChecklist,
  });

  /// Demo diagnostic submitted, or any completed session.
  final bool demoOrFirstTestDone;

  /// Scored answers (correct + wrong). Demo is ephemeral, so excluded.
  final int scoredAttempts;

  /// Loud START HERE card (demo still open).
  final bool shouldShowChecklist;

  /// Snooze (X) only from the calendar day after START HERE first appeared.
  final bool canSnoozeChecklist;

  bool get todo1Done => demoOrFirstTestDone;

  bool get todo3Unlocked =>
      scoredAttempts >= ActivationJourneyConstants.confidenceMapPreviewAttempts;
}

final homeActivationJourneyProvider =
    FutureProvider<HomeActivationJourneyState>((ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  final db = ref.watch(userDatabaseProvider);

  final scoredAttempts = await db.sessionQuestionsDao.countScoredAttempts();
  final completedSessions = await db.sessionsDao.countCompletedSessions();
  final demoDone = prefs.getStartedDiagnosticAttempted;
  final demoOrFirstTestDone = demoDone || completedSessions > 0;

  // Grandfather existing active users so we don't re-gate START HERE.
  if (!prefs.activationJourneyInitialized) {
    prefs.activationJourneyInitialized = true;
    if (scoredAttempts >=
            ActivationJourneyConstants.confidenceMapUnlockAttempts ||
        (prefs.homeActivationComplete && completedSessions >= 3)) {
      prefs.activationJourneyDismissed = true;
    }
  }

  final snoozedUntil = prefs.activationJourneySnoozedUntil;
  final checklistSnoozed =
      snoozedUntil.isNotEmpty && _todayYyyyMmDd().compareTo(snoozedUntil) < 0;

  final stillActive = !prefs.activationJourneyDismissed;
  final shouldShowChecklist =
      stillActive && !demoOrFirstTestDone && !checklistSnoozed;

  var firstShownOn = prefs.activationJourneyFirstShownOn;
  if (shouldShowChecklist && firstShownOn.isEmpty) {
    firstShownOn = _todayYyyyMmDd();
    prefs.activationJourneyFirstShownOn = firstShownOn;
  }
  final canSnoozeChecklist = shouldShowChecklist &&
      firstShownOn.isNotEmpty &&
      _todayYyyyMmDd().compareTo(firstShownOn) > 0;

  return HomeActivationJourneyState(
    demoOrFirstTestDone: demoOrFirstTestDone,
    scoredAttempts: scoredAttempts,
    shouldShowChecklist: shouldShowChecklist,
    canSnoozeChecklist: canSnoozeChecklist,
  );
});

/// Hide START HERE until tomorrow; returns daily until the demo is done.
Future<void> snoozeActivationJourneyUntilTomorrow(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.activationJourneySnoozedUntil = _tomorrowYyyyMmDd();
  ref.invalidate(prefsServiceProvider);
  ref.invalidate(homeActivationJourneyProvider);
}
