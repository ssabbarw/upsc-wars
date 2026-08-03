import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/services/battle_messaging_service.dart';
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

/// Home activation surfaces after onboarding.
///
/// Phase A — [shouldShowChecklist]: START HERE with demo + reminders.
/// Phase B — [shouldShowDangerZoneNudge]: quiet Danger Zone progress / CTA
/// after early steps are done (checklist is gone).
/// Dismissed once Danger Zone is opened (or grandfathered).
class HomeActivationJourneyState {
  const HomeActivationJourneyState({
    required this.demoOrFirstTestDone,
    required this.scoredAttempts,
    required this.confidenceMapOpened,
    required this.remindersEnabled,
    required this.topSubjectSlug,
    required this.shouldShowChecklist,
    required this.shouldShowDangerZoneNudge,
    required this.canSnoozeChecklist,
  });

  /// Step 1: demo diagnostic submitted, or any completed session.
  final bool demoOrFirstTestDone;

  /// Scored answers (correct + wrong). Demo is ephemeral, so excluded.
  final int scoredAttempts;

  /// Danger Zone opened (preview or full) — journey graduate.
  final bool confidenceMapOpened;

  /// Step 2 done: notifications / daily reminders are enabled.
  final bool remindersEnabled;

  /// Best subject to open for the danger-zone step (most attempts), or null.
  final String? topSubjectSlug;

  /// Loud START HERE checklist (demo + reminders still open).
  final bool shouldShowChecklist;

  /// Quiet Danger Zone nudge after checklist graduates.
  final bool shouldShowDangerZoneNudge;

  /// Snooze (X) only from the calendar day after START HERE first appeared.
  final bool canSnoozeChecklist;

  int get previewThreshold =>
      ActivationJourneyConstants.confidenceMapPreviewAttempts;

  int get fullThreshold =>
      ActivationJourneyConstants.confidenceMapUnlockAttempts;

  bool get todo1Done => demoOrFirstTestDone;

  bool get todo2Done => remindersEnabled;

  bool get earlyStepsDone => todo1Done && todo2Done;

  /// Checklist progress: demo + reminders only.
  int get checklistCompletedCount =>
      (todo1Done ? 1 : 0) + (todo2Done ? 1 : 0);

  static const checklistStepCount = 2;

  /// Step 3 becomes actionable at the *preview* threshold (early signal).
  bool get todo3Unlocked => scoredAttempts >= previewThreshold;

  /// The full, trustworthy Danger Zone map.
  bool get todo3FullUnlocked => scoredAttempts >= fullThreshold;

  /// In the preview band: enough for an early read, not yet the full map.
  bool get todo3IsPreview => todo3Unlocked && !todo3FullUnlocked;

  bool get todo3Done => confidenceMapOpened;

  bool get shouldShowActivationSurface =>
      shouldShowChecklist || shouldShowDangerZoneNudge;

  // ── Progress toward Danger Zone preview (nudge) ────────────────────────────

  int get attemptsTowardPreview => scoredAttempts.clamp(0, previewThreshold);

  int get attemptsRemainingToPreview =>
      (previewThreshold - scoredAttempts).clamp(0, previewThreshold);

  double get previewUnlockProgress =>
      previewThreshold == 0 ? 1 : attemptsTowardPreview / previewThreshold;
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
  final remindersEnabled =
      await BattleMessagingService.notificationsAreEnabled();
  final dismissed = prefs.activationJourneyDismissed;

  final earlyStepsDone = demoOrFirstTestDone && remindersEnabled;

  // Graduate the whole journey once Danger Zone has been opened.
  if (earlyStepsDone && confidenceMapOpened && !dismissed) {
    prefs.activationJourneyDismissed = true;
  }

  final snoozedUntil = prefs.activationJourneySnoozedUntil;
  final checklistSnoozed = snoozedUntil.isNotEmpty &&
      _todayYyyyMmDd().compareTo(snoozedUntil) < 0;

  final stillActive = !prefs.activationJourneyDismissed;
  final shouldShowChecklist =
      stillActive && !earlyStepsDone && !checklistSnoozed;
  final shouldShowDangerZoneNudge =
      stillActive && earlyStepsDone && !confidenceMapOpened;

  // Stamp first-shown day so snooze appears only from day 2 onward.
  var firstShownOn = prefs.activationJourneyFirstShownOn;
  if (shouldShowChecklist && firstShownOn.isEmpty) {
    firstShownOn = _todayYyyyMmDd();
    prefs.activationJourneyFirstShownOn = firstShownOn;
  }
  final canSnoozeChecklist = shouldShowChecklist &&
      firstShownOn.isNotEmpty &&
      _todayYyyyMmDd().compareTo(firstShownOn) > 0;

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
    shouldShowDangerZoneNudge: shouldShowDangerZoneNudge,
    canSnoozeChecklist: canSnoozeChecklist,
  );
});

/// Marks Danger Zone opened — dismisses the home nudge.
Future<void> markActivationConfidenceMapOpened(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.activationConfidenceMapOpened = true;
  prefs.activationJourneyDismissed = true;
  ref.invalidate(prefsServiceProvider);
  ref.invalidate(homeActivationJourneyProvider);
}

/// Hide START HERE until tomorrow; returns daily until early steps are done.
Future<void> snoozeActivationJourneyUntilTomorrow(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.activationJourneySnoozedUntil = _tomorrowYyyyMmDd();
  ref.invalidate(prefsServiceProvider);
  ref.invalidate(homeActivationJourneyProvider);
}
