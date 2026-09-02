/// FOMO Pulse — breaking-news push MCQs.
abstract final class FomoPulseConstants {
  static const broadcastFcmTopic = 'upsc_wars_fomo_pulse';
  static const analyticsKey = 'fomo_pulse';
  static const fcmKind = 'fomo_pulse';

  /// Share-card FOMO copy stays gated so a handful of attempts does not
  /// look like a crowd. In-app list/detail always show raw attempt counts.
  static const minStatsAttempts = 20;

  static const historyPageSize = 20;

  /// Skip a list refetch when the user reopens within this window (e.g. back
  /// from detail). Detail screens always fetch the latest pulse doc.
  static const historyRefreshDebounce = Duration(seconds: 45);

  static const cachePulsesKey = 'fomo_pulse_cache_pulses_v1';
  static const cacheAttemptsKey = 'fomo_pulse_cache_attempts_v1';
  static const cacheListSyncedAtMsKey = 'fomo_pulse_cache_list_synced_at_ms_v1';

  /// Custom scheme used when Chrome/Safari share an article into the app.
  static const incomingShareScheme = 'upscwars';
  static const incomingShareHost = 'pulse-article';

  /// Public HTTPS + in-app path: `https://upscwars.in/ca-shot/{pulseId}`.
  static const publicPathSegment = 'ca-shot';

  /// Older shares used `/fomo-pulse/{pulseId}` — still accepted on inbound links.
  static const legacyPathSegment = 'fomo-pulse';

  /// Opens a published CA Shot: upscwars://ca-shot/{pulseId}
  static const deepLinkHost = publicPathSegment;
  static const legacyDeepLinkHost = legacyPathSegment;

  static const hubLocation = '/$publicPathSegment';

  static bool isPublicPathSegment(String raw) {
    final s = raw.trim().toLowerCase();
    return s == deepLinkHost || s == legacyDeepLinkHost;
  }

  static const entryPush = 'push';
  static const entryHistory = 'history';
  static const entryShare = 'share';
  static const entryInApp = 'in_app';

  static String normalizeEntrySource(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case entryPush:
      case entryHistory:
      case entryShare:
        return raw!.trim().toLowerCase();
      default:
        return entryInApp;
    }
  }

  static String detailLocation(
    String pulseId, {
    String? source,
    bool mcq = false,
  }) {
    final id = pulseId.trim();
    final src = normalizeEntrySource(source);
    final path = '/$publicPathSegment/$id${mcq ? '/mcq' : ''}';
    if (src == entryInApp) return path;
    return '$path?src=$src';
  }
}
