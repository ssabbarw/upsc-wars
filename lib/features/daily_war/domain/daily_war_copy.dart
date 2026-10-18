import 'package:intl/intl.dart';

import '../../../core/constants/subject_constants.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_schedule.dart';
import '../../../l10n/l10n.dart';

/// Shared copy helpers for Static War surfaces.
abstract final class DailyWarCopy {
  DailyWarCopy._();

  /// The program: static GS, two topics a night, All-India paper.
  static const programName = 'Static War';
  static const programNameCaps = 'STATIC WAR';

  /// Mon–Fri 9 PM event.
  static const dailyEventName = 'Daily Battle';
  static const dailyEventNameCaps = 'DAILY BATTLE';

  /// Saturday week-revision event.
  static const grandEventName = 'Grand War';
  static const grandEventNameCaps = 'GRAND WAR';

  static String eventName({required bool isGrand}) =>
      isGrand ? grandEventName : dailyEventName;

  static String eventNameCaps({required bool isGrand}) =>
      isGrand ? grandEventNameCaps : dailyEventNameCaps;

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

  static String topicsLine(
    List<DailyWarTopicRef> topics, {
    String sep = ' + ',
  }) {
    if (topics.isEmpty) return '';
    return topics.map((t) => t.topic).join(sep);
  }

  /// e.g. `Sat · 2 Aug` from `YYYY-MM-DD`.
  static String formatWarDate(String dateId) {
    try {
      final d = DailyWarSchedule.parseIsoDate(dateId);
      return DateFormat('EEE · d MMM').format(d);
    } on Object {
      return dateId;
    }
  }

  static String compactTopics(
    List<DailyWarTopicRef> topics, {
    bool loadFailed = false,
    bool isLoading = false,
  }) {
    if (topics.isEmpty) {
      if (loadFailed) return appL10n.dwTopicsLoadFailed;
      if (isLoading) return appL10n.dwTopicsFinding;
      return appL10n.dwTwoTopics;
    }
    final subjects = subjectsLine(topics);
    final names = topicsLine(topics);
    return '$subjects · $names';
  }

  static String rulesLine({required int questionCount, required bool isGrand}) {
    final mins = DailyWarSchedule.liveWindowMinutesFor(questionCount);
    return '$questionCount Q · $mins MIN';
  }

  static String rulesLineLobby({
    required int questionCount,
    required bool isGrand,
  }) {
    final mins = DailyWarSchedule.liveWindowMinutesFor(questionCount);
    return appL10n.dwRulesLobby(questionCount, mins);
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
