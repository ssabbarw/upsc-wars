import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/session_entry_source.dart';
import '../../../core/deep_link/share_session_opener.dart';
import '../daily_ca_share_constants.dart';

/// Parses `today` or `YYYY-MM-DD` from app / universal link URIs.
String? parseDailyCaDateSegmentFromUri(Uri uri) {
  if (uri.scheme == 'upscwars' &&
      DailyCaShareConstants.isPublicPathSegment(uri.host) &&
      uri.pathSegments.isNotEmpty) {
    final seg = uri.pathSegments.first.trim();
    return DailyCaShareConstants.isShareableDateSegment(seg) ? seg : null;
  }

  if (uri.scheme == 'https' || uri.scheme == 'http') {
    var host = uri.host.toLowerCase();
    var segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (host == 'upscwars' && segs.isNotEmpty && segs.first == 'in') {
      host = 'upscwars.in';
      segs = segs.skip(1).toList();
    }
    if ((host == 'upscwars.in' || host == 'www.upscwars.in') &&
        segs.length >= 2 &&
        DailyCaShareConstants.isPublicPathSegment(segs[0])) {
      final seg = segs[1].trim();
      // Ignore nested in-app paths like /daily-ca/{date}/leaderboard when
      // delivered as a full https location (leaderboard stays in-app only).
      if (segs.length >= 3) return null;
      return DailyCaShareConstants.isShareableDateSegment(seg) ? seg : null;
    }
  }
  return null;
}

/// Opens `/daily-ca/{date|today}?src=share&start=1` from a shared link.
Future<bool> openDailyCaFromIncomingLink({
  required GoRouter router,
  required Uri uri,
  bool replaceStack = false,
}) async {
  final segment = parseDailyCaDateSegmentFromUri(uri);
  if (segment == null) return false;

  SessionEntrySource.capture(
    SessionEntrySource.deepLink,
    detail: 'daily_ca',
  );

  final target = DailyCaShareConstants.dateLocation(
    segment,
    source: DailyCaShareConstants.entryShare,
    start: true,
  );
  debugPrint('[daily-ca-link] navigating to $target (replace=$replaceStack)');
  navigateLive(target, fallback: router, replace: true);
  return true;
}
