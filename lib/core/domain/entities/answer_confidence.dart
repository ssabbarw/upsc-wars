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

  /// Exam / results copy (maps to same storage as [verySure] etc.).
  static String examShortLabel(String stored) {
    switch (stored) {
      case verySure:
        return 'Sure';
      case somewhatSure:
        return 'Intelligent guess';
      case guessing:
        return 'Pure guess';
      default:
        return stored;
    }
  }

  /// Slider index 1..3 or null when unset.
  static int? examSliderIndex(String? stored) {
    switch (stored) {
      case verySure:
        return 1;
      case somewhatSure:
        return 2;
      case guessing:
        return 3;
      default:
        return null;
    }
  }

  static String? fromExamSliderIndex(int index) {
    switch (index) {
      case 1:
        return verySure;
      case 2:
        return somewhatSure;
      case 3:
        return guessing;
      default:
        return null;
    }
  }

  /// Wrong + (very sure or somewhat sure) = danger zone for UX copy.
  static bool isDangerouslyConfident(String? stored) {
    return stored == verySure || stored == somewhatSure;
  }
}
