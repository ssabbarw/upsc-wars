/// Super-user-only membership list written by Cloud Functions to
/// `admin_dashboard/traffic_bots`. Regular clients never receive this doc.
class TrafficBotIndex {
  const TrafficBotIndex({
    this.emails = const {},
    this.uids = const {},
    this.warPeopleLast24h = 0,
    this.battleCompletedPeopleLast24h = 0,
  });

  final Set<String> emails;
  final Set<String> uids;

  /// Unique real users who started a 1v1 war with a traffic bot in the last 24h.
  /// Written by Cloud Functions; 0 when the field is missing.
  final int warPeopleLast24h;

  /// Unique real users who submitted a bot 1v1 paper in the last 24h.
  final int battleCompletedPeopleLast24h;

  static const empty = TrafficBotIndex();

  factory TrafficBotIndex.fromMap(Map<String, dynamic>? map) {
    if (map == null) return empty;
    return TrafficBotIndex(
      emails: _stringSet(map['emails'], lower: true),
      uids: _stringSet(map['uids'], lower: false),
      warPeopleLast24h: _asInt(map['warPeopleLast24h']),
      battleCompletedPeopleLast24h: _asInt(map['battleCompletedPeopleLast24h']),
    );
  }

  bool matches({String? email, String? uid}) {
    final e = email?.trim().toLowerCase() ?? '';
    if (e.isNotEmpty && emails.contains(e)) return true;
    final id = uid?.trim() ?? '';
    return id.isNotEmpty && uids.contains(id);
  }
}

Set<String> _stringSet(Object? raw, {required bool lower}) {
  if (raw is! Iterable) return const {};
  return {
    for (final item in raw)
      if (item != null && '$item'.trim().isNotEmpty)
        lower ? '$item'.trim().toLowerCase() : '$item'.trim(),
  };
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}
