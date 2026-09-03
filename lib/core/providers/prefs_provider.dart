import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/daily_drill_constants.dart';

part 'prefs_provider.g.dart';

abstract final class PrefKeys {
  static const currentStreak = 'current_streak';
  static const longestStreak = 'longest_streak';
  static const lastActiveDate = 'last_active_date';

  /// JSON list of streak lengths already celebrated (3 / 7 / 14 / 30).
  static const celebratedStreakMilestonesV1 =
      'celebrated_streak_milestones_v1';

  /// Pending home toast for a newly reached streak milestone (cleared on show).
  static const pendingStreakMilestoneCelebrationV1 =
      'pending_streak_milestone_celebration_v1';
  static const dailyGoal = 'daily_goal';
  static const language = 'language';
  static const dbInitialized = 'db_initialized';
  static const dbAssetVersion = 'db_asset_version';
  static const darkModeEnabled = 'dark_mode_enabled';

  /// Android persistent status-bar style prelims countdown (days only).
  static const prelimsPersistentNotification =
      'prelims_persistent_notification';

  /// JSON payload to restore battle spectate after app restart.
  static const battleSpectateRecovery = 'battle_spectate_recovery_v1';

  /// Last user-dragged position for the live-duel FAB (`"left,top"` in logical px).
  static const battleSpectateFabPos = 'battle_spectate_fab_pos_v1';

  /// Ask confidence before reveal in practice (adaptive); default on.
  static const confidenceTrackingEnabled = 'confidence_tracking_enabled';

  /// Shown once: Hindi/English availability + question-screen toggle.
  static const bilingualQuestionWelcomeSeen =
      'bilingual_question_welcome_seen_v1';

  /// Shown once: onboarding “Pattern Interrupt” diagnosis screen.
  static const patternInterruptOnboardingSeen =
      'pattern_interrupt_onboarding_seen_v1';

  /// After onboarding, auto-open the Get Started subject sheet once on home.
  static const getStartedSheetPendingAfterOnboarding =
      'get_started_sheet_pending_after_onboarding_v1';

  /// User submitted the 7-question Get Started demo (widget or intro sheet).
  static const getStartedDiagnosticAttemptedV1 =
      'get_started_diagnostic_attempted_v1';

  /// Demo Q3+ intro sheet before the first confidence ask.
  static const demoConfidenceIntroSeenV1 = 'demo_confidence_intro_seen_v1';

  /// Demo overlay pointing at the EN | हि language toggle.
  static const demoLanguageCoachSeenV1 = 'demo_language_coach_seen_v1';

  /// Demo Q1 sheet: verdict + read the explanation (once).
  static const demoExplanationCoachSeenV1 = 'demo_explanation_coach_seen_v1';

  /// Demo results overlay: review mistakes vs review all.
  static const demoResultsReviewCoachSeenV1 =
      'demo_results_review_coach_seen_v1';

  /// User opened post-demo session review (mistakes or all questions).
  static const demoDiagnosticReviewOpenedV1 =
      'demo_diagnostic_review_opened_v1';

  /// User dismissed the Get Started home card via the explain sheet.
  /// Legacy — ignored; prefer [getStartedCardSnoozedUntilV1].
  static const getStartedCardDismissedV1 = 'get_started_card_dismissed_v1';

  /// YYYY-MM-DD: first local calendar day the Get Started card may show again.
  static const getStartedCardSnoozedUntilV1 =
      'get_started_card_snoozed_until_v1';

  /// One-time init for the home activation journey checklist.
  static const activationJourneyInitializedV1 =
      'activation_journey_initialized_v1';

  /// User opened the confidence map (Todo 2) after unlock — journey can end.
  static const activationConfidenceMapOpenedV1 =
      'activation_confidence_map_opened_v1';

  /// User opened Games from the activation checklist (legacy Todo — games left
  /// the activation path; kept for back-compat / existing users).
  static const activationGamesOpenedV1 = 'activation_games_opened_v1';

