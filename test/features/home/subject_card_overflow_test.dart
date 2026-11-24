import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/core/theme/app_theme.dart';
import 'package:upsc_wars/features/home/screens/home_screen.dart';

/// Mirrors the homepage subject card: 36px icon, 12px title, 11px progress.
class _ProbeCard extends StatelessWidget {
  const _ProbeCard(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        width: double.infinity,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: AppTextStyles.labelSm().copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '2/25 tests',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<String>> _pumpGrid(
  WidgetTester tester, {
  required double gridWidth,
  required double aspectRatio,
  required double textScale,
}) async {
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details.exceptionAsString());
  };
  addTearDown(() => FlutterError.onError = previous);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridWidth,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: aspectRatio,
              children: const [
                _ProbeCard('Ancient History of the Indian Subcontinent'),
                _ProbeCard('Polity'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  FlutterError.onError = previous;
  return errors;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('subject cards do not overflow on a narrow homepage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // List padding plus the practice block padding. 320 is the narrow phone
    // that clips a 2.35 cell; 390 is a normal phone where 2.35 still fits.
    const cases = <(double screen, double scale)>[
      (320, 1),
      (320, 1.3),
      (360, 1),
      (390, 1),
      (390, 1.5),
    ];

    for (final (screen, scale) in cases) {
      final gridWidth = screen - AppSpacing.lg * 4;
      final ratio = subjectCardAspectRatio(gridWidth, TextScaler.linear(scale));
      final errors = await _pumpGrid(
        tester,
        gridWidth: gridWidth,
        aspectRatio: ratio,
        textScale: scale,
      );
      expect(
        errors.where((e) => e.contains('overflowed')),
        isEmpty,
        reason: 'screen=$screen scale=$scale ratio=$ratio',
      );
      if (screen == 320 && scale == 1) {
        final longName = tester.renderObject<RenderParagraph>(
          find.text('Ancient History of the Indian Subcontinent'),
        );
        final shortName = tester.renderObject<RenderParagraph>(
          find.text('Polity'),
        );
        expect(
          tester
              .widget<Text>(
                find.text('Ancient History of the Indian Subcontinent'),
              )
              .overflow,
          TextOverflow.fade,
        );
        expect(
          longName.getMaxIntrinsicWidth(longName.size.height),
          greaterThan(longName.size.width),
        );
        expect(
          shortName.getMaxIntrinsicWidth(shortName.size.height),
          lessThanOrEqualTo(shortName.size.width + 1),
        );
      }
    }
  });

  testWidgets('the old 2.35 ratio overflows a 320-wide homepage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final errors = await _pumpGrid(
      tester,
      gridWidth: 320 - AppSpacing.lg * 4,
      aspectRatio: 2.35,
      textScale: 1,
    );
    expect(errors.any((e) => e.contains('overflowed')), isTrue);
  });
}
