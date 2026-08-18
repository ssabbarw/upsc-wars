import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native share-sheet fallback for Chrome (Android) and Safari/Chrome (iOS).
///
/// `app_links` often misses ACTION_SEND / share-extension URLs. Native code
/// extracts the article URL and delivers it here.
abstract final class FomoPulseNativeShare {
  static const _methods = MethodChannel('upsc_wars/share');
  static const _events = EventChannel('upsc_wars/share/events');

  static Stream<String>? _urlStream;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<String?> consumePendingUrl() async {
    if (!_supported) return null;
    try {
      final raw = await _methods.invokeMethod<String>('consumeSharedArticleUrl');
      final url = raw?.trim();
      if (url == null || url.isEmpty) return null;
      debugPrint('[pulse-share] native pending url=$url');
      return url;
    } catch (e) {
      debugPrint('[pulse-share] native consume failed: $e');
      return null;
    }
  }

  static Stream<String> urlStream() {
    if (!_supported) {
      return const Stream.empty();
    }
    return _urlStream ??= _events
        .receiveBroadcastStream()
        .map((event) => event?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty);
  }
}
