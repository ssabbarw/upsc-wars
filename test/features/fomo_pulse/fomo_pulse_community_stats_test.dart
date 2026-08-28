import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/fomo_pulse/domain/fomo_pulse_models.dart';
import 'package:upsc_wars/features/fomo_pulse/fomo_pulse_constants.dart';

FomoPulse _pulse({int attempts = 0, int correct = 0}) {
  return FomoPulse(
    pulseId: 'p1',
    title: 'Title',
    body: 'Body',
    newsSummary: 'Summary',
    sourceUrl: 'https://example.com',
    question: FomoPulseQuestion.fromMap(null),
    sentAt: DateTime.utc(2026, 8, 22),
    expiresAt: DateTime.utc(2026, 8, 24),
    attemptCount: attempts,
    correctCount: correct,
  );
}

void main() {
  group('FomoPulseCommunityStats', () {
    test('breakdown lists attempted, right, and wrong', () {
      const stats = FomoPulseCommunityStats(
        attemptCount: 12,
        correctCount: 5,
      );
      expect(stats.wrongCount, 7);
      expect(stats.correctPct, 42);
      expect(stats.fellPct, 58);
      expect(
        stats.breakdownLine,
        '12 attempted · 5 got it right · 7 got it wrong',
      );
    });

    test('zero attempts has a clear empty line', () {
      const stats = FomoPulseCommunityStats(attemptCount: 0, correctCount: 0);
      expect(stats.breakdownLine, 'No attempts yet');
      expect(stats.trapLine, 'No attempts yet');
    });

    test('fromMap prefers correct_count over correct_pct', () {
      final stats = FomoPulseCommunityStats.fromMap({
        'attempt_count': 10,
        'correct_count': 4,
        'correct_pct': 99,
      });
      expect(stats.correctCount, 4);
      expect(stats.wrongCount, 6);
    });

    test('fromMap reconstructs counts from correct_pct', () {
      final stats = FomoPulseCommunityStats.fromMap({
        'attempt_count': 10,
        'correct_pct': 40,
      });
      expect(stats.correctCount, 4);
      expect(stats.wrongCount, 6);
    });
  });

  group('FomoPulse.communityStats', () {
    test('in-app default shows raw counts from the first attempt', () {
      final pulse = _pulse(attempts: 3, correct: 1);
      final stats = pulse.communityStats();
      expect(stats, isNotNull);
      expect(
        stats!.breakdownLine,
        '3 attempted · 1 got it right · 2 got it wrong',
      );
    });

    test('share FOMO copy still waits for a crowd', () {
      final pulse = _pulse(attempts: 3, correct: 1);
      expect(
        pulse.communityStats(minAttempts: FomoPulseConstants.minStatsAttempts),
        isNull,
      );
      expect(
        _pulse(
          attempts: 20,
          correct: 8,
        ).communityStats(minAttempts: FomoPulseConstants.minStatsAttempts),
        isNotNull,
      );
    });
  });
}
