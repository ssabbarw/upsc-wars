import 'share_link_kind.dart';

/// Parsed in-app share / deep link (custom scheme or https).
class ShareLinkPayload {
  const ShareLinkPayload({
    required this.kind,
    required this.shareId,
    required this.questionIds,
    this.subject,
    this.topic,
  });

  final ShareLinkKind kind;
  final String shareId;
  final List<String> questionIds;
  final String? subject;
  final String? topic;
}

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isUuid(String s) => _uuid.hasMatch(s.trim());

/// Returns null if [uri] is not a recognized share link.
ShareLinkPayload? parseShareLinkUri(Uri uri) {
  late final ShareLinkKind kind;
  late final String shareIdRaw;

  if (uri.scheme == 'upscwars' &&
      uri.host.toLowerCase() == 'share' &&
      uri.pathSegments.length >= 2) {
    final segments = uri.pathSegments;
    final k = ShareLinkKind.parse(segments[0]);
    if (k == null) return null;
    kind = k;
    shareIdRaw = segments[1];
  } else if (uri.scheme == 'https' &&
      uri.host.toLowerCase() == 'upscwars.app' &&
      uri.pathSegments.length >= 3 &&
      uri.pathSegments[0].toLowerCase() == 'share') {
    final segments = uri.pathSegments;
    final k = ShareLinkKind.parse(segments[1]);
    if (k == null) return null;
    kind = k;
    shareIdRaw = segments[2];
  } else {
    return null;
  }

  final id = shareIdRaw.trim();
  if (id.isEmpty) return null;
  if (!isUuid(id)) return null;

  final rawIds = uri.queryParameters['ids']?.trim() ?? '';
  final ids = rawIds
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (ids.isNotEmpty) {
    for (final u in ids) {
      if (!isUuid(u)) return null;
    }
    if (kind == ShareLinkKind.question && ids.length != 1) {
      return null;
    }
  }

  final subject = uri.queryParameters['subject']?.trim();
  final topic = uri.queryParameters['topic']?.trim();

  return ShareLinkPayload(
    kind: kind,
    shareId: id,
    questionIds: ids,
    subject: (subject != null && subject.isNotEmpty) ? subject : null,
    topic: (topic != null && topic.isNotEmpty) ? topic : null,
  );
}
