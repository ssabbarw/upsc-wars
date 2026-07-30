import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/mini_game_content_repository.dart';
import '../shared/mini_game_models.dart';

/// Match length — configurable constant, not a user setting this phase.
const duelMatchLength = 5;

enum DuelPhase { playing, bothWrong, matchOver }

enum DuelPlayer { one, two }

class DuelState {
  const DuelState({
    required this.pool,
    required this.matchQuestions,
    required this.questionIndex,
    this.p1Score = 0,
    this.p2Score = 0,
    this.p1Locked = false,
    this.p2Locked = false,
    this.phase = DuelPhase.playing,
    this.roundWinner,
    this.revealedAnswer = false,
    this.error,
  });

  final List<DuelQuestion> pool;
  final List<DuelQuestion> matchQuestions;
  final int questionIndex;
  final int p1Score;
  final int p2Score;
  final bool p1Locked;
  final bool p2Locked;
  final DuelPhase phase;
  final DuelPlayer? roundWinner;
  final bool revealedAnswer;
  final String? error;

  DuelQuestion? get current => matchQuestions.isEmpty
      ? null
      : matchQuestions[questionIndex.clamp(0, matchQuestions.length - 1)];

  int get questionNumber => questionIndex + 1;

  DuelState copyWith({
    List<DuelQuestion>? pool,
    List<DuelQuestion>? matchQuestions,
    int? questionIndex,
    int? p1Score,
    int? p2Score,
    bool? p1Locked,
    bool? p2Locked,
    DuelPhase? phase,
    DuelPlayer? roundWinner,
    bool clearRoundWinner = false,
    bool? revealedAnswer,
    String? error,
  }) {
    return DuelState(
      pool: pool ?? this.pool,
      matchQuestions: matchQuestions ?? this.matchQuestions,
      questionIndex: questionIndex ?? this.questionIndex,
      p1Score: p1Score ?? this.p1Score,
      p2Score: p2Score ?? this.p2Score,
      p1Locked: p1Locked ?? this.p1Locked,
      p2Locked: p2Locked ?? this.p2Locked,
      phase: phase ?? this.phase,
      roundWinner:
          clearRoundWinner ? null : (roundWinner ?? this.roundWinner),
      revealedAnswer: revealedAnswer ?? this.revealedAnswer,
      error: error ?? this.error,
    );
  }
}

class DuelController extends AsyncNotifier<DuelState> {
  DuelController(this.filter);

  final MiniGameFilter filter;

  @override
  Future<DuelState> build() async {
    final pool = await ref.read(duelRepositoryProvider).loadQuestions();
    if (pool.isEmpty) {
      return const DuelState(
        pool: [],
        matchQuestions: [],
        questionIndex: 0,
        error: 'No duel questions found.',
      );
    }
    return DuelState(
      pool: pool,
      matchQuestions: _pickMatch(pool),
      questionIndex: 0,
    );
  }

  List<DuelQuestion> _pickMatch(List<DuelQuestion> pool) {
    final drawn = drawMiniGameSession(
      pool: pool,
      filter: filter,
      count: duelMatchLength,
      subjectOf: (q) => q.subject,
      difficultyOf: (q) => q.difficulty,
    );
    if (drawn.length >= duelMatchLength) return drawn;
    // Loop/reuse if the pool is smaller than match length.
    final out = <DuelQuestion>[];
    var i = 0;
    while (out.length < duelMatchLength) {
      out.add(drawn[i % drawn.length]);
      i++;
    }
    return out;
  }

  void tap(DuelPlayer player, int optionIndex) {
    final current = state.asData?.value;
    if (current == null ||
        current.phase != DuelPhase.playing ||
        current.current == null) {
      return;
    }
    if (player == DuelPlayer.one && current.p1Locked) return;
    if (player == DuelPlayer.two && current.p2Locked) return;

    final correct = optionIndex == current.current!.answerIndex;
    if (correct) {
      state = AsyncData(
        current.copyWith(
          p1Score: player == DuelPlayer.one
              ? current.p1Score + 1
              : current.p1Score,
          p2Score: player == DuelPlayer.two
              ? current.p2Score + 1
              : current.p2Score,
          phase: DuelPhase.playing,
          roundWinner: player,
          revealedAnswer: true,
          p1Locked: true,
          p2Locked: true,
        ),
      );
      // Brief pause then advance — screens call next after showing winner,
      // or we auto-advance here via microtask delay from the screen.
      return;
    }

    // Wrong tap: lock that player out.
    final p1Locked = player == DuelPlayer.one ? true : current.p1Locked;
    final p2Locked = player == DuelPlayer.two ? true : current.p2Locked;
    if (p1Locked && p2Locked) {
      state = AsyncData(
        current.copyWith(
          p1Locked: p1Locked,
          p2Locked: p2Locked,
          phase: DuelPhase.bothWrong,
          revealedAnswer: true,
          clearRoundWinner: true,
        ),
      );
    } else {
      state = AsyncData(
        current.copyWith(p1Locked: p1Locked, p2Locked: p2Locked),
      );
    }
  }

  void nextQuestion() {
    final current = state.asData?.value;
    if (current == null || current.matchQuestions.isEmpty) return;

    final nextIndex = current.questionIndex + 1;
    if (nextIndex >= current.matchQuestions.length) {
      state = AsyncData(
        current.copyWith(
          phase: DuelPhase.matchOver,
          revealedAnswer: false,
          clearRoundWinner: true,
        ),
      );
      return;
    }

    state = AsyncData(
      current.copyWith(
        questionIndex: nextIndex,
        p1Locked: false,
        p2Locked: false,
        phase: DuelPhase.playing,
        clearRoundWinner: true,
        revealedAnswer: false,
      ),
    );
  }

  void playAgain() {
    final current = state.asData?.value;
    if (current == null || current.pool.isEmpty) return;
    state = AsyncData(
      DuelState(
        pool: current.pool,
        matchQuestions: _pickMatch(current.pool),
        questionIndex: 0,
      ),
    );
  }
}

final duelControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DuelController, DuelState, MiniGameFilter>(
  DuelController.new,
);
