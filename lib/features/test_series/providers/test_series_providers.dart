import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/super_user_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../home/providers/auth_providers.dart';
import '../data/series_local_repository.dart';
import '../data/test_series_access_service.dart';
import '../data/test_series_purchase_service.dart';
import '../data/test_series_repository.dart';
import '../domain/series_stats.dart';
import '../domain/test_series_models.dart';

final testSeriesRepositoryProvider = Provider<TestSeriesRepository>(
  (ref) => TestSeriesRepository(),
);

final testSeriesPurchaseServiceProvider = Provider<TestSeriesPurchaseService>((
  ref,
) {
  final service = TestSeriesPurchaseService();
  ref.onDispose(service.dispose);
  return service;
});

final seriesLocalRepositoryProvider = Provider<SeriesLocalRepository>(
  (ref) => SeriesLocalRepository(ref.watch(userDatabaseProvider)),
);

final testSeriesAccessServiceProvider = Provider<TestSeriesAccessService>(
  (ref) => TestSeriesAccessService(),
);

/// Series ids the signed-in user owns: RevenueCat entitlements (paid) plus
/// account grants from a promo code or free offer (`test_series_grants/{uid}`),
/// cached locally so access works offline.
///
/// A series pass is one-time and never expires: once an id is in this set the
/// user keeps full access to that series' tests, history and dashboard.
///
/// In [kDebugMode] nothing is cached: ownership follows RevenueCat and the
/// server grants only, so cancelled license-test purchases can be bought again
/// without clearing app data.
class OwnedSeriesNotifier extends AsyncNotifier<Set<String>> {
  String _cacheKey(String? uid) => 'test_series_owned_ids_${uid ?? 'anon'}';

  Future<Set<String>> _readCache(String? uid) async {
    if (kDebugMode) {
      // Drop any prefs left over from earlier debug runs.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey(uid));
      return const {};
    }
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_cacheKey(uid)) ?? const <String>[]).toSet();
  }

  Future<void> _writeCache(String? uid, Set<String> ids) async {
    if (kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cacheKey(uid), ids.toList());
  }

  /// Grants for [uid] from Firestore. Null when signed out or the read failed
  /// (callers then keep what they already know instead of dropping access).
  Future<Set<String>?> _fetchGrants(String? uid) async {
    if (uid == null) return null;
    try {
      return await ref
          .read(testSeriesAccessServiceProvider)
          .fetchGrantedSeriesIds(uid)
          // A slow network must not hold the entry screen on a spinner.
          .timeout(const Duration(seconds: 6));
    } on Object {
      return null;
    }
  }

  @override
  Future<Set<String>> build() async {
    final service = ref.watch(testSeriesPurchaseServiceProvider);
    final User? user = ref.watch(authStateChangesProvider).asData?.value;
    final uid = AuthSession.isAccountSignedIn(user) ? user!.uid : null;

    final cached = await _readCache(uid);
    // Latest grants we know about; RevenueCat updates must not drop them.
    var grants = const <String>{};

    final sub = service.ownedChanges.listen((ids) {
      if (kDebugMode) {
        // Trust live entitlements only (no sticky merge).
        state = AsyncData({...ids, ...grants});
        return;
      }
      // Never drop a cached pass because of a transient empty answer.
      final merged = {...cached, ...grants, ...ids};
      unawaited(_writeCache(uid, merged));
      state = AsyncData(merged);
    });
    ref.onDispose(sub.cancel);

    grants = await _fetchGrants(uid) ?? const <String>{};

    var live = const <String>{};
    if (service.isSupported) {
      try {
        await service.sync(accountUid: uid);
        live = await service.ownedSeriesIds();
      } on Object {
        // Fall through with whatever the cache and grants say.
      }
    }
    if (kDebugMode) return {...live, ...grants};
    final merged = {...cached, ...grants, ...live};
    await _writeCache(uid, merged);
    return merged;
  }

  /// Re-reads entitlements and grants (after a purchase, restore or redeem).
  ///
  /// Soft-updates [state] instead of [invalidateSelf] so the series home
  /// (and its TabBar) is not torn down into a loading spinner mid-frame.
  Future<void> refresh() async {
    final service = ref.read(testSeriesPurchaseServiceProvider);
    final user = FirebaseAuth.instance.currentUser;
    final uid = AuthSession.isAccountSignedIn(user) ? user!.uid : null;
    try {
      final grants = await _fetchGrants(uid) ?? const <String>{};
      var live = const <String>{};
      if (service.isSupported) {
        await service.sync(accountUid: uid);
        live = await service.ownedSeriesIds();
      }
      if (kDebugMode) {
        state = AsyncData({...live, ...grants});
        return;
      }
      final current = state.asData?.value ?? await _readCache(uid);
      final merged = {...current, ...grants, ...live};
      await _writeCache(uid, merged);
      state = AsyncData(merged);
    } on Object {
      // Keep whatever we already showed.
    }
  }

  /// Restores access for the signed-in account: store purchases (RevenueCat)
  /// plus free-access grants. Returns the owned ids.
  ///
  /// Throws only when *neither* source could be checked, so "nothing found"
  /// is never reported just because the network was down.
  Future<Set<String>> restore() async {
    final service = ref.read(testSeriesPurchaseServiceProvider);
    final user = FirebaseAuth.instance.currentUser;
    final uid = AuthSession.isAccountSignedIn(user) ? user!.uid : null;

    Set<String> restored = const {};
    Object? storeError;
    try {
      restored = await service.restore();
    } on Object catch (e) {
      storeError = e;
    }
    final grants = await _fetchGrants(uid);
    if (storeError != null && grants == null) throw storeError;

    final fresh = {...restored, ...?grants};
    if (kDebugMode) {
      state = AsyncData(fresh);
      return fresh;
    }
    final current = state.asData?.value ?? const <String>{};
    final merged = {...current, ...fresh};
    await _writeCache(uid, merged);
    state = AsyncData(merged);
    return merged;
  }
}

