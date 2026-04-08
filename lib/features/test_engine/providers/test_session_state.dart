import 'package:upsc_wars/core/domain/entities/active_session.dart';

enum LearningVerdict { correct, incorrect, timedOut }

class TestSessionState {
  const TestSessionState({
    required this.isLoading,
    required this.error,
    required this.session,
    required this.currentIndex,
    required this.currentQuestionElapsedSecs,
    required this.totalElapsedSecs,
    required this.learningRemainingSecs,
    required this.explanationVisible,
    required this.paletteOpen,
    required this.submitSheetOpen,
    required this.learningVerdict,
    required this.isSubmitting,
    required this.bookmarkedByUuid,
    required this.showTimedExamResumeBanner,
    required this.furthestAnsweredIndex,
  });

  factory TestSessionState.initial() => const TestSessionState(
    isLoading: true,
    error: null,
    session: null,
    currentIndex: 0,
    currentQuestionElapsedSecs: 0,
    totalElapsedSecs: 0,
    learningRemainingSecs: 0,
    explanationVisible: false,
    paletteOpen: false,
    submitSheetOpen: false,
    learningVerdict: null,
    isSubmitting: false,
    bookmarkedByUuid: {},
    showTimedExamResumeBanner: false,
    furthestAnsweredIndex: -1,
  );

  final bool isLoading;
  final String? error;
  final ActiveSession? session;
  final int currentIndex;
  final int currentQuestionElapsedSecs;
  final int totalElapsedSecs;
  final int learningRemainingSecs;
  final bool explanationVisible;
  final bool paletteOpen;
  final bool submitSheetOpen;
  final LearningVerdict? learningVerdict;
  final bool isSubmitting;
  final Map<String, bool> bookmarkedByUuid;
  final bool showTimedExamResumeBanner;
  final int furthestAnsweredIndex;

  TestSessionState copyWith({
    bool? isLoading,
    String? error,
    ActiveSession? session,
    int? currentIndex,
    int? currentQuestionElapsedSecs,
    int? totalElapsedSecs,
    int? learningRemainingSecs,
    bool? explanationVisible,
    bool? paletteOpen,
    bool? submitSheetOpen,
    LearningVerdict? learningVerdict,
    bool clearError = false,
    bool clearLearningVerdict = false,
    bool? isSubmitting,
    Map<String, bool>? bookmarkedByUuid,
    bool? showTimedExamResumeBanner,
    int? furthestAnsweredIndex,
  }) {
    return TestSessionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      session: session ?? this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      currentQuestionElapsedSecs:
          currentQuestionElapsedSecs ?? this.currentQuestionElapsedSecs,
      totalElapsedSecs: totalElapsedSecs ?? this.totalElapsedSecs,
      learningRemainingSecs:
          learningRemainingSecs ?? this.learningRemainingSecs,
      explanationVisible: explanationVisible ?? this.explanationVisible,
      paletteOpen: paletteOpen ?? this.paletteOpen,
      submitSheetOpen: submitSheetOpen ?? this.submitSheetOpen,
      learningVerdict:
          clearLearningVerdict
              ? null
              : (learningVerdict ?? this.learningVerdict),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      bookmarkedByUuid: bookmarkedByUuid ?? this.bookmarkedByUuid,
      showTimedExamResumeBanner:
          showTimedExamResumeBanner ?? this.showTimedExamResumeBanner,
      furthestAnsweredIndex:
          furthestAnsweredIndex ?? this.furthestAnsweredIndex,
    );
  }
}
