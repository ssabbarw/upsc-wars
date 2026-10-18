import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_scoring.dart';

void main() {
  group('DailyCaScoring', () {
    test('+2 correct, −2/3 wrong, 0 unanswered', () {
      const keys = {'q1': 'a', 'q2': 'b', 'q3': 'c'};
      final breakdown = DailyCaScoring.score(
        selectedByUuid: const {'q1': 'a', 'q2': 'd'},
        correctByUuid: keys,
      );
      expect(breakdown.correct, 1);
      expect(breakdown.wrong, 1);
      expect(breakdown.unanswered, 1);
      expect(breakdown.points, 1.33);
    });

    test('max points is 2 per question', () {
      expect(DailyCaScoring.maxPoints(8), 16);
    });
  });
}
