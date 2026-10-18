import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';
import '../../../l10n/l10n.dart';

/// Puzzles played per session, drawn randomly from the filtered pool.
const oddOneOutSessionSize = 10;

class OddOneOutState {
  const OddOneOutState({
    required this.pool,
    required this.session,
    required this.index,
    this.selectedIndex,
    this.revealed = false,
    this.sessionComplete = false,
    this.correctCount = 0,
    this.error,
  });

  final List<OddOneOutItem> pool;
  final List<OddOneOutItem> session;
  final int index;
  final int? selectedIndex;
  final bool revealed;
  final bool sessionComplete;
  final int correctCount;
  final String? error;

  OddOneOutItem? get current =>
      session.isEmpty || index >= session.length ? null : session[index];

  OddOneOutState copyWith({
    List<OddOneOutItem>? pool,
    List<OddOneOutItem>? session,
    int? index,
    int? selectedIndex,
    bool clearSelected = false,
    bool? revealed,
    bool? sessionComplete,
    int? correctCount,
    String? error,
  }) {
    return OddOneOutState(
      pool: pool ?? this.pool,
      session: session ?? this.session,
      index: index ?? this.index,
      selectedIndex: clearSelected
          ? null
          : (selectedIndex ?? this.selectedIndex),
      revealed: revealed ?? this.revealed,
      sessionComplete: sessionComplete ?? this.sessionComplete,
      correctCount: correctCount ?? this.correctCount,
      error: error ?? this.error,
    );
  }
}

class OddOneOutController extends AsyncNotifier<OddOneOutState> {
  OddOneOutController(this.filter);

  final MiniGameFilter filter;

  @override
  Future<OddOneOutState> build() async {
    final pool = await ref.read(oddOneOutRepositoryProvider).loadItems();
    if (pool.isEmpty) {
      return OddOneOutState(
        pool: [],
        session: [],
        index: 0,
        error: appL10n.gmErrNoOdd,
      );
    }
    return _newSession(pool);
  }

  OddOneOutState _newSession(List<OddOneOutItem> pool) {
    return OddOneOutState(
      pool: pool,
      session: drawMiniGameSession(
        pool: pool,
        filter: filter,
        count: oddOneOutSessionSize,
        subjectOf: (i) => i.subject,
        difficultyOf: (i) => i.difficulty,
      ),
      index: 0,
    );
  }

  void select(int itemIndex) {
    final current = state.asData?.value;
    if (current == null || current.revealed || current.current == null) return;
    final correct = itemIndex == current.current!.oddIndex;
    state = AsyncData(
      current.copyWith(
        selectedIndex: itemIndex,
        revealed: true,
        correctCount: correct ? current.correctCount + 1 : current.correctCount,
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
      current.copyWith(index: nextIndex, clearSelected: true, revealed: false),
    );
  }

  void playAgain() {
    final current = state.asData?.value;
    if (current == null || current.pool.isEmpty) return;
    state = AsyncData(_newSession(current.pool));
  }
}

final oddOneOutControllerProvider = AsyncNotifierProvider.autoDispose
    .family<OddOneOutController, OddOneOutState, MiniGameFilter>(
      OddOneOutController.new,
    );
