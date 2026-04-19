/// Extracts a YouTube video id from common watch / embed / shorts URLs.
String? extractYoutubeVideoId(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null || !uri.hasScheme) return null;
  final host = uri.host.toLowerCase();

  if (host == 'youtu.be' || host == 'www.youtu.be') {
    final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    return _normalizeYoutubeId(seg);
  }

  if (!host.contains('youtube.com')) return null;

  final segs = uri.pathSegments;
  if (segs.isNotEmpty) {
    switch (segs.first) {
      case 'shorts':
      case 'embed':
      case 'live':
        if (segs.length >= 2) {
          final id = _normalizeYoutubeId(segs[1]);
          if (id != null) return id;
        }
      case 'v':
        if (segs.length >= 2) return _normalizeYoutubeId(segs[1]);
    }
  }

  final v = uri.queryParameters['v'];
  if (v != null && v.isNotEmpty) return _normalizeYoutubeId(v);
  return null;
}

String? _normalizeYoutubeId(String raw) {
  final id = raw.trim();
  if (id.length != 11) return null;
  final ok = RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id);
  return ok ? id : null;
}
