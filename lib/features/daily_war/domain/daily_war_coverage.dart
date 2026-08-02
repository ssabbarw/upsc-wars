import 'daily_war_curriculum.dart';
import 'daily_war_models.dart';

/// Syllabus coverage derived from wars already announced (history + tonight).
abstract final class DailyWarCoverage {
  DailyWarCoverage._();

  static int get totalTopics => DailyWarCurriculum.totalTopicCount;

  static String _key(DailyWarTopicRef t) => '${t.subjectSlug}::${t.topic}';

  /// Unique topics that have appeared in [wars] (e.g. history cache).
  static Set<String> keysFromWars(Iterable<DailyWarDoc> wars) {
    final out = <String>{};
    for (final w in wars) {
      for (final t in w.topics) {
        out.add(_key(t));
      }
    }
    return out;
  }

  static ({int covered, int tonightAdds, int total}) compute({
    required Iterable<DailyWarDoc> historyWars,
    required List<DailyWarTopicRef> tonightTopics,
    DailyWarDoc? tonightDoc,
  }) {
    final seen = keysFromWars(historyWars);
    if (tonightDoc != null) {
      for (final t in tonightDoc.topics) {
        seen.add(_key(t));
      }
    }
    var tonightAdds = 0;
    final historyOnly = keysFromWars(historyWars);
    for (final t in tonightTopics) {
      if (!historyOnly.contains(_key(t))) tonightAdds++;
    }
    // Prefer union including tonight when announced.
    final covered = tonightTopics.isEmpty
        ? historyOnly.length
        : {...historyOnly, ...tonightTopics.map(_key)}.length;
    return (covered: covered, tonightAdds: tonightAdds, total: totalTopics);
  }
}
