import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upsc_wars/features/mini_games/connect_the_dots/connect_the_dots_screen.dart';
import 'package:upsc_wars/features/mini_games/duel/duel_screen.dart';
import 'package:upsc_wars/features/mini_games/fact_or_bluff/fact_or_bluff_screen.dart';
import 'package:upsc_wars/features/mini_games/hub/games_hub_screen.dart';
import 'package:upsc_wars/features/mini_games/odd_one_out/odd_one_out_screen.dart';
import 'package:upsc_wars/features/mini_games/shared/game_intro_view.dart';
import 'package:upsc_wars/features/mini_games/timeline_sorter/timeline_sorter_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      // Skip how-to sheets by default so game smoke tests stay focused.
      GameHowToPrefs.timelineSorter: true,
      GameHowToPrefs.oddOneOut: true,
      GameHowToPrefs.factOrBluff: true,
      GameHowToPrefs.connectTheDots: true,
      GameHowToPrefs.duel: true,
    });
  });

  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  Future<void> pumpFrames(WidgetTester tester, {int count = 20}) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('games hub renders every entry', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(wrap(const GamesHubScreen()));
    await pumpFrames(tester);

    expect(find.text('Revision Games'), findsOneWidget);
    expect(find.text('Memory Pairs'), findsOneWidget);
    expect(find.text('1v1 Duel'), findsOneWidget);
  });

  testWidgets('how-to bottom sheet shows checkbox and can start', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: Consumer(
                  builder: (context, ref, _) => FilledButton(
                    onPressed: () => showGameHowToIfNeeded(
                      context: context,
                      ref: ref,
                      config: const GameHowToConfig(
                        prefKey: GameHowToPrefs.timelineSorter,
                        icon: Icons.timeline_rounded,
                        accent: Color(0xFFBA7517),
                        title: 'Timeline Sorter',
                        steps: ['One.', 'Two.', 'Three.'],
                      ),
                    ),
                    child: const Text('Open how-to'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Open how-to'));
    await pumpFrames(tester, count: 30);

    expect(find.text('How to play'), findsOneWidget);
    expect(find.text("Don't show again"), findsOneWidget);

    await tester.tap(find.text("Don't show again"));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await pumpFrames(tester, count: 20);

    expect(find.text('How to play'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(GameHowToPrefs.timelineSorter), isTrue);
  });

  for (final (name, screen) in <(String, Widget)>[
    ('Timeline Sorter', const TimelineSorterScreen()),
    ('Odd One Out', const OddOneOutScreen()),
    ('Connect the Dots', const ConnectTheDotsScreen()),
    ('1v1 Duel', const DuelScreen()),
  ]) {
    testWidgets('$name loads without how-to when skipped', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(wrap(screen));
      await pumpFrames(tester, count: 30);

      expect(find.text('How to play'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Fact or Bluff answers without how-to', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(wrap(const FactOrBluffScreen()));
    await pumpFrames(tester, count: 40);

    expect(find.text('FACT'), findsOneWidget);
    expect(find.text('BLUFF'), findsOneWidget);

    await tester.tap(find.text('FACT'));
    await tester.pump();
    expect(find.text('Next →'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
