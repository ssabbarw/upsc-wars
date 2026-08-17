/// Closed vocabularies for daily current-affairs questions.
///
/// Layer 1 — [gsSubjects]: one GS paper bucket (Polity CA, Environment CA, …).
/// Layer 2 — [caTags]: 1–3 revision chips for last-2-months drills
/// (schemes, maps, reports, …).
abstract final class CaRevisionTags {
  CaRevisionTags._();

  static const gsSubjects = <String>[
    'Polity',
    'Economy',
    'Environment',
    'Geography',
    'Science & Technology',
    'International Relations',
    'Art and Culture',
    'Social Issues',
    'Internal Security',
    'Ancient History',
    'Medieval History',
    'Modern History',
  ];

  static const caTags = <String>[
    'Government schemes',
    'Laws, bills & judgments',
    'Institutions & bodies',
    'Reports & indices',
    'Indian map',
    'World map',
    'Species & protected areas',
    'Climate & conventions',
    'International groupings',
    'Budget, tax & fiscal',
    'Banking & RBI',
    'Agriculture & food',
    'Energy & infrastructure',
    'Science, space & nuclear',
    'Defence & security',
    'Health & social welfare',
    'Culture, GI & heritage',
  ];

  static const Set<String> gsSubjectSet = {...gsSubjects};
  static const Set<String> caTagSet = {...caTags};

  static const minTags = 1;
  static const maxTags = 3;

  static String? primaryTag(List<String> tags) {
    for (final tag in tags) {
      final t = tag.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  /// Keeps only known tags, max [maxTags], order preserved.
  static List<String> sanitizeTags(Iterable<dynamic>? raw) {
    if (raw == null) return const [];
    final out = <String>[];
    final seen = <String>{};
    for (final item in raw) {
      final tag = item?.toString().trim() ?? '';
      if (tag.isEmpty || seen.contains(tag)) continue;
      if (!caTagSet.contains(tag)) continue;
      seen.add(tag);
      out.add(tag);
      if (out.length >= maxTags) break;
    }
    return out;
  }
}
