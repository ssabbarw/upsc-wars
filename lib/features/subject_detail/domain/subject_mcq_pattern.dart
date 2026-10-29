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
SubjectMcqPatternStat? pickWeakestMcqPattern(
  Iterable<({String type, int wrong, int attempted})> rows, {
  int minAttempts = kMcqPatternMinAttempts,
}) {
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

  final withWrongs = merged.values.where((s) => s.wrong > 0).toList();
  if (withWrongs.isEmpty) return null;

  final qualified = withWrongs
      .where((s) => s.attempted >= minAttempts)
      .toList();
  final pool = qualified.isEmpty ? withWrongs : qualified;
  pool.sort(_byWeakness);
  return pool.first;
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
