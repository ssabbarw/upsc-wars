/// Stored in `attempts.confidence` (nullable).
abstract final class AnswerConfidence {
  static const verySure = 'very_sure';
  static const somewhatSure = 'somewhat_sure';
  static const guessing = 'guessing';

  static const values = [verySure, somewhatSure, guessing];

  static int? analyticsCode(String? stored) {
    switch (stored) {
      case verySure:
        return 3;
      case somewhatSure:
        return 2;
      case guessing:
        return 1;
      default:
        return null;
    }
  }

  static String displayLabel(String stored) {
    switch (stored) {
      case verySure:
        return 'Very Sure';
      case somewhatSure:
        return 'Somewhat Sure';
      case guessing:
        return 'Guessing';
      default:
        return stored;
    }
  }

  /// Wrong + (very sure or somewhat sure) = danger zone for UX copy.
  static bool isDangerouslyConfident(String? stored) {
    return stored == verySure || stored == somewhatSure;
  }
}
