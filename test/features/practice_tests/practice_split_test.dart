import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/practice_tests/domain/practice_season.dart';
import 'package:upsc_wars/features/practice_tests/domain/practice_test_splitter.dart';
import 'package:upsc_wars/features/stats/domain/focus_recommendations.dart';

void main() {
  test('split is deterministic and covers every question once', () {
    final uuids = [for (var i = 0; i < 60; i++) 'q$i'];
    final a = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: uuids,
    );
    final b = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: uuids,
    );
    expect(a, b);
    expect(a.length, 3);
    expect(a[0], hasLength(25));
    expect(a[1], hasLength(25));
    expect(a[2], hasLength(10));
    expect(a.expand((t) => t).toSet(), uuids.toSet());
  });

  test('changing the season changes the order', () {
    final uuids = [for (var i = 0; i < 30; i++) 'q$i'];
    final a = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: uuids,
    );
    final b = splitIntoTests(
      season: 2028,
      scope: 'subject:Polity',
      uuids: uuids,
    );
    expect(a, isNot(b));
  });

  test('maxTests keeps only the first groups', () {
    final uuids = [for (var i = 0; i < 80; i++) 'q$i'];
    final capped = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: uuids,
      maxTests: 2,
    );
    final full = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: uuids,
    );
    expect(capped, hasLength(2));
    expect(capped, full.take(2).toList());
  });

  test('removing one question keeps the relative order of the rest', () {
    final uuids = [for (var i = 0; i < 40; i++) 'q$i'];
    final full = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: uuids,
    ).expand((t) => t).toList();
    final without = splitIntoTests(
      season: 2027,
      scope: 'subject:Polity',
      uuids: [...uuids]..remove('q3'),
    ).expand((t) => t).toList();
    expect(without, full.where((id) => id != 'q3').toList());
  });

  test(
    'seasonFor uses the prelims year until the exam, then the next year',
    () {
      final exam = DateTime(2027, 5, 23, 9, 30);
      expect(seasonFor(exam, DateTime(2027, 5, 23, 9, 30)), 2027);
      expect(seasonFor(exam, DateTime(2027, 1, 1)), 2027);
      expect(seasonFor(exam, DateTime(2027, 5, 23, 9, 31)), 2028);
      expect(
        seasonStart(exam, DateTime(2027, 1, 1)),
        DateTime(2026, 5, 23, 9, 30),
      );
      expect(seasonStart(exam, DateTime(2027, 6, 1)), exam);
    },
  );

  test('focus ranks weak, then shaky, then untouched, largest pool first', () {
    final items = [
      const FocusCandidate(
        subject: 'Polity',
        topic: 'small weak',
        displayName: 'small weak',
        poolSize: 10,
        answered: 5,
        correct: 1,
      ),
      const FocusCandidate(
        subject: 'Polity',
        topic: 'big weak',
        displayName: 'big weak',
        poolSize: 40,
        answered: 8,
        correct: 2,
      ),
      const FocusCandidate(
        subject: 'Economy',
        topic: 'shaky',
        displayName: 'shaky',
        poolSize: 30,
        answered: 10,
        correct: 7,
      ),
      const FocusCandidate(
        subject: 'Economy',
        topic: 'fresh',
        displayName: 'fresh',
        poolSize: 50,
        answered: 0,
        correct: 0,
      ),
      const FocusCandidate(
        subject: 'Polity',
        topic: 'fine',
        displayName: 'fine',
        poolSize: 20,
        answered: 10,
        correct: 9,
      ),
    ];
    final ranked = focusRecommendations(items, limit: 4);
    expect(ranked.map((r) => r.topic).toList(), [
      'big weak',
      'small weak',
      'shaky',
      'fresh',
    ]);
    expect(
      focusRecommendations(items, subject: 'Economy').map((r) => r.topic),
      ['shaky', 'fresh'],
    );
  });
}
