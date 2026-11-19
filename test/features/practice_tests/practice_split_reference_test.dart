import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/practice_tests/domain/practice_test_splitter.dart';

/// The split as first shipped. Test ids and saved progress depend on this
/// exact order, so [splitIntoTests] must keep matching it.
List<List<String>> referenceSplit({
  required int season,
  required String scope,
  required List<String> uuids,
  int size = practiceTestSize,
  int? maxTests,
}) {
  if (uuids.isEmpty || size <= 0) return const [];

  int keyOf(String id) {
    final digest = sha1.convert(utf8.encode('$season|$scope|$id')).bytes;
    return (digest[0] << 24) | (digest[1] << 16) | (digest[2] << 8) | digest[3];
  }

  final sorted = [...uuids]..sort((a, b) {
    final byKey = keyOf(a).compareTo(keyOf(b));
    return byKey != 0 ? byKey : a.compareTo(b);
  });

  final tests = <List<String>>[];
  for (var i = 0; i < sorted.length; i += size) {
    final end = i + size < sorted.length ? i + size : sorted.length;
    tests.add(List<String>.unmodifiable(sorted.sublist(i, end)));
    if (maxTests != null && tests.length >= maxTests) break;
  }
  return tests;
}

/// Uuid-shaped ids that are the same on every run.
List<String> fakeUuids(int count, {int seed = 0}) {
  return [
    for (var i = 0; i < count; i++)
      () {
        final hex = sha1.convert(utf8.encode('fake-$seed-$i')).toString();
        return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
            '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
            '${hex.substring(20, 32)}';
      }(),
  ];
}

void main() {
  const cases = [
    (season: 2027, scope: 'subject:Polity', count: 4393, maxTests: 25),
    (season: 2027, scope: 'subject:Economy', count: 3000, maxTests: null),
    (
      season: 2028,
      scope: 'topic:Geography:Climatology',
      count: 600,
      maxTests: 10,
    ),
    (season: 2027, scope: 'topic:Polity:Parliament', count: 7, maxTests: 10),
  ];

  for (final c in cases) {
    test('matches the shipped split for ${c.season} ${c.scope}', () {
      final uuids = fakeUuids(c.count, seed: c.count);
      expect(
        splitIntoTests(
          season: c.season,
          scope: c.scope,
          uuids: uuids,
          maxTests: c.maxTests,
        ),
        referenceSplit(
          season: c.season,
          scope: c.scope,
          uuids: uuids,
          maxTests: c.maxTests,
        ),
      );
    });
  }

  test('matches the shipped split when an id repeats', () {
    final uuids = fakeUuids(200);
    final withDuplicate = [...uuids, uuids[17], uuids[150]];
    expect(
      splitIntoTests(
        season: 2027,
        scope: 'subject:Polity',
        uuids: withDuplicate,
      ),
      referenceSplit(
        season: 2027,
        scope: 'subject:Polity',
        uuids: withDuplicate,
      ),
    );
  });

  test('input order does not change the split', () {
    final uuids = fakeUuids(500, seed: 9);
    final reversed = uuids.reversed.toList();
    final a = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: uuids,
    );
    final b = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: reversed,
    );
    expect(a, b);
    expect(
      b,
      referenceSplit(season: 2027, scope: 'subject:Polity', uuids: reversed),
    );
  });
}