  /// Journey fully dismissed (grandfathered or completed).
  static const activationJourneyDismissedV1 =
      'activation_journey_dismissed_v1';

  /// YYYY-MM-DD: first local calendar day the START HERE checklist may show again.
  static const activationJourneySnoozedUntilV1 =
      'activation_journey_snoozed_until_v1';

  /// YYYY-MM-DD: first local calendar day START HERE was shown (gates snooze).
  static const activationJourneyFirstShownOnV1 =
      'activation_journey_first_shown_on_v1';

  /// Shown once: session review share button coach mark.
  static const sessionReviewShareCoachSeen =
      'session_review_share_coach_seen_v1';

  /// Shown once: test config sheet coach mark (question count, mode, timed toggle).
  static const testConfigCoachMarkSeen = 'test_config_coach_mark_seen_v1';

  /// Last Remote Config `home_page_video` JSON `version` the user dismissed.
  static const homePageVideoDismissedVersion =
      'home_page_video_dismissed_version_v1';

  /// When the user last published an open challenge (local epoch ms); 24h cooldown for new creates.
  static const openChallengeLastPublishedAtMs =
      'open_challenge_last_published_at_ms_v1';

  /// JSON array of epoch ms for QOTD posts from this device (rolling 24h client cap).
  static const qotdLocalPostEpochsMsJson = 'qotd_local_post_epochs_ms_json_v1';

  /// Shown once: what Community QOTD is, before the first post sheet.
  static const qotdWhatIsIntroSeenV1 = 'qotd_what_is_intro_seen_v1';

  /// Legacy: one-shot “education sheet done” (older builds). When true, no modal
  /// or home nudge (preserves prior installs).
  static const deferredPushPermissionSheetCompletedV1 =
      'deferred_push_permission_sheet_completed_v1';

  /// How many times the deferred push **education modal** was shown (max 2).
  static const deferredPushModalShownCountV2 =
      'deferred_push_modal_shown_count_v2';

  /// Epoch ms of the last automatic notification-permission sheet.
  static const deferredPushLastAutomaticShownAtMsV1 =
      'deferred_push_last_automatic_shown_at_ms_v1';

  /// User dismissed the post-modal home notification hint.
  static const deferredPushHomeNudgeDismissedV2 =
      'deferred_push_home_nudge_dismissed_v2';

  /// Number of times the app process was opened (local counter).
  /// Used for "ask notification permission on 2nd open".
  static const appOpenCountV1 = 'app_open_count_v1';

  /// JSON list of [ActivationMilestones] ids already logged to analytics.
  static const activationMilestonesV1 = 'activation_milestones_v1';

  /// One-time: first time the user saw any Insights surface (per device).
  static const firstInsightSeenV1 = 'first_insight_seen_v1';

  /// One-time: first time the user opened Memory Pairs / Revision Games.
  static const memoryPairsGameDiscoveredV1 = 'memory_pairs_game_discovered_v1';

  /// One-time: first time the user started a Memory Pairs match game.
  static const memoryPairsGamePlayedV1 = 'memory_pairs_game_played_v1';

  /// One-time in-app rating/review prompt was already shown (never ask again).
  static const appReviewPromptShownV1 = 'app_review_prompt_shown_v1';

  /// Last applied `question_corrections/active.revision` from Firestore.
  static const questionCorrectionsRevision = 'question_corrections_revision_v1';

  /// Epoch ms of last successful question-corrections sync.
  static const questionCorrectionsSyncedAtMs =
      'question_corrections_synced_at_ms_v1';

  /// User completed activation (any session with Sure/Edu confidence logged).
  static const homeActivationCompleteV1 = 'home_activation_complete_v1';

  /// JSON list of yyyy-MM-dd days with at least one completed session.
  static const activationSessionDaysV1 = 'activation_session_days_v1';

  /// Epoch ms when the app was first installed on this device (new installs only).
  static const firstInstallAtMsV1 = 'first_install_at_ms_v1';

  /// Local no-test reminder was scheduled or already delivered.
  static const noTestReminderHandledV1 = 'no_test_reminder_handled_v1';

