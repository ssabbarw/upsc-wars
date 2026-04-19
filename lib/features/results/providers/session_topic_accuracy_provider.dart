import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/catalog_providers.dart';

/// Per-topic scored stats for a completed session (correct / attempted per topic).
final sessionTopicAccuracyProvider = FutureProvider.autoDispose
    .family<List<({String topic, int correct, int attempted})>, String>((
      ref,
      sessionId,
    ) async {
      final load = await ref.watch(loadSessionUseCaseProvider.future);
      final active = await load.execute(sessionId);
      final map = <String, ({int c, int a})>{};
      for (final q in active.questions) {
        if (q.status != 'correct' && q.status != 'wrong') continue;
        final t = q.topic;
        final prev = map[t] ?? (c: 0, a: 0);
        map[t] = (c: prev.c + (q.status == 'correct' ? 1 : 0), a: prev.a + 1);
      }
      final out =
          map.entries
              .map(
                (e) => (topic: e.key, correct: e.value.c, attempted: e.value.a),
              )
              .toList()
            ..sort((a, b) => b.attempted.compareTo(a.attempted));
      return out;
    });
