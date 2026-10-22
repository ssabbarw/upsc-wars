import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/super_user_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../../core/services/local_daily_reminders_sync.dart';
import '../../home/providers/auth_providers.dart';
import '../data/daily_ca_cloud_service.dart';
import '../data/daily_ca_firestore.dart';
import '../data/daily_ca_leaderboard_cache.dart';
import '../data/daily_ca_repository.dart';
import '../domain/daily_ca_rank_models.dart';
import '../domain/daily_ca_schedule.dart';

/// Earliest selectable daily CA date from Remote Config (`daily_ca_calendar_min_date`).
final dailyCaCalendarMinDateProvider = FutureProvider<DateTime>((ref) async {
  if (kIsWeb) return DailyCaSchedule.defaultCalendarMinDate;
  await ref.watch(killSwitchProvider.future);
  try {
    final raw = FirebaseRemoteConfig.instance
        .getString(dailyCaCalendarMinDateRemoteConfigKey)
        .trim();
    return DailyCaSchedule.parseCalendarMinDate(
      raw.isEmpty ? DailyCaSchedule.defaultCalendarMinDateIso : raw,
    );
  } on Object catch (_) {
    return DailyCaSchedule.defaultCalendarMinDate;
  }
});

final dailyCaRepositoryProvider = Provider<DailyCaRepository>((ref) {
  return DailyCaRepository(db: ref.watch(userDatabaseProvider));
});

/// Whether the clock-open paper actually has a live `daily_mcqs` document.
///
/// Snapshot stream so home updates when auto-publish writes the doc (the
/// one-shot fetch cached `false` if the user opened the app a few minutes
/// early).
final dailyCaScheduledPaperIsLiveProvider = StreamProvider.autoDispose<bool>((
  ref,
) async* {
  final minDate = await ref.watch(dailyCaCalendarMinDateProvider.future);
  final scheduled = DailyCaSchedule.paperQuizContentDate();
  if (scheduled == null) {
    yield false;
    return;
  }
  if (!DailyCaSchedule.isOnOrAfterMinDate(scheduled, minDate)) {
    yield false;
    return;
  }

  final iso = DailyCaSchedule.formatIsoDate(scheduled);
  yield* DailyCaFirestore.dayDoc(iso).snapshots().map((snap) {
    if (!snap.exists) return false;
    return DailyCaRepository.snapshotHasQuestions(snap.data());
  });
});

class DailyCaMonthKey {
  const DailyCaMonthKey({required this.year, required this.month});

  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is DailyCaMonthKey && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

final dailyCaCompletedDatesProvider = FutureProvider.autoDispose
    .family<Set<String>, DailyCaMonthKey>((ref, key) async {
      final db = ref.watch(userDatabaseProvider);
      return db.sessionsDao.getCompletedDailyCaDatesBetween(
        startInclusive: DailyCaSchedule.monthStartIso(key.year, key.month),
        endInclusive: DailyCaSchedule.monthEndIso(key.year, key.month),
      );
    });

final dailyCaDayCompletedProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, isoDate) async {
      final db = ref.watch(userDatabaseProvider);
      return db.sessionsDao.hasCompletedDailyCa(isoDate);
    });

/// Whether Daily CA ranks are available for the signed-in user.
///
/// Requires [dailyCaRanksEnabledRemoteConfigKey]. If
/// [dailyCaRanksAdminsOnlyRemoteConfigKey] is true, only super-users pass.
final dailyCaRanksRemoteEnabledProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  await ref.watch(killSwitchProvider.future);
  try {
    final rc = FirebaseRemoteConfig.instance;
    if (!rc.getBool(dailyCaRanksEnabledRemoteConfigKey)) {
      return false;
    }
    final adminsOnly = rc.getBool(dailyCaRanksAdminsOnlyRemoteConfigKey);
    if (!adminsOnly) return true;
    return ref.watch(isSuperUserProvider);
  } on Object catch (_) {
    return false;
  }
});

final dailyCaMySubmissionProvider = FutureProvider.autoDispose
    .family<DailyCaSubmission?, String>((ref, isoDate) async {
      final uid = ref.watch(authStateChangesProvider).asData?.value?.uid;
      if (uid == null || uid.isEmpty) return null;
      const cloud = DailyCaCloudService();
      final rank = await cloud.myRank(dateId: isoDate);
      if (!rank.ok) return null;
      return DailyCaSubmission(
        uid: uid,
        mode: rank.mode ?? 'live',
        score: rank.score ?? 0,
        correct: rank.correct ?? 0,
        wrong: rank.wrong ?? 0,
        unanswered: rank.unanswered ?? 0,
        elapsedMs: rank.elapsedMs ?? 0,
        air: rank.air,
        percentile: rank.percentile,
        participantCount: rank.participantCount,
      );
    });

