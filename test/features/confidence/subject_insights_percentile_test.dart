import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/subject_detail/domain/subject_insights.dart';

void main() {
  group('topicRowsWithPercentileTiers', () {
    test('empty input yields empty list', () {
      expect(topicRowsWithPercentileTiers([]), isEmpty);
    });

    test('single topic is always high tier (top band)', () {
      final rows = topicRowsWithPercentileTiers([
        (topic: 'A', dangerCount: 3),
      ]);
      expect(rows, hasLength(1));
      expect(rows.single.topic, 'A');
      expect(rows.single.dangerCount, 3);
      expect(rows.single.tier, RiskTier.high);
    });

    test('ten topics: first 20% red, next 30% yellow, rest green', () {
      final raw = List.generate(
        10,
        (i) => (topic: 'T${i + 1}', dangerCount: 10 - i),
      );
      final rows = topicRowsWithPercentileTiers(raw);
      expect(rows, hasLength(10));
      final redN = (10 * 0.2).ceil();
      final yellowN = (10 * 0.3).ceil();
      expect(redN, 2);
      expect(yellowN, 3);
      for (var i = 0; i < 10; i++) {
        final expected =
            i < redN
                ? RiskTier.high
                : i < redN + yellowN
                    ? RiskTier.medium
                    : RiskTier.low;
        expect(rows[i].tier, expected, reason: 'index $i');
      }
    });

    test('preserves descending danger order from input', () {
      final rows = topicRowsWithPercentileTiers([
        (topic: 'high', dangerCount: 9),
        (topic: 'mid', dangerCount: 5),
        (topic: 'low', dangerCount: 1),
      ]);
      expect(rows.map((e) => e.topic).toList(), ['high', 'mid', 'low']);
    });
  });
}
