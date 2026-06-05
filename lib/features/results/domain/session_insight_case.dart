import '../../../core/domain/entities/session_result.dart';

/// Session summary hero insight variant (A–F).
enum SessionInsightCase {
  /// Sure-wrong only.
  a,

  /// Educated-guess-wrong only.
  b,

  /// Both sure-wrong and educated-guess-wrong.
  c,

  /// Wrong answers with no sure/educated wrong (pure guess / unlogged).
  d,

  /// No wrong answers (clean session).
  e,

  /// Confidence tracking disabled in settings.
  fLockedSettings,

  /// Tracking on but insufficient confidence coverage on this session.
  fLockedSkipped,
}

const kPrelimsWrongMarkPenalty = 0.66;

int sessionAnsweredScored(SessionResult result) => result.correct + result.wrong;

int sessionLoggedConfidenceTotal(SessionResult result) =>
    result.confidenceSureTotal +
    result.confidenceIntelligentTotal +
    result.confidencePureTotal;

double sessionConfidenceCoverage(SessionResult result) {
  final answered = sessionAnsweredScored(result);
  if (answered <= 0) return 0;
  return (sessionLoggedConfidenceTotal(result) / answered).clamp(0.0, 1.0);
}

int sessionSureWrongCount(SessionResult result) =>
    result.confidenceSureTotal - result.confidenceSureCorrect;

int sessionEduWrongCount(SessionResult result) =>
    result.confidenceIntelligentTotal - result.confidenceIntelligentCorrect;

int sessionPureWrongCount(SessionResult result) =>
    result.confidencePureTotal - result.confidencePureCorrect;

double sessionTierMarksLost(int wrongCount) => wrongCount * kPrelimsWrongMarkPenalty;

/// Classifies which hero insight card to show (priority order A–F).
SessionInsightCase classifySessionInsight({
  required SessionResult result,
  required bool confidenceTrackingEnabled,
  double? confidenceCoverage,
}) {
  final coverage = confidenceCoverage ?? sessionConfidenceCoverage(result);
  final answered = sessionAnsweredScored(result);
  final sureWrong = sessionSureWrongCount(result);
  final eduWrong = sessionEduWrongCount(result);

  if (!confidenceTrackingEnabled) {
    return SessionInsightCase.fLockedSettings;
  }

  if (answered >= 4 && coverage < 0.5) {
    return SessionInsightCase.fLockedSkipped;
  }

  if (result.mode == 'exam' &&
      sessionLoggedConfidenceTotal(result) == 0 &&
      answered > 0) {
    return SessionInsightCase.fLockedSkipped;
  }

  if (sureWrong > 0 && eduWrong > 0) {
    return SessionInsightCase.c;
  }
  if (sureWrong > 0) {
    return SessionInsightCase.a;
  }
  if (eduWrong > 0) {
    return SessionInsightCase.b;
  }
  if (result.wrong > 0) {
    return SessionInsightCase.d;
  }
  return SessionInsightCase.e;
}

String sessionInsightCaseAnalyticsName(SessionInsightCase c) {
  return switch (c) {
    SessionInsightCase.a => 'a_confident',
    SessionInsightCase.b => 'b_educated_guess',
    SessionInsightCase.c => 'c_high_risk',
    SessionInsightCase.d => 'd_pure_guess',
    SessionInsightCase.e => 'e_clean',
    SessionInsightCase.fLockedSettings => 'f_locked_settings',
    SessionInsightCase.fLockedSkipped => 'f_locked_skipped',
  };
}
