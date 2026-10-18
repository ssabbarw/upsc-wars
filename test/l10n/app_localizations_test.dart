import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/l10n/l10n.dart';

void main() {
  test('Hindi and English resolve, with plurals and placeholders', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final hi = lookupAppLocalizations(const Locale('hi'));

    expect(en.settingsTitle, 'Settings');
    expect(hi.settingsTitle, 'सेटिंग्स');
    expect(en.homeStreakDays(1), '1 day');
    expect(en.homeStreakDays(5), '5 days');
    expect(hi.homeStreakDays(5), '5 दिन');
    expect(hi.testQuestionOfTotal(3, 20), 'Q3/20');
    expect(hi.homeChallengeGoalMixed('poster', 7), contains('7/10'));
  });

  testWidgets('MaterialApp locale switches the UI language', (tester) async {
    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(builder: (c) => Text(c.l10n.settingsTitle)),
    );

    await tester.pumpWidget(app(const Locale('en')));
    expect(find.text('Settings'), findsOneWidget);
    await tester.pumpWidget(app(const Locale('hi')));
    await tester.pumpAndSettle();
    expect(find.text('सेटिंग्स'), findsOneWidget);
  });
}
