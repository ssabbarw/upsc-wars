import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../home/providers/auth_providers.dart';
import '../data/open_challenge_repository.dart';
import '../domain/open_challenge_models.dart';
import '../open_challenge/open_challenge_create_availability.dart';

final openChallengeRepositoryProvider = Provider<OpenChallengeRepository>((ref) {
  return OpenChallengeRepository(FirebaseFirestore.instance);
});

final openChallengesListProvider =
    FutureProvider.autoDispose<List<OpenChallengeListTileModel>>((ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  final repo = ref.watch(openChallengeRepositoryProvider);
  return repo.fetchAllSummaries(currentUserEmail: user?.email);
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
  final prefs = await ref.watch(prefsServiceProvider.future);
  final repo = ref.watch(openChallengeRepositoryProvider);
  final items = await repo.fetchHomeIndex();
  return rankHomeOpenChallenges(
    items,
    attempted: prefs.attemptedOpenChallengeIds,
  );
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
