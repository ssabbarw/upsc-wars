import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';

/// Puzzles played per session, drawn randomly from the filtered pool.
const connectTheDotsSessionSize = 10;

class ConnectTheDotsState {
  const ConnectTheDotsState({
    required this.pool,
    required this.session,
    required this.index,
    this.selectedIndex,
    this.revealed = false,
    this.sessionComplete = false,
    this.correctCount = 0,
    this.error,
  });

  final List<ConnectTheDotsItem> pool;
  final List<ConnectTheDotsItem> session;
  final int index;
  final int? selectedIndex;
  final bool revealed;
  final bool sessionComplete;
  final int correctCount;
  final String? error;

  ConnectTheDotsItem? get current =>
      session.isEmpty || index >= session.length ? null : session[index];

  ConnectTheDotsState copyWith({
    List<ConnectTheDotsItem>? pool,
    List<ConnectTheDotsItem>? session,
    int? index,
    int? selectedIndex,
    bool clearSelected = false,
    bool? revealed,
    bool? sessionComplete,
    int? correctCount,
    String? error,
  }) {
    return ConnectTheDotsState(
      pool: pool ?? this.pool,
      session: session ?? this.session,
      index: index ?? this.index,
      selectedIndex:
          clearSelected ? null : (selectedIndex ?? this.selectedIndex),
      revealed: revealed ?? this.revealed,
      sessionComplete: sessionComplete ?? this.sessionComplete,
      correctCount: correctCount ?? this.correctCount,
      error: error ?? this.error,
    );
  }
}

class ConnectTheDotsController extends AsyncNotifier<ConnectTheDotsState> {
  ConnectTheDotsController(this.filter);

  final MiniGameFilter filter;

  @override
  Future<ConnectTheDotsState> build() async {
    final pool = await ref.read(connectTheDotsRepositoryProvider).loadItems();
    if (pool.isEmpty) {
      return const ConnectTheDotsState(
        pool: [],
        session: [],
        index: 0,
        error: 'No connect-the-dots items found.',
      );
    }
    return _newSession(pool);
  }

  ConnectTheDotsState _newSession(List<ConnectTheDotsItem> pool) {
    return ConnectTheDotsState(
      pool: pool,
      session: drawMiniGameSession(
        pool: pool,
        filter: filter,
        count: connectTheDotsSessionSize,
        subjectOf: (i) => i.subject,
        difficultyOf: (i) => i.difficulty,
      ),
      index: 0,
    );
  }

  void select(int optionIndex) {
    final current = state.asData?.value;
    if (current == null || current.revealed || current.current == null) return;
    final correct = optionIndex == current.current!.answerIndex;
    state = AsyncData(
      current.copyWith(
        selectedIndex: optionIndex,
        revealed: true,
        correctCount:
            correct ? current.correctCount + 1 : current.correctCount,
      ),
    );
  }

  void next() {
    final current = state.asData?.value;
    if (current == null || current.session.isEmpty) return;
    final nextIndex = current.index + 1;
    if (nextIndex >= current.session.length) {
      state = AsyncData(current.copyWith(sessionComplete: true));
      return;
    }
    state = AsyncData(
      current.copyWith(
        index: nextIndex,
        clearSelected: true,
        revealed: false,
      ),
    );
  }

  void playAgain() {
    final current = state.asData?.value;
    if (current == null || current.pool.isEmpty) return;
    state = AsyncData(_newSession(current.pool));
  }
}

final connectTheDotsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ConnectTheDotsController, ConnectTheDotsState, MiniGameFilter>(
  ConnectTheDotsController.new,
);
