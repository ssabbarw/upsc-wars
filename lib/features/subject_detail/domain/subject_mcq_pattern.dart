import '../../../l10n/l10n.dart';

/// UPSC stem shape stored on `questions.question_type`.
///
/// This is the exam's MCQ pattern (how the options are framed), separate from
/// `trap_type` (entity swap, partial truth, and the other content traps).
enum UpscMcqPattern {
  howMany,
  statementCombination,
  assertionReason,
  matchFollowing,
  direct,
  singleStatement,
  other,
}

/// One pattern's Sure + Educated-guess record inside a subject.
class SubjectMcqPatternStat {
  const SubjectMcqPatternStat({
    required this.pattern,
    required this.otherSlug,
    required this.wrong,
    required this.attempted,
  });

  final UpscMcqPattern pattern;

  /// Set only for [UpscMcqPattern.other], already normalized.
  final String? otherSlug;
  final int wrong;
  final int attempted;

  int get wrongPercent =>
      attempted == 0 ? 0 : ((100 * wrong) / attempted).round();

  String labelFor(AppLocalizations l10n) {
    switch (pattern) {
      case UpscMcqPattern.howMany:
        return l10n.mcqHowMany;
      case UpscMcqPattern.statementCombination:
        return l10n.mcqStatementCombo;
      case UpscMcqPattern.assertionReason:
        return l10n.mcqAssertion;
      case UpscMcqPattern.matchFollowing:
        return l10n.mcqMatch;
      case UpscMcqPattern.direct:
        return l10n.mcqDirect;
      case UpscMcqPattern.singleStatement:
        return l10n.mcqSingle;
      case UpscMcqPattern.other:
        return _titleCaseSlug(otherSlug ?? '');
    }
  }

  String explainFor(AppLocalizations l10n) {
    switch (pattern) {
      case UpscMcqPattern.howMany:
        return l10n.mcqHowManyBody;
      case UpscMcqPattern.statementCombination:
        return l10n.mcqStatementComboBody;
      case UpscMcqPattern.assertionReason:
        return l10n.mcqAssertionBody;
      case UpscMcqPattern.matchFollowing:
        return l10n.mcqMatchBody;
      case UpscMcqPattern.direct:
        return l10n.mcqDirectBody;
      case UpscMcqPattern.singleStatement:
        return l10n.mcqSingleBody;
      case UpscMcqPattern.other:
        return explainOtherMcqSlug(otherSlug, l10n);
    }
  }

  /// Stable slug for the trap detail route (`/weak-areas/trap/:trapType`).
  String get infoKey {
    switch (pattern) {
      case UpscMcqPattern.howMany:
        return 'how-many';
      case UpscMcqPattern.statementCombination:
        return 'statement-combination';
      case UpscMcqPattern.assertionReason:
        return 'assertion-reason';
      case UpscMcqPattern.matchFollowing:
        return 'match-the-following';
      case UpscMcqPattern.direct:
        return 'direct';
      case UpscMcqPattern.singleStatement:
        return 'single-statement';
      case UpscMcqPattern.other:
        return otherSlug ?? 'other';
    }
  }
}

/// Reconstruct a zero-stat pattern from [SubjectMcqPatternStat.infoKey].
SubjectMcqPatternStat mcqPatternStatFromInfoKey(String key) {
  final pattern = classifyUpscMcqPattern(key);
  return SubjectMcqPatternStat(
    pattern: pattern,
    otherSlug: pattern == UpscMcqPattern.other ? _normalizeType(key) : null,
    wrong: 0,
    attempted: 0,
  );
}

/// Fewest attempts before a pattern can win on wrong-rate.
///
/// Below this, a single miss would look like a 100% weakness.
const int kMcqPatternMinAttempts = 3;

/// Pattern the user gets wrong most often among Sure and Educated-guess
/// answers in one subject.
///
/// Rows that share a canonical pattern are added together first (the bank
/// stores both `multi_statement_count` and `how-many` style slugs).
///
/// Winner is the highest wrong-rate among patterns with at least
/// [minAttempts] attempts. Ties go to more wrongs, then more attempts.
/// If every pattern is under the minimum, the one with the most wrongs wins,
/// so a thin history still surfaces something. Returns null when nothing
/// was answered wrong.
/// Patterns with at least one wrong, weakest first.
List<SubjectMcqPatternStat> rankMcqPatterns(
  Iterable<({String type, int wrong, int attempted})> rows,
) {
  final merged = <String, SubjectMcqPatternStat>{};
  for (final row in rows) {
    if (row.attempted <= 0) continue;
    final pattern = classifyUpscMcqPattern(row.type);
    final slug = pattern == UpscMcqPattern.other
        ? _normalizeType(row.type)
        : null;
    final key = pattern == UpscMcqPattern.other ? 'other:$slug' : pattern.name;
    final prev = merged[key];
    merged[key] = SubjectMcqPatternStat(
      pattern: pattern,
      otherSlug: slug,
      wrong: (prev?.wrong ?? 0) + row.wrong,
      attempted: (prev?.attempted ?? 0) + row.attempted,
    );
  }

  return merged.values.where((s) => s.wrong > 0).toList()..sort(_byWeakness);
}

