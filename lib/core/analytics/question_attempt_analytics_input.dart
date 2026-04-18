/// Optional metadata for a scored MCQ attempt (wired from session notifiers).
class QuestionAttemptAnalyticsInput {
  const QuestionAttemptAnalyticsInput({
    required this.secondsOnQuestion,
    required this.isBattle,
  });

  /// Best-effort time on this question (seconds); may be 0 when not tracked.
  final int secondsOnQuestion;

  final bool isBattle;
}
