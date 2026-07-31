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
    this.p1SelectedIndex,
    this.p2SelectedIndex,
    this.p1Passed = false,
    this.p2Passed = false,
    this.p1WrongIndex,
    this.p2WrongIndex,
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

  /// Player has locked in a choice or passed this round (choice still hidden).
  final bool p1Locked;
  final bool p2Locked;

  /// Option index chosen this round; null if not chosen (or passed).
  final int? p1SelectedIndex;
  final int? p2SelectedIndex;
  final bool p1Passed;
  final bool p2Passed;

  /// Option index each player got wrong — set only after reveal.
  final int? p1WrongIndex;
  final int? p2WrongIndex;
  final DuelPhase phase;

  /// Sole scorer this round; null if neither or both scored.
  final DuelPlayer? roundWinner;
  final bool revealedAnswer;
  final String? error;

  DuelQuestion? get current => matchQuestions.isEmpty
      ? null
      : matchQuestions[questionIndex.clamp(0, matchQuestions.length - 1)];

  int get questionNumber => questionIndex + 1;

  bool playerGotItRight(DuelPlayer player) {
    if (!revealedAnswer || current == null) return false;
    if (player == DuelPlayer.one) {
      return !p1Passed && p1SelectedIndex == current!.answerIndex;
    }
    return !p2Passed && p2SelectedIndex == current!.answerIndex;
  }

  DuelState copyWith({
    List<DuelQuestion>? pool,
    List<DuelQuestion>? matchQuestions,
    int? questionIndex,
    int? p1Score,
    int? p2Score,
    bool? p1Locked,
    bool? p2Locked,
    int? p1SelectedIndex,
    int? p2SelectedIndex,
    bool? p1Passed,
    bool? p2Passed,
    int? p1WrongIndex,
    int? p2WrongIndex,
    bool clearSelections = false,
    bool clearWrongIndices = false,
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
      p1Locked: clearSelections ? false : (p1Locked ?? this.p1Locked),
      p2Locked: clearSelections ? false : (p2Locked ?? this.p2Locked),
      p1SelectedIndex:
          clearSelections ? null : (p1SelectedIndex ?? this.p1SelectedIndex),
      p2SelectedIndex:
          clearSelections ? null : (p2SelectedIndex ?? this.p2SelectedIndex),
      p1Passed: clearSelections ? false : (p1Passed ?? this.p1Passed),
      p2Passed: clearSelections ? false : (p2Passed ?? this.p2Passed),
      p1WrongIndex: clearWrongIndices
          ? null
          : (p1WrongIndex ?? this.p1WrongIndex),
      p2WrongIndex: clearWrongIndices
          ? null
          : (p2WrongIndex ?? this.p2WrongIndex),
      phase: phase ?? this.phase,
      roundWinner: clearRoundWinner ? null : (roundWinner ?? this.roundWinner),
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
        current.revealedAnswer ||
        current.current == null) {
      return;
    }
    if (player == DuelPlayer.one && current.p1Locked) return;
    if (player == DuelPlayer.two && current.p2Locked) return;

    final next = current.copyWith(
      p1Locked: player == DuelPlayer.one ? true : current.p1Locked,
      p2Locked: player == DuelPlayer.two ? true : current.p2Locked,
      p1SelectedIndex:
          player == DuelPlayer.one ? optionIndex : current.p1SelectedIndex,
      p2SelectedIndex:
          player == DuelPlayer.two ? optionIndex : current.p2SelectedIndex,
      p1Passed: player == DuelPlayer.one ? false : current.p1Passed,
      p2Passed: player == DuelPlayer.two ? false : current.p2Passed,
    );
    state = AsyncData(_maybeResolve(next));
  }

  void pass(DuelPlayer player) {
    final current = state.asData?.value;
    if (current == null ||
        current.phase != DuelPhase.playing ||
        current.revealedAnswer ||
        current.current == null) {
      return;
    }
    if (player == DuelPlayer.one && current.p1Locked) return;
    if (player == DuelPlayer.two && current.p2Locked) return;

    final next = current.copyWith(
      p1Locked: player == DuelPlayer.one ? true : current.p1Locked,
      p2Locked: player == DuelPlayer.two ? true : current.p2Locked,
      p1Passed: player == DuelPlayer.one ? true : current.p1Passed,
      p2Passed: player == DuelPlayer.two ? true : current.p2Passed,
    );
    state = AsyncData(_maybeResolve(next));
  }

  DuelState _maybeResolve(DuelState pending) {
    if (!pending.p1Locked || !pending.p2Locked) return pending;
    return _resolve(pending);
  }

  DuelState _resolve(DuelState pending) {
    final answer = pending.current!.answerIndex;
    final p1Correct =
        !pending.p1Passed && pending.p1SelectedIndex == answer;
    final p2Correct =
        !pending.p2Passed && pending.p2SelectedIndex == answer;

    final p1Wrong = !pending.p1Passed &&
            pending.p1SelectedIndex != null &&
            pending.p1SelectedIndex != answer
        ? pending.p1SelectedIndex
        : null;
    final p2Wrong = !pending.p2Passed &&
            pending.p2SelectedIndex != null &&
            pending.p2SelectedIndex != answer
        ? pending.p2SelectedIndex
        : null;

    DuelPlayer? winner;
    if (p1Correct && !p2Correct) {
      winner = DuelPlayer.one;
    } else if (p2Correct && !p1Correct) {
      winner = DuelPlayer.two;
    }

    final neitherScored = !p1Correct && !p2Correct;
    return pending.copyWith(
      p1Score: p1Correct ? pending.p1Score + 1 : pending.p1Score,
      p2Score: p2Correct ? pending.p2Score + 1 : pending.p2Score,
      p1WrongIndex: p1Wrong,
      p2WrongIndex: p2Wrong,
      phase: neitherScored ? DuelPhase.bothWrong : DuelPhase.playing,
      roundWinner: winner,
      clearRoundWinner: winner == null,
      revealedAnswer: true,
    );
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
        clearSelections: true,
        clearWrongIndices: true,
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
    .family<DuelController, DuelState, MiniGameFilter>(DuelController.new);
