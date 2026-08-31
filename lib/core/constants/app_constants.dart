/// App-wide URLs, support contact, and product name.
///
/// The in-app version label and kill-switch comparison use pubspec `version`
/// (via `package_info_plus`). Remote Config `kill_switch_version` uses the same
/// format (e.g. `2.1` or `v2.1`); clients older than that minimum are prompted
/// to update.
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

  /// Legacy placeholder image. Treated as “no photo” so initials are shown.
  static const String defaultProfilePhotoUrl =
      'https://firebasestorage.googleapis.com/v0/b/questionmaker-a821f.appspot.com/o/default_dp.jpg?alt=media&token=6857cccc-5149-4949-a1de-4255dc06dd53';

  /// Custom uploaded photo, or empty when missing / placeholder / `no_image`.
  static String customProfilePhotoUrl(String? photoUrl) {
    final t = photoUrl?.trim() ?? '';
    if (t.isEmpty || t == 'no_image') return '';
    if (t == defaultProfilePhotoUrl) return '';
    if (t.contains('/o/default_dp.jpg')) return '';
    return t;
  }

  /// Same as [customProfilePhotoUrl]. Empty means show initials, not a default DP.
  static String profileImageUrlOrDefault(String? photoUrl) =>
      customProfilePhotoUrl(photoUrl);

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
