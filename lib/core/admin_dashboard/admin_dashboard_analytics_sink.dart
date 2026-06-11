import '../analytics/analytics_events.dart';
import '../analytics/activation_milestones.dart';
import '../analytics/analytics_sink.dart';
import 'admin_dashboard_service.dart';

/// Mirrors selected [AnalyticsEvent]s into Firestore `admin_dashboard` docs.
class AdminDashboardAnalyticsSink implements AnalyticsSink {
  AdminDashboardAnalyticsSink({AdminDashboardWriterService? writer})
      : _writer = writer ?? AdminDashboardWriterService();

  final AdminDashboardWriterService _writer;

  @override
  Future<void> send(AnalyticsEvent event) async {
    switch (event) {
      case OnboardingFlowCompletedEvent():
        await _writer.recordOnboardingCompleted();
      case ActivationMilestoneEvent(:final milestoneId):
        if (milestoneId == ActivationMilestones.getStartedDiagnosticCompleted) {
          await _writer.recordFirstDemoTestCompleted();
        }
      case McqTestSessionStartedEvent(:final analyticsFeatureKey):
        await _writer.recordTestStarted(
          analyticsFeatureKey: analyticsFeatureKey,
        );
      default:
        break;
    }
  }
}
