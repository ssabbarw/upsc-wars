import '../../../core/domain/entities/active_session.dart';
import '../../../core/domain/entities/session_result.dart';
import 'create_get_started_session_use_case.dart';

/// In-memory snapshot for the Get Started demo test after DB rows are discarded.
class DemoDiagnosticEphemeralSnapshot {
  const DemoDiagnosticEphemeralSnapshot({
    required this.result,
    required this.session,
  });

  final SessionResult result;
  final ActiveSession session;
}

/// Ephemeral cache keyed by session id (cleared when the user leaves results).
class DemoDiagnosticEphemeralStore {
  DemoDiagnosticEphemeralStore._();
  static final DemoDiagnosticEphemeralStore instance =
      DemoDiagnosticEphemeralStore._();

  final Map<String, DemoDiagnosticEphemeralSnapshot> _bySessionId = {};

  bool isDemoAnalyticsKey(String? key) =>
      key == CreateGetStartedSessionUseCase.analyticsKey;

  void put(String sessionId, DemoDiagnosticEphemeralSnapshot snapshot) {
    _bySessionId[sessionId] = snapshot;
  }

  DemoDiagnosticEphemeralSnapshot? peek(String sessionId) =>
      _bySessionId[sessionId];

  void remove(String sessionId) => _bySessionId.remove(sessionId);
}

void clearDemoDiagnosticEphemeral(String sessionId) {
  DemoDiagnosticEphemeralStore.instance.remove(sessionId);
}
