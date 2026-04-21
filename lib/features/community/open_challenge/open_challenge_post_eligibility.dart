import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/session_result.dart';
import 'open_challenge_analytics.dart';

/// Whether we should show “post as open challenge” on the generic results screen.
bool shouldOfferPostAsOpenChallenge(SessionResult r) {
  if (r.mode != 'exam') return false;
  if (r.questionCount != 10) return false;
  if (r.correct < 7) return false;
  final key = r.analyticsFeatureKey;
  if (key == OpenChallengeAnalytics.create ||
      key == OpenChallengeAnalytics.accept) {
    return false;
  }
  if (key == 'mcq_battle') return false;
  return SubjectConstants.bySlug(r.subject) != null;
}
