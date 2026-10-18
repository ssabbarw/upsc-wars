import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/kill_switch_provider.dart';
import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';
import '../../../l10n/l10n.dart';

/// Fallback / Remote Config default when RC is unavailable.
const factOrBluffDefaultSeconds = 10;

/// Statements played per session, drawn randomly from the filtered pool.
const factOrBluffSessionSize = 10;

enum FactOrBluffVerdict { none, correct, wrong, timeout }

class FactOrBluffState {
  const FactOrBluffState({
    required this.pool,
    required this.session,
    required this.index,
    required this.durationSeconds,
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

  /// Full countdown length for this session (from Remote Config).
  final int durationSeconds;
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

  double get progress => durationSeconds <= 0
      ? 0
      : (secondsLeft / durationSeconds).clamp(0.0, 1.0);

  FactOrBluffState copyWith({
    List<FactOrBluffItem>? pool,
    List<FactOrBluffItem>? session,
    int? index,
    int? durationSeconds,
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
      durationSeconds: durationSeconds ?? this.durationSeconds,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      answeredIsFact: clearAnswer
          ? null
          : (answeredIsFact ?? this.answeredIsFact),
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
    final durationSeconds = await ref.watch(
      factOrBluffSecondsRemoteProvider.future,
    );
    final pool = await ref.read(factOrBluffRepositoryProvider).loadItems();
    if (pool.isEmpty) {
      return FactOrBluffState(
        pool: const [],
        session: const [],
        index: 0,
        durationSeconds: durationSeconds,
        secondsLeft: 0,
        error: appL10n.gmErrNoFob,
      );
    }
    // Timer is armed only once the player leaves the "How to play" sheet and
    // calls [start] — otherwise the countdown would run behind the sheet.
    return _newSession(pool, durationSeconds);
  }

  /// Begins the countdown for the current statement. Called by the screen when
  /// the player dismisses the intro. Safe to call once content has loaded.
  void start() => _startTimer();

  FactOrBluffState _newSession(
    List<FactOrBluffItem> pool,
    int durationSeconds,
  ) {
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
      durationSeconds: durationSeconds,
      secondsLeft: durationSeconds.toDouble(),
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
        verdict: correct
            ? FactOrBluffVerdict.correct
            : FactOrBluffVerdict.wrong,
        streak: correct ? current.streak + 1 : 0,
        correctCount: correct ? current.correctCount + 1 : current.correctCount,
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
        secondsLeft: current.durationSeconds.toDouble(),
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
    state = AsyncData(_newSession(current.pool, current.durationSeconds));
    Future.microtask(_startTimer);
  }
}

final factOrBluffControllerProvider = AsyncNotifierProvider.autoDispose
    .family<FactOrBluffController, FactOrBluffState, MiniGameFilter>(
      FactOrBluffController.new,
    );
