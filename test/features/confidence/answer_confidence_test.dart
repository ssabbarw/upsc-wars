import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/domain/entities/answer_confidence.dart';

void main() {
  group('AnswerConfidence', () {
    test('isDangerouslyConfident is true only for very sure and somewhat sure', () {
      expect(AnswerConfidence.isDangerouslyConfident(AnswerConfidence.verySure), isTrue);
      expect(
        AnswerConfidence.isDangerouslyConfident(AnswerConfidence.somewhatSure),
        isTrue,
      );
      expect(AnswerConfidence.isDangerouslyConfident(AnswerConfidence.guessing), isFalse);
      expect(AnswerConfidence.isDangerouslyConfident(null), isFalse);
      expect(AnswerConfidence.isDangerouslyConfident('other'), isFalse);
    });

    test('analyticsCode maps stored values to ints', () {
      expect(AnswerConfidence.analyticsCode(AnswerConfidence.verySure), 3);
      expect(AnswerConfidence.analyticsCode(AnswerConfidence.somewhatSure), 2);
      expect(AnswerConfidence.analyticsCode(AnswerConfidence.guessing), 1);
      expect(AnswerConfidence.analyticsCode(null), isNull);
    });

    test('displayLabel returns readable strings', () {
      expect(AnswerConfidence.displayLabel(AnswerConfidence.verySure), 'Very Sure');
      expect(
        AnswerConfidence.displayLabel(AnswerConfidence.somewhatSure),
        'Somewhat Sure',
      );
      expect(AnswerConfidence.displayLabel(AnswerConfidence.guessing), 'Guessing');
    });

    test('values contains exactly the three storage strings', () {
      expect(AnswerConfidence.values, hasLength(3));
      expect(AnswerConfidence.values, contains(AnswerConfidence.verySure));
      expect(AnswerConfidence.values, contains(AnswerConfidence.somewhatSure));
      expect(AnswerConfidence.values, contains(AnswerConfidence.guessing));
    });

    test('exam slider index maps tiers 1–3; null when unset', () {
      expect(AnswerConfidence.examSliderIndex(null), isNull);
      expect(AnswerConfidence.examSliderIndex(AnswerConfidence.verySure), 1);
      expect(AnswerConfidence.examSliderIndex(AnswerConfidence.somewhatSure), 2);
      expect(AnswerConfidence.examSliderIndex(AnswerConfidence.guessing), 3);
    });

    test('fromExamSliderIndex maps 1–3 to storage; 0 or other to null', () {
      expect(AnswerConfidence.fromExamSliderIndex(0), isNull);
      expect(AnswerConfidence.fromExamSliderIndex(1), AnswerConfidence.verySure);
      expect(AnswerConfidence.fromExamSliderIndex(2), AnswerConfidence.somewhatSure);
      expect(AnswerConfidence.fromExamSliderIndex(3), AnswerConfidence.guessing);
      expect(AnswerConfidence.fromExamSliderIndex(99), isNull);
    });

    test('examShortLabel matches exam copy', () {
      expect(AnswerConfidence.examShortLabel(AnswerConfidence.verySure), 'Sure');
      expect(
        AnswerConfidence.examShortLabel(AnswerConfidence.somewhatSure),
        'Intelligent guess',
      );
      expect(AnswerConfidence.examShortLabel(AnswerConfidence.guessing), 'Pure guess');
    });
  });
}