  /// Subject slug for the home daily practice drill (`misc` or a catalog subject).
  static const dailyPracticeSubjectV1 = 'daily_practice_subject_v1';

  /// Local hour (0–23) for the daily practice reminder notification.
  static const dailyPracticeReminderHourV1 = 'daily_practice_reminder_hour_v1';

  /// Prompt for push permission once home loads after first-test results exit.
  static const pushPermissionPromptPendingAfterFirstTestV1 =
      'push_permission_prompt_pending_after_first_test_v1';

  /// Consecutive War nights with a live (ranked) attempt on this device.
  static const dailyWarStreakV1 = 'daily_war_streak_v1';

  /// Longest War streak recorded on this device.
  static const dailyWarLongestStreakV1 = 'daily_war_longest_streak_v1';

  /// YYYY-MM-DD of last live War attempt used for streak continuity.
  static const dailyWarLastPlayedDateIdV1 =
      'daily_war_last_played_date_id_v1';

  /// Consecutive War nights missed since last play (0 or 1 grace).
  static const dailyWarPendingMissesV1 = 'daily_war_pending_misses_v1';

  /// User collapsed the Daily War home card (null = smart default).
  static const dailyWarHomeCollapsedV1 = 'daily_war_home_collapsed_v1';

  /// yyyy-MM-dd days where every available Today ring was closed (recent only).
  static const todayFullDayDatesV1 = 'today_full_day_dates_v1';

  /// ISO dates (`YYYY-MM-DD`) whose Daily CA results/explanations were opened.
  static const dailyCaResultsOpenedDatesV1 =
      'daily_ca_results_opened_dates_v1';

  /// Shown once: Home sheet introducing CA Shots, Daily CA Test, Daily Battle.
  static const dailyRitualsIntroSeenV1 = 'daily_rituals_intro_seen_v1';

  /// JSON list of [DailyRitualIds] the user has opened at least once.
  static const dailyRitualsOpenedIdsV1 = 'daily_rituals_opened_ids_v1';

  /// Last [ReleaseVersion] string the user dismissed on the soft-update banner.
  static const softUpdateDismissedVersionV1 =
      'soft_update_dismissed_version_v1';
}

class PrefsService {
  PrefsService(this._p);

  final SharedPreferences _p;

  String? getString(String key) => _p.getString(key);
  Future<bool> setString(String key, String value) => _p.setString(key, value);
  bool getBool(String key) => _p.getBool(key) ?? false;
  Future<bool> setBool(String key, bool value) => _p.setBool(key, value);

  int get currentStreak => _p.getInt(PrefKeys.currentStreak) ?? 0;
  set currentStreak(int v) => _p.setInt(PrefKeys.currentStreak, v);

  int get longestStreak => _p.getInt(PrefKeys.longestStreak) ?? 0;
  set longestStreak(int v) => _p.setInt(PrefKeys.longestStreak, v);

  String? get lastActiveDate => _p.getString(PrefKeys.lastActiveDate);
  set lastActiveDate(String? v) {
    if (v == null) {
      _p.remove(PrefKeys.lastActiveDate);
    } else {
      _p.setString(PrefKeys.lastActiveDate, v);
    }
  }

