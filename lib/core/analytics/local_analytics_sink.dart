import '../database/user_db.dart';
import 'analytics_events.dart';
import 'analytics_sink.dart';

/// Second sink: writes **on-device** aggregates (Drift) for a subset of events
/// (feature view/start/complete, trap wrongs). **Does not** upload to GA4; see
/// [FirebaseAnalyticsSink] for cloud event names. Events not listed in [send]
/// are ignored.
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
