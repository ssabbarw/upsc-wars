import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:upsc_wars/features/home/providers/daily_drill_provider.dart';
import 'package:upsc_wars/features/home/widgets/revision_test_cards.dart';
import 'package:upsc_wars/l10n/app_localizations.dart';

DailyDrillState _drill({int wrong = 0, int saved = 0}) {
  return DailyDrillState(
    subject: 'misc',
    subjectDisplayName: 'Misc',
    completedToday: false,
    wrongCount: wrong,
    bookmarkCount: saved,
    wrongUuids: const [],
    bookmarkUuids: const [],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required DailyDrillState state,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dailyDrillProvider.overrideWith((ref) async => state)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: RevisionTestCards(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('empty pools say there is nothing to test', (tester) async {
    await _pump(tester, state: _drill());

    expect(find.text('Revise'), findsOneWidget);
    expect(find.text('No incorrect MCQs'), findsOneWidget);
    expect(find.text('No bookmarked MCQs'), findsOneWidget);

    await tester.tap(find.text('Incorrect MCQs'));
    await tester.pumpAndSettle();

    expect(find.text('You have no incorrect MCQs'), findsOneWidget);
    expect(
      find.text('They show up when you get a question wrong.'),
      findsOneWidget,
    );
    expect(find.text('Got it'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(
      find.text('They show up when you get a question wrong.'),
      findsNothing,
    );

    await tester.tap(find.text('Bookmarked MCQs'));
    await tester.pumpAndSettle();
    expect(
      find.text('Bookmark a question in a test and it will show up here.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'cards preview a random test of 10, or fewer when the pool is smaller',
    (tester) async {
      await _pump(tester, state: _drill(wrong: 24, saved: 4));

      expect(find.text('24\u00a0incorrect'), findsOneWidget);
      expect(find.text('Random test · 10'), findsOneWidget);
      expect(find.text('4\u00a0bookmarks'), findsOneWidget);
      expect(find.text('Random test · 4'), findsOneWidget);
      expect(find.text('No incorrect MCQs'), findsNothing);
      expect(find.text('No bookmarked MCQs'), findsNothing);
    },
  );
}
