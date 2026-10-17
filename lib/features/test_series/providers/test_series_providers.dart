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

/// Series ids the signed-in user owns (RevenueCat entitlements, cached
/// locally so access works offline).
///
/// A series pass is one-time and never expires: once an id is in this set the
/// user keeps full access to that series' tests, history and dashboard.
class OwnedSeriesNotifier extends AsyncNotifier<Set<String>> {
  String _cacheKey(String? uid) => 'test_series_owned_ids_${uid ?? 'anon'}';

  Future<Set<String>> _readCache(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_cacheKey(uid)) ?? const <String>[]).toSet();
  }

  Future<void> _writeCache(String? uid, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cacheKey(uid), ids.toList());
  }

  @override
  Future<Set<String>> build() async {
    final service = ref.watch(testSeriesPurchaseServiceProvider);
    final User? user = ref.watch(authStateChangesProvider).asData?.value;
    final uid = AuthSession.isAccountSignedIn(user) ? user!.uid : null;

    final cached = await _readCache(uid);

    final sub = service.ownedChanges.listen((ids) {
      // Never drop a cached pass because of a transient empty answer.
      final merged = {...cached, ...ids};
      unawaited(_writeCache(uid, merged));
      state = AsyncData(merged);
    });
    ref.onDispose(sub.cancel);

    if (!service.isSupported) return cached;
    try {
      await service.sync(accountUid: uid);
      final live = await service.ownedSeriesIds();
      final merged = {...cached, ...live};
      await _writeCache(uid, merged);
      return merged;
    } on Object {
      return cached;
    }
  }

  /// Re-reads entitlements from RevenueCat (after a purchase or restore).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Restores purchases from the store account. Returns the owned ids.
  Future<Set<String>> restore() async {
    final service = ref.read(testSeriesPurchaseServiceProvider);
    final restored = await service.restore();
    final current = state.asData?.value ?? const <String>{};
    final merged = {...current, ...restored};
    final user = ref.read(authStateChangesProvider).asData?.value;
    final uid = AuthSession.isAccountSignedIn(user) ? user!.uid : null;
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
final testSeriesEntryVisibleProvider = FutureProvider<bool>((ref) async {
  // Debug builds always show it so the feature can be developed and tested
  // without touching Remote Config. Release builds are unaffected.
  if (kDebugMode || ref.watch(isSuperUserProvider)) return true;
  final owned = await ref.watch(ownedSeriesIdsProvider.future);
  if (owned.isNotEmpty) return true;
  return ref.watch(testSeriesSalesRemoteEnabledProvider.future);
});

/// Whether the user can be offered the *purchase* of the active series.
final testSeriesCanSellProvider = FutureProvider<bool>((ref) async {
  if (kDebugMode || ref.watch(isSuperUserProvider)) return true;
  return ref.watch(testSeriesSalesRemoteEnabledProvider.future);
});

/// A series with all its tests. Emits the cached copy first (instant,
/// offline-friendly), then the fresh copy from Firestore.
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
