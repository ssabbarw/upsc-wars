import 'memory_pair_models.dart';

/// Preferred subject order for the catalog list.
const kMemoryPairSubjectOrder = [
  'Polity',
  'Ancient History',
  'Modern History',
  'Geography',
  'Environment',
  'Science',
  'Economy',
  'Current Affairs',
  'Art & Culture',
];

class MemoryPairSubjectGroup {
  const MemoryPairSubjectGroup({
    required this.subjectKey,
    required this.subjectLabel,
    required this.sortedItems,
  });

  final String subjectKey;
  final String subjectLabel;
  final List<MemoryPairSetListItem> sortedItems;

  int get totalSets => sortedItems.length;

  int get unlockedCount => sortedItems.where((i) => i.isUnlocked).length;

  int countForDifficulty(MemoryPairDifficulty difficulty) =>
      sortedItems.where((i) => i.definition.difficulty == difficulty).length;

  List<MemoryPairSetListItem> itemsForDifficulty(MemoryPairDifficulty difficulty) =>
      sortedItems.where((i) => i.definition.difficulty == difficulty).toList();
}

int _difficultySortKey(MemoryPairDifficulty d) => switch (d) {
      MemoryPairDifficulty.easy => 0,
      MemoryPairDifficulty.medium => 1,
      MemoryPairDifficulty.hard => 2,
    };

List<MemoryPairSubjectGroup> groupMemoryPairSetsBySubject(
  List<MemoryPairSetListItem> items, {
  required String lang,
}) {
  final buckets = <String, List<MemoryPairSetListItem>>{};
  final labels = <String, String>{};

  for (final item in items) {
    final key = item.definition.displaySubjectEn;
    buckets.putIfAbsent(key, () => []).add(item);
    labels[key] = item.definition.subjectLabelForLang(lang);
  }

  final orderedKeys = [
    ...kMemoryPairSubjectOrder.where(buckets.containsKey),
    ...() {
      final rest = buckets.keys
          .where((k) => !kMemoryPairSubjectOrder.contains(k))
          .toList()
        ..sort();
      return rest;
    }(),
  ];

  return [
    for (final key in orderedKeys)
      MemoryPairSubjectGroup(
        subjectKey: key,
        subjectLabel: labels[key] ?? key,
        sortedItems: () {
          final list = List<MemoryPairSetListItem>.from(buckets[key] ?? []);
          list.sort((a, b) {
            final byDiff = _difficultySortKey(a.definition.difficulty)
                .compareTo(_difficultySortKey(b.definition.difficulty));
            if (byDiff != 0) return byDiff;
            return a.definition.nameEn.compareTo(b.definition.nameEn);
          });
          return list;
        }(),
      ),
  ];
}
