import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_summary.dart';
import '../../../core/providers/catalog_providers.dart';

typedef SessionCoachHistoryArg = ({
  String sessionId,
  String subject,
  String? topic,
});

/// Chart points (oldest → newest), up to 10 completed tests, plus trend helpers.
final sessionCoachHistoryProvider = FutureProvider.autoDispose
    .family<SessionCoachHistory, SessionCoachHistoryArg>((ref, arg) async {
      final uc = ref.watch(getSessionListUseCaseProvider);
      final all = await uc.execute(subject: arg.subject);
      final filtered = <SessionSummary>[];
      for (final s in all) {
        if (s.status != 'completed') continue;
        if (s.mode != 'learning' && s.mode != 'exam') continue;
        if (s.accuracy == null) continue;
        final t = arg.topic;
        if (t != null && t.isNotEmpty) {
          if ((s.topic ?? '') != t) continue;
        }
        filtered.add(s);
      }
      // Newest first (repository order is already desc by createdAt).
      final newestFirst = filtered.take(10).toList();
      final chronological = newestFirst.reversed.toList();

      final pts = <SessionCoachPoint>[];
      for (var i = 0; i < chronological.length; i++) {
        final s = chronological[i];
        pts.add(
          SessionCoachPoint(
            testNumber: i + 1,
            sessionId: s.sessionId,
            accuracyPct: s.accuracy!,
          ),
        );
      }

      final idxCurrent = newestFirst.indexWhere(
        (s) => s.sessionId == arg.sessionId,
      );
      double? vsImmediatePrevious;
      if (idxCurrent >= 0 && idxCurrent + 1 < newestFirst.length) {
        final cur = newestFirst[idxCurrent].accuracy!;
        final prev = newestFirst[idxCurrent + 1].accuracy!;
        vsImmediatePrevious = cur - prev;
      }

      double? firstVsLastInWindow;
      if (pts.length >= 2) {
        firstVsLastInWindow = pts.last.accuracyPct - pts.first.accuracyPct;
      }

      return SessionCoachHistory(
        chartPoints: pts,
        vsImmediatePrevious: vsImmediatePrevious,
        firstVsLastInWindow: firstVsLastInWindow,
      );
    });

class SessionCoachPoint {
  const SessionCoachPoint({
    required this.testNumber,
    required this.sessionId,
    required this.accuracyPct,
  });
  final int testNumber;
  final String sessionId;
  final double accuracyPct;
}

class SessionCoachHistory {
  const SessionCoachHistory({
    required this.chartPoints,
    this.vsImmediatePrevious,
    this.firstVsLastInWindow,
  });

  final List<SessionCoachPoint> chartPoints;
  final double? vsImmediatePrevious;
  final double? firstVsLastInWindow;
}

/// Per-question times for the completed session (seconds).
final sessionCoachTimeStatsProvider = FutureProvider.autoDispose
    .family<({int avgSecs, int minSecs, int maxSecs}), String>((
      ref,
      sessionId,
    ) async {
      final load = await ref.watch(loadSessionUseCaseProvider.future);
      final session = await load.execute(sessionId);
      final times = session.questions
          .map((q) => q.timeSpentSecs)
          .whereType<int>()
          .where((t) => t > 0)
          .toList();
      if (times.isEmpty) {
        return (avgSecs: 0, minSecs: 0, maxSecs: 0);
      }
      times.sort();
      final sum = times.fold<int>(0, (a, b) => a + b);
      return (
        avgSecs: (sum / times.length).round(),
        minSecs: times.first,
        maxSecs: times.last,
      );
    });