  Set<int> get celebratedStreakMilestones {
    final raw = _p.getString(PrefKeys.celebratedStreakMilestonesV1);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toSet();
      return list;
    } catch (_) {
      return {};
    }
  }

  set celebratedStreakMilestones(Set<int> v) {
    _p.setString(
      PrefKeys.celebratedStreakMilestonesV1,
      jsonEncode(v.toList()..sort()),
    );
  }

  int? get pendingStreakMilestoneCelebration {
    if (!_p.containsKey(PrefKeys.pendingStreakMilestoneCelebrationV1)) {
      return null;
    }
    return _p.getInt(PrefKeys.pendingStreakMilestoneCelebrationV1);
  }

  set pendingStreakMilestoneCelebration(int? v) {
    if (v == null) {
      _p.remove(PrefKeys.pendingStreakMilestoneCelebrationV1);
    } else {
      _p.setInt(PrefKeys.pendingStreakMilestoneCelebrationV1, v);
    }
  }

  int get dailyGoal => _p.getInt(PrefKeys.dailyGoal) ?? 25;
  set dailyGoal(int v) => _p.setInt(PrefKeys.dailyGoal, v);

  String get language => _p.getString(PrefKeys.language) ?? 'en';
  set language(String v) => _p.setString(PrefKeys.language, v);

  bool get dbInitialized => _p.getBool(PrefKeys.dbInitialized) ?? false;
  set dbInitialized(bool v) => _p.setBool(PrefKeys.dbInitialized, v);

  int get dbAssetVersion => _p.getInt(PrefKeys.dbAssetVersion) ?? 0;
  set dbAssetVersion(int v) => _p.setInt(PrefKeys.dbAssetVersion, v);

  bool get darkModeEnabled => _p.getBool(PrefKeys.darkModeEnabled) ?? false;
  set darkModeEnabled(bool v) => _p.setBool(PrefKeys.darkModeEnabled, v);

  /// Default off; user can enable in Profile (Android status bar countdown).
  bool get prelimsPersistentNotificationEnabled =>
      _p.getBool(PrefKeys.prelimsPersistentNotification) ?? false;
  set prelimsPersistentNotificationEnabled(bool v) =>
      _p.setBool(PrefKeys.prelimsPersistentNotification, v);

  /// JSON for restoring battle spectate after restart; null clears.
  String? get battleSpectateRecoveryJson =>
      _p.getString(PrefKeys.battleSpectateRecovery);
  set battleSpectateRecoveryJson(String? v) {
    if (v == null || v.isEmpty) {
      _p.remove(PrefKeys.battleSpectateRecovery);
    } else {
      _p.setString(PrefKeys.battleSpectateRecovery, v);
    }
  }

  /// Persisted top-left of the live-duel FAB; null uses default bottom-right.
  String? get battleSpectateFabPosition =>
      _p.getString(PrefKeys.battleSpectateFabPos);
  set battleSpectateFabPosition(String? v) {
    if (v == null || v.isEmpty) {
      _p.remove(PrefKeys.battleSpectateFabPos);
    } else {
      _p.setString(PrefKeys.battleSpectateFabPos, v);
    }
  }

  bool get confidenceTrackingEnabled =>
      _p.getBool(PrefKeys.confidenceTrackingEnabled) ?? true;
  set confidenceTrackingEnabled(bool v) =>
      _p.setBool(PrefKeys.confidenceTrackingEnabled, v);

  bool get bilingualQuestionWelcomeSeen =>
      _p.getBool(PrefKeys.bilingualQuestionWelcomeSeen) ?? false;
  set bilingualQuestionWelcomeSeen(bool v) =>
      _p.setBool(PrefKeys.bilingualQuestionWelcomeSeen, v);

  bool get patternInterruptOnboardingSeen =>
      _p.getBool(PrefKeys.patternInterruptOnboardingSeen) ?? false;
  set patternInterruptOnboardingSeen(bool v) =>
      _p.setBool(PrefKeys.patternInterruptOnboardingSeen, v);

  bool get getStartedSheetPendingAfterOnboarding =>
      _p.getBool(PrefKeys.getStartedSheetPendingAfterOnboarding) ?? false;
  set getStartedSheetPendingAfterOnboarding(bool v) =>
      _p.setBool(PrefKeys.getStartedSheetPendingAfterOnboarding, v);

  bool get getStartedDiagnosticAttempted =>
      _p.getBool(PrefKeys.getStartedDiagnosticAttemptedV1) ?? false;
  set getStartedDiagnosticAttempted(bool v) =>
      _p.setBool(PrefKeys.getStartedDiagnosticAttemptedV1, v);

  bool get demoConfidenceIntroSeen =>
      _p.getBool(PrefKeys.demoConfidenceIntroSeenV1) ?? false;
  set demoConfidenceIntroSeen(bool v) =>
      _p.setBool(PrefKeys.demoConfidenceIntroSeenV1, v);

  bool get demoLanguageCoachSeen =>
      _p.getBool(PrefKeys.demoLanguageCoachSeenV1) ?? false;
  set demoLanguageCoachSeen(bool v) =>
      _p.setBool(PrefKeys.demoLanguageCoachSeenV1, v);

  bool get demoExplanationCoachSeen =>
      _p.getBool(PrefKeys.demoExplanationCoachSeenV1) ?? false;
  set demoExplanationCoachSeen(bool v) =>
      _p.setBool(PrefKeys.demoExplanationCoachSeenV1, v);

  bool get demoResultsReviewCoachSeen =>
      _p.getBool(PrefKeys.demoResultsReviewCoachSeenV1) ?? false;
  set demoResultsReviewCoachSeen(bool v) =>
      _p.setBool(PrefKeys.demoResultsReviewCoachSeenV1, v);

  /// Language, explanation, confidence intro, and results coaches — once per
  /// demo visit. Call when opening a demo (resume or a new attempt).
  void resetDemoCoachPrompts() {
    demoLanguageCoachSeen = false;
    demoExplanationCoachSeen = false;
    demoConfidenceIntroSeen = false;
    demoResultsReviewCoachSeen = false;
  }

  bool get demoDiagnosticReviewOpened =>
      _p.getBool(PrefKeys.demoDiagnosticReviewOpenedV1) ?? false;
  set demoDiagnosticReviewOpened(bool v) =>
      _p.setBool(PrefKeys.demoDiagnosticReviewOpenedV1, v);

  bool get getStartedCardDismissed =>
      _p.getBool(PrefKeys.getStartedCardDismissedV1) ?? false;
  set getStartedCardDismissed(bool v) =>
      _p.setBool(PrefKeys.getStartedCardDismissedV1, v);

  /// Empty = not snoozed. Otherwise YYYY-MM-DD when the card may show again.
  String get getStartedCardSnoozedUntil =>
      (_p.getString(PrefKeys.getStartedCardSnoozedUntilV1) ?? '').trim();
  set getStartedCardSnoozedUntil(String v) =>
      _p.setString(PrefKeys.getStartedCardSnoozedUntilV1, v.trim());

  bool get activationJourneyInitialized =>
      _p.getBool(PrefKeys.activationJourneyInitializedV1) ?? false;
  set activationJourneyInitialized(bool v) =>
      _p.setBool(PrefKeys.activationJourneyInitializedV1, v);

  bool get activationConfidenceMapOpened =>
      _p.getBool(PrefKeys.activationConfidenceMapOpenedV1) ?? false;
  set activationConfidenceMapOpened(bool v) =>
      _p.setBool(PrefKeys.activationConfidenceMapOpenedV1, v);

  bool get activationGamesOpened =>
      _p.getBool(PrefKeys.activationGamesOpenedV1) ?? false;
  set activationGamesOpened(bool v) =>
      _p.setBool(PrefKeys.activationGamesOpenedV1, v);

  bool get activationJourneyDismissed =>
      _p.getBool(PrefKeys.activationJourneyDismissedV1) ?? false;
  set activationJourneyDismissed(bool v) =>
      _p.setBool(PrefKeys.activationJourneyDismissedV1, v);

  /// Empty = not snoozed. Otherwise YYYY-MM-DD when the checklist may show again.
  String get activationJourneySnoozedUntil =>
      (_p.getString(PrefKeys.activationJourneySnoozedUntilV1) ?? '').trim();
  set activationJourneySnoozedUntil(String v) =>
      _p.setString(PrefKeys.activationJourneySnoozedUntilV1, v.trim());

  /// Empty = never shown. Otherwise YYYY-MM-DD of first START HERE appearance.
  String get activationJourneyFirstShownOn =>
      (_p.getString(PrefKeys.activationJourneyFirstShownOnV1) ?? '').trim();
  set activationJourneyFirstShownOn(String v) =>
      _p.setString(PrefKeys.activationJourneyFirstShownOnV1, v.trim());

  bool get sessionReviewShareCoachSeen =>
      _p.getBool(PrefKeys.sessionReviewShareCoachSeen) ?? false;
  set sessionReviewShareCoachSeen(bool v) =>
      _p.setBool(PrefKeys.sessionReviewShareCoachSeen, v);

  bool get testConfigCoachMarkSeen =>
      _p.getBool(PrefKeys.testConfigCoachMarkSeen) ?? false;
  set testConfigCoachMarkSeen(bool v) =>
      _p.setBool(PrefKeys.testConfigCoachMarkSeen, v);

  int get homePageVideoDismissedVersion =>
      _p.getInt(PrefKeys.homePageVideoDismissedVersion) ?? 0;
  set homePageVideoDismissedVersion(int v) =>
      _p.setInt(PrefKeys.homePageVideoDismissedVersion, v);

  /// Local-only: last time this device published an open challenge to Firestore.
  int? get openChallengeLastPublishedAtMs =>
      _p.containsKey(PrefKeys.openChallengeLastPublishedAtMs)
      ? _p.getInt(PrefKeys.openChallengeLastPublishedAtMs)
      : null;
  set openChallengeLastPublishedAtMs(int? v) {
    if (v == null) {
      _p.remove(PrefKeys.openChallengeLastPublishedAtMs);
    } else {
      _p.setInt(PrefKeys.openChallengeLastPublishedAtMs, v);
    }
  }

  /// JSON list of ints: `DateTime.now().millisecondsSinceEpoch` for each QOTD post from this device.
  String get qotdLocalPostEpochsMsJson =>
      _p.getString(PrefKeys.qotdLocalPostEpochsMsJson) ?? '[]';
  set qotdLocalPostEpochsMsJson(String v) =>
      _p.setString(PrefKeys.qotdLocalPostEpochsMsJson, v);

  bool get qotdWhatIsIntroSeen =>
      _p.getBool(PrefKeys.qotdWhatIsIntroSeenV1) ?? false;
  set qotdWhatIsIntroSeen(bool v) =>
      _p.setBool(PrefKeys.qotdWhatIsIntroSeenV1, v);

  bool get deferredPushPermissionSheetCompletedV1 =>
      _p.getBool(PrefKeys.deferredPushPermissionSheetCompletedV1) ?? false;
  set deferredPushPermissionSheetCompletedV1(bool v) =>
      _p.setBool(PrefKeys.deferredPushPermissionSheetCompletedV1, v);

  int get deferredPushModalShownCountV2 =>
      _p.getInt(PrefKeys.deferredPushModalShownCountV2) ?? 0;
  set deferredPushModalShownCountV2(int v) =>
      _p.setInt(PrefKeys.deferredPushModalShownCountV2, v);

  DateTime? get deferredPushLastAutomaticShownAt {
    final ms = _p.getInt(PrefKeys.deferredPushLastAutomaticShownAtMsV1);
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  set deferredPushLastAutomaticShownAt(DateTime? v) {
    if (v == null) {
      _p.remove(PrefKeys.deferredPushLastAutomaticShownAtMsV1);
    } else {
      _p.setInt(
        PrefKeys.deferredPushLastAutomaticShownAtMsV1,
        v.millisecondsSinceEpoch,
      );
    }
  }

  bool get deferredPushHomeNudgeDismissedV2 =>
      _p.getBool(PrefKeys.deferredPushHomeNudgeDismissedV2) ?? false;
  set deferredPushHomeNudgeDismissedV2(bool v) =>
      _p.setBool(PrefKeys.deferredPushHomeNudgeDismissedV2, v);

  int get appOpenCount => _p.getInt(PrefKeys.appOpenCountV1) ?? 0;
  set appOpenCount(int v) => _p.setInt(PrefKeys.appOpenCountV1, v);

  /// Ids of [activation_milestone] events already sent (one-time activation).
  Set<String> get activationMilestones {
    final raw = _p.getString(PrefKeys.activationMilestonesV1);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = jsonDecode(raw);
      if (list is! List) return <String>{};
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  bool hasActivationMilestone(String id) => activationMilestones.contains(id);

  void addActivationMilestone(String id) {
    if (id.isEmpty) return;
    final s = activationMilestones;
    s.add(id);
    _p.setString(PrefKeys.activationMilestonesV1, jsonEncode(s.toList()..sort()));
  }

  bool get firstInsightSeen =>
      _p.getBool(PrefKeys.firstInsightSeenV1) ?? false;
  set firstInsightSeen(bool v) => _p.setBool(PrefKeys.firstInsightSeenV1, v);

  bool get memoryPairsGameDiscovered =>
      _p.getBool(PrefKeys.memoryPairsGameDiscoveredV1) ?? false;
  set memoryPairsGameDiscovered(bool v) =>
      _p.setBool(PrefKeys.memoryPairsGameDiscoveredV1, v);

  bool get memoryPairsGamePlayed =>
      _p.getBool(PrefKeys.memoryPairsGamePlayedV1) ?? false;
  set memoryPairsGamePlayed(bool v) =>
      _p.setBool(PrefKeys.memoryPairsGamePlayedV1, v);

  bool get appReviewPromptShown =>
      _p.getBool(PrefKeys.appReviewPromptShownV1) ?? false;
  set appReviewPromptShown(bool v) => _p.setBool(PrefKeys.appReviewPromptShownV1, v);

  bool get homeActivationComplete =>
      _p.getBool(PrefKeys.homeActivationCompleteV1) ?? false;
  set homeActivationComplete(bool v) =>
      _p.setBool(PrefKeys.homeActivationCompleteV1, v);

  List<String> get activationSessionDays {
    final raw = _p.getString(PrefKeys.activationSessionDaysV1);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list.map((e) => e.toString()).toList()..sort();
    } catch (_) {
      return const [];
    }
  }

  void appendActivationSessionDay(String yyyyMmDd) {
    if (yyyyMmDd.isEmpty) return;
    final days = activationSessionDays.toSet();
    days.add(yyyyMmDd);
    final sorted = days.toList()..sort();
    _p.setString(PrefKeys.activationSessionDaysV1, jsonEncode(sorted));
  }

  int? get firstInstallAtMs =>
      _p.containsKey(PrefKeys.firstInstallAtMsV1)
          ? _p.getInt(PrefKeys.firstInstallAtMsV1)
          : null;
  set firstInstallAtMs(int? v) {
    if (v == null) {
      _p.remove(PrefKeys.firstInstallAtMsV1);
    } else {
      _p.setInt(PrefKeys.firstInstallAtMsV1, v);
    }
  }

  bool get noTestReminderHandled =>
      _p.getBool(PrefKeys.noTestReminderHandledV1) ?? false;
  set noTestReminderHandled(bool v) =>
      _p.setBool(PrefKeys.noTestReminderHandledV1, v);

  String get dailyPracticeSubject =>
      _p.getString(PrefKeys.dailyPracticeSubjectV1) ??
      DailyDrillConstants.defaultSubject;
  set dailyPracticeSubject(String v) =>
      _p.setString(PrefKeys.dailyPracticeSubjectV1, v);

  int get dailyPracticeReminderHour =>
      _p.getInt(PrefKeys.dailyPracticeReminderHourV1) ??
      DailyDrillConstants.defaultReminderHour;
  set dailyPracticeReminderHour(int v) =>
      _p.setInt(PrefKeys.dailyPracticeReminderHourV1, v);

  bool get pushPermissionPromptPendingAfterFirstTest =>
      _p.getBool(PrefKeys.pushPermissionPromptPendingAfterFirstTestV1) ?? false;
  set pushPermissionPromptPendingAfterFirstTest(bool v) => _p.setBool(
        PrefKeys.pushPermissionPromptPendingAfterFirstTestV1,
        v,
      );

  int get dailyWarStreak => _p.getInt(PrefKeys.dailyWarStreakV1) ?? 0;
  set dailyWarStreak(int v) => _p.setInt(PrefKeys.dailyWarStreakV1, v);

  int get dailyWarLongestStreak =>
      _p.getInt(PrefKeys.dailyWarLongestStreakV1) ?? 0;
  set dailyWarLongestStreak(int v) =>
      _p.setInt(PrefKeys.dailyWarLongestStreakV1, v);

  String? get dailyWarLastPlayedDateId =>
      _p.getString(PrefKeys.dailyWarLastPlayedDateIdV1);
  set dailyWarLastPlayedDateId(String? v) {
    if (v == null || v.isEmpty) {
      _p.remove(PrefKeys.dailyWarLastPlayedDateIdV1);
    } else {
      _p.setString(PrefKeys.dailyWarLastPlayedDateIdV1, v);
    }
  }

  int get dailyWarPendingMisses =>
      _p.getInt(PrefKeys.dailyWarPendingMissesV1) ?? 0;
  set dailyWarPendingMisses(int v) =>
      _p.setInt(PrefKeys.dailyWarPendingMissesV1, v);

  /// `null` when the user has never toggled collapse on the home War card.
  bool? get dailyWarHomeCollapsedOrNull =>
      _p.containsKey(PrefKeys.dailyWarHomeCollapsedV1)
          ? _p.getBool(PrefKeys.dailyWarHomeCollapsedV1)
          : null;

  set dailyWarHomeCollapsed(bool v) =>
      _p.setBool(PrefKeys.dailyWarHomeCollapsedV1, v);

  List<String> get todayFullDayDates =>
      _p.getStringList(PrefKeys.todayFullDayDatesV1) ?? const [];
  set todayFullDayDates(List<String> v) =>
      _p.setStringList(PrefKeys.todayFullDayDatesV1, v);

  List<String> get dailyCaResultsOpenedDates =>
      _p.getStringList(PrefKeys.dailyCaResultsOpenedDatesV1) ?? const [];

  bool hasOpenedDailyCaResults(String isoDate) =>
      dailyCaResultsOpenedDates.contains(isoDate);

  void markDailyCaResultsOpened(String isoDate) {
    final iso = isoDate.trim();
    if (iso.isEmpty) return;
    final next = [
      iso,
      for (final d in dailyCaResultsOpenedDates)
        if (d != iso) d,
    ];
    if (next.length > 21) next.removeRange(21, next.length);
    _p.setStringList(PrefKeys.dailyCaResultsOpenedDatesV1, next);
  }

  bool get dailyRitualsIntroSeen =>
      _p.getBool(PrefKeys.dailyRitualsIntroSeenV1) ?? false;
  set dailyRitualsIntroSeen(bool v) =>
      _p.setBool(PrefKeys.dailyRitualsIntroSeenV1, v);

  Set<String> get dailyRitualsOpenedIds {
    final raw = _p.getString(PrefKeys.dailyRitualsOpenedIdsV1);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = jsonDecode(raw);
      if (list is! List) return <String>{};
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Returns `true` when [id] was newly recorded.
  bool markDailyRitualOpened(String id) {
    if (id.isEmpty) return false;
    final next = dailyRitualsOpenedIds;
    if (!next.add(id)) return false;
    _p.setString(
      PrefKeys.dailyRitualsOpenedIdsV1,
      jsonEncode(next.toList()..sort()),
    );
    return true;
  }

  String get softUpdateDismissedVersion =>
      (_p.getString(PrefKeys.softUpdateDismissedVersionV1) ?? '').trim();
  set softUpdateDismissedVersion(String v) =>
      _p.setString(PrefKeys.softUpdateDismissedVersionV1, v.trim());
}

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) async =>
    SharedPreferences.getInstance();

@Riverpod(keepAlive: true)
Future<PrefsService> prefsService(Ref ref) async {
  final p = await ref.watch(sharedPreferencesProvider.future);
  return PrefsService(p);
}
