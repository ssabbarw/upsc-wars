import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';

enum TimelinePhase { playing, revealed }

class TimelineSorterState {
  const TimelineSorterState({
    required this.sets,
    required this.setIndex,
    required this.order,
    this.selectedSlot,
    this.phase = TimelinePhase.playing,
    this.isLoading = false,
    this.error,
  });

  final List<TimelineSorterSet> sets;
  final int setIndex;
  final List<int> order;
  final int? selectedSlot;
  final TimelinePhase phase;
  final bool isLoading;
  final String? error;

  TimelineSorterSet? get current =>
      sets.isEmpty ? null : sets[setIndex % sets.length];

  bool get isCorrect {
    final set = current;
    if (set == null) return false;
    for (var i = 0; i < order.length; i++) {
      if (i > 0) {
        final prev = set.items[order[i - 1]].sortKey;
        final curr = set.items[order[i]].sortKey;
        if (prev > curr) return false;
      }
    }
    return true;
  }

  TimelineSorterState copyWith({
    List<TimelineSorterSet>? sets,
    int? setIndex,
    List<int>? order,
    int? selectedSlot,
    bool clearSelectedSlot = false,
    TimelinePhase? phase,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TimelineSorterState(
      sets: sets ?? this.sets,
      setIndex: setIndex ?? this.setIndex,
      order: order ?? this.order,
      selectedSlot:
          clearSelectedSlot ? null : (selectedSlot ?? this.selectedSlot),
      phase: phase ?? this.phase,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TimelineSorterController extends AsyncNotifier<TimelineSorterState> {
  @override
  Future<TimelineSorterState> build() async {
    final sets = await ref.read(timelineSorterRepositoryProvider).loadSets();
    if (sets.isEmpty) {
      return const TimelineSorterState(
        sets: [],
        setIndex: 0,
        order: [],
        error: 'No timeline sets found.',
      );
    }
    return TimelineSorterState(
      sets: sets,
      setIndex: 0,
      order: _shuffledOrder(sets.first.items.length),
    );
  }

  List<int> _shuffledOrder(int length) {
    final order = List<int>.generate(length, (i) => i);
    order.shuffle();
    // Avoid starting already sorted when possible.
    if (length > 1 && _isSorted(order)) {
      order.shuffle();
    }
    return order;
  }

  bool _isSorted(List<int> order) {
    for (var i = 1; i < order.length; i++) {
      if (order[i - 1] > order[i]) return false;
    }
    // order of indices ascending means original order — for sort_key we
    // need the actual items. Caller uses item indices into set.items which
    // are already in correct sort order in JSON, so ascending indices = correct.
    return true;
  }

  void tapSlot(int slot) {
    final current = state.asData?.value;
    if (current == null || current.phase != TimelinePhase.playing) return;

    final selected = current.selectedSlot;
    if (selected == null) {
      state = AsyncData(current.copyWith(selectedSlot: slot));
      return;
    }
    if (selected == slot) {
      state = AsyncData(current.copyWith(clearSelectedSlot: true));
      return;
    }

    final order = List<int>.from(current.order);
    final tmp = order[selected];
    order[selected] = order[slot];
    order[slot] = tmp;
    state = AsyncData(
      current.copyWith(order: order, clearSelectedSlot: true),
    );
  }

  void check() {
    final current = state.asData?.value;
    if (current == null || current.phase != TimelinePhase.playing) return;
    state = AsyncData(
      current.copyWith(
        phase: TimelinePhase.revealed,
        clearSelectedSlot: true,
      ),
    );
  }

  void nextSet() {
    final current = state.asData?.value;
    if (current == null || current.sets.isEmpty) return;
    final nextIndex = (current.setIndex + 1) % current.sets.length;
    final next = current.sets[nextIndex];
    state = AsyncData(
      current.copyWith(
        setIndex: nextIndex,
        order: _shuffledOrder(next.items.length),
        clearSelectedSlot: true,
        phase: TimelinePhase.playing,
      ),
    );
  }
}

final timelineSorterControllerProvider =
    AsyncNotifierProvider.autoDispose<TimelineSorterController,
        TimelineSorterState>(TimelineSorterController.new);
