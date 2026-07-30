import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';

const factOrBluffSeconds = 5;

/// Statements played per session, drawn randomly from the filtered pool.
const factOrBluffSessionSize = 10;

enum FactOrBluffVerdict { none, correct, wrong, timeout }

class FactOrBluffState {
  const FactOrBluffState({
    required this.pool,
    required this.session,
    required this.index,
    required this.secondsLeft,
    this.answeredIsFact,
    this.verdict = FactOrBluffVerdict.none,
    this.streak = 0,
    this.correctCount = 0,
    this.sessionComplete = false,
    this.error,
  });

  final List<FactOrBluffItem> pool;
  final List<FactOrBluffItem> session;
  final int index;
  final double secondsLeft;
  final bool? answeredIsFact;
  final FactOrBluffVerdict verdict;
  final int streak;
  final int correctCount;
  final bool sessionComplete;
  final String? error;

  FactOrBluffItem? get current =>
      session.isEmpty || index >= session.length ? null : session[index];

  bool get isAwaitingAnswer => verdict == FactOrBluffVerdict.none;

  FactOrBluffState copyWith({
    List<FactOrBluffItem>? pool,
    List<FactOrBluffItem>? session,
    int? index,
    double? secondsLeft,
    bool? answeredIsFact,
    bool clearAnswer = false,
    FactOrBluffVerdict? verdict,
    int? streak,
    int? correctCount,
    bool? sessionComplete,
    String? error,
  }) {
    return FactOrBluffState(
      pool: pool ?? this.pool,
      session: session ?? this.session,
      index: index ?? this.index,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      answeredIsFact:
          clearAnswer ? null : (answeredIsFact ?? this.answeredIsFact),
      verdict: verdict ?? this.verdict,
      streak: streak ?? this.streak,
      correctCount: correctCount ?? this.correctCount,
      sessionComplete: sessionComplete ?? this.sessionComplete,
      error: error ?? this.error,
    );
  }
}

class FactOrBluffController extends AsyncNotifier<FactOrBluffState> {
  FactOrBluffController(this.filter);

  final MiniGameFilter filter;

  Timer? _timer;

  @override
  Future<FactOrBluffState> build() async {
    ref.onDispose(() => _timer?.cancel());
    final pool = await ref.read(factOrBluffRepositoryProvider).loadItems();
    if (pool.isEmpty) {
      return const FactOrBluffState(
        pool: [],
        session: [],
        index: 0,
        secondsLeft: 0,
        error: 'No fact-or-bluff items found.',
      );
    }
    final initial = _newSession(pool);
    Future.microtask(_startTimer);
    return initial;
  }

  FactOrBluffState _newSession(List<FactOrBluffItem> pool) {
    return FactOrBluffState(
      pool: pool,
      session: drawMiniGameSession(
        pool: pool,
        filter: filter,
        count: factOrBluffSessionSize,
        subjectOf: (i) => i.subject,
        difficultyOf: (i) => i.difficulty,
      ),
      index: 0,
      secondsLeft: factOrBluffSeconds.toDouble(),
    );
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
    if (current == null ||
        !current.isAwaitingAnswer ||
        current.current == null) {
      return;
    }
    _timer?.cancel();
    final correct = current.current!.isFact == isFact;
    state = AsyncData(
      current.copyWith(
        answeredIsFact: isFact,
        verdict:
            correct ? FactOrBluffVerdict.correct : FactOrBluffVerdict.wrong,
        streak: correct ? current.streak + 1 : 0,
        correctCount:
            correct ? current.correctCount + 1 : current.correctCount,
      ),
    );
  }

  void next() {
    final current = state.asData?.value;
    if (current == null || current.session.isEmpty) return;
    _timer?.cancel();
    final nextIndex = current.index + 1;
    if (nextIndex >= current.session.length) {
      state = AsyncData(current.copyWith(sessionComplete: true));
      return;
    }
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

  void playAgain() {
    final current = state.asData?.value;
    if (current == null || current.pool.isEmpty) return;
    _timer?.cancel();
    state = AsyncData(_newSession(current.pool));
    Future.microtask(_startTimer);
  }
}

final factOrBluffControllerProvider = AsyncNotifierProvider.autoDispose
    .family<FactOrBluffController, FactOrBluffState, MiniGameFilter>(
  FactOrBluffController.new,
);
