/// Super-user-only membership list written by Cloud Functions to
/// `admin_dashboard/traffic_bots`. Regular clients never receive this doc.
class TrafficBotIndex {
  const TrafficBotIndex({
    this.emails = const {},
    this.uids = const {},
  });

  final Set<String> emails;
  final Set<String> uids;

  static const empty = TrafficBotIndex();

  factory TrafficBotIndex.fromMap(Map<String, dynamic>? map) {
    if (map == null) return empty;
    return TrafficBotIndex(
      emails: _stringSet(map['emails'], lower: true),
      uids: _stringSet(map['uids'], lower: false),
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
