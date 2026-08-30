import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:upsc_wars/core/analytics/question_attempt_analytics_input.dart';
import 'package:upsc_wars/core/domain/entities/active_session.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';
import 'package:upsc_wars/core/domain/entities/test_question.dart';
import 'package:upsc_wars/core/constants/question_source_constants.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/core/providers/prefs_provider.dart';
import 'package:upsc_wars/core/providers/user_database_provider.dart';
import 'package:upsc_wars/core/router/app_router.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/features/home/domain/create_get_started_session_use_case.dart';
import 'package:upsc_wars/features/test_engine/domain/confidence_prompt_policy.dart';
import 'package:upsc_wars/shared/widgets/top_snack_bar.dart';

import 'test_session_state.dart';

part 'test_session_provider.g.dart';

@Riverpod(keepAlive: true)
class TestSessionNotifier extends _$TestSessionNotifier {
  static const String _kSingleQuestionTutorialKey =
      'share_single_question_tutorial';

  bool _isSingleQuestionTutorial(ActiveSession s) {
    return s.mode == 'learning' &&
        s.questionCount == 1 &&
        (s.analyticsFeatureKey == _kSingleQuestionTutorialKey);
  }

  @override
  Future<TestSessionState> build(String sessionId) async {
    final load = await ref.read(loadSessionUseCaseProvider.future);
    final active = await load.execute(sessionId);
    final repo = await ref.read(testEngineRepositoryProvider.future);
    final bm = <String, bool>{};
    for (final q in active.questions) {
      bm[q.uuid] = await repo.isBookmarked(q.uuid);
    }
    final lifetime = await repo.countScoredAttempts();
    final pairs = active.questions
        .map((q) => (subject: q.subject, topic: q.topic))
        .toList();
    final weak = await repo.fetchWeakTopicKeys(pairs);
    return _stateForLoadedSession(
      active,
      bm,
      lifetimeScoredAttempts: lifetime,
      weakTopicKeys: weak,
    );
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
      final lifetime = await repo.countScoredAttempts();
      final pairs = active.questions
          .map((q) => (subject: q.subject, topic: q.topic))
          .toList();
      final weak = await repo.fetchWeakTopicKeys(pairs);
      return _stateForLoadedSession(
        active,
        bm,
        lifetimeScoredAttempts: lifetime,
        weakTopicKeys: weak,
      );
    });
  }

  void setPreStartPaused(bool paused) {
    final cur = state.asData?.value;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(preStartPaused: paused));
  }

  TestSessionState _stateForLoadedSession(
    ActiveSession active,
    Map<String, bool> bookmarkedByUuid, {
    required int lifetimeScoredAttempts,
    required Set<String> weakTopicKeys,
  }) {
    final firstUnattempted = active.questions.indexWhere(
      (q) => q.status == 'unattempted',
    );
    var startIndex = firstUnattempted == -1 ? 0 : firstUnattempted;
    if (startIndex >= active.questions.length) startIndex = 0;

    final startQ = active.questions[startIndex];
    final learningStartExplanation =
        active.mode == 'learning' &&
        (startQ.selectedOption != null || startQ.status == 'timed_out');

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

    final learningLimit = active.mode != 'learning'
        ? 0
        : (!active.isTimed ? -1 : (active.timeLimitSecs ?? 60));
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
      lifetimeScoredAttempts: lifetimeScoredAttempts,
      weakTopicKeys: weakTopicKeys,
      clearError: true,
      explanationVisible: learningStartExplanation,
      learningVerdict: learningStartExplanation
          ? _learningVerdictFromStatus(startQ.status)
          : null,
      clearLearningVerdict: !learningStartExplanation,
    );
  }

  Future<void> selectOption(String option) async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    final q = s.questions[current.currentIndex];

    if (s.mode == 'learning' && current.explanationVisible) return;

    if (current.confidencePromptVisible) return;

    // Special-case: shared single-question tutorial flow always prompts
    // confidence before reveal, regardless of user settings/policy.
    if (_isSingleQuestionTutorial(s)) {
      state = AsyncData(
        current.copyWith(
          pendingSelectedOption: option,
          confidencePromptVisible: true,
        ),
      );
      return;
    }

    final prefs = await ref.read(prefsServiceProvider.future);

    // Exam: optional confidence via slider after answer (never blocking sheet).
    if (s.mode == 'exam') {
      await _commitSelectedOption(option, confidence: null);
      return;
    }

    // Learning: optional global toggle; then adaptive sheet or direct commit.
    if (!prefs.confidenceTrackingEnabled) {
      await _commitSelectedOption(option, confidence: null);
      return;
    }

    // Demo: CA first, no confidence. Ask from the first static question so
    // results can show confident-wrong topics.
    if (s.analyticsFeatureKey == CreateGetStartedSessionUseCase.analyticsKey) {
      final row = await ref
          .read(userDatabaseProvider)
          .questionsDao
          .getByUuid(q.uuid);
      if (row?.sourceKind == QuestionSourceConstants.kindCurrentAffairs) {
        await _commitSelectedOption(option, confidence: null);
        return;
      }
      state = AsyncData(
        current.copyWith(
          pendingSelectedOption: option,
          confidencePromptVisible: true,
        ),
      );
      return;
    }

    final prompt = ConfidencePromptPolicy.shouldPrompt(
      prefs: prefs,
      question: q,
      session: s,
      lifetimeScoredAttempts: current.lifetimeScoredAttempts,
      weakTopicKeys: current.weakTopicKeys,
    );

    if (prompt) {
      state = AsyncData(
        current.copyWith(
          pendingSelectedOption: option,
          confidencePromptVisible: true,
        ),
      );
      return;
    }

    await _commitSelectedOption(option, confidence: null);
  }

  /// Set or clear confidence after the answer is saved (exam or learning).
  /// Learning: once a tier is stored for the current question, further updates
  /// are ignored (first pick is final for that attempt).
  Future<void> updateExamQuestionConfidence({
    required String questionUuid,
    required String? confidence,
  }) async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    if (s.mode != 'exam' && s.mode != 'learning') return;
    final prefs = await ref.read(prefsServiceProvider.future);
    if (!prefs.confidenceTrackingEnabled) return;
    if (confidence != null && !AnswerConfidence.values.contains(confidence)) {
      return;
    }

    final qIdx = s.questions.indexWhere((q) => q.uuid == questionUuid);
    if (qIdx >= 0 &&
        s.mode == 'learning' &&
        s.questions[qIdx].confidence != null) {
      return;
    }

    try {
      final repo = await ref.read(testEngineRepositoryProvider.future);
      await repo.updateAttemptConfidenceOnly(
        sessionId: s.id,
        questionUuid: questionUuid,
        confidence: confidence,
      );
      if (qIdx < 0) return;
      final updated = [...s.questions];
      updated[qIdx] = updated[qIdx].copyWith(confidence: confidence);
      state = AsyncData(
        current.copyWith(session: s.copyWith(questions: updated)),
      );
    } catch (_) {
      _showStorageSnack();
    }
  }

  Future<void> submitConfidenceForPending(String confidence) async {
    final before = state.asData?.value;
    final pending = before?.pendingSelectedOption;
    if (before == null || pending == null) return;
    await _commitSelectedOption(pending, confidence: confidence);
    final after = state.asData?.value;
    if (after == null) return;
    state = AsyncData(
      after.copyWith(clearPendingOption: true, confidencePromptVisible: false),
    );
  }

  void cancelConfidencePrompt() {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        clearPendingOption: true,
        confidencePromptVisible: false,
      ),
    );
  }

  Future<void> _commitSelectedOption(
    String option, {
    required String? confidence,
  }) async {
    var current = state.asData?.value;
    if (current == null || current.session == null) return;

    // Clear the flag synchronously before any await. Otherwise the modal
    // finishes, `_showConfidenceBottomSheet` sees `confidencePromptVisible` still
    // true, calls `cancelConfidencePrompt`, and the subsequent commit state write
    // can briefly flip the flag true again — `ref.listen` fires twice.
    if (current.confidencePromptVisible) {
      state = AsyncData(current.copyWith(confidencePromptVisible: false));
      current = state.asData?.value;
      if (current == null || current.session == null) return;
    }

    final s = current.session!;
    final q = s.questions[current.currentIndex];
    final wasFresh =
        q.status == 'unattempted' &&
        (q.selectedOption == null || q.selectedOption!.isEmpty);

    try {
      final uc = await ref.read(updateQuestionAttemptUseCaseProvider.future);
      final secsOnQuestion =
          (q.timeSpentSecs ?? 0) + current.currentQuestionElapsedSecs;
      final isCorrect = await uc.execute(
        sessionId: s.id,
        questionUuid: q.uuid,
        selectedOption: option,
        confidence: confidence,
        analytics: QuestionAttemptAnalyticsInput(
          secondsOnQuestion: secsOnQuestion,
          isBattle: false,
        ),
      );

      if (isCorrect &&
          (s.subject == 'revision' || s.subject == 'revision_quick')) {
        final rev = await ref.read(
          updateRevisionQueueProgressUseCaseProvider.future,
        );
        await rev.execute(q.uuid);
      }

      final updatedQuestions = [...s.questions];
      updatedQuestions[current.currentIndex] = q.copyWith(
        selectedOption: option.toLowerCase(),
        status: isCorrect ? 'correct' : 'wrong',
        confidence: confidence,
      );

      state = AsyncData(
        current.copyWith(
          session: s.copyWith(questions: updatedQuestions),
          explanationVisible: s.mode == 'learning',
          learningVerdict: isCorrect
              ? LearningVerdict.correct
              : LearningVerdict.incorrect,
          furthestAnsweredIndex:
              current.currentIndex > current.furthestAnsweredIndex
              ? current.currentIndex
              : current.furthestAnsweredIndex,
          lifetimeScoredAttempts: wasFresh
              ? current.lifetimeScoredAttempts + 1
              : current.lifetimeScoredAttempts,
          confidencePromptVisible: false,
        ),
      );
    } catch (_) {
      _showStorageSnack();
      final failed = state.asData?.value;
      if (failed != null) {
        state = AsyncData(
          failed.copyWith(
            clearPendingOption: true,
            confidencePromptVisible: false,
          ),
        );
      }
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
      learningRemainingSecs: s.mode == 'learning'
          ? (nextAnswered
                ? current.learningRemainingSecs
                : (!s.isTimed ? -1 : (s.timeLimitSecs ?? 60)))
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
        explanationVisible: s.mode == 'learning'
            ? prevAnswered
            : current.explanationVisible,
        learningVerdict: s.mode == 'learning'
            ? prevVerdict
            : current.learningVerdict,
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

  Future<void> discardSession() async {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    try {
      final repo = await ref.read(testEngineRepositoryProvider.future);
      await repo.discardSession(s.id, userInitiatedQuit: true);
    } catch (_) {
      _showStorageSnack();
    }
  }

  void tickSecond() {
    final current = state.asData?.value;
    final s = current?.session;
    if (current == null || s == null) return;
    var learningLeft = current.learningRemainingSecs;
    if (s.mode == 'learning' &&
        !current.explanationVisible &&
        learningLeft > 0) {
      learningLeft = learningLeft - 1;
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
    String? analyticsFeatureKey,
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
      analyticsFeatureKey: analyticsFeatureKey ?? this.analyticsFeatureKey,
    );
  }
}
