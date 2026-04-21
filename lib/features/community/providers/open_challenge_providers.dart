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
