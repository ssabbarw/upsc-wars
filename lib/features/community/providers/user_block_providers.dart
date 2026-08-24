import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../home/providers/auth_providers.dart';
import '../data/blocked_users_local_cache.dart';
import '../domain/entities/community_user.dart';
import 'community_providers.dart';

String? _currentUserEmail(Ref ref) {
  return AuthSession.emailOf(
        ref.watch(authStateChangesProvider).asData?.value,
      ) ??
      AuthSession.currentEmail();
}

String? _currentUserUid(Ref ref) {
  return ref.read(authStateChangesProvider).asData?.value?.uid;
}

/// Lowercased emails the current user has blocked.
///
/// Firebase `block_lists/{uid}` is read on login (and once if this device has
/// no cache). After that the on-device cache is the source of truth. Block /
/// unblock writes the cache and `block_lists/{uid}`.
final blockedUserEmailsProvider =
    AsyncNotifierProvider<BlockedUserEmailsNotifier, Set<String>>(
      BlockedUserEmailsNotifier.new,
    );

class BlockedUserEmailsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    ref.listen(authStateChangesProvider, (prev, next) {
      final prevReady = prev?.hasValue ?? false;
      if (!prevReady) return;
      final wasSignedIn = AuthSession.isAccountSignedIn(prev?.asData?.value);
      final nowSignedIn = AuthSession.isAccountSignedIn(next.asData?.value);
      if (wasSignedIn || !nowSignedIn) return;
      unawaited(_hydrateFromRemote());
    });

    final user = ref.read(authStateChangesProvider).asData?.value;
    final email = _currentUserEmail(ref);
    final uid = _currentUserUid(ref);
    if (email == null ||
        uid == null ||
        uid.isEmpty ||
        !AuthSession.isAccountSignedIn(user)) {
      return const {};
    }

    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final cache = BlockedUsersLocalCache(prefs);
    final cached = cache.read(email);
    if (cached != null) return cached;

    try {
      return await _loadFromRemote(email: email, uid: uid, cache: cache);
    } catch (e, st) {
      debugPrint('fetchBlockedEmails failed: $e');
      debugPrintStack(stackTrace: st);
      return const {};
    }
  }

  Future<Set<String>> _loadFromRemote({
    required String email,
    required String uid,
    required BlockedUsersLocalCache cache,
  }) async {
    final remote = await ref
        .read(communityRepositoryProvider)
        .fetchBlockedEmails(ownerUid: uid);
    await cache.write(email, remote);
    return remote;
  }

  Future<void> _hydrateFromRemote() async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    final email = AuthSession.emailOf(user);
    final uid = user?.uid;
    if (email == null ||
        uid == null ||
        uid.isEmpty ||
        !AuthSession.isAccountSignedIn(user)) {
      return;
    }
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final cache = BlockedUsersLocalCache(prefs);
      final remote = await _loadFromRemote(
        email: email,
        uid: uid,
        cache: cache,
      );
      if (!ref.mounted) return;
      final current = AuthSession.emailOf(
            ref.read(authStateChangesProvider).asData?.value,
          ) ??
          AuthSession.currentEmail();
      if (current != email) return;
      state = AsyncData(remote);
    } catch (e, st) {
      debugPrint('fetchBlockedEmails failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> setBlocked({
    required String otherEmail,
    required bool blocked,
  }) async {
    final user = ref.read(authStateChangesProvider).asData?.value;
    final me = AuthSession.emailOf(user) ?? AuthSession.currentEmail();
    final uid = user?.uid;
    if (me == null || uid == null || uid.isEmpty) return;
    final other = otherEmail.toLowerCase().trim();
    if (other.isEmpty || other == me) return;

    final previous = state.value ?? const <String>{};
    final next = {...previous};
    if (blocked) {
      next.add(other);
    } else {
      next.remove(other);
    }
    state = AsyncData(next);

    final prefs = await ref.read(sharedPreferencesProvider.future);
    final cache = BlockedUsersLocalCache(prefs);
    await cache.write(me, next);

    try {
      await ref.read(communityRepositoryProvider).setUserBlocked(
            ownerEmail: me,
            otherEmail: other,
            blocked: blocked,
            blockedEmails: next,
            ownerUid: uid,
          );
    } catch (e) {
      state = AsyncData(previous);
      await cache.write(me, previous);
      rethrow;
    }
  }
}

/// True if [otherEmail] is blocked by the signed-in user.
final isPeerBlockedProvider =
    Provider.family<bool, String>((ref, otherEmail) {
  final normalized = otherEmail.toLowerCase().trim();
  final blocked = ref.watch(blockedUserEmailsProvider).value;
  if (blocked == null) return false;
  return blocked.contains(normalized);
});

/// Profile docs for people the current user has blocked. Missing docs omitted.
final blockedUserProfilesProvider =
    FutureProvider<Map<String, CommunityUser>>((ref) async {
  final emails = await ref.watch(blockedUserEmailsProvider.future);
  if (emails.isEmpty) return const {};
  return ref
      .read(communityRepositoryProvider)
      .fetchCommunityUsersByEmails(emails);
});
