import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsc_wars/l10n/app_localizations.dart';
import 'package:upsc_wars/features/weak_areas/widgets/trap_patterns_tracking_note.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('explains that we track which traps catch you most', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TrapPatternsTrackingNote()),
      ),
    );

    expect(
      find.text(lookupAppLocalizations(const Locale('en')).trapsTrackingNote),
      findsOneWidget,
    );
    expect(find.textContaining('exam'), findsOneWidget);
  });
}
