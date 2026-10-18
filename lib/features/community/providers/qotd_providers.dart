import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/test_question.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../data/qotd_repository.dart';
import '../domain/qotd_models.dart';

/// Live list of QOTD attempts for one post (newest [QotdAttemptEntry.attemptedAt] first).
final qotdPostAttemptsProvider = StreamProvider.autoDispose
    .family<List<QotdAttemptEntry>, String>((ref, postId) {
      return ref.read(qotdRepositoryProvider).watchAttempts(postId);
    });

/// [TestQuestion] plus catalog fields not on [TestQuestion] (e.g. subtopic).
class QotdQuestionVm {
  const QotdQuestionVm({required this.question, required this.subTopic});

  final TestQuestion question;
  final String subTopic;
}

final qotdRepositoryProvider = Provider<QotdRepository>((ref) {
  return QotdRepository(FirebaseFirestore.instance);
});

/// Remote Config `qotd_max_posts_per_day` — max QOTD posts per device in a rolling 24h window (local).
/// Default 3; fails open to 3 on errors / web.
final qotdMaxPostsPerDayProvider = FutureProvider<int>((ref) async {
  if (kIsWeb) return 3;
  await ref.watch(killSwitchProvider.future);
  try {
    final n = FirebaseRemoteConfig.instance.getInt(
      qotdMaxPostsPerDayRemoteConfigKey,
    );
    if (n <= 0) return 3;
    if (n > 99) return 99;
    return n;
  } on Object catch (_) {
    return 3;
  }
});

final qotdQuestionByUuidProvider =
    FutureProvider.family<QotdQuestionVm?, String>((ref, uuid) async {
      final repo = await ref.watch(testEngineRepositoryProvider.future);
      final q = await repo.loadStandaloneQuestionByUuid(uuid);
      if (q == null) return null;
      final row = await ref
          .read(userDatabaseProvider)
          .questionsDao
          .getByUuid(uuid);
      final sub = (row?.subTopic ?? '').trim();
      return QotdQuestionVm(question: q, subTopic: sub);
    });

class QotdFeedView {
  const QotdFeedView({required this.posts, required this.hasMore});

  final List<QotdPost> posts;
  final bool hasMore;

  QotdFeedView copyWith({List<QotdPost>? posts, bool? hasMore}) {
    return QotdFeedView(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final qotdFeedNotifierProvider =
    AsyncNotifierProvider<QotdFeedNotifier, QotdFeedView>(QotdFeedNotifier.new);

class QotdFeedNotifier extends AsyncNotifier<QotdFeedView> {
  static const _pageSize = 12;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _loadMoreInFlight = false;

  @override
  Future<QotdFeedView> build() async {
    _cursor = null;
    final repo = ref.read(qotdRepositoryProvider);
    final page = await repo.fetchPage(limit: _pageSize, startAfter: null);
    _cursor = page.last;
    final hasMore = page.posts.length >= _pageSize;
    return QotdFeedView(posts: page.posts, hasMore: hasMore);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _cursor = null;
      final repo = ref.read(qotdRepositoryProvider);
      final page = await repo.fetchPage(limit: _pageSize, startAfter: null);
      _cursor = page.last;
      final hasMore = page.posts.length >= _pageSize;
      return QotdFeedView(posts: page.posts, hasMore: hasMore);
    });
  }

  Future<void> loadMore() async {
    final vm = state.value;
    if (vm == null || !vm.hasMore || _loadMoreInFlight || state.isLoading) {
      return;
    }
    if (_cursor == null) return;
    _loadMoreInFlight = true;
    try {
      final repo = ref.read(qotdRepositoryProvider);
      final page = await repo.fetchPage(limit: _pageSize, startAfter: _cursor);
      if (page.posts.isEmpty) {
        state = AsyncData(vm.copyWith(hasMore: false));
        return;
      }
      _cursor = page.last;
      final hasMore = page.posts.length >= _pageSize;
      state = AsyncData(
        QotdFeedView(posts: [...vm.posts, ...page.posts], hasMore: hasMore),
      );
    } finally {
      _loadMoreInFlight = false;
    }
  }
}
