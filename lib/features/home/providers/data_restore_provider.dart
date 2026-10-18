import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/backup/bookmark_backup_service.dart';
import '../../../core/backup/session_backup_service.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';
import '../../test_series/providers/test_series_providers.dart';
import 'home_activation_provider.dart';

final sessionBackupServiceProvider = Provider<SessionBackupService>(
  (ref) => SessionBackupService(userDb: ref.watch(userDatabaseProvider)),
);

final bookmarkBackupServiceProvider = Provider<BookmarkBackupService>(
  (ref) => BookmarkBackupService(userDb: ref.watch(userDatabaseProvider)),
);

/// Pref key remembering which account has already been restored on this
/// install (`backup_restored_uid`).
const _restoredUidPrefKey = 'backup_restored_uid';

/// Restores the signed-in account's backed-up tests in the background and
/// exposes progress for the home "Restoring your data" card.
///
/// Runs at most once per account per process. If the account was already
/// restored on this install *and* the local DB still has history, it only
/// uploads anything pending (a cheap local query).
class DataRestoreController extends Notifier<RestoreProgress> {
  String? _handledUid;
  bool _running = false;
  void Function()? _stopBookmarkWatch;

  @override
  RestoreProgress build() => const RestoreProgress();

  /// Call whenever the Firebase user changes. Anonymous users are ignored —
  /// their history is uploaded by [SessionBackupService.runBackfillOnce] the
  /// moment they sign in.
  Future<void> onUserChanged(User? user) async {
    if (!AuthSession.isAccountSignedIn(user)) return;
    final uid = user!.uid;
    if (_handledUid == uid || _running) return;
    _handledUid = uid;
    await _run(uid);
  }

  /// Manual retry after a failure.
  Future<void> retry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (!AuthSession.isAccountSignedIn(user) || _running) return;
    await _run(user!.uid);
  }

  /// Hides the "done" card.
  void dismiss() {
    if (state.phase == RestorePhase.done ||
        state.phase == RestorePhase.failed) {
      state = const RestoreProgress();
    }
  }

  Future<void> _run(String uid) async {
    _running = true;
    final service = ref.read(sessionBackupServiceProvider);
    try {
      final prefs = await ref.read(prefsServiceProvider.future);
      final db = ref.read(userDatabaseProvider);
      final alreadyRestored = prefs.getString(_restoredUidPrefKey) == uid;
      final localHasHistory = await db.sessionsDao.countCompletedSessions() > 0;

      if (!(alreadyRestored && localHasHistory)) {
        final caRepo = ref.read(dailyCaRepositoryProvider);
        Future<void> ensureCa(String date) async {
          await caRepo.ensureCachedForDate(date);
        }

        final restored = await service.restore(
          onProgress: (p) => state = p,
          ensureCaDate: ensureCa,
        );
        // Bookmarks are one small doc; restore them (and their revision-queue
        // entries) before the watcher below can upload a partial set.
        final bookmarksRestored = await ref
            .read(bookmarkBackupServiceProvider)
            .restore(ensureCaDate: ensureCa);
        await prefs.setString(_restoredUidPrefKey, uid);
        if (restored > 0 || bookmarksRestored > 0) {
          _refreshLocalViews();
        }
        if (restored > 0) {
          state = state.copyWith(
            phase: RestorePhase.done,
            restored: restored,
            message: 'Restored $restored ${restored == 1 ? 'test' : 'tests'}',
          );
        } else {
          state = const RestoreProgress();
        }
      }

      // Restore is settled for this account, so it is now safe to mirror local
      // bookmark changes to the cloud (also uploads existing users' bookmarks
      // the first time, via the content hash).
      final bookmarks = ref.read(bookmarkBackupServiceProvider);
      _stopBookmarkWatch?.call();
      _stopBookmarkWatch = bookmarks.startWatching();
      unawaited(bookmarks.syncIfChanged());
    } catch (e, st) {
      debugPrint('DataRestoreController: restore failed: $e');
      debugPrintStack(stackTrace: st);
      // Allow retry / the next launch to try again.
      _handledUid = null;
      state = state.copyWith(
        phase: RestorePhase.failed,
        message: 'Could not restore your data. Check your connection.',
      );
    } finally {
      _running = false;
    }

    // One-time upload of history that predates backup (old users updating the
    // app). Delayed so it never competes with first-frame work; the reading and
    // encoding run on a background isolate. After it succeeds once it is never
    // run again — tests are uploaded inline at submit.
    unawaited(
      Future<void>.delayed(
        const Duration(seconds: 8),
        () => service.runBackfillOnce(),
      ),
    );
  }

  void _refreshLocalViews() {
    ref.invalidate(homeStateProvider);
    ref.invalidate(homeActivationProvider);
    ref.invalidate(seriesStatsProvider);
    ref.invalidate(seriesInProgressProvider);
    ref.invalidate(mySeriesIdsProvider);
  }
}

final dataRestoreProvider =
    NotifierProvider<DataRestoreController, RestoreProgress>(
      DataRestoreController.new,
    );
