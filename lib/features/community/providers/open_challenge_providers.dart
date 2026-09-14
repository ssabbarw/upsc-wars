import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../home/providers/auth_providers.dart';
import '../data/open_challenge_repository.dart';
import '../domain/open_challenge_models.dart';
import '../open_challenge/open_challenge_create_availability.dart';

final openChallengeRepositoryProvider = Provider<OpenChallengeRepository>((ref) {
  return OpenChallengeRepository(FirebaseFirestore.instance);
});

bool _isFirestorePermissionDenied(Object error) {
  if (error is FirebaseException) {
    return error.code.toLowerCase() == 'permission-denied';
  }
  final text = error.toString();
  return text.contains('PERMISSION_DENIED') ||
      text.contains('permission-denied');
}

/// Ensures Auth has a user + ID token before Firestore rules run. Returns null
/// when signed out or still restoring, so callers can skip the read.
Future<User?> _authenticatedUserForFirestore(Ref ref) async {
  final auth = ref.watch(authStateChangesProvider);
  if (auth.isLoading) return null;
  final user = auth.asData?.value;
  if (user == null) return null;
  // Cold start can emit a user before the token reaches Firestore; rules then
  // see request.auth == null and deny (same pattern as community presence).
  await user.getIdToken();
  return user;
}

final openChallengesListProvider =
    FutureProvider.autoDispose<List<OpenChallengeListTileModel>>((ref) async {
  final user = await _authenticatedUserForFirestore(ref);
  if (user == null) return const [];
  final repo = ref.watch(openChallengeRepositoryProvider);
  try {
    return await repo.fetchAllSummaries(currentUserEmail: user.email);
  } on Object catch (e) {
    if (_isFirestorePermissionDenied(e)) {
      if (kDebugMode) {
        debugPrint('[OpenChallenge:list] permission-denied: $e');
      }
      return const [];
    }
    rethrow;
  }
});

/// Challenges the user has not attempted, most contested first.
///
/// Home features the head of this list and links the rest through to Community.
/// Ranking by attempt count rather than recency stops a minutes-old challenge
/// with only the creator on it from outranking one people are fighting over.
///
/// Costs exactly one document read per app session: it reads the Cloud
/// Function-maintained index, and is deliberately **not** autoDispose so
/// returning to Home does not refetch. Community keeps its own always-fresh
/// [openChallengesListProvider].
final homeOpenChallengesProvider =
    FutureProvider<List<OpenChallengeListTileModel>>((ref) async {
  // Index is world-readable (no emails) so unsigned users still see Home
  // teasers. Watch auth so a late sign-in re-ranks via attempted prefs —
  // without it, this kept-alive provider would stay stale for the session.
  ref.watch(authStateChangesProvider);

  final prefs = await ref.watch(prefsServiceProvider.future);
  final repo = ref.watch(openChallengeRepositoryProvider);
  try {
    final items = await repo.fetchHomeIndex();
    if (kDebugMode) {
      debugPrint(
        '[OpenChallenge:home] index read ok: ${items.length} live entries',
      );
    }
    return rankHomeOpenChallenges(
      items,
      attempted: prefs.attemptedOpenChallengeIds,
    );
  } on Object catch (e) {
    // Home renders this as an absent row; don't surface expected auth/rules
    // denials as provider errors (Crashlytics).
    if (kDebugMode) {
      debugPrint('[OpenChallenge:home] index read FAILED: $e');
    }
    if (_isFirestorePermissionDenied(e)) return const [];
    rethrow;
  }
});

/// Drops already-attempted challenges and orders the rest most-contested first,
/// newest breaking ties. Pure so the ordering rule stays testable.
List<OpenChallengeListTileModel> rankHomeOpenChallenges(
  List<OpenChallengeListTileModel> items, {
  Set<String> attempted = const {},
}) {
  final untried = [
    for (final item in items)
      if (item.myScore == null && !attempted.contains(item.id)) item,
  ];
  untried.sort((a, b) {
    final byContest = b.attemptCount.compareTo(a.attemptCount);
    if (byContest != 0) return byContest;
    final ta = a.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tb = b.postedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return tb.compareTo(ta);
  });
  return untried;
}

final openChallengeDetailProvider =
    FutureProvider.autoDispose.family<OpenChallengeDetail?, String>((ref, id) async {
  final repo = ref.watch(openChallengeRepositoryProvider);
  return repo.fetchDetail(id);
});

/// Local prefs: whether create / post-as-challenge is allowed (24h after last publish).
final openChallengeCreateAvailabilityProvider =
    FutureProvider.autoDispose<OpenChallengeCreateAvailability>((ref) async {
  final prefs = await ref.watch(prefsServiceProvider.future);
  return OpenChallengeCreateAvailability.fromPrefs(prefs);
});

/// Call after a successful Firestore publish (create flow only).
Future<void> recordOpenChallengePublished(WidgetRef ref) async {
  final prefs = await ref.read(prefsServiceProvider.future);
  prefs.openChallengeLastPublishedAtMs =
      DateTime.now().millisecondsSinceEpoch;
  ref.invalidate(openChallengeCreateAvailabilityProvider);
}
