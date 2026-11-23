import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/core/theme/app_theme.dart';
import 'package:upsc_wars/features/home/screens/home_screen.dart';

/// Home list padding is 16 on each side, so a 390-wide phone gives the
/// subject grid 358px.
const _gridWidth = 358.0;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('default text size keeps the 2.35 subject card ratio', (
    tester,
  ) async {
    final extent = await _extent(tester, textScale: 1);
    final tileWidth = (_gridWidth - AppSpacing.sm) / 2;

    expect(extent, tileWidth / 2.35);
  });

  for (final scale in [1.3, 1.6, 2.0, 3.0]) {
    testWidgets('subject card fits title and progress at text scale $scale', (
      tester,
    ) async {
      final extent = await _pumpCard(tester, textScale: scale);

      expect(tester.takeException(), isNull);
      expect(find.text('प्राचीन इतिहास'), findsOneWidget);
      expect(find.text('3/25 tests'), findsOneWidget);

      final normal = await _extent(tester, textScale: 1);
      expect(extent, greaterThanOrEqualTo(normal));
      if (scale >= 1.6) expect(extent, greaterThan(normal));
    });
  }
}

Future<double> _extent(WidgetTester tester, {required double textScale}) async {
  late double extent;
  await tester.pumpWidget(
    _app(
      textScale: textScale,
      child: Builder(
        builder: (context) {
          extent = homeSubjectCardExtent(context, _gridWidth);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return extent;
}

Future<double> _pumpCard(
  WidgetTester tester, {
  required double textScale,
}) async {
  late double extent;
  await tester.pumpWidget(
    _app(
      textScale: textScale,
      child: Builder(
        builder: (context) {
          extent = homeSubjectCardExtent(context, _gridWidth);
          final tileWidth = (_gridWidth - AppSpacing.sm) / 2;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: tileWidth,
              height: extent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 36, height: 36),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'प्राचीन इतिहास',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSm().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '3/25 tests',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  return extent;
}

Widget _app({required double textScale, required Widget child}) {
  return MaterialApp(
    theme: AppTheme.light(),
    builder: (context, child) {
      return MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      );
    },
    home: Scaffold(body: child),
  );
}
