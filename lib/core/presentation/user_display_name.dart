/// Shown in place of the signed-in user's stored display name when the UI is
/// labeling a person who is the viewer.
const String kViewerSelfDisplayLabel = 'You';

/// Returns [kViewerSelfDisplayLabel] when [subjectUid] matches [viewerUid], or
/// when [subjectEmail] matches [viewerEmail] (case-insensitive). Otherwise
/// returns [name].
///
/// Prefer UID when both sides have it; email is used when UIDs are absent or
/// only one side has a UID.
String displayNameForViewer({
  required String name,
  String? viewerUid,
  String? subjectUid,
  String? viewerEmail,
  String? subjectEmail,
}) {
  final vu = viewerUid?.trim();
  final su = subjectUid?.trim();
  if (vu != null && su != null && vu.isNotEmpty && su.isNotEmpty && vu == su) {
    return kViewerSelfDisplayLabel;
  }
  final ve = viewerEmail?.toLowerCase().trim();
  final se = subjectEmail?.toLowerCase().trim();
  if (ve != null && se != null && ve.isNotEmpty && se.isNotEmpty && ve == se) {
    return kViewerSelfDisplayLabel;
  }
  return name;
}
