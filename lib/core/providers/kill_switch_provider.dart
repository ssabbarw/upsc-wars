import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../admin_dashboard/admin_dashboard_collection_config.dart';
import '../config/feature_flags.dart';
import '../constants/app_constants.dart';
import 'package_info_provider.dart';
import 'super_user_provider.dart';

part 'kill_switch_provider.g.dart';

/// Remote Config: minimum client version (same rules as [ReleaseVersion.parse]).
/// Example: `2.1` means builds below 2.1.0 must update; `2.1.0` is allowed.
const killSwitchVersionRemoteConfigKey = 'kill_switch_version';

/// Remote Config: when `false`, hide the Community shell tab (compile flag must still be on).
const communityTabEnabledRemoteConfigKey = 'community_tab_enabled';

/// Remote Config: when `false`, hide the Daily Current Affairs Test on home.
const dailyCaEnabledRemoteConfigKey = 'daily_ca_enabled';

/// Remote Config: when `false`, hide CA Shots on home (fails closed).
const caShotsEnabledRemoteConfigKey = 'ca_shots_enabled';

/// Remote Config: when `false`, hide Daily War on the home screen (fails closed).
const dailyWarEnabledRemoteConfigKey = 'daily_war_enabled';

/// Remote Config: when `true`, Daily War (UI + attempt + push) is admin-only.
/// When `false` and [dailyWarEnabledRemoteConfigKey] is on, everyone gets it.
const dailyWarAdminsOnlyRemoteConfigKey = 'daily_war_admins_only';

/// Remote Config: when `false`, hide lobby / participant count numbers on War UI.
const dailyWarLobbyCountEnabledRemoteConfigKey =
    'daily_war_lobby_count_enabled';

/// Remote Config: minimum count before showing raw numbers (int, default 200).
const dailyWarMinVisibleLobbyCountRemoteConfigKey =
    'daily_war_min_visible_lobby_count';

/// Remote Config: RTDB live-count poll interval seconds (int, default 5).
const dailyWarLiveCountPollSecondsRemoteConfigKey =
    'daily_war_live_count_poll_seconds';

/// Remote Config: earliest selectable daily CA calendar date (`YYYY-MM-DD`, IST).
const dailyCaCalendarMinDateRemoteConfigKey = 'daily_ca_calendar_min_date';

/// Remote Config: when `false`, hide Daily CA ranks / leaderboard.
const dailyCaRanksEnabledRemoteConfigKey = 'daily_ca_ranks_enabled';

/// Remote Config: when `true`, Daily CA ranks are admin-only.
const dailyCaRanksAdminsOnlyRemoteConfigKey = 'daily_ca_ranks_admins_only';

/// Remote Config: max QOTD posts per device in a rolling 24h window (int, default 3; enforced locally).
const qotdMaxPostsPerDayRemoteConfigKey = 'qotd_max_posts_per_day';

/// Remote Config: Fact or Bluff countdown seconds (int, default 10).
const factOrBluffSecondsRemoteConfigKey = 'fact_or_bluff_seconds';

/// Remote Config: mirrors Firestore `question_corrections/active.revision` (int).
const questionCorrectionsRevisionRemoteConfigKey =
    'question_corrections_revision';

/// Remote Config: when `false`, the Test Series is not sold. People who already
/// bought it keep full access; everyone else sees nothing (fails closed).
const testSeriesSalesEnabledRemoteConfigKey = 'test_series_sales_enabled';

/// Remote Config: id of the series currently on sale (e.g. `prelims_2027`).
const testSeriesActiveIdRemoteConfigKey = 'test_series_active_id';

/// Result of comparing this build to Remote Config.
class KillSwitchSnapshot {
  const KillSwitchSnapshot({
    required this.isActive,
    this.requiredMinimum,
    this.appVersion,
  });

  /// `true` when this app’s version is **strictly less** than [requiredMinimum].
  final bool isActive;

  /// Parsed Remote Config minimum, if any.
  final ReleaseVersion? requiredMinimum;

  /// Parsed pubspec `version` (from [packageInfoProvider]).
  final ReleaseVersion? appVersion;

  static const inactive = KillSwitchSnapshot(isActive: false);
}

