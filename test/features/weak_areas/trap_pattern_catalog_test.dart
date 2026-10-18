import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/domain/entities/trap_pattern_group.dart';
import 'package:upsc_wars/core/providers/trap_descriptions_provider.dart';
import 'package:upsc_wars/features/weak_areas/domain/trap_pattern_catalog.dart';

TrapDescription _desc(String type, String name, String blurb) {
  return TrapDescription(
    trapType: type,
    displayName: name,
    blurb: blurb,
    description: '$blurb longer',
  );
}

void main() {
  test('TrapDescription.fromJson prefers blurb over the long description', () {
    final d = TrapDescription.fromJson({
      'trap_type': 'entity-swap',
      'display_name': 'Entity Swap',
      'blurb': 'Right fact, wrong person.',
      'description': 'A much longer paragraph.',
    });
    expect(d.blurb, 'Right fact, wrong person.');
    expect(d.description, 'A much longer paragraph.');
  });

  test('lists every catalog trap at 0× when the user has no data', () {
    final items = TrapPatternCatalog.merge(
      descriptions: {
        'entity-swap': _desc('entity-swap', 'Entity Swap', 'Wrong person.'),
        'temporal-swap': _desc('temporal-swap', 'Temporal Swap', 'Wrong year.'),
      },
      groups: const [],
    );

    expect(items, hasLength(2));
    expect(items.map((i) => i.trapType), ['entity-swap', 'temporal-swap']);
    expect(items.every((i) => i.caughtCount == 0), isTrue);
    expect(items.first.blurb, 'Wrong person.');
  });

  test('puts traps that caught the user first, then the rest at 0×', () {
    final items = TrapPatternCatalog.merge(
      descriptions: {
        'entity-swap': _desc('entity-swap', 'Entity Swap', 'a'),
        'scope-extension': _desc('scope-extension', 'Scope Extension', 'b'),
        'temporal-swap': _desc('temporal-swap', 'Temporal Swap', 'c'),
      },
      groups: const [
        TrapPatternGroup(
          trapType: 'temporal-swap',
          questionCount: 3,
          questionUuids: ['q1', 'q2', 'q3'],
        ),
        TrapPatternGroup(
          trapType: 'entity-swap',
          questionCount: 1,
          questionUuids: ['q4'],
        ),
      ],
    );

    expect(items.map((i) => i.trapType).toList(), [
      'temporal-swap',
      'entity-swap',
      'scope-extension',
    ]);
    expect(items[0].caughtCount, 3);
    expect(items[1].caughtCount, 1);
    expect(items[2].caughtCount, 0);
  });

  test(
    'keeps unknown trap types from user data at the end of caught group',
    () {
      final items = TrapPatternCatalog.merge(
        descriptions: {'entity-swap': _desc('entity-swap', 'Entity Swap', 'a')},
        groups: const [
          TrapPatternGroup(
            trapType: 'mystery-trap',
            questionCount: 2,
            questionUuids: ['q1', 'q2'],
          ),
        ],
      );

      expect(items.map((i) => i.trapType).toList(), [
        'mystery-trap',
        'entity-swap',
      ]);
      expect(items[0].displayName, 'Mystery Trap');
      expect(items[1].caughtCount, 0);
    },
  );
}
