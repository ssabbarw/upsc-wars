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

/// Lowercased emails the current user has blocked.
///
/// Loaded once from Firestore (then cached on device). Block/unblock updates
/// the cache and writes the remote doc — no snapshot listener.
final blockedUserEmailsProvider =
    AsyncNotifierProvider<BlockedUserEmailsNotifier, Set<String>>(
      BlockedUserEmailsNotifier.new,
    );

class BlockedUserEmailsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final email = _currentUserEmail(ref);
    if (email == null) return const {};

    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final cache = BlockedUsersLocalCache(prefs);
    final cached = cache.read(email);
    if (cached != null) {
      unawaited(_refreshFromRemote(email, cache));
      return cached;
    }

    try {
      return await _loadFromRemote(email, cache);
    } catch (e, st) {
      debugPrint('fetchBlockedEmails failed: $e');
      debugPrintStack(stackTrace: st);
      return const {};
    }
  }

  Future<Set<String>> _loadFromRemote(
    String email,
    BlockedUsersLocalCache cache,
  ) async {
    final remote = await ref
        .read(communityRepositoryProvider)
        .fetchBlockedEmails(email);
    await cache.write(email, remote);
    return remote;
  }

  Future<void> _refreshFromRemote(
    String email,
    BlockedUsersLocalCache cache,
  ) async {
    try {
      final remote = await _loadFromRemote(email, cache);
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
    final me = AuthSession.emailOf(
          ref.read(authStateChangesProvider).asData?.value,
        ) ??
        AuthSession.currentEmail();
    if (me == null) return;
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
