import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/l10n/app_localizations.dart';
import 'package:upsc_wars/features/weak_areas/domain/trap_pattern_catalog.dart';
import 'package:upsc_wars/features/weak_areas/widgets/trap_pattern_card.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows 0× and See example for a trap with no user data', (
    tester,
  ) async {
    var opened = false;
    var example = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TrapPatternCard(
            item: const TrapPatternListItem(
              trapType: 'entity-swap',
              displayName: 'Entity Swap',
              blurb: 'Right fact, wrong person.',
              description: 'Longer copy.',
              caughtCount: 0,
            ),
            border: AppColors.borderLight,
            onOpen: () => opened = true,
            onSeeExample: () => example = true,
          ),
        ),
      ),
    );

    expect(find.text('Entity Swap'), findsOneWidget);
    expect(find.text('Right fact, wrong person.'), findsOneWidget);
    expect(find.text('0×'), findsOneWidget);
    expect(find.byIcon(Icons.switch_account_rounded), findsOneWidget);

    await tester.tap(find.text('See example'));
    await tester.pump();
    expect(example, isTrue);
    expect(opened, isFalse);
  });

  testWidgets('tapping the card (not the CTA) opens the trap', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TrapPatternCard(
            item: const TrapPatternListItem(
              trapType: 'entity-swap',
              displayName: 'Entity Swap',
              blurb: 'Right fact, wrong person.',
              description: 'Longer copy.',
              caughtCount: 2,
            ),
            border: AppColors.borderLight,
            onOpen: () => opened = true,
            onSeeExample: () {},
          ),
        ),
      ),
    );

    expect(find.text('Caught you 2×'), findsOneWidget);
    await tester.tap(find.text('Entity Swap'));
    await tester.pump();
    expect(opened, isTrue);
  });
}
