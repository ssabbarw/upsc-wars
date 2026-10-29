import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/l10n/app_localizations.dart';
import 'package:upsc_wars/features/weak_areas/domain/trap_example.dart';
import 'package:upsc_wars/features/weak_areas/widgets/trap_example_sheet.dart';

import '../../support/test_question_builder.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const en = TrapExampleContent(
    stem: 'Which body recommends how Union taxes are shared with the States?',
    options: {
      'a': 'NITI Aayog',
      'b': 'Finance Commission',
      'c': 'Comptroller and Auditor General of India',
      'd': 'Union Ministry of Finance',
    },
    why: 'NITI Aayog is real and central, which is why it works as bait.',
  );

  const hi = TrapExampleContent(
    stem: 'संघ के करों के बँटवारे की सिफ़ारिश कौन-सा निकाय करता है?',
    options: {
      'a': 'नीति आयोग',
      'b': 'वित्त आयोग',
      'c': 'नियंत्रक एवं महालेखापरीक्षक',
      'd': 'केंद्रीय वित्त मंत्रालय',
    },
    why: 'करों के बँटवारे की सिफ़ारिश वित्त आयोग करता है।',
  );

  const example = TrapExample(
    trapType: 'entity-swap',
    correctOption: 'b',
    en: en,
    hi: hi,
  );

  Widget wrap(Widget child) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  Widget sheet({String language = 'en', TrapExample value = example}) {
    return wrap(
      TrapExampleSheet(
        trapType: 'entity-swap',
        displayName: 'Entity Swap',
        blurb: 'Right fact, wrong person or institution.',
        exampleOverride: value,
        languageOverride: language,
      ),
    );
  }

  testWidgets('names the trap after a wrong pick', (tester) async {
    await tester.pumpWidget(sheet());
    await tester.pump();

    expect(find.text('Entity Swap'), findsOneWidget);
    expect(
      find.text('Right fact, wrong person or institution.'),
      findsOneWidget,
    );
    expect(find.text(en.stem), findsOneWidget);
    expect(find.text(en.why), findsNothing);

    await tester.tap(find.text('NITI Aayog'));
    await tester.pump();

    expect(find.text("That's the trap."), findsOneWidget);
    expect(find.text(en.why), findsOneWidget);
  });

  testWidgets('congratulates a correct pick and still explains the trap', (
    tester,
  ) async {
    await tester.pumpWidget(sheet());
    await tester.pump();

    await tester.tap(find.text('Finance Commission'));
    await tester.pump();

    expect(find.text('You spotted it.'), findsOneWidget);
    expect(find.text(en.why), findsOneWidget);
  });

  testWidgets('a second tap cannot change the revealed answer', (tester) async {
    await tester.pumpWidget(sheet());
    await tester.pump();

    await tester.tap(find.text('NITI Aayog'));
    await tester.pump();
    await tester.tap(find.text('Finance Commission'));
    await tester.pump();

    expect(find.text("That's the trap."), findsOneWidget);
    expect(find.text('You spotted it.'), findsNothing);
  });

  testWidgets('reads in Hindi when the app language is Hindi', (tester) async {
    await tester.pumpWidget(sheet(language: 'hi'));
    await tester.pump();

    expect(find.text(hi.stem), findsOneWidget);
    expect(find.text(en.stem), findsNothing);

    await tester.tap(find.text('नीति आयोग'));
    await tester.pump();
    expect(find.text(hi.why), findsOneWidget);
  });

  testWidgets('falls back to English when Hindi copy is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      sheet(
        language: 'hi',
        value: const TrapExample(
          trapType: 'entity-swap',
          correctOption: 'b',
          en: en,
        ),
      ),
    );
    await tester.pump();

    expect(find.text(en.stem), findsOneWidget);
  });

  test('fromQuestion copies stem, options, and the correct key', () {
    final example = TrapExample.fromQuestion(
      buildTestQuestion(uuid: 'pair-1', questionType: 'identify-the-pair'),
      trapType: 'identify-the-pair',
    );
    expect(example.trapType, 'identify-the-pair');
    expect(example.correctOption, 'a');
    expect(example.en.stem, 'Q pair-1');
    expect(example.en.options['b'], 'B');
  });
}
