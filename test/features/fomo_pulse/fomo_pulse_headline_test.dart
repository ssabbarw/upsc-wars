import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/fomo_pulse/domain/fomo_pulse_models.dart';

FomoPulse _pulse({
  String title = 'India may import sugar. But why?',
  String body = 'Ethanol blending is squeezing domestic supply.',
  String headline = 'India weighing sugar imports amid ethanol blending push',
  String headlineHi = 'एथेनॉल मिश्रण के बीच भारत गन्ना चीनी आयात पर विचार कर रहा है',
  String newsSummary =
      'The government is considering sugar imports after ethanol blending tightened domestic availability.',
  String newsSummaryHi =
      'एथेनॉल मिश्रण ने घरेलू आपूर्ति को तंग किया है, इसलिए सरकार चीनी आयात पर विचार कर रही है।',
}) {
  return FomoPulse(
    pulseId: 'p1',
    title: title,
    body: body,
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
  group('FomoPulse headlines', () {
    test('in-app heading is the serious headline, not the push title', () {
      final pulse = _pulse();
      expect(
        pulse.displayHeadline(preferHindi: false),
        'India weighing sugar imports amid ethanol blending push',
      );
      expect(pulse.title, isNot(pulse.displayHeadline(preferHindi: false)));
    });

    test('Hindi in-app heading uses headlineHi, not Kya hua summary', () {
      final pulse = _pulse(
        newsSummaryHi: 'क्या हुआ: सरकार चीनी आयात पर विचार कर रही है।',
      );
      expect(
        pulse.displayHeadline(preferHindi: true),
        'एथेनॉल मिश्रण के बीच भारत गन्ना चीनी आयात पर विचार कर रहा है',
      );
      expect(pulse.displayHeadline(preferHindi: true), isNot(contains('क्या हुआ')));
    });

    test('legacy pulses without headline fall back to push title', () {
      final pulse = _pulse(headline: '', headlineHi: '');
      expect(
        pulse.displayHeadline(preferHindi: false),
        'India may import sugar. But why?',
      );
    });

    test('list subtitle prefers briefing once a headline exists', () {
      final pulse = _pulse();
      expect(
        pulse.listBody(preferHindi: false),
        contains('ethanol blending'),
      );
      expect(pulse.listBody(preferHindi: false), isNot(pulse.body));
    });
  });
}
