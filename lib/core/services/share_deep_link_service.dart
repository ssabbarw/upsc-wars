import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/analytics/session_entry_source.dart';
import 'package:upsc_wars/core/deep_link/share_session_opener.dart';
import 'package:upsc_wars/features/fomo_pulse/data/fomo_pulse_incoming_share.dart';

/// Subscribes to platform share / universal links after app bootstrap.
///
/// App Links and iOS Universal Links are unreliable on emulators; validate on
/// physical Android and iOS devices.
class ShareDeepLinkService {
  ShareDeepLinkService._();

  static StreamSubscription<Uri>? _subscription;
  static String? _lastFingerprint;
  static DateTime _lastHandledAt = DateTime.fromMillisecondsSinceEpoch(0);

  static bool _shouldHandle(Uri uri) {
    final fp = uri.toString();
    final now = DateTime.now();
    if (_lastFingerprint == fp &&
        now.difference(_lastHandledAt) < const Duration(milliseconds: 1200)) {
      return false;
    }
    _lastFingerprint = fp;
    _lastHandledAt = now;
    return true;
  }

  static Future<void> initialize(WidgetRef ref, GoRouter router) async {
    await dispose();
    final appLinks = AppLinks();
    final initial = await appLinks.getInitialLink();
    if (initial != null && _shouldHandle(initial)) {
      await _handleIncoming(
        ref: ref,
        router: router,
        uri: initial,
        replaceStack: true,
      );
    }

    _subscription = appLinks.uriLinkStream.listen((uri) async {
      if (!_shouldHandle(uri)) return;
      await _handleIncoming(ref: ref, router: router, uri: uri);
    });
  }

  static Future<void> _handleIncoming({
    required WidgetRef ref,
    required GoRouter router,
    required Uri uri,
    bool replaceStack = false,
  }) async {
    final openedPulse = await openPulseArticleFromIncomingShare(
      ref: ref,
      router: router,
      uri: uri,
      replaceStack: replaceStack,
    );
    if (openedPulse) return;
    final openedCaShot = await openFomoPulseFromIncomingLink(
      router: router,
      uri: uri,
      replaceStack: replaceStack,
    );
    if (openedCaShot) return;
    SessionEntrySource.capture(
      SessionEntrySource.deepLink,
      detail: 'share',
    );
    await openShareUriIfApplicable(ref: ref, router: router, uri: uri);
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
