/// App-wide URLs, support contact, and release version.
///
/// Bump [releaseVersionLabel] when you ship a new store build. Remote Config
/// `kill_switch_version` uses the same format (e.g. `2.1` or `v2.1`); clients
/// older than that minimum are prompted to update.
abstract final class AppConstants {
  AppConstants._();

  /// Human-readable product name (launcher, window title, in-app copy).
  static const String appDisplayName = 'Upsc Wars';

  // ── Store listings ─────────────────────────────────────────────────────────
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=practice.upsc.indiaapps.com.upscmcqpractice';

  static const String appStoreUrl =
      'https://apps.apple.com/in/app/upsc-wars/id1550273627';

  // ── Telegram ─────────────────────────────────────────────────────────────
  static const String developerTelegramUrl = 'https://t.me/upsc_wars_sachin';
  static const String groupTelegramUrl = 'https://t.me/upsc_wars_group';

  /// Shown when a user has no profile photo (local UI + community fallback).
  static const String defaultProfilePhotoUrl =
      'https://firebasestorage.googleapis.com/v0/b/questionmaker-a821f.appspot.com/o/default_dp.jpg?alt=media&token=6857cccc-5149-4949-a1de-4255dc06dd53';

  /// Returns [photoUrl] when non-empty; otherwise [defaultProfilePhotoUrl].
  static String profileImageUrlOrDefault(String? photoUrl) {
    final t = photoUrl?.trim();
    if (t != null && t.isNotEmpty) {
      return t;
    }
    return defaultProfilePhotoUrl;
  }

  // ── Email ─────────────────────────────────────────────────────────────────
  static const String supportEmail = 'upscwars@gmail.com';

  static Uri supportMailtoUri() => Uri(
    scheme: 'mailto',
    path: supportEmail,
    queryParameters: {
      'subject': '$appDisplayName — feedback',
      'body': 'Hi,\n\n',
    },
  );

  // ── Release (bump when publishing) ───────────────────────────────────────
  /// Shown on Profile and compared to Remote Config `kill_switch_version`.
  ///
  /// Kill switch rule (see `kill_switch_provider.dart`):
  /// - If `appVersion` < Remote Config `kill_switch_version` ⇒ update screen blocks the app.
  ///
  /// What value to set to block a version:
  /// - To block **this** build, set `kill_switch_version` to a **higher** version than this
  ///   label. Example: if this is `v2.4`, set `kill_switch_version` to `2.5` (or `v2.5`).
  /// - To block **all 2.4.x** builds, set `kill_switch_version` to `2.5`.
  static const String releaseVersionLabel = 'v2.5';
}

/// Comparable version from `v2.1`, `2.1`, or `2.1.0`.
final class ReleaseVersion implements Comparable<ReleaseVersion> {
  const ReleaseVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static ReleaseVersion? parse(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    final parts = s.split('.');
    final major = int.tryParse(parts.first);
    if (major == null) return null;
    final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
    return ReleaseVersion(major, minor, patch);
  }

  static ReleaseVersion? get appCurrent =>
      ReleaseVersion.parse(AppConstants.releaseVersionLabel);

  @override
  int compareTo(ReleaseVersion other) {
    final c = major.compareTo(other.major);
    if (c != 0) return c;
    final c2 = minor.compareTo(other.minor);
    if (c2 != 0) return c2;
    return patch.compareTo(other.patch);
  }

  @override
  String toString() => '$major.$minor.$patch';
}
