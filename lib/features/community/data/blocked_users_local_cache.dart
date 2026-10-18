import 'package:shared_preferences/shared_preferences.dart';

/// On-device copy of `block_lists/{uid}` emails (keyed by owner email).
class BlockedUsersLocalCache {
  BlockedUsersLocalCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'blocked_emails_v1_';

  String _key(String ownerEmail) =>
      '$_prefix${ownerEmail.toLowerCase().trim()}';

  /// `null` if this device has never stored a list for [ownerEmail].
  Set<String>? read(String ownerEmail) {
    final raw = _prefs.getStringList(_key(ownerEmail));
    if (raw == null) return null;
    return raw
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  Future<void> write(String ownerEmail, Set<String> emails) {
    final list =
        emails
            .map((e) => e.toLowerCase().trim())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    return _prefs.setStringList(_key(ownerEmail), list);
  }
}
