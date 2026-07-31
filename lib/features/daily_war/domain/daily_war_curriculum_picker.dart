import 'daily_war_curriculum.dart';
import 'daily_war_models.dart';
import 'daily_war_schedule.dart';

/// Pure helpers to advance the sequential syllabus without Firestore.
abstract final class DailyWarCurriculumPicker {
  DailyWarCurriculumPicker._();

  /// Picks the next [DailyWarCurriculum.topicsPerWar] topics for [subjectSlug]
  /// starting at [topicIndex] (wraps). Returns topics + next index.
  static ({List<DailyWarTopicRef> topics, int nextIndex}) pickForSubject({
    required String subjectSlug,
    required int topicIndex,
  }) {
    final list = DailyWarCurriculum.topicsBySubject[subjectSlug] ?? const [];
    if (list.isEmpty) {
      return (topics: const [], nextIndex: 0);
    }
    final n = DailyWarCurriculum.topicsPerWar;
    final topics = <DailyWarTopicRef>[];
    var idx = topicIndex % list.length;
    for (var i = 0; i < n; i++) {
      topics.add(
        DailyWarTopicRef(subjectSlug: subjectSlug, topic: list[idx]),
      );
      idx = (idx + 1) % list.length;
    }
    return (topics: topics, nextIndex: idx);
  }

  /// Weekday War: advance one subject in rotation by [subjectRotationIndex].
  static ({
    List<DailyWarTopicRef> topics,
    String subjectSlug,
    int nextSubjectRotationIndex,
    int nextTopicIndexForSubject,
  }) pickWeekday({
    required int subjectRotationIndex,
    required Map<String, int> topicIndexBySubject,
  }) {
    final rotation = DailyWarCurriculum.subjectRotation;
    final subjectSlug =
        rotation[subjectRotationIndex % rotation.length];
    final topicIndex = topicIndexBySubject[subjectSlug] ?? 0;
    final picked = pickForSubject(
      subjectSlug: subjectSlug,
      topicIndex: topicIndex,
    );
    return (
      topics: picked.topics,
      subjectSlug: subjectSlug,
      nextSubjectRotationIndex:
          (subjectRotationIndex + 1) % rotation.length,
      nextTopicIndexForSubject: picked.nextIndex,
    );
  }

  static int questionCountForIstDate(DateTime istDate) =>
      DailyWarSchedule.questionCountForDate(istDate);
}
