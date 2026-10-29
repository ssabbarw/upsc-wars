import '../../../core/domain/entities/trap_pattern_group.dart';
import '../../../core/providers/trap_descriptions_provider.dart';

/// One row on the Trap Patterns list: catalog copy plus how often it caught
/// this user (0 when they have no revision data yet).
class TrapPatternListItem {
  const TrapPatternListItem({
    required this.trapType,
    required this.displayName,
    required this.blurb,
    required this.description,
    required this.caughtCount,
  });

  final String trapType;
  final String displayName;
  final String blurb;
  final String description;
  final int caughtCount;
}

/// Merges the static trap catalog with the user's caught-question counts.
abstract final class TrapPatternCatalog {
  static const negativeFraming = 'negative-framing';

  static List<TrapPatternListItem> merge({
    required Map<String, TrapDescription> descriptions,
    required List<TrapPatternGroup> groups,
    String language = 'en',
  }) {
    final counts = <String, int>{
      for (final g in groups) g.trapType: g.questionCount,
    };
    final items = <TrapPatternListItem>[];
    final seen = <String>{};

    for (final entry in descriptions.entries) {
      seen.add(entry.key);
      items.add(
        TrapPatternListItem(
          trapType: entry.key,
          displayName: entry.value.displayName,
          blurb: entry.value.blurbFor(language),
          description: entry.value.descriptionFor(language),
          caughtCount: counts[entry.key] ?? 0,
        ),
      );
    }

    for (final group in groups) {
      if (seen.contains(group.trapType)) continue;
      items.add(
        TrapPatternListItem(
          trapType: group.trapType,
          displayName: _titleCaseSlug(group.trapType),
          blurb: '',
          description: '',
          caughtCount: group.questionCount,
        ),
      );
    }

    final caught = items.where((i) => i.caughtCount > 0).toList()
      ..sort((a, b) => b.caughtCount.compareTo(a.caughtCount));
    final rest = items.where((i) => i.caughtCount == 0).toList();
    return [...caught, ...rest];
  }

  static String _titleCaseSlug(String slug) {
    return slug
        .split('-')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
