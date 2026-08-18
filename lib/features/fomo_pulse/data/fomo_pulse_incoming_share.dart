import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/deep_link/share_session_opener.dart';
import '../../../core/providers/super_user_provider.dart';
import '../../home/providers/auth_providers.dart';
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

/// Builds `/internal/fomo-pulse-composer/article?url=…` for share/deep-link entry.
String pulseArticleRouteForUrl(String articleUrl) {
  return Uri(
    path: '/internal/fomo-pulse-composer/article',
    queryParameters: {'url': articleUrl.trim()},
  ).toString();
}

FomoPulseArticleArgs? pulseArticleArgsFromRoute(GoRouterState state) {
  final extra = state.extra;
  if (extra is FomoPulseArticleArgs) return extra;
  final raw = state.uri.queryParameters['url']?.trim() ?? '';
  if (raw.isEmpty) return null;
  final decoded = Uri.decodeComponent(raw).trim();
  final candidate = decoded.startsWith('http') ? decoded : raw;
  if (candidate.startsWith('http://') || candidate.startsWith('https://')) {
    return FomoPulseArticleArgs.url(url: candidate);
  }
  return null;
}

/// Opens the Pulse article screen when a signed-in admin shares a news URL.
Future<bool> openPulseArticleFromIncomingShare({
  required WidgetRef ref,
  required GoRouter router,
  required Uri uri,
  bool replaceStack = false,
}) async {
  final url = articleUrlFromIncomingShareUri(uri);
  if (url == null) return false;
  if (_isOwnProductUrl(url)) return false;

  final auth = ref.read(authStateChangesProvider);
  if (auth.isLoading) {
    FomoPulseIncomingShareStore.pendingUrl = url;
    return true;
  }
  if (!ref.read(isSuperUserProvider)) {
    showShareLinkMessage(
      'Sign in as an admin to make a Pulse from this article.',
    );
    return true;
  }

  final target = pulseArticleRouteForUrl(url);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    debugPrint('[pulse-share] navigating to $target (replace=$replaceStack)');
    if (replaceStack) {
      router.go(target);
    } else {
      router.push(target);
    }
  });
  return true;
}

/// Holds a share URL until Firebase auth finishes loading on cold start.
abstract final class FomoPulseIncomingShareStore {
  static String? pendingUrl;

  static void consumePending(GoRouter router) {
    final url = pendingUrl?.trim();
    if (url == null || url.isEmpty) return;
    pendingUrl = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(pulseArticleRouteForUrl(url));
    });
  }
}
