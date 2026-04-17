class ParsedQuestionDisplayText {
  const ParsedQuestionDisplayText({
    required this.stem,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
  });

  final String stem;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
}

abstract final class QuestionDisplayTextParser {
  QuestionDisplayTextParser._();

  static final RegExp _marker = RegExp(
    r'^\s*[\(\[]([a-dA-D])[\)\]]\s+',
    multiLine: true,
  );

  static ParsedQuestionDisplayText parse(String raw) {
    final matches = _marker.allMatches(raw).toList();
    if (matches.length < 4) {
      return ParsedQuestionDisplayText(
        stem: raw.trim(),
        optionA: '',
        optionB: '',
        optionC: '',
        optionD: '',
      );
    }

    final ordered = <String, String>{};
    final firstStart = matches.first.start;
    final stem = raw.substring(0, firstStart).trim();

    for (var i = 0; i < matches.length; i++) {
      final current = matches[i];
      final key = (current.group(1) ?? '').toLowerCase();
      final valueStart = current.end;
      final valueEnd = i + 1 < matches.length ? matches[i + 1].start : raw.length;
      if (!ordered.containsKey(key)) {
        ordered[key] = raw.substring(valueStart, valueEnd).trim();
      }
    }

    if (!(ordered.containsKey('a') &&
        ordered.containsKey('b') &&
        ordered.containsKey('c') &&
        ordered.containsKey('d'))) {
      return ParsedQuestionDisplayText(
        stem: raw.trim(),
        optionA: '',
        optionB: '',
        optionC: '',
        optionD: '',
      );
    }

    return ParsedQuestionDisplayText(
      stem: stem.isEmpty ? raw.trim() : stem,
      optionA: ordered['a'] ?? '',
      optionB: ordered['b'] ?? '',
      optionC: ordered['c'] ?? '',
      optionD: ordered['d'] ?? '',
    );
  }

}
