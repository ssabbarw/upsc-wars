import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_summary.dart';
import '../../../core/providers/catalog_providers.dart';

typedef SubjectAccuracyTrendArg = ({
  String subject,
  String? topic,
  int rangeDays,
});

/// One point per calendar day: mean session accuracy (% of attempts correct).
final subjectAccuracyTrendProvider = FutureProvider.autoDispose
    .family<
      List<({DateTime day, double accuracyPct})>,
      SubjectAccuracyTrendArg
    >((ref, arg) async {
      final uc = ref.watch(getSessionListUseCaseProvider);
      final sessions = await uc.execute(subject: arg.subject);
      final cutoff = DateTime.now().subtract(Duration(days: arg.rangeDays));
      final buckets = <DateTime, List<double>>{};

      for (final SessionSummary s in sessions) {
        if (s.status != 'completed') continue;
        if (s.mode != 'learning' && s.mode != 'exam') continue;
        if (s.accuracy == null) continue;
        if (s.createdAt.isBefore(cutoff)) continue;
        final t = arg.topic;
        if (t != null && t.isNotEmpty) {
          if ((s.topic ?? '') != t) continue;
        }
        final day = DateTime(
          s.createdAt.year,
          s.createdAt.month,
          s.createdAt.day,
        );
        buckets.putIfAbsent(day, () => []).add(s.accuracy!);
      }

      final out =
          buckets.entries
              .map(
                (e) => (
                  day: e.key,
                  accuracyPct: e.value.reduce((a, b) => a + b) / e.value.length,
                ),
              )
              .toList()
            ..sort((a, b) => a.day.compareTo(b.day));
      return out;
    });
