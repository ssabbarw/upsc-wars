/// Inverse of [QuestionDisplayTextParser] — rebuilds stored `display_text`.
abstract final class QuestionDisplayTextComposer {
  QuestionDisplayTextComposer._();

  static String compose({
    required String stem,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
  }) {
    final s = stem.trim();
    final a = optionA.trim();
    final b = optionB.trim();
    final c = optionC.trim();
    final d = optionD.trim();
    if (a.isEmpty && b.isEmpty && c.isEmpty && d.isEmpty) {
      return s;
    }
    final buf = StringBuffer();
    if (s.isNotEmpty) {
      buf.writeln(s);
      buf.writeln();
    }
    buf.writeln('(a) $a');
    buf.writeln('(b) $b');
    buf.writeln('(c) $c');
    buf.writeln('(d) $d');
    return buf.toString().trimRight();
  }
}

/// Splits / joins the Value Addition block inside [final_explanation].
abstract final class FinalExplanationParts {
  FinalExplanationParts._();

  static const valueAdditionMarker = '\n\nValue Addition:';

  static ({String body, String valueAddition}) split(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty) {
      return (body: '', valueAddition: '');
    }
    final idx = text.indexOf(valueAdditionMarker);
    if (idx < 0) {
      return (body: text, valueAddition: '');
    }
    final body = text.substring(0, idx).trim();
    final valueAddition = text
        .substring(idx + valueAdditionMarker.length)
        .trim();
    return (body: body, valueAddition: valueAddition);
  }

  static String join({required String body, required String valueAddition}) {
    final b = body.trim();
    final v = valueAddition.trim();
    if (v.isEmpty) return b;
    if (b.isEmpty) return 'Value Addition:\n$v';
    return '$b$valueAdditionMarker\n$v';
  }
}
