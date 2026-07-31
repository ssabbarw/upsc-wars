import '../../../core/constants/subject_constants.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_schedule.dart';

/// Shared copy helpers for Daily War surfaces.
abstract final class DailyWarCopy {
  DailyWarCopy._();

  /// Maps curriculum slugs (`polity`, `modern_history`) → session subject slugs.
  static String sessionSubjectSlug(String curriculumSlug) {
    const map = <String, String>{
      'polity': 'Polity',
      'economy': 'Economy',
      'geography': 'Geography',
      'environment': 'Environment',
      'modern_history': 'Modern History',
      'ancient_history': 'Ancient History',
      'medieval_history': 'Medieval History',
      'art_and_culture': 'Art and Culture',
    };
    final key = curriculumSlug.trim().toLowerCase();
    return map[key] ??
        SubjectConstants.bySlug(curriculumSlug)?.slug ??
        curriculumSlug;
  }

  static String subjectDisplay(String slug) =>
      SubjectConstants.bySlug(sessionSubjectSlug(slug))?.displayName ??
      SubjectConstants.bySlug(slug)?.displayName ??
      slug;

  static String subjectsLine(List<DailyWarTopicRef> topics) {
    if (topics.isEmpty) return '';
    return topics.map((t) => subjectDisplay(t.subjectSlug)).toSet().join(' + ');
  }

  static String topicsLine(List<DailyWarTopicRef> topics, {String sep = ' + '}) {
    if (topics.isEmpty) return '';
    return topics.map((t) => t.topic).join(sep);
  }

  static String compactTopics(List<DailyWarTopicRef> topics) {
    if (topics.isEmpty) return 'Tonight\'s topics loading…';
    final subjects = subjectsLine(topics);
    final names = topicsLine(topics);
    return '$subjects · $names';
  }

  static String rulesLine({
    required int questionCount,
    required bool isGrand,
  }) {
    final mins = isGrand ? 30 : DailyWarSchedule.liveWindowMinutes;
    return '$questionCount Q · $mins MIN · −1/3 NEGATIVE';
  }

  static String rulesLineLobby({
    required int questionCount,
    required bool isGrand,
  }) {
    final mins = isGrand ? 30 : DailyWarSchedule.liveWindowMinutes;
    return '$questionCount Q · $mins MIN · −1/3 · ONE ATTEMPT';
  }

  /// Formats a count for display, or `null` when RC / threshold hide it.
  static String? formatVisibleCount({
    required int? raw,
    required bool enabled,
    required int minVisible,
  }) {
    if (!enabled) return null;
    final n = raw ?? 0;
    if (n < minVisible) return null;
    return _withCommas(n);
  }

  static String _withCommas(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
