/// App-wide seconds allocated **per MCQ** when building timed exam limits as
/// `questionCount * kDebugSecondsPerQuestion` (battles, subject/topic exam
/// config, home quick practice exam mode).
///
/// Lower this locally (e.g. `15`) to debug timers and submissions faster.
/// Production / real pacing: **72** seconds per question.
const int kDebugSecondsPerQuestion = 72;
