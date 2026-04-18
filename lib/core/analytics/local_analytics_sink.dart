import '../database/user_db.dart';
import 'analytics_events.dart';
import 'analytics_sink.dart';

/// Persists high-signal aggregates into the local Drift DB (feature health,
/// trap failures). Topic rollups stay on the existing session completion path.
class LocalAnalyticsSink implements AnalyticsSink {
  LocalAnalyticsSink(this._db);

  final UserDatabase _db;

  @override
  Future<void> send(AnalyticsEvent event) async {
    final now = DateTime.now();
    switch (event) {
      case FeatureViewedEvent(:final featureName):
        await _db.userFeatureStatsDao.incrementViews(featureName, now);
      case FeatureStartedEvent(:final featureName):
        await _db.userFeatureStatsDao.incrementStarts(featureName, now);
      case FeatureCompletedEvent(:final featureName):
        await _db.userFeatureStatsDao.incrementCompletions(featureName, now);
      case QuestionAttemptedEvent(
          :final correct,
          :final trapType,
        ):
        if (!correct && trapType != null && trapType.isNotEmpty) {
          await _db.userTrapStatsDao.recordFailure(trapType: trapType, at: now);
        }
      default:
        break;
    }
  }
}
