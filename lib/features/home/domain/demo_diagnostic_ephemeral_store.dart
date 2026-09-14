import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/entities/active_session.dart';
import '../../../core/domain/entities/session_result.dart';
import '../../../core/providers/prefs_provider.dart';
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

/// True when opening explanations should mark the demo review as opened.
bool shouldMarkDemoDiagnosticReviewOpened({
  required bool isDemoSession,
  required bool getStartedDiagnosticAttempted,
}) {
  if (isDemoSession) return true;
  // Review CTAs often omit the analytics key, and the in-memory demo snapshot
  // is gone by the time the user opens explanations.
  return getStartedDiagnosticAttempted;
}

/// Marks that the user opened post-demo question review (mistakes or all).
void maybeMarkDemoDiagnosticReviewOpened(
  String sessionId, {
  String? analyticsFeatureKey,
}) {
  final store = DemoDiagnosticEphemeralStore.instance;
  final snap = store.peek(sessionId);
  final isDemoSession = snap != null ||
      store.isDemoAnalyticsKey(
        analyticsFeatureKey ?? snap?.result.analyticsFeatureKey,
      );
  unawaited(() async {
    final prefs = PrefsService(await SharedPreferences.getInstance());
    if (prefs.demoDiagnosticReviewOpened) return;
    if (!shouldMarkDemoDiagnosticReviewOpened(
      isDemoSession: isDemoSession,
      getStartedDiagnosticAttempted: prefs.getStartedDiagnosticAttempted,
    )) {
      return;
    }
    prefs.demoDiagnosticReviewOpened = true;
  }());
}
