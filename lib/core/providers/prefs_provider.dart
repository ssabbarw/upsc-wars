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
  static const prelimsPersistentNotification = 'prelims_persistent_notification';
  /// JSON payload to restore battle spectate after app restart.
  static const battleSpectateRecovery = 'battle_spectate_recovery_v1';
  /// Ask confidence before reveal in practice (adaptive); default on.
  static const confidenceTrackingEnabled = 'confidence_tracking_enabled';
  /// Shown once: Hindi/English availability + question-screen toggle.
  static const bilingualQuestionWelcomeSeen =
      'bilingual_question_welcome_seen_v1';
  /// Last Remote Config `home_page_video` JSON `version` the user dismissed.
  static const homePageVideoDismissedVersion =
      'home_page_video_dismissed_version_v1';
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

  /// Default `true` so existing installs keep the prelims notification until
  /// they turn it off in Profile.
  bool get prelimsPersistentNotificationEnabled =>
      _p.getBool(PrefKeys.prelimsPersistentNotification) ?? true;
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

  bool get confidenceTrackingEnabled =>
      _p.getBool(PrefKeys.confidenceTrackingEnabled) ?? true;
  set confidenceTrackingEnabled(bool v) =>
      _p.setBool(PrefKeys.confidenceTrackingEnabled, v);

  bool get bilingualQuestionWelcomeSeen =>
      _p.getBool(PrefKeys.bilingualQuestionWelcomeSeen) ?? false;
  set bilingualQuestionWelcomeSeen(bool v) =>
      _p.setBool(PrefKeys.bilingualQuestionWelcomeSeen, v);

  int get homePageVideoDismissedVersion =>
      _p.getInt(PrefKeys.homePageVideoDismissedVersion) ?? 0;
  set homePageVideoDismissedVersion(int v) =>
      _p.setInt(PrefKeys.homePageVideoDismissedVersion, v);
}

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) async =>
    SharedPreferences.getInstance();

@Riverpod(keepAlive: true)
Future<PrefsService> prefsService(Ref ref) async {
  final p = await ref.watch(sharedPreferencesProvider.future);
  return PrefsService(p);
}