@Riverpod(keepAlive: true)
Future<KillSwitchSnapshot> killSwitch(Ref ref) async {
  if (kIsWeb) {
    return KillSwitchSnapshot.inactive;
  }
  final pkg = await ref.watch(packageInfoProvider.future);
  final app = releaseVersionFromPackageInfo(pkg);
  if (app == null) {
    return KillSwitchSnapshot.inactive;
  }
  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 12),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(minutes: 30),
      ),
    );
    await rc.setDefaults(<String, dynamic>{
      killSwitchVersionRemoteConfigKey: '',
      communityTabEnabledRemoteConfigKey: true,
      dailyCaEnabledRemoteConfigKey: true,
      caShotsEnabledRemoteConfigKey: true,
      // On by default for admin preview; set admins_only false to open to all.
      dailyWarEnabledRemoteConfigKey: true,
      dailyWarAdminsOnlyRemoteConfigKey: true,
      dailyWarLobbyCountEnabledRemoteConfigKey: true,
      dailyWarMinVisibleLobbyCountRemoteConfigKey: 200,
      dailyWarLiveCountPollSecondsRemoteConfigKey: 15,
      dailyCaCalendarMinDateRemoteConfigKey: '2026-08-18',
      dailyCaRanksEnabledRemoteConfigKey: true,
      dailyCaRanksAdminsOnlyRemoteConfigKey: true,
      qotdMaxPostsPerDayRemoteConfigKey: 3,
      factOrBluffSecondsRemoteConfigKey: 10,
      questionCorrectionsRevisionRemoteConfigKey: 0,
      // Selling is off until you switch it on in the Firebase console.
      testSeriesSalesEnabledRemoteConfigKey: false,
      testSeriesActiveIdRemoteConfigKey: 'prelims_2027',
      adminDashboardCollectionEnabledRemoteConfigKey: true,
      // YYYY-MM-DD (time defaults to 09:30 local)
      'prelims_date': '2027-05-23',
      // JSON: { "video_link": "https://...", "message": "...", "version": 1 }
      'home_page_video': '',
      // Optional dismissible update banner (same format as kill_switch_version).
      'soft_update_version': '',
      'soft_update_message': '',
    });
    await rc.fetchAndActivate();
    final raw = rc.getString(killSwitchVersionRemoteConfigKey).trim();
    if (raw.isEmpty) {
      return KillSwitchSnapshot(isActive: false, appVersion: app);
    }
    final required = ReleaseVersion.parse(raw);
    if (required == null) {
      return KillSwitchSnapshot(isActive: false, appVersion: app);
    }
    final active = app.compareTo(required) < 0;
    return KillSwitchSnapshot(
      isActive: active,
      requiredMinimum: required,
      appVersion: app,
    );
  } on Object catch (_) {
    return KillSwitchSnapshot.inactive;
  }
}

/// Whether the Community tab should be shown (after [killSwitchProvider] fetch).
///
/// Fails open (`true`) while loading or on read errors so the tab stays unless RC
/// explicitly disables it. On web, only [FeatureFlags.communityTab] applies.
@Riverpod(keepAlive: true)
Future<bool> communityTabRemoteEnabled(Ref ref) async {
  if (kIsWeb) {
    return FeatureFlags.communityTab;
  }
  if (!FeatureFlags.communityTab) {
    return false;
  }
  await ref.watch(killSwitchProvider.future);
  try {
    return FirebaseRemoteConfig.instance.getBool(
      communityTabEnabledRemoteConfigKey,
    );
  } on Object catch (_) {
    return true;
  }
}

/// Whether the Daily Current Affairs Test home entry should be shown.
///
/// Fails closed (`false`) while loading or on read errors.
@Riverpod(keepAlive: true)
Future<bool> dailyCaRemoteEnabled(Ref ref) async {
  if (kIsWeb) {
    return false;
  }
  await ref.watch(killSwitchProvider.future);
  try {
    return FirebaseRemoteConfig.instance.getBool(
      dailyCaEnabledRemoteConfigKey,
    );
  } on Object catch (_) {
    return false;
  }
}

/// Whether the CA Shots home entry should be shown.
///
/// Fails closed (`false`) while loading or on read errors.
@Riverpod(keepAlive: true)
Future<bool> caShotsRemoteEnabled(Ref ref) async {
  if (kIsWeb) {
    return false;
  }
  await ref.watch(killSwitchProvider.future);
  try {
    return FirebaseRemoteConfig.instance.getBool(
      caShotsEnabledRemoteConfigKey,
    );
  } on Object catch (_) {
    return false;
  }
}

