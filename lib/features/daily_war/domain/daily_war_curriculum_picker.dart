import 'daily_war_curriculum.dart';
import 'daily_war_models.dart';
import 'daily_war_schedule.dart';

/// Pure helpers to advance the sequential syllabus without Firestore.
abstract final class DailyWarCurriculumPicker {
  DailyWarCurriculumPicker._();

  /// Picks the next topics for [subjectSlug] starting at [topicIndex].
  ///
  /// Takes up to [DailyWarCurriculum.topicsPerWar] topics and does **not**
  /// wrap within the subject — a leftover single topic is returned alone.
  static ({List<DailyWarTopicRef> topics, int nextIndex}) pickForSubject({
    required String subjectSlug,
    required int topicIndex,
  }) {
    final list = DailyWarCurriculum.topicsBySubject[subjectSlug] ?? const [];
    if (list.isEmpty) {
      return (topics: const [], nextIndex: 0);
    }
    final start = topicIndex.clamp(0, list.length);
    final remaining = list.length - start;
    final n = remaining < DailyWarCurriculum.topicsPerWar
        ? remaining
        : DailyWarCurriculum.topicsPerWar;
    final topics = <DailyWarTopicRef>[
      for (var i = 0; i < n; i++)
        DailyWarTopicRef(subjectSlug: subjectSlug, topic: list[start + i]),
    ];
    return (topics: topics, nextIndex: start + n);
  }

  /// Weekday War: finish the current subject (2 topics at a time) before
  /// advancing. [nextTopicIndexForSubject] is the pointer for the subject at
  /// [nextSubjectRotationIndex] (0 when that subject is newly started).
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
    if (rotation.isEmpty) {
      return (
        topics: const <DailyWarTopicRef>[],
        subjectSlug: '',
        nextSubjectRotationIndex: 0,
        nextTopicIndexForSubject: 0,
      );
    }

    final startIndex =
        ((subjectRotationIndex % rotation.length) + rotation.length) %
        rotation.length;

    for (var offset = 0; offset < rotation.length; offset++) {
      final subjectIndex = (startIndex + offset) % rotation.length;
      final picked = _pickOpenSubject(
        subjectIndex: subjectIndex,
        topicIndexBySubject: topicIndexBySubject,
      );
      if (picked != null) return picked;
    }

    // Every subject pointer is exhausted — restart the cycle.
    return _pickOpenSubject(
      subjectIndex: 0,
      topicIndexBySubject: const {},
    )!;
  }

  static ({
    List<DailyWarTopicRef> topics,
    String subjectSlug,
    int nextSubjectRotationIndex,
    int nextTopicIndexForSubject,
  })?
  _pickOpenSubject({
    required int subjectIndex,
    required Map<String, int> topicIndexBySubject,
  }) {
    final rotation = DailyWarCurriculum.subjectRotation;
    final subjectSlug = rotation[subjectIndex];
    final list = DailyWarCurriculum.topicsBySubject[subjectSlug] ?? const [];
    var topicIndex = topicIndexBySubject[subjectSlug] ?? 0;
    if (topicIndex < 0) topicIndex = 0;
    if (list.isEmpty || topicIndex >= list.length) return null;

    final picked = pickForSubject(
      subjectSlug: subjectSlug,
      topicIndex: topicIndex,
    );
    final finished = picked.nextIndex >= list.length;
    return (
      topics: picked.topics,
      subjectSlug: subjectSlug,
      nextSubjectRotationIndex: finished
          ? (subjectIndex + 1) % rotation.length
          : subjectIndex,
      nextTopicIndexForSubject: finished ? 0 : picked.nextIndex,
    );
  }

  static int questionCountForIstDate(DateTime istDate) =>
      DailyWarSchedule.questionCountForDate(istDate);
}
