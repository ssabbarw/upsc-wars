import '../constants/subject_constants.dart';
import '../constants/question_source_constants.dart';

/// Human-readable label for a session or question [subject] row.
String displayNameForSessionSubject(String subject) {
  if (subject == 'misc') return 'Misc (mixed subjects)';
  if (subject == QuestionSourceConstants.dailyCaSessionSubject) {
    return 'Daily Current Affairs';
  }
  if (subject == 'sunday_review') return 'Week review';
  if (subject == 'daily_revision') return 'Revision';
  final def = SubjectConstants.bySlug(subject);
  if (def != null) return def.displayName;
  final pyq = RegExp(r'^upsc_pyq_(\d{4})$').firstMatch(subject.trim());
  if (pyq != null) return 'Prelims PYQ · ${pyq.group(1)}';
  return subject;
}

/// Open-challenge list/detail headers: human label, first character uppercased.
String openChallengeSubjectTitle(String rawSubject) {
  final label = displayNameForSessionSubject(rawSubject).trim();
  if (label.isEmpty) return label;
  return label[0].toUpperCase() + label.substring(1);
}