SubjectMcqPatternStat? pickWeakestMcqPattern(
  Iterable<({String type, int wrong, int attempted})> rows, {
  int minAttempts = kMcqPatternMinAttempts,
}) {
  final ranked = rankMcqPatterns(rows);
  if (ranked.isEmpty) return null;
  final qualified = ranked.where((s) => s.attempted >= minAttempts).toList();
  return (qualified.isEmpty ? ranked : qualified).first;
}

int _byWeakness(SubjectMcqPatternStat a, SubjectMcqPatternStat b) {
  final rate = b._wrongRate.compareTo(a._wrongRate);
  if (rate != 0) return rate;
  final wrongs = b.wrong.compareTo(a.wrong);
  if (wrongs != 0) return wrongs;
  return b.attempted.compareTo(a.attempted);
}

extension on SubjectMcqPatternStat {
  double get _wrongRate => attempted == 0 ? 0 : wrong / attempted;
}

/// True when bank [type] is the same stem shape as [stat].
bool matchesMcqPattern(String type, SubjectMcqPatternStat stat) {
  final classified = classifyUpscMcqPattern(type);
  if (classified != stat.pattern) return false;
  if (classified != UpscMcqPattern.other) return true;
  return _normalizeType(type) == stat.otherSlug;
}

UpscMcqPattern classifyUpscMcqPattern(String raw) {
  switch (_normalizeType(raw)) {
    case 'multi-statement-count':
    case 'how-many':
    case 'how-many-of-the-above':
      return UpscMcqPattern.howMany;
    case 'multi-statement-combination':
    case 'multi-statement-correct':
    case 'multi-statement':
    case 'statement-based':
    case 'statement-combination':
      return UpscMcqPattern.statementCombination;
    case 'assertion-reason':
      return UpscMcqPattern.assertionReason;
    case 'match-the-column':
    case 'match-the-following':
      return UpscMcqPattern.matchFollowing;
    case 'fact-based-direct':
    case 'direct':
    case 'factual':
      return UpscMcqPattern.direct;
    case 'single-statement-correctness':
    case 'single-statement':
      return UpscMcqPattern.singleStatement;
    default:
      return UpscMcqPattern.other;
  }
}

String _normalizeType(String raw) =>
    raw.trim().toLowerCase().replaceAll('_', '-');

String _titleCaseSlug(String slug) {
  if (slug.isEmpty) return slug;
  return slug
      .split('-')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Pattern-specific copy for uncommon stem slugs (Identify the pair, …).
String explainOtherMcqSlug(String? slug, AppLocalizations l10n) {
  final key = slug ?? '';
  if (key.contains('identify-the-pair') || key.contains('pair')) {
    return l10n.mcqIdentifyPairBody;
  }
  if (key.contains('odd-one')) {
    return l10n.mcqOddOneBody;
  }
  if (key.contains('fill-in') || key.contains('blank')) {
    return l10n.mcqFillBlankBody;
  }
  if (key.contains('chronolog') || key.contains('timeline')) {
    return l10n.mcqChronologyBody;
  }
  if (key.contains('quantitative') || key.contains('pairing')) {
    return l10n.mcqQuantitativeBody;
  }
  if (key.contains('incorrect')) {
    return l10n.mcqIncorrectBody;
  }
  if (key.contains('application') || key.contains('scenario')) {
    return l10n.mcqApplicationBody;
  }
  if (key.contains('relationship') || key.contains('two-statement')) {
    return l10n.mcqTwoStatementBody;
  }
  if (key.contains('map')) {
    return l10n.mcqMapBody;
  }
  if (key.contains('negative')) {
    return l10n.mcqNegativeBody;
  }
  if (key.contains('conceptual')) {
    return l10n.mcqConceptualBody;
  }
  return l10n.mcqOtherBody;
}
