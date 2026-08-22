import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/fomo_pulse/domain/fomo_pulse_models.dart';

FomoPulse _pulse({
  String headline = "India's 1st Train Wasn't Mumbai–Thane?",
  String headlineHi = 'क्या भारत की पहली ट्रेन मुंबई–थाने नहीं थी?',
  String newsSummary = 'Madras Day reveals a forgotten 1830s railway.',
  String newsSummaryHi = 'मद्रास डे एक भुलाई गई 1830 की रेल याद दिलाता है।',
}) {
  return FomoPulse(
    pulseId: 'p1',
    title: 'Push title',
    body: 'Push body',
    headline: headline,
    headlineHi: headlineHi,
    newsSummary: newsSummary,
    newsSummaryHi: newsSummaryHi,
    sourceUrl: 'https://example.com',
    question: FomoPulseQuestion.fromMap(null),
    sentAt: DateTime.utc(2026, 8, 22),
    expiresAt: DateTime.utc(2026, 8, 24),
    attemptCount: 0,
    correctCount: 0,
  );
}

void main() {
  group('FomoPulse copy', () {
    test('list and detail use headline + news_summary per language', () {
      final pulse = _pulse();
      expect(
        pulse.listTitle(preferHindi: false),
        "India's 1st Train Wasn't Mumbai–Thane?",
      );
      expect(
        pulse.listTitle(preferHindi: true),
        'क्या भारत की पहली ट्रेन मुंबई–थाने नहीं थी?',
      );
      expect(
        pulse.listBody(preferHindi: false),
        'Madras Day reveals a forgotten 1830s railway.',
      );
      expect(
        pulse.listBody(preferHindi: true),
        'मद्रास डे एक भुलाई गई 1830 की रेल याद दिलाता है।',
      );
      expect(
        pulse.displayHeadline(preferHindi: true),
        pulse.listTitle(preferHindi: true),
      );
    });

    test('empty headline uses the push title, not the briefing', () {
      final pulse = _pulse(headline: '', headlineHi: '');
      expect(pulse.listTitle(preferHindi: false), 'Push title');
      expect(
        pulse.listBody(preferHindi: false),
        'Madras Day reveals a forgotten 1830s railway.',
      );
    });

    test('Hindi falls back to English when hi fields are empty', () {
      final pulse = _pulse(headlineHi: '', newsSummaryHi: '');
      expect(
        pulse.listTitle(preferHindi: true),
        "India's 1st Train Wasn't Mumbai–Thane?",
      );
      expect(
        pulse.listBody(preferHindi: true),
        'Madras Day reveals a forgotten 1830s railway.',
      );
    });

    test('list and detail drop a leading What happened label', () {
      final pulse = _pulse(
        newsSummary: 'What happened: Madras Day reveals a forgotten railway.',
        newsSummaryHi: '**क्या हुआ:** मद्रास डे एक भुलाई गई रेल याद दिलाता है।',
      );
      expect(
        pulse.listBody(preferHindi: false),
        'Madras Day reveals a forgotten railway.',
      );
      expect(
        pulse.listBody(preferHindi: true),
        'मद्रास डे एक भुलाई गई रेल याद दिलाता है।',
      );
    });
  });
}