/// Snapshot of the top 100. Frozen boards stay on disk and are not re-fetched.
final dailyCaLeaderboardCacheProvider = FutureProvider<DailyCaLeaderboardCache>(
  (ref) async {
    final prefs = await SharedPreferences.getInstance();
    return DailyCaLeaderboardCache(prefs);
  },
);

final dailyCaLeaderboardProvider = FutureProvider.autoDispose
    .family<DailyCaLeaderboard?, String>((ref, isoDate) async {
      final cache = await ref.watch(dailyCaLeaderboardCacheProvider.future);
      final cached = cache.get(isoDate);
      if (cached != null && cached.isFrozen) return cached;

      // Leaderboard docs require a signed-in account. Skip the read for guests
      // so we don't spam PERMISSION_DENIED and show a false "no ranks" empty.
      final user = ref.watch(authStateChangesProvider).asData?.value;
      if (!AuthSession.isAccountSignedIn(user)) {
        return cached;
      }

      try {
        final snap = await DailyCaFirestore.leaderboardDoc(isoDate).get();
        final data = snap.data();
        if (!snap.exists || data == null) return cached;
        final lb = DailyCaLeaderboard.fromMap(isoDate, data);
        if (lb.isFrozen) await cache.putFrozen(lb);
        return lb;
      } on Object catch (e, st) {
        debugPrint('dailyCaLeaderboardProvider($isoDate): $e');
        debugPrintStack(stackTrace: st);
        return cached;
      }
    });

/// Preferred board for the Daily CA hub: today's paper while live, else the
/// previous paper's board. Null when neither date is usable.
class DailyCaHubHeroBoard {
  const DailyCaHubHeroBoard({
    required this.dateId,
    this.lb,
    this.isToday = false,
  });

  final String dateId;
  final DailyCaLeaderboard? lb;
  final bool isToday;
}

final dailyCaHubHeroBoardProvider =
    FutureProvider.autoDispose<DailyCaHubHeroBoard?>((ref) async {
      final minDate = await ref.watch(dailyCaCalendarMinDateProvider.future);
      final ranksOn = await ref.watch(dailyCaRanksRemoteEnabledProvider.future);
      if (!ranksOn) return null;

      final todayPaper = DailyCaSchedule.paperQuizContentDate();
      final todayLive = await ref.watch(
        dailyCaScheduledPaperIsLiveProvider.future,
      );
      if (todayPaper != null &&
          todayLive &&
          DailyCaSchedule.isOnOrAfterMinDate(todayPaper, minDate)) {
        final iso = DailyCaSchedule.formatIsoDate(todayPaper);
        final lb = await ref.watch(dailyCaLeaderboardProvider(iso).future);
        return DailyCaHubHeroBoard(dateId: iso, lb: lb, isToday: true);
      }

      final prev = DailyCaSchedule.previousPaperQuizContentDate();
      if (prev == null || !DailyCaSchedule.isOnOrAfterMinDate(prev, minDate)) {
        return null;
      }
      final iso = DailyCaSchedule.formatIsoDate(prev);
      final lb = await ref.watch(dailyCaLeaderboardProvider(iso).future);
      if (lb == null || lb.top.isEmpty) return null;
      return DailyCaHubHeroBoard(dateId: iso, lb: lb, isToday: false);
    });

/// Bumped after [markDailyCaResultsOpened] so home can leave the revise hero.
class DailyCaResultsOpenedEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final dailyCaResultsOpenedEpochProvider =
    NotifierProvider<DailyCaResultsOpenedEpoch, int>(
      DailyCaResultsOpenedEpoch.new,
    );

/// Record that results/explanations for this paper date were opened.
Future<void> markDailyCaResultsOpened(WidgetRef ref, String isoDate) async {
  final iso = isoDate.trim();
  if (iso.isEmpty) return;
  final prefs = await ref.read(prefsServiceProvider.future);
  if (prefs.hasOpenedDailyCaResults(iso)) return;
  prefs.markDailyCaResultsOpened(iso);
  ref.read(dailyCaResultsOpenedEpochProvider.notifier).bump();
  unawaited(
    LocalDailyRemindersSync.syncPractice(
      prefs: prefs,
      db: ref.read(userDatabaseProvider),
    ),
  );
}
