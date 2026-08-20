import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/widgets/daily_ca_month_calendar.dart';

void main() {
  testWidgets('tapping today opens the day even before the paper is live', (
    tester,
  ) async {
    String? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 520,
            child: DailyCaMonthCalendar(
              year: 2026,
              month: 8,
              completedDates: const {},
              minDate: DateTime(2026, 8, 18),
              nowIst: DateTime(2026, 8, 20, 15),
              onDateTap: (iso) => tapped = iso,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('20'));
    expect(tapped, '2026-08-20');

    tapped = null;
    await tester.tap(find.text('21'));
    expect(tapped, isNull);
  });
}
