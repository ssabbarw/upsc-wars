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
    AsyncNotifierProvider<CommunityRecentUsersNotifier, CommunityRecentsView>(
      CommunityRecentUsersNotifier.new,
    );

class CommunityRecentsView {
  const CommunityRecentsView({
    required this.users,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.lastRefreshedAt,
  });

  final List<CommunityUser> users;
  final bool isLoadingMore;
  final bool hasMore;
  final DateTime? lastRefreshedAt;

  CommunityRecentsView copyWith({
    List<CommunityUser>? users,
    bool? isLoadingMore,
    bool? hasMore,
    DateTime? lastRefreshedAt,
  }) {
    return CommunityRecentsView(
      users: users ?? this.users,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }
}

class CommunityRecentUsersNotifier extends AsyncNotifier<CommunityRecentsView> {
  int _bucketOffset = -1;
  bool _hasMore = true;
  bool _loadMoreInFlight = false;

  bool get hasMore => _hasMore;
  DateTime? get lastRefreshedAt => state.value?.lastRefreshedAt;

  @override
  Future<CommunityRecentsView> build() async {
    return _fetchFirstPage();
  }

  List<CommunityUser> _merge(
    List<CommunityUser> current,
    List<CommunityUser> next,
  ) {
    return dedupeCommunityUsersByLatest([...current, ...next]);
  }

  Future<List<CommunityUser>> _readNextBucket() async {
    final next = _bucketOffset + 1;
    if (next >= CommunityBucketUtils.maxBucketLookback) {
      _hasMore = false;
      return const [];
    }
    _bucketOffset = next;
    _hasMore = _bucketOffset < CommunityBucketUtils.maxBucketLookback - 1;
    final repo = ref.read(communityRepositoryProvider);
    return repo.fetchRecentUsers(bucketOffset: _bucketOffset);
  }

  Future<CommunityRecentsView> _fetchFirstPage() async {
    _bucketOffset = -1;
    _hasMore = true;
    var users = <CommunityUser>[];
    while (users.isEmpty && _hasMore) {
      final batch = await _readNextBucket();
      users = _merge(users, batch);
    }
    return CommunityRecentsView(
      users: users,
      hasMore: _hasMore,
      lastRefreshedAt: DateTime.now(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading || _loadMoreInFlight) return;
    final current =
        state.value ?? const CommunityRecentsView(users: <CommunityUser>[]);
    if (current.isLoadingMore) return;

    _loadMoreInFlight = true;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      var users = current.users;
      var foundNewPeople = false;
      while (!foundNewPeople && _hasMore) {
        final batch = await _readNextBucket();
        if (batch.isEmpty) continue;
        final seen = {for (final u in users) u.email};
        final hasNew = batch.any((u) => !seen.contains(u.email));
        users = _merge(users, batch);
        if (hasNew) foundNewPeople = true;
      }
      state = AsyncData(
        CommunityRecentsView(
          users: users,
          hasMore: _hasMore,
          lastRefreshedAt: DateTime.now(),
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
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
