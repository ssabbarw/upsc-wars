/// One content trap's Sure or Educated-guess record inside a subject.
///
/// [trapType] is `questions.trap_type` (entity-swap, partial-truth, …),
/// not the MCQ stem shape (`question_type`).
class SubjectTrapStat {
  const SubjectTrapStat({
    required this.trapType,
    required this.wrong,
    required this.attempted,
  });

  final String trapType;
  final int wrong;
  final int attempted;

  int get wrongPercent =>
      attempted == 0 ? 0 : ((100 * wrong) / attempted).round();

  String get title => titleCaseTrapSlug(trapType);
}

String normalizeTrapType(String raw) =>
    raw.trim().toLowerCase().replaceAll('_', '-');

String titleCaseTrapSlug(String slug) {
  final key = normalizeTrapType(slug);
  if (key.isEmpty) return key;
  return key
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Traps with at least one wrong, weakest first (wrong-rate, then volume).
List<SubjectTrapStat> rankContentTraps(
  Iterable<({String type, int wrong, int attempted})> rows,
) {
  final merged = <String, SubjectTrapStat>{};
  for (final row in rows) {
    if (row.attempted <= 0) continue;
    final key = normalizeTrapType(row.type);
    if (key.isEmpty) continue;
    final prev = merged[key];
    merged[key] = SubjectTrapStat(
      trapType: key,
      wrong: (prev?.wrong ?? 0) + row.wrong,
      attempted: (prev?.attempted ?? 0) + row.attempted,
    );
  }

  return merged.values.where((s) => s.wrong > 0).toList()..sort((a, b) {
    final rate = b._wrongRate.compareTo(a._wrongRate);
    if (rate != 0) return rate;
    final wrongs = b.wrong.compareTo(a.wrong);
    if (wrongs != 0) return wrongs;
    return b.attempted.compareTo(a.attempted);
  });
}

extension on SubjectTrapStat {
  double get _wrongRate => attempted == 0 ? 0 : wrong / attempted;
}
