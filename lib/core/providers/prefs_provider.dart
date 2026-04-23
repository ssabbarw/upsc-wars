import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'prefs_provider.g.dart';

abstract final class PrefKeys {
  static const currentStreak = 'current_streak';
  static const longestStreak = 'longest_streak';
  static const lastActiveDate = 'last_active_date';
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

  /// Last Remote Config `home_page_video` JSON `version` the user dismissed.
  static const homePageVideoDismissedVersion =
      'home_page_video_dismissed_version_v1';

  /// When the user last published an open challenge (local epoch ms); 24h cooldown for new creates.
  static const openChallengeLastPublishedAtMs =
      'open_challenge_last_published_at_ms_v1';

  /// JSON array of epoch ms for QOTD posts from this device (rolling 24h client cap).
  static const qotdLocalPostEpochsMsJson = 'qotd_local_post_epochs_ms_json_v1';

  /// Legacy: one-shot “education sheet done” (older builds). When true, no modal
  /// or home nudge (preserves prior installs).
  static const deferredPushPermissionSheetCompletedV1 =
      'deferred_push_permission_sheet_completed_v1';

  /// How many times the deferred push **education modal** was shown (max 2).
  static const deferredPushModalShownCountV2 =
      'deferred_push_modal_shown_count_v2';

  /// User dismissed the post-modal home notification hint.
  static const deferredPushHomeNudgeDismissedV2 =
      'deferred_push_home_nudge_dismissed_v2';
}

class PrefsService {
  PrefsService(this._p);

  final SharedPreferences _p;

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

  bool get deferredPushPermissionSheetCompletedV1 =>
      _p.getBool(PrefKeys.deferredPushPermissionSheetCompletedV1) ?? false;
  set deferredPushPermissionSheetCompletedV1(bool v) =>
      _p.setBool(PrefKeys.deferredPushPermissionSheetCompletedV1, v);

  int get deferredPushModalShownCountV2 =>
      _p.getInt(PrefKeys.deferredPushModalShownCountV2) ?? 0;
  set deferredPushModalShownCountV2(int v) =>
      _p.setInt(PrefKeys.deferredPushModalShownCountV2, v);

  bool get deferredPushHomeNudgeDismissedV2 =>
      _p.getBool(PrefKeys.deferredPushHomeNudgeDismissedV2) ?? false;
  set deferredPushHomeNudgeDismissedV2(bool v) =>
      _p.setBool(PrefKeys.deferredPushHomeNudgeDismissedV2, v);
}

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) async =>
    SharedPreferences.getInstance();

@Riverpod(keepAlive: true)
Future<PrefsService> prefsService(Ref ref) async {
  final p = await ref.watch(sharedPreferencesProvider.future);
  return PrefsService(p);
}
