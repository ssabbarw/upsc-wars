import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';
import '../../../l10n/l10n.dart';

/// Sets played per session, drawn randomly from the filtered pool.
const timelineSessionSize = 10;

enum TimelinePhase { playing, revealed, sessionComplete }

class TimelineSorterState {
  const TimelineSorterState({
    required this.pool,
    required this.session,
    required this.setIndex,
    required this.order,
    this.phase = TimelinePhase.playing,
    this.correctCount = 0,
    this.error,
  });

  final List<TimelineSorterSet> pool;
  final List<TimelineSorterSet> session;
  final int setIndex;

  /// Permutation of item indices (display order).
  final List<int> order;
  final TimelinePhase phase;
  final int correctCount;
  final String? error;

  TimelineSorterSet? get current =>
      session.isEmpty || setIndex >= session.length ? null : session[setIndex];

  bool get isCorrect {
    final set = current;
    if (set == null) return false;
    for (var i = 1; i < order.length; i++) {
      if (set.items[order[i - 1]].sortKey > set.items[order[i]].sortKey) {
        return false;
      }
    }
    return true;
  }

  /// Whether each display slot holds a chronologically correct item, so the
  /// reveal can score "4 of 5" instead of all-or-nothing.
  List<bool> get slotCorrectness {
    final set = current;
    if (set == null || order.length != set.items.length) return const [];
    final sortedKeys = set.items.map((i) => i.sortKey).toList()..sort();
    return [
      for (var i = 0; i < order.length; i++)
        set.items[order[i]].sortKey == sortedKeys[i],
    ];
  }

  int get slotCorrectCount => slotCorrectness.where((ok) => ok).length;

  TimelineSorterState copyWith({
    List<TimelineSorterSet>? pool,
    List<TimelineSorterSet>? session,
    int? setIndex,
    List<int>? order,
    TimelinePhase? phase,
    int? correctCount,
    String? error,
  }) {
    return TimelineSorterState(
      pool: pool ?? this.pool,
      session: session ?? this.session,
      setIndex: setIndex ?? this.setIndex,
      order: order ?? this.order,
      phase: phase ?? this.phase,
      correctCount: correctCount ?? this.correctCount,
      error: error ?? this.error,
    );
  }
}

class TimelineSorterController extends AsyncNotifier<TimelineSorterState> {
  TimelineSorterController(this.filter);

  final MiniGameFilter filter;

  @override
  Future<TimelineSorterState> build() async {
    final pool = await ref.read(timelineSorterRepositoryProvider).loadSets();
    if (pool.isEmpty) {
      return TimelineSorterState(
        pool: [],
        session: [],
        setIndex: 0,
        order: [],
        error: appL10n.gmErrNoTimeline,
      );
    }
    return _newSession(pool);
  }

  TimelineSorterState _newSession(List<TimelineSorterSet> pool) {
    final session = drawMiniGameSession(
      pool: pool,
      filter: filter,
      count: timelineSessionSize,
      subjectOf: (s) => s.subject,
      difficultyOf: (s) => s.difficulty,
    );
    return TimelineSorterState(
      pool: pool,
      session: session,
      setIndex: 0,
      order: _shuffledOrder(session.first.items.length),
    );
  }

  List<int> _shuffledOrder(int length) {
    final order = List<int>.generate(length, (i) => i);
    order.shuffle();
    if (length > 1 && _isAscending(order)) {
      order.shuffle();
    }
    return order;
  }

  bool _isAscending(List<int> order) {
    for (var i = 1; i < order.length; i++) {
      if (order[i - 1] > order[i]) return false;
    }
    return true;
  }

  void reorder(int oldIndex, int newIndex) {
    final current = state.asData?.value;
    if (current == null || current.phase != TimelinePhase.playing) return;
    if (oldIndex < newIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    final order = List<int>.from(current.order);
    final item = order.removeAt(oldIndex);
    order.insert(newIndex, item);
    state = AsyncData(current.copyWith(order: order));
  }

  void check() {
    final current = state.asData?.value;
    if (current == null || current.phase != TimelinePhase.playing) return;
    state = AsyncData(
      current.copyWith(
        phase: TimelinePhase.revealed,
        correctCount: current.isCorrect
            ? current.correctCount + 1
            : current.correctCount,
      ),
    );
  }

  void nextSet() {
    final current = state.asData?.value;
    if (current == null || current.session.isEmpty) return;
    final nextIndex = current.setIndex + 1;
    if (nextIndex >= current.session.length) {
      state = AsyncData(current.copyWith(phase: TimelinePhase.sessionComplete));
      return;
    }
    state = AsyncData(
      current.copyWith(
        setIndex: nextIndex,
        order: _shuffledOrder(current.session[nextIndex].items.length),
        phase: TimelinePhase.playing,
      ),
    );
  }

  void playAgain() {
    final current = state.asData?.value;
    if (current == null || current.pool.isEmpty) return;
    state = AsyncData(_newSession(current.pool));
  }
}

final timelineSorterControllerProvider = AsyncNotifierProvider.autoDispose
    .family<TimelineSorterController, TimelineSorterState, MiniGameFilter>(
      TimelineSorterController.new,
    );
