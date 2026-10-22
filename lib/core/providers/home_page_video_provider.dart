import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'kill_switch_provider.dart';
import 'prefs_provider.dart';

part 'home_page_video_provider.g.dart';

/// Remote Config key; value is JSON:
/// `{ "video_link": "https://...", "message": "...", "version": 1 }`
const homePageVideoRemoteConfigKey = 'home_page_video';

/// Parsed [homePageVideoRemoteConfigKey] payload.
final class HomePageVideoPayload {
  const HomePageVideoPayload({
    required this.videoUrl,
    required this.message,
    required this.version,
  });

  final String videoUrl;
  final String message;
  final int version;

  static HomePageVideoPayload? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final link = _readVideoLink(map);
      if (link == null || link.isEmpty) return null;
      final version = _readVersion(map);
      if (version == null || version < 1) return null;
      final message = map['message'] is String
          ? map['message'] as String
          : '${map['message'] ?? ''}';
      return HomePageVideoPayload(
        videoUrl: link,
        message: message,
        version: version,
      );
    } on Object {
      return null;
    }
  }

  static String? _readVideoLink(Map<String, dynamic> map) {
    final v = map['video_link'] ?? map['videoLink'] ?? map['url'];
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }

  static int? _readVersion(Map<String, dynamic> map) {
    final v = map['version'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

/// Temporary preview link while we check the home video banner layout.
const _temporaryHomePageVideoJson =
    '{"video_link":"https://www.youtube.com/watch?v=Y1RKdq0YxL","message":"Watch this tip","version":99}';

@Riverpod(keepAlive: true)
Future<HomePageVideoPayload?> homePageVideoPayload(Ref ref) async {
  if (kIsWeb) return null;
  await ref.watch(killSwitchProvider.future);
  final raw = FirebaseRemoteConfig.instance
      .getString(homePageVideoRemoteConfigKey)
      .trim();
  return HomePageVideoPayload.tryParse(raw) ??
      HomePageVideoPayload.tryParse(_temporaryHomePageVideoJson);
}

@Riverpod(keepAlive: true)
Future<HomePageVideoPayload?> homePageVideoVisible(Ref ref) async {
  final payload = await ref.watch(homePageVideoPayloadProvider.future);
  if (payload == null) return null;
  final uri = Uri.tryParse(payload.videoUrl);
  if (uri == null || !(uri.hasScheme && uri.hasAuthority)) return null;
  final prefs = await ref.watch(prefsServiceProvider.future);
  if (prefs.homePageVideoDismissedVersion >= payload.version) return null;
  return payload;
}
