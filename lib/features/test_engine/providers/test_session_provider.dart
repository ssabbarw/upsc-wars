import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/router/app_router.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/shared/widgets/top_snack_bar.dart';

import 'test_session_state.dart';

part 'test_session_provider.g.dart';

@Riverpod(keepAlive: true)
class TestSessionNotifier extends _$TestSessionNotifier {
  @override
  Future<TestSessionState> build(String sessionId) async {
    final load = await ref.watch(loadSessionUseCaseProvider.future);
    final active = await load.execute(sessionId);
    final repo = await ref.read(testEngineRepositoryProvider.future);
    final bm = <String, bool>{};
    for (final q in active.questions) {
      bm[q.uuid] = await repo.isBookmarked(q.uuid);
    }
    return _stateForLoadedSession(active, bm);
  }

  Future<void> reload() async {
    final id = sessionId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final load = await ref.read(loadSessionUseCaseProvider.future);
      final active = await load.execute(id);
      final bm = <String, bool>{};
      final repo = await ref.read(testEngineRepositoryProvider.future);
      for (final q in active.questions) {
        bm[q.uuid] = await repo.isBookmarked(q.uuid);
      }
      return _stateForLoadedSession(active, bm);
    });
  }

  TestSessionState _stateForLoadedSession(
    ActiveSession active,
    Map<String, bool> bookmarkedByUuid,
  ) {
    final firstUnattempted = active.questions.indexWhere(
      (q) => q.status == 'unattempted',
    );
    var startIndex = firstUnattempted == -1 ? 0 : firstUnattempted;
    if (startIndex >= active.questions.length) startIndex = 0;

    var totalElapsed = 0;
    var showBanner = false;
    if (active.mode == 'exam' &&
        active.isTimed &&
        active.timeLimitSecs != null) {
      final saved = active.savedExamRemainingSecs;
      if (saved != null) {
        totalElapsed = (active.timeLimitSecs! - saved).clamp(
          0,
          active.timeLimitSecs!,
        );
        showBanner = totalElapsed > 0;
      }
    }

    final learningLimit =
        active.mode == 'learning' ? (active.timeLimitSecs ?? 60) : 0;
    final furthestAnswered = active.questions.lastIndexWhere(
      (q) => q.selectedOption != null || q.status == 'timed_out',
    );

    return TestSessionState.initial().copyWith(
      isLoading: false,
      session: active,
      currentIndex: startIndex,
      totalElapsedSecs: totalElapsed,
      learningRemainingSecs: learningLimit,
      bookmarkedByUuid: bookmarkedByUuid,
      showTimedExamResumeBanner: showBanner,
      furthestAnsweredIndex: furthestAnswered,
      clearError: true,
    );
  }

  Future<void> selectOption(String option) async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    final q = s.questions[current.currentIndex];

    if (s.mode == 'learning' && current.explanationVisible) return;

    try {
      final uc = await ref.read(updateQuestionAttemptUseCaseProvider.future);
      final isCorrect = await uc.execute(
        sessionId: s.id,
        questionUuid: q.uuid,
        selectedOption: option,
      );

      if (isCorrect && (s.subject == 'revision' || s.subject == 'revision_quick')) {
        final rev = await ref.read(
          updateRevisionQueueProgressUseCaseProvider.future,
        );
        await rev.execute(q.uuid);
      }

      final updatedQuestions = [...s.questions];
      updatedQuestions[current.currentIndex] = q.copyWith(
        selectedOption: option.toLowerCase(),
        status: isCorrect ? 'correct' : 'wrong',
      );

      state = AsyncData(
        current.copyWith(
          session: s.copyWith(questions: updatedQuestions),
          explanationVisible: s.mode == 'learning',
          learningVerdict:
              isCorrect ? LearningVerdict.correct : LearningVerdict.incorrect,
          furthestAnsweredIndex:
              current.currentIndex > current.furthestAnsweredIndex
                  ? current.currentIndex
                  : current.furthestAnsweredIndex,
        ),
      );
    } catch (_) {
      _showStorageSnack();
    }
  }

  Future<void> onLearningTimedOut() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null || s.mode != 'learning') return;
    final q = s.questions[current.currentIndex];
    if (current.explanationVisible) return;

    try {
      final uc = await ref.read(handleTimedOutQuestionUseCaseProvider.future);
      await uc.execute(sessionId: s.id, questionUuid: q.uuid);

      final updated = [...s.questions];
      updated[current.currentIndex] = q.copyWith(status: 'timed_out');

      state = AsyncData(
        current.copyWith(
          session: s.copyWith(questions: updated),
          explanationVisible: true,
          learningVerdict: LearningVerdict.timedOut,
          furthestAnsweredIndex:
              current.currentIndex > current.furthestAnsweredIndex
                  ? current.currentIndex
                  : current.furthestAnsweredIndex,
        ),
      );
    } catch (_) {
      _showStorageSnack();
    }
  }

  Future<void> toggleFlag() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    final q = s.questions[current.currentIndex];

    final next = !q.flagged;
    try {
      final uc = await ref.read(flagQuestionUseCaseProvider.future);
      await uc.execute(sessionId: s.id, questionUuid: q.uuid, flagged: next);

      final updated = [...s.questions];
      updated[current.currentIndex] = q.copyWith(flagged: next);
      state = AsyncData(
        current.copyWith(session: s.copyWith(questions: updated)),
      );
    } catch (_) {
      _showStorageSnack();
    }
  }

  Future<void> moveNext() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    if (current.currentIndex >= s.questions.length - 1) return;
    if (s.mode == 'learning') {
      final question = s.questions[current.currentIndex];
      final isAnswered =
          question.selectedOption != null || question.status == 'timed_out';
      final canAdvance =
          current.currentIndex < current.furthestAnsweredIndex || isAnswered;
      if (!canAdvance) return;
    }

    await _persistCurrentQuestionTime();

    final nextIndex = current.currentIndex + 1;
    final nextQuestion = s.questions[nextIndex];
    final nextAnswered =
        nextQuestion.selectedOption != null ||
        nextQuestion.status == 'timed_out';
    final nextVerdict = _learningVerdictFromStatus(nextQuestion.status);
    final nextState = current.copyWith(
      currentIndex: nextIndex,
      currentQuestionElapsedSecs: 0,
      explanationVisible: s.mode == 'learning' ? nextAnswered : false,
      learningVerdict: s.mode == 'learning' ? nextVerdict : null,
      clearLearningVerdict: s.mode == 'learning' ? false : true,
      learningRemainingSecs:
          s.mode == 'learning'
              ? (nextAnswered
                  ? current.learningRemainingSecs
                  : (s.timeLimitSecs ?? 60))
              : current.learningRemainingSecs,
    );
    state = AsyncData(nextState);
  }

  Future<void> movePrev() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    if (current.currentIndex <= 0) return;

    await _persistCurrentQuestionTime();
    final prevIndex = current.currentIndex - 1;
    final prevQuestion = s.questions[prevIndex];
    final prevAnswered =
        prevQuestion.selectedOption != null ||
        prevQuestion.status == 'timed_out';
    final prevVerdict = _learningVerdictFromStatus(prevQuestion.status);

    state = AsyncData(
      current.copyWith(
        currentIndex: prevIndex,
        currentQuestionElapsedSecs: 0,
        explanationVisible:
            s.mode == 'learning' ? prevAnswered : current.explanationVisible,
        learningVerdict:
            s.mode == 'learning' ? prevVerdict : current.learningVerdict,
        clearLearningVerdict: s.mode == 'learning' ? false : true,
      ),
    );
  }

  Future<String> submit() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) throw StateError('No active session');

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      await _persistCurrentQuestionTime();
      final uc = await ref.read(submitSessionUseCaseProvider.future);
      final id = await uc.execute(s.id);
      final now = state.asData?.value;
      if (now != null) {
        state = AsyncData(now.copyWith(isSubmitting: false));
      }
      return id;
    } catch (_) {
      final now = state.asData?.value;
      if (now != null) {
        state = AsyncData(now.copyWith(isSubmitting: false));
      }
      _showStorageSnack();
      rethrow;
    }
  }

  Future<void> markAbandoned() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    try {
      final uc = await ref.read(markSessionAbandonedUseCaseProvider.future);
      await uc.execute(s.id);
    } catch (_) {
      _showStorageSnack();
    }
  }

  void tickSecond() {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    var learningLeft = current.learningRemainingSecs;
    if (s.mode == 'learning' && !current.explanationVisible) {
      learningLeft = (learningLeft - 1).clamp(0, 1 << 30);
    }

    final newElapsed = current.totalElapsedSecs + 1;

    state = AsyncData(
      current.copyWith(
        totalElapsedSecs: newElapsed,
        currentQuestionElapsedSecs: current.currentQuestionElapsedSecs + 1,
        learningRemainingSecs: learningLeft,
      ),
    );

    if (s.mode == 'exam' &&
        s.isTimed &&
        s.timeLimitSecs != null &&
        newElapsed > 0 &&
        newElapsed % 10 == 0) {
      final remain = (s.timeLimitSecs! - newElapsed).clamp(0, s.timeLimitSecs!);
      unawaited(_persistExamRemaining(s.id, remain));
    }
  }

  Future<void> _persistExamRemaining(
    String sessionId,
    int remainingSecs,
  ) async {
    try {
      final repo = await ref.read(testEngineRepositoryProvider.future);
      await repo.saveExamRemainingSeconds(
        sessionId: sessionId,
        remainingSecs: remainingSecs,
      );
    } catch (_) {
      _showStorageSnack();
    }
  }

  void _showStorageSnack() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showTopSnackBar(
      ctx,
      content: Text(
        'Could not save progress. Please check your device storage.',
        style: AppTextStyles.bodyMd().copyWith(
          color: Theme.of(ctx).colorScheme.onSurface,
        ),
      ),
    );
  }

  Future<void> jumpToIndex(int index) async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    if (index < 0 || index >= s.questions.length) return;
    await _persistCurrentQuestionTime();
    state = AsyncData(
      current.copyWith(currentIndex: index, currentQuestionElapsedSecs: 0),
    );
  }

  Future<bool> toggleBookmark() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return false;
    final q = s.questions[current.currentIndex];
    final isMarked = current.bookmarkedByUuid[q.uuid] ?? false;
    try {
      final repo = await ref.read(testEngineRepositoryProvider.future);
      if (isMarked) {
        await repo.removeBookmark(q.uuid);
      } else {
        await repo.addBookmark(q.uuid);
      }
      final nextMap = {...current.bookmarkedByUuid, q.uuid: !isMarked};
      state = AsyncData(current.copyWith(bookmarkedByUuid: nextMap));
      return !isMarked;
    } catch (_) {
      _showStorageSnack();
      return isMarked;
    }
  }

  Future<void> _persistCurrentQuestionTime() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    final q = s.questions[current.currentIndex];
    final secs = current.currentQuestionElapsedSecs;
    if (secs <= 0) return;
    try {
      final uc = await ref.read(updateQuestionTimeUseCaseProvider.future);
      final existing = q.timeSpentSecs ?? 0;
      await uc.execute(
        sessionId: s.id,
        questionUuid: q.uuid,
        timeSpentSecs: existing + secs,
      );

      final updated = [...s.questions];
      updated[current.currentIndex] = q.copyWith(
        timeSpentSecs: existing + secs,
      );
      state = AsyncData(
        current.copyWith(
          session: s.copyWith(questions: updated),
          currentQuestionElapsedSecs: 0,
        ),
      );
    } catch (_) {
      _showStorageSnack();
    }
  }
}

LearningVerdict? _learningVerdictFromStatus(String status) {
  if (status == 'correct') return LearningVerdict.correct;
  if (status == 'wrong') return LearningVerdict.incorrect;
  if (status == 'timed_out') return LearningVerdict.timedOut;
  return null;
}

extension on ActiveSession {
  ActiveSession copyWith({
    List<TestQuestion>? questions,
    String? status,
    int? savedExamRemainingSecs,
  }) {
    return ActiveSession(
      id: id,
      mode: mode,
      subject: subject,
      topic: topic,
      subTopic: subTopic,
      questionCount: questionCount,
      isTimed: isTimed,
      timeLimitSecs: timeLimitSecs,
      status: status ?? this.status,
      language: language,
      questions: questions ?? this.questions,
      savedExamRemainingSecs:
          savedExamRemainingSecs ?? this.savedExamRemainingSecs,
    );
  }
}
