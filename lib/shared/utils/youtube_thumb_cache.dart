import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'youtube_video_id.dart';

/// Cached YouTube still for the home promo banner.
class YoutubeThumbMeta {
  const YoutubeThumbMeta({
    required this.videoId,
    required this.imageUrl,
    required this.isPortrait,
    required this.width,
    required this.height,
  });

  final String videoId;
  final String imageUrl;
  final bool isPortrait;
  final int width;
  final int height;
}

final _memory = <String, YoutubeThumbMeta>{};
final _inFlight = <String, Future<YoutubeThumbMeta?>>{};

/// Whether [rawUrl] is a YouTube Shorts link (typically portrait).
bool isYoutubeShortsUrl(String rawUrl) {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return false;
  final host = uri.host.toLowerCase();
  if (!host.contains('youtube.com') && !host.contains('youtu.be')) {
    return false;
  }
  return uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first.toLowerCase() == 'shorts';
}

String youtubeThumbUrl(String videoId, String quality) =>
    'https://i.ytimg.com/vi/$videoId/$quality.jpg';

/// Resolves the best available YouTube still, caches it on disk, and detects
/// portrait vs landscape from the decoded image (or Shorts URL).
Future<YoutubeThumbMeta?> resolveYoutubeThumbMeta(String videoUrl) async {
  final videoId = extractYoutubeVideoId(videoUrl);
  if (videoId == null) return null;

  final cached = _memory[videoId];
  if (cached != null) return cached;

  final pending = _inFlight.putIfAbsent(
    videoId,
    () => _resolve(videoId, preferPortrait: isYoutubeShortsUrl(videoUrl)),
  );
  try {
    final meta = await pending;
    if (meta != null) _memory[videoId] = meta;
    return meta;
  } finally {
    _inFlight.remove(videoId);
  }
}

Future<YoutubeThumbMeta?> _resolve(
  String videoId, {
  required bool preferPortrait,
}) async {
  // Prefer higher quality; skip YouTube's tiny "missing maxres" placeholder.
  const qualities = ['maxresdefault', 'sddefault', 'hqdefault', 'mqdefault'];
  for (final quality in qualities) {
    final url = youtubeThumbUrl(videoId, quality);
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final w = image.width;
      final h = image.height;
      image.dispose();
      // Missing maxresdefault is a 120×90 grey stub.
      if (w <= 120 && h <= 90) continue;
      final fromPixels = h > w;
      return YoutubeThumbMeta(
        videoId: videoId,
        imageUrl: url,
        isPortrait: preferPortrait || fromPixels,
        width: w,
        height: h,
      );
    } on Object catch (e, st) {
      debugPrint('youtube thumb $quality failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }
  return null;
}
