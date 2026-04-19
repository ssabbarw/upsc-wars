import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../home/providers/auth_providers.dart';
import '../data/community_repository.dart';
import '../domain/community_bucket_utils.dart';
import '../domain/entities/community_user.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(FirebaseFirestore.instance);
});

final communityRecentUsersProvider =
    AsyncNotifierProvider<CommunityRecentUsersNotifier, List<CommunityUser>>(
      CommunityRecentUsersNotifier.new,
    );

class CommunityRecentUsersNotifier extends AsyncNotifier<List<CommunityUser>> {
  int _bucketOffset = 0;
  bool _hasMore = true;
  bool _loadMoreInFlight = false;
  DateTime? _lastRefreshedAt;

  bool get hasMore => _hasMore;
  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  @override
  Future<List<CommunityUser>> build() async {
    return _fetchFirstPage();
  }

  Future<List<CommunityUser>> _fetchFirstPage() async {
    _bucketOffset = 0;
    _hasMore = true;
    final repo = ref.read(communityRepositoryProvider);
    final users = await repo.fetchRecentUsers(bucketOffset: _bucketOffset);
    _hasMore = _bucketOffset < CommunityBucketUtils.maxBucketLookback - 1;
    _lastRefreshedAt = DateTime.now();
    return users;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading || _loadMoreInFlight) return;
    final nextOffset = _bucketOffset + 1;
    if (nextOffset >= CommunityBucketUtils.maxBucketLookback) {
      _hasMore = false;
      state = AsyncData(state.value ?? const <CommunityUser>[]);
      return;
    }

    _loadMoreInFlight = true;
    final current = state.value ?? const <CommunityUser>[];
    state = AsyncData(current);
    try {
      final repo = ref.read(communityRepositoryProvider);
      final nextBatch = await repo.fetchRecentUsers(bucketOffset: nextOffset);
      _bucketOffset = nextOffset;
      _hasMore = _bucketOffset < CommunityBucketUtils.maxBucketLookback - 1;
      final merged = <String, CommunityUser>{for (final u in current) u.email: u};
      for (final u in nextBatch) {
        final existing = merged[u.email];
        if (existing == null || u.lastOnlineTime > existing.lastOnlineTime) {
          merged[u.email] = u;
        }
      }
      final list = merged.values.toList()
        ..sort((a, b) => b.lastOnlineTime.compareTo(a.lastOnlineTime));
      state = AsyncData(list);
    } catch (_) {
      // Keep current list and bucket cursor so the user can retry the same bucket.
      state = AsyncData(current);
    } finally {
      _loadMoreInFlight = false;
    }
  }
}

final communityChallengersProvider = FutureProvider<List<CommunityUser>>((
  ref,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.fetchChallengers();
});

final communitySettingsProvider =
    AsyncNotifierProvider<CommunitySettingsNotifier, CommunitySettingsState>(
      CommunitySettingsNotifier.new,
    );

class CommunitySettingsState {
  const CommunitySettingsState({
    required this.acceptingBattleInvites,
    required this.showInBattleStatus,
  });

  final bool acceptingBattleInvites;
  final bool showInBattleStatus;

  CommunitySettingsState copyWith({
    bool? acceptingBattleInvites,
    bool? showInBattleStatus,
  }) {
    return CommunitySettingsState(
      acceptingBattleInvites:
          acceptingBattleInvites ?? this.acceptingBattleInvites,
      showInBattleStatus: showInBattleStatus ?? this.showInBattleStatus,
    );
  }
}

class CommunitySettingsNotifier extends AsyncNotifier<CommunitySettingsState> {
  static const _prefAcceptInvites = 'community_accepting_battle_invites';
  static const _prefShowBattleStatus = 'community_show_in_battle_status';

  @override
  Future<CommunitySettingsState> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return CommunitySettingsState(
      acceptingBattleInvites: prefs.getBool(_prefAcceptInvites) ?? true,
      showInBattleStatus: prefs.getBool(_prefShowBattleStatus) ?? true,
    );
  }

  Future<void> updateSettings({
    required bool acceptingBattleInvites,
    required bool showInBattleStatus,
  }) async {
    final current =
        state.value ??
        const CommunitySettingsState(
          acceptingBattleInvites: true,
          showInBattleStatus: true,
        );
    state = AsyncData(
      current.copyWith(
        acceptingBattleInvites: acceptingBattleInvites,
        showInBattleStatus: showInBattleStatus,
      ),
    );

    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setBool(_prefAcceptInvites, acceptingBattleInvites);
      await prefs.setBool(_prefShowBattleStatus, showInBattleStatus);

      final user = ref.read(authStateChangesProvider).asData?.value;
      final email = user?.email;
      if (email != null && email.isNotEmpty) {
        final repo = ref.read(communityRepositoryProvider);
        await repo.updateCommunityVisibility(
          email: email,
          acceptingBattleInvites: acceptingBattleInvites,
          showInBattleStatus: showInBattleStatus,
        );
      }
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
