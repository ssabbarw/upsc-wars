import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/core/parsers/question_display_text_composer.dart';
import 'package:upsc_wars/core/parsers/question_display_text_parser.dart';

void main() {
  test('stemOnly strips inline options when separate options exist', () {
    const raw =
        'According to Iran, which condition must the U.S. meet? (a) Withdraw troops (b) Lift sanctions (c) Recognize nuclear program (d) Close ports';
    final stem = QuestionDisplayTextParser.stemOnly(
      raw,
      hasSeparateOptions: true,
    );
    expect(stem, 'According to Iran, which condition must the U.S. meet?');
  });

  test('stemOnly keeps full text when options are not separate', () {
    const raw = 'Simple stem with (a) inline marker';
    final stem = QuestionDisplayTextParser.stemOnly(
      raw,
      hasSeparateOptions: false,
    );
    expect(stem, raw);
  });

  test('compose round-trips with parser', () {
    const raw = 'What is 2+2?\n\n(a) 3\n(b) 4\n(c) 5\n(d) 6';
    final parsed = QuestionDisplayTextParser.parse(raw);
    final composed = QuestionDisplayTextComposer.compose(
      stem: parsed.stem,
      optionA: parsed.optionA,
      optionB: parsed.optionB,
      optionC: parsed.optionC,
      optionD: parsed.optionD,
    );
    final again = QuestionDisplayTextParser.parse(composed);
    expect(again.stem, parsed.stem);
    expect(again.optionA, parsed.optionA);
    expect(again.optionB, parsed.optionB);
    expect(again.optionC, parsed.optionC);
    expect(again.optionD, parsed.optionD);
  });

  test('FinalExplanationParts split and join', () {
    const raw = 'Body text.\n\nValue Addition:\nExtra facts.';
    final parts = FinalExplanationParts.split(raw);
    expect(parts.body, 'Body text.');
    expect(parts.valueAddition, 'Extra facts.');
    final joined = FinalExplanationParts.join(
      body: parts.body,
      valueAddition: parts.valueAddition,
    );
    expect(joined, raw);
  });
}
