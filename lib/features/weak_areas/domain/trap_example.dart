import '../../../core/domain/entities/test_question.dart';

/// Stem, options, and trap explanation in one language.
class TrapExampleContent {
  const TrapExampleContent({
    required this.stem,
    required this.options,
    required this.why,
  });

  final String stem;

  /// Option key (`a`–`d`) to option text, in display order.
  final Map<String, String> options;

  /// One or two lines naming the trap, shown after the user picks.
  final String why;

  factory TrapExampleContent.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as Map).cast<String, dynamic>();
    return TrapExampleContent(
      stem: (json['stem'] as String).trim(),
      options: {
        for (final key in const ['a', 'b', 'c', 'd'])
          key: (rawOptions[key] as String).trim(),
      },
      why: (json['why'] as String).trim(),
    );
  }
}

/// One hand-written demo MCQ from trap_examples.json, shown in the trap
/// example sheet. These are illustrations only — never scored or persisted.
class TrapExample {
  const TrapExample({
    required this.trapType,
    required this.correctOption,
    required this.en,
    this.hi,
  });

  final String trapType;
  final String correctOption;
  final TrapExampleContent en;
  final TrapExampleContent? hi;

  /// Hindi copy when the user reads in Hindi and it exists; English otherwise.
  TrapExampleContent forLanguage(String language) {
    if (language == 'hi' && hi != null) return hi!;
    return en;
  }

  factory TrapExample.fromJson(Map<String, dynamic> json) {
    final hiRaw = json['hi'] as Map<String, dynamic>?;
    return TrapExample(
      trapType: json['trap_type'] as String,
      correctOption: (json['correct_option'] as String).toLowerCase().trim(),
      en: TrapExampleContent.fromJson(json['en'] as Map<String, dynamic>),
      hi: hiRaw == null ? null : TrapExampleContent.fromJson(hiRaw),
    );
  }

  /// Bank question shown as a demo MCQ. Never scored.
  factory TrapExample.fromQuestion(
    TestQuestion question, {
    required String trapType,
  }) {
    TrapExampleContent content({required bool hindi}) {
      String pick(String en, String hi) =>
          hindi && hi.trim().isNotEmpty ? hi : en;
      final whyEn = _firstNonEmpty([
        question.upscTrapExplanation,
        question.finalExplanation,
      ]);
      final whyHi = _firstNonEmpty([
        question.upscTrapExplanationHi,
        question.finalExplanationHi,
        whyEn,
      ]);
      return TrapExampleContent(
        stem: pick(question.displayText, question.displayTextHi),
        options: {
          'a': pick(question.optionA, question.optionAHi),
          'b': pick(question.optionB, question.optionBHi),
          'c': pick(question.optionC, question.optionCHi),
          'd': pick(question.optionD, question.optionDHi),
        },
        why: hindi ? whyHi : whyEn,
      );
    }

    return TrapExample(
      trapType: trapType,
      correctOption: question.correctOption.toLowerCase().trim(),
      en: content(hindi: false),
      hi: question.displayTextHi.trim().isEmpty ? null : content(hindi: true),
    );
  }
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}