/// Whether Daily War is available for the **signed-in user**.
///
/// Requires [dailyWarEnabledRemoteConfigKey]. If
/// [dailyWarAdminsOnlyRemoteConfigKey] is true, only super-users pass.
/// Fails closed (`false`) while loading or on read errors.
@Riverpod(keepAlive: true)
Future<bool> dailyWarRemoteEnabled(Ref ref) async {
  if (kIsWeb) {
    return false;
  }
  await ref.watch(killSwitchProvider.future);
  try {
    final rc = FirebaseRemoteConfig.instance;
    if (!rc.getBool(dailyWarEnabledRemoteConfigKey)) {
      return false;
    }
    final adminsOnly = rc.getBool(dailyWarAdminsOnlyRemoteConfigKey);
    if (!adminsOnly) return true;
    return ref.watch(isSuperUserProvider);
  } on Object catch (_) {
    return false;
  }
}

/// Raw RC: Daily War limited to admin accounts (ignores who is signed in).
@Riverpod(keepAlive: true)
Future<bool> dailyWarAdminsOnlyRemote(Ref ref) async {
  if (kIsWeb) return true;
  await ref.watch(killSwitchProvider.future);
  try {
    return FirebaseRemoteConfig.instance.getBool(
      dailyWarAdminsOnlyRemoteConfigKey,
    );
  } on Object catch (_) {
    return true;
  }
}

/// Whether lobby / participant count numbers should be shown on War surfaces.
///
/// Fails open (`true`) so counts stay visible unless RC explicitly disables them.
@Riverpod(keepAlive: true)
Future<bool> dailyWarLobbyCountRemoteEnabled(Ref ref) async {
  if (kIsWeb) return false;
  await ref.watch(killSwitchProvider.future);
  try {
    return FirebaseRemoteConfig.instance.getBool(
      dailyWarLobbyCountEnabledRemoteConfigKey,
    );
  } on Object catch (_) {
    return true;
  }
}

/// Minimum lobby/participant count before showing the raw number.
@Riverpod(keepAlive: true)
Future<int> dailyWarMinVisibleLobbyCountRemote(Ref ref) async {
  const fallback = 200;
  if (kIsWeb) return fallback;
  await ref.watch(killSwitchProvider.future);
  try {
    final n = FirebaseRemoteConfig.instance.getInt(
      dailyWarMinVisibleLobbyCountRemoteConfigKey,
    );
    if (n <= 0) return fallback;
    return n.clamp(1, 1000000);
  } on Object catch (_) {
    return fallback;
  }
}

/// How often clients poll RTDB live counts during lobby / live (seconds).
///
/// Defaults to 15. Clamped to 3–60.
@Riverpod(keepAlive: true)
Future<int> dailyWarLiveCountPollSecondsRemote(Ref ref) async {
  const fallback = 15;
  if (kIsWeb) return fallback;
  await ref.watch(killSwitchProvider.future);
  try {
    final n = FirebaseRemoteConfig.instance.getInt(
      dailyWarLiveCountPollSecondsRemoteConfigKey,
    );
    if (n <= 0) return fallback;
    return n.clamp(3, 60);
  } on Object catch (_) {
    return fallback;
  }
}

/// Fact or Bluff countdown length from Remote Config (seconds).
///
/// Defaults to 10. Clamped to 3–60. Waits for [killSwitchProvider] so RC
/// defaults / fetch have run on mobile.
@Riverpod(keepAlive: true)
Future<int> factOrBluffSecondsRemote(Ref ref) async {
  const fallback = 10;
  if (kIsWeb) return fallback;
  try {
    await ref.watch(killSwitchProvider.future);
    final n =
        FirebaseRemoteConfig.instance.getInt(factOrBluffSecondsRemoteConfigKey);
    if (n <= 0) return fallback;
    return n.clamp(3, 60);
  } on Object catch (_) {
    return fallback;
  }
}

/// Whether the Test Series may be **sold** to people who have not bought it.
///
/// Fails closed (`false`) while loading, on web, or on read errors. Buyers are
/// handled separately: they keep access regardless of this flag.
@Riverpod(keepAlive: true)
Future<bool> testSeriesSalesRemoteEnabled(Ref ref) async {
  if (kIsWeb) return false;
  await ref.watch(killSwitchProvider.future);
  try {
    return FirebaseRemoteConfig.instance.getBool(
      testSeriesSalesEnabledRemoteConfigKey,
    );
  } on Object catch (_) {
    return false;
  }
}

/// Series id currently on sale (Remote Config `test_series_active_id`).
@Riverpod(keepAlive: true)
Future<String> testSeriesActiveIdRemote(Ref ref) async {
  const fallback = 'prelims_2027';
  if (kIsWeb) return fallback;
  await ref.watch(killSwitchProvider.future);
  try {
    final v = FirebaseRemoteConfig.instance
        .getString(testSeriesActiveIdRemoteConfigKey)
        .trim();
    return v.isEmpty ? fallback : v;
  } on Object catch (_) {
    return fallback;
  }
}
