import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/practice_tests/domain/subject_trap_stat.dart';

void main() {
  test('ranks by wrong rate and ignores empty trap types', () {
    final ranked = rankContentTraps(const [
      (type: 'entity-swap', wrong: 2, attempted: 10),
      (type: 'partial_truth', wrong: 4, attempted: 5),
      (type: '', wrong: 9, attempted: 9),
      (type: 'entity-swap', wrong: 1, attempted: 2),
    ]);

    expect(ranked.map((t) => t.trapType), ['partial-truth', 'entity-swap']);
    expect(ranked.first.wrong, 4);
    expect(ranked.last.wrong, 3);
    expect(ranked.last.attempted, 12);
  });

  test('title-cases catalog slugs', () {
    expect(titleCaseTrapSlug('entity-swap'), 'Entity Swap');
    expect(normalizeTrapType('Partial_Truth'), 'partial-truth');
  });
}
