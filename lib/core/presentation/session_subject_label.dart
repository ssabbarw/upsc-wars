import '../constants/subject_constants.dart';

/// Human-readable label for a session or question [subject] row.
String displayNameForSessionSubject(String subject) {
  final def = SubjectConstants.bySlug(subject);
  if (def != null) return def.displayName;
  final pyq = RegExp(r'^upsc_pyq_(\d{4})$').firstMatch(subject.trim());
  if (pyq != null) return 'Prelims PYQ · ${pyq.group(1)}';
  return subject;
}
