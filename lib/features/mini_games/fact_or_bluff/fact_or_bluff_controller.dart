import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';

const factOrBluffSeconds = 5;

enum FactOrBluffVerdict { none, correct, wrong, timeout }

class FactOrBluffState {
  const FactOrBluffState({
    required this.items,
    required this.index,
    required this.secondsLeft,
    this.answeredIsFact,
    this.verdict = FactOrBluffVerdict.none,
    this.streak = 0,
    this.error,
  });

  final List<FactOrBluffItem> items;
  final int index;
  final double secondsLeft;
  final bool? answeredIsFact;
  final FactOrBluffVerdict verdict;
  final int streak;
  final String? error;

  FactOrBluffItem? get current =>
      items.isEmpty ? null : items[index % items.length];

  bool get isAwaitingAnswer => verdict == FactOrBluffVerdict.none;

  FactOrBluffState copyWith({
    List<FactOrBluffItem>? items,
    int? index,
    double? secondsLeft,
    bool? answeredIsFact,
    bool clearAnswer = false,
    FactOrBluffVerdict? verdict,
    int? streak,
    String? error,
  }) {
    return FactOrBluffState(
      items: items ?? this.items,
      index: index ?? this.index,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      answeredIsFact:
          clearAnswer ? null : (answeredIsFact ?? this.answeredIsFact),
      verdict: verdict ?? this.verdict,
      streak: streak ?? this.streak,
      error: error ?? this.error,
    );
  }
}

class FactOrBluffController extends AsyncNotifier<FactOrBluffState> {
  Timer? _timer;

  @override
  Future<FactOrBluffState> build() async {
    ref.onDispose(() => _timer?.cancel());
    final items = await ref.read(factOrBluffRepositoryProvider).loadItems();
    if (items.isEmpty) {
      return const FactOrBluffState(
        items: [],
        index: 0,
        secondsLeft: 0,
        error: 'No fact-or-bluff items found.',
      );
    }
    final initial = FactOrBluffState(
      items: items,
      index: 0,
      secondsLeft: factOrBluffSeconds.toDouble(),
    );
    // Start timer after the first frame of state is available.
    Future.microtask(_startTimer);
    return initial;
  }

  void _startTimer() {
    _timer?.cancel();
    final current = state.asData?.value;
    if (current == null || !current.isAwaitingAnswer) return;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final snap = state.asData?.value;
      if (snap == null || !snap.isAwaitingAnswer) {
        timer.cancel();
        return;
      }
      final next = snap.secondsLeft - 0.05;
      if (next <= 0) {
        timer.cancel();
        state = AsyncData(
          snap.copyWith(
            secondsLeft: 0,
            verdict: FactOrBluffVerdict.timeout,
            streak: 0,
          ),
        );
      } else {
        state = AsyncData(snap.copyWith(secondsLeft: next));
      }
    });
  }

  void answer(bool isFact) {
    final current = state.asData?.value;
    if (current == null || !current.isAwaitingAnswer || current.current == null) {
      return;
    }
    _timer?.cancel();
    final correct = current.current!.isFact == isFact;
    state = AsyncData(
      current.copyWith(
        answeredIsFact: isFact,
        verdict: correct ? FactOrBluffVerdict.correct : FactOrBluffVerdict.wrong,
        streak: correct ? current.streak + 1 : 0,
      ),
    );
  }

  void next() {
    final current = state.asData?.value;
    if (current == null || current.items.isEmpty) return;
    _timer?.cancel();
    final nextIndex = (current.index + 1) % current.items.length;
    state = AsyncData(
      current.copyWith(
        index: nextIndex,
        secondsLeft: factOrBluffSeconds.toDouble(),
        clearAnswer: true,
        verdict: FactOrBluffVerdict.none,
      ),
    );
    _startTimer();
  }
}

final factOrBluffControllerProvider =
    AsyncNotifierProvider.autoDispose<FactOrBluffController, FactOrBluffState>(
  FactOrBluffController.new,
);