final ownedSeriesIdsProvider =
    AsyncNotifierProvider<OwnedSeriesNotifier, Set<String>>(
      OwnedSeriesNotifier.new,
    );

/// Series currently on sale (Remote Config).
final activeSeriesIdProvider = FutureProvider<String>(
  (ref) => ref.watch(testSeriesActiveIdRemoteProvider.future),
);

/// Whether the home entry should show. Buyers always see it (even after sales
/// are switched off); everyone else only while selling is on. Super-users
/// always see it so they can test before launch.
///
/// A live "free for everyone" offer also shows it, so the push that announces
/// the offer always lands somewhere even while sales are off.
final testSeriesEntryVisibleProvider = FutureProvider<bool>((ref) async {
  // Debug builds always show it so the feature can be developed and tested
  // without touching Remote Config. Release builds are unaffected.
  if (kDebugMode || ref.watch(isSuperUserProvider)) return true;
  final owned = await ref.watch(ownedSeriesIdsProvider.future);
  if (owned.isNotEmpty) return true;
  if (await ref.watch(testSeriesOpenOfferProvider.future) != null) return true;
  return ref.watch(testSeriesSalesRemoteEnabledProvider.future);
});

/// Whether the user can be offered the *purchase* of the active series.
final testSeriesCanSellProvider = FutureProvider<bool>((ref) async {
  if (kDebugMode || ref.watch(isSuperUserProvider)) return true;
  return ref.watch(testSeriesSalesRemoteEnabledProvider.future);
});

/// The live "free for everyone" offer on the active series, or null.
///
/// Public read, so it works signed out. Any failure counts as "no offer":
/// this only ever adds a free path, it never gates one.
final testSeriesOpenOfferProvider =
    FutureProvider.autoDispose<SeriesOpenOffer?>((ref) async {
      try {
        final seriesId = await ref.watch(activeSeriesIdProvider.future);
        return await ref
            .read(testSeriesAccessServiceProvider)
            .fetchOpenOffer(seriesId)
            .timeout(const Duration(seconds: 6));
      } on Object {
        return null;
      }
    });

/// Whether the active series can be unlocked at all right now: on sale, or
/// free through a live offer. Drives the unlock bar and entry screen.
final testSeriesCanUnlockProvider = FutureProvider<bool>((ref) async {
  if (await ref.watch(testSeriesCanSellProvider.future)) return true;
  return await ref.watch(testSeriesOpenOfferProvider.future) != null;
});

/// A series with all its tests. Emits the cached copy first (instant,
/// offline-friendly), then the fresh copy from Firestore.
///
/// Catalog reads are public so signed-out users get a preview; paid access is
/// gated in the UI via RevenueCat (`ownedSeriesIdsProvider`).
///
/// Retry is disabled: Riverpod 3 would otherwise keep the provider in a
/// "loading" state while it silently retries, so a permission or network error
/// would show an endless spinner instead of the Retry button.
final seriesBundleProvider = StreamProvider.family<SeriesBundle, String>((
  ref,
  seriesId,
) async* {
  final repo = ref.watch(testSeriesRepositoryProvider);
  final cached = await repo.readCache(seriesId);
  if (cached != null) yield cached;
  try {
    yield await repo.fetch(seriesId);
  } on Object {
    if (cached == null) rethrow;
  }
}, retry: (_, _) => null);

/// Stats and per-test attempts for a series, from the local database.
final seriesStatsProvider = FutureProvider.autoDispose.family<SeriesStats, String>((
  ref,
  seriesId,
) async {
  final bundle = await ref.watch(seriesBundleProvider(seriesId).future);
  final local = ref.watch(seriesLocalRepositoryProvider);
  final attempts = await local.completedAttempts(seriesId);
  final answers = await local.answerRows(seriesId);
  return SeriesStats.compute(
    bundle: bundle,
    attemptList: attempts,
    answers: answers,
  );
});

/// `testId -> sessionId` for started-but-unfinished scored attempts.
final seriesInProgressProvider = FutureProvider.autoDispose.family<Map<String, String>, String>((
  ref,
  seriesId,
) {
  return ref.watch(seriesLocalRepositoryProvider).inProgressSessions(seriesId);
});

/// Every series that belongs in "My Test Series": owned ones plus any the user
/// has attempted tests of (for example only the free tests). Newest year first.
final mySeriesIdsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final owned = await ref.watch(ownedSeriesIdsProvider.future);
  final attempted = await ref
      .watch(seriesLocalRepositoryProvider)
      .seriesIdsWithSessions();
  final ids = <String>{...owned, ...attempted}.toList()
    ..sort((a, b) => b.compareTo(a));
  return ids;
});

/// Call after a test finishes (or starts) so lists and the dashboard refresh.
void refreshSeriesLocalState(WidgetRef ref, String seriesId) {
  ref.invalidate(seriesStatsProvider(seriesId));
  ref.invalidate(seriesInProgressProvider(seriesId));
}
