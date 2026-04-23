import 'share_link_kind.dart';

const shareLinkWebHost = 'upscwars.in';
const shareLinkHttpsOrigin = 'https://$shareLinkWebHost';

/// Builds the public HTTPS link used in the system share sheet (Universal Links).
///
/// When [questionIds] is empty, the URL points at Firestore `session/{shareId}` only
/// (no `ids` query). Non-empty [questionIds] keeps legacy self-contained links.
Uri buildShareHttpsUri({
  required ShareLinkKind kind,
  required String shareId,
  List<String> questionIds = const [],
  String? subject,
  String? topic,
}) {
  final q = <String, String>{
    if (questionIds.isNotEmpty) 'ids': questionIds.join(','),
    if (subject != null && subject.isNotEmpty) 'subject': subject,
    if (topic != null && topic.isNotEmpty) 'topic': topic,
  };
  return Uri(
    scheme: 'https',
    host: shareLinkWebHost,
    pathSegments: ['share', kind.pathSegment, shareId],
    queryParameters: q,
  );
}
