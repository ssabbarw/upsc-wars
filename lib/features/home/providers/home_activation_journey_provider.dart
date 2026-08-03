import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/services/battle_messaging_service.dart';
import '../domain/activation_journey_constants.dart';

/// State for the 3-step home activation checklist (START HERE).
///
/// Order: (1) demo test → (2) turn on daily reminders (enables the 2nd-day
/// return) → (3) Danger Zone (previews early at 20 attempts, full map at 50).
class HomeActivationJourneyState {
  const HomeActivationJourneyState({
    required this.demoOrFirstTestDone,
    required this.scoredAttempts,
    required this.confidenceMapOpened,
    required this.remindersEnabled,
    required this.topSubjectSlug,
    required this.shouldShowChecklist,
  });

  /// Step 1: demo diagnostic submitted, or any completed session.
  final bool demoOrFirstTestDone;

  /// Scored answers (correct + wrong). Demo is ephemeral, so excluded.
  final int scoredAttempts;

  /// Step 3 done: user opened their Danger Zone (preview or full).
  final bool confidenceMapOpened;

  /// Step 2 done: notifications / daily reminders are enabled.
  final bool remindersEnabled;

  /// Best subject to open for the danger-zone step (most attempts), or null.
  final String? topSubjectSlug;

  /// Show the START HERE card on home.
  final bool shouldShowChecklist;

  int get previewThreshold =>
      ActivationJourneyConstants.confidenceMapPreviewAttempts;

  int get fullThreshold =>
      ActivationJourneyConstants.confidenceMapUnlockAttempts;

  bool get todo1Done => demoOrFirstTestDone;

  /// Reminders unlock after the demo / first test.
  bool get todo2Unlocked => todo1Done;

  bool get todo2Done => remindersEnabled;

  /// Step 3 becomes actionable at the *preview* threshold (early signal).
  bool get todo3Unlocked => scoredAttempts >= previewThreshold;

  /// The full, trustworthy Danger Zone map.
  bool get todo3FullUnlocked => scoredAttempts >= fullThreshold;

  /// In the preview band: enough for an early read, not yet the full map.
  bool get todo3IsPreview => todo3Unlocked && !todo3FullUnlocked;

  bool get todo3Done => confidenceMapOpened;

  bool get allDone => todo1Done && todo2Done && todo3Done;

  int get completedCount =>
      (todo1Done ? 1 : 0) + (todo2Done ? 1 : 0) + (todo3Done ? 1 : 0);

  // ── Progress toward the next Danger Zone gate ──────────────────────────────
  // While locked, the next gate is the preview (20). In the preview band, the
  // next gate is the full map (50).

  int get nextThreshold => todo3Unlocked ? fullThreshold : previewThreshold;

  int get attemptsTowardNext => scoredAttempts.clamp(0, nextThreshold);

  int get attemptsRemaining =>
      (nextThreshold - scoredAttempts).clamp(0, nextThreshold);

  double get unlockProgress =>
      nextThreshold == 0 ? 1 : attemptsTowardNext / nextThreshold;
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

  // Grandfather existing active users so we don't re-gate the checklist.
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
  // Checked once notifications are allowed — the lever for the 2nd-day return.
  final pushStatus =
      await BattleMessagingService.notificationAuthorizationStatus();
  final remindersEnabled =
      BattleMessagingService.notificationAuthorizationAllowsPush(pushStatus);
  final dismissed = prefs.activationJourneyDismissed;

  final allDone =
      demoOrFirstTestDone && remindersEnabled && confidenceMapOpened;
  if (allDone && !dismissed) {
    prefs.activationJourneyDismissed = true;
  }

  // Stay visible until every step is complete, then disappear.
  final shouldShowChecklist = !allDone && !prefs.activationJourneyDismissed;

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
    remindersEnabled: remindersEnabled,
    topSubjectSlug: topSubjectSlug,
    shouldShowChecklist: shouldShowChecklist,
  );
});

/// Marks the danger-zone step opened. Journey hides only when all 3 are done.
Future<void> markActivationConfidenceMapOpened(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.activationConfidenceMapOpened = true;
  ref.invalidate(prefsServiceProvider);
  ref.invalidate(homeActivationJourneyProvider);
}
