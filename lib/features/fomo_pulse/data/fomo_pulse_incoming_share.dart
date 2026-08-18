import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/deep_link/share_session_opener.dart';
import '../../../core/providers/super_user_provider.dart';
import '../domain/fomo_pulse_models.dart';
import '../fomo_pulse_constants.dart';

final _httpUrlRe = RegExp(
  r'''https?://[^\s<>"'\)\]]+''',
  caseSensitive: false,
);

/// First http(s) URL in [raw], or null.
String? extractHttpUrlFromSharedText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final direct = Uri.tryParse(trimmed);
  if (direct != null &&
      (direct.scheme == 'http' || direct.scheme == 'https') &&
      direct.host.isNotEmpty) {
    return trimmed;
  }
  final match = _httpUrlRe.firstMatch(trimmed);
  if (match == null) return null;
  var url = match.group(0)!.trim();
  while (url.endsWith('.') || url.endsWith(',')) {
    url = url.substring(0, url.length - 1);
  }
  final parsed = Uri.tryParse(url);
  if (parsed == null || parsed.host.isEmpty) return null;
  if (parsed.scheme != 'http' && parsed.scheme != 'https') return null;
  return url;
}

/// Article URL carried on `upscwars://pulse-article?url=…`.
String? articleUrlFromIncomingShareUri(Uri uri) {
  if (uri.scheme != FomoPulseConstants.incomingShareScheme) return null;
  if (uri.host.toLowerCase() != FomoPulseConstants.incomingShareHost) {
    return null;
  }
  final fromQuery = uri.queryParameters['url']?.trim() ?? '';
  return extractHttpUrlFromSharedText(fromQuery);
}

bool _isOwnProductUrl(String url) {
  final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
  return host == 'upscwars.in' || host == 'www.upscwars.in';
}

/// Opens the Pulse article screen when a signed-in admin shares a news URL.
Future<bool> openPulseArticleFromIncomingShare({
  required WidgetRef ref,
  required GoRouter router,
  required Uri uri,
}) async {
  final url = articleUrlFromIncomingShareUri(uri);
  if (url == null) return false;
  if (_isOwnProductUrl(url)) return false;
  if (!ref.read(isSuperUserProvider)) {
    showShareLinkMessage(
      'Sign in as an admin to make a Pulse from this article.',
    );
    return true;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    router.push(
      '/internal/fomo-pulse-composer/article',
      extra: FomoPulseArticleArgs.url(url: url),
    );
  });
  return true;
}
