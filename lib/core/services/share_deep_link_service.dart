import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:upsc_wars/core/analytics/session_entry_source.dart';
import 'package:upsc_wars/core/deep_link/share_session_opener.dart';
import 'package:upsc_wars/features/fomo_pulse/data/fomo_pulse_incoming_share.dart';
import 'package:upsc_wars/features/fomo_pulse/data/fomo_pulse_native_share.dart';

/// Subscribes to platform share / universal links after app bootstrap.
///
/// App Links and iOS Universal Links are unreliable on emulators; validate on
/// physical Android and iOS devices.
class ShareDeepLinkService {
  ShareDeepLinkService._();

  static StreamSubscription<Uri>? _subscription;
  static StreamSubscription<String>? _nativeShareSubscription;
  static GoRouter? _fallbackRouter;
  static String? _lastFingerprint;
  static DateTime _lastHandledAt = DateTime.fromMillisecondsSinceEpoch(0);

  static GoRouter? _router() => liveGoRouter(fallback: _fallbackRouter);

  static bool _shouldHandle(Uri uri) {
    final article = articleUrlFromIncomingUri(uri) ?? uri.toString();
    final now = DateTime.now();
    if (_lastFingerprint == article &&
        now.difference(_lastHandledAt) < const Duration(milliseconds: 1500)) {
      return false;
    }
    _lastFingerprint = article;
    _lastHandledAt = now;
    return true;
  }

  static Future<void> initialize(WidgetRef ref, GoRouter router) async {
    await dispose();
    _fallbackRouter = router;
    final appLinks = AppLinks();
    final initial = await appLinks.getInitialLink();
    if (initial != null && _shouldHandle(initial)) {
      await _handleIncoming(ref: ref, uri: initial, replaceStack: true);
    }

    final nativeUrl = await FomoPulseNativeShare.consumePendingUrl();
    if (nativeUrl != null) {
      final uri = pulseArticleDeepLinkForUrl(nativeUrl);
      if (_shouldHandle(uri)) {
        await _handleIncoming(ref: ref, uri: uri, replaceStack: true);
      }
    }

    _subscription = appLinks.uriLinkStream.listen((uri) async {
      if (!_shouldHandle(uri)) return;
      await _handleIncoming(ref: ref, uri: uri);
    });
    _nativeShareSubscription = FomoPulseNativeShare.urlStream().listen((
      url,
    ) async {
      // EventChannel no longer clears native pending (so resume can retry).
      // Consume here so a later app-resume does not reopen the same share.
      unawaited(FomoPulseNativeShare.consumePendingUrl());
      final uri = pulseArticleDeepLinkForUrl(url);
      if (!_shouldHandle(uri)) return;
      await _handleIncoming(ref: ref, uri: uri);
    });
  }

  /// Chrome/Safari can deliver the URL after Flutter is already running
  /// (share sheet while backgrounded). Re-check native pending on resume.
  static Future<void> handleResume(WidgetRef ref, GoRouter router) async {
    _fallbackRouter = router;
    final nativeUrl = await FomoPulseNativeShare.consumePendingUrl();
    if (nativeUrl != null) {
      final uri = pulseArticleDeepLinkForUrl(nativeUrl);
      if (_shouldHandle(uri)) {
        await _handleIncoming(ref: ref, uri: uri);
      }
    }
    FomoPulseIncomingShareStore.consumePending(fallback: _router());
  }

  static Future<void> _handleIncoming({
    required WidgetRef ref,
    required Uri uri,
    bool replaceStack = false,
  }) async {
    final router = _router();
    if (router == null) {
      debugPrint('[share-link] no live router yet uri=$uri');
      final url = articleUrlFromIncomingUri(uri);
      if (url != null) FomoPulseIncomingShareStore.pendingUrl = url;
      return;
    }
    debugPrint('[share-link] incoming uri=$uri');
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
    SessionEntrySource.capture(SessionEntrySource.deepLink, detail: 'share');
    await openShareUriIfApplicable(ref: ref, router: router, uri: uri);
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _nativeShareSubscription?.cancel();
    _nativeShareSubscription = null;
  }
}
