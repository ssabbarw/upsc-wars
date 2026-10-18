import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:upsc_wars/core/providers/catalog_providers.dart';
import 'package:upsc_wars/l10n/app_localizations.dart';
import 'package:upsc_wars/features/test_series/domain/series_sample_question.dart';
import 'package:upsc_wars/features/test_series/domain/series_stats.dart';
import 'package:upsc_wars/features/test_series/domain/test_series_models.dart';
import 'package:upsc_wars/features/test_series/providers/series_sample_question_provider.dart';
import 'package:upsc_wars/features/test_series/providers/test_series_providers.dart';
import 'package:upsc_wars/features/test_series/screens/test_series_home_screen.dart';
import 'package:upsc_wars/features/test_series/widgets/series_paywall_sheet.dart';

SeriesTest _test(
  String id,
  String kind, {
  String bucket = '',
  bool free = false,
}) => SeriesTest(
  id: id,
  seriesId: 'prelims_2027',
  kind: kind,
  bucket: bucket,
  title: id,
  index: 1,
  isFree: free,
  unlockAt: DateTime(2026),
  durationMins: 60,
  questionCount: 10,
  status: 'ready',
  questions: const [],
);

SeriesBundle _bundle({int ca = 12}) => SeriesBundle(
  info: TestSeriesInfo(
    id: 'prelims_2027',
    title: 'Prelims 2027 Test Series',
    titleHi: '',
    year: 2027,
    productId: 'prelims_2027_pass',
    entitlementId: 'prelims_2027',
    prelimsDate: DateTime(2099, 5, 23),
  ),
  tests: [
    for (var i = 1; i <= 10; i++) _test('flt_$i', SeriesTestKind.fullLength),
    for (var i = 1; i <= 30; i++)
      _test('s_$i', SeriesTestKind.staticTest, bucket: SeriesBuckets.polity),
    for (var i = 1; i <= ca; i++) _test('ca_$i', SeriesTestKind.currentAffairs),
    for (var i = 1; i <= 4; i++)
      _test('pyq_$i', SeriesTestKind.pyqMix, free: true),
  ],
);

Map<String, dynamic> _caQuestion({
  String correct = 'b',
  bool table = false,
  bool rich = true,
}) => {
  'uuid': 'q1',
  'meta': {
    'gs_subject': 'Environment',
    'concepts_used': ['Green credit'],
  },
  'shared': {'correct_option': correct, 'has_table': table},
  'en': {
    'display_text':
        '1. Consider the following statements:\n'
        '(a) 1 only\n(b) 2 only\n(c) Both 1 and 2\n(d) Neither 1 nor 2',
    'statement_analysis': rich
        ? [
            {'statement': 'Statement 1', 'is_correct': false, 'reason': 'No.'},
          ]
        : null,
    'elimination_logic': rich ? ['Eliminate (a).'] : <String>[],
    'strong_distractor': rich ? 'Option C — looks right.' : '',
    'upsc_trap_explanation': '',
    'final_explanation': 'Body.\n\nValue Addition: extra',
  },
};

class _NotOwned extends OwnedSeriesNotifier {
  @override
  Future<Set<String>> build() async => <String>{};
}

class _Owned extends OwnedSeriesNotifier {
  @override
  Future<Set<String>> build() async => <String>{'prelims_2027'};
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SeriesSampleQuestion.pickFromDailyCa', () {
    test('parses options and strips the leading question number', () {
      final picked = SeriesSampleQuestion.pickFromDailyCa([_caQuestion()])!;
      expect(picked.correctOption, 'b');
      expect(picked.subjectLabel, 'Environment');
      expect(picked.isCurrentAffairs, isTrue);
      expect(picked.en.stem, 'Consider the following statements:');
      expect(picked.en.options['c'], 'Both 1 and 2');
      expect(picked.en.hasStatements, isTrue);
    });

    test('skips table questions and bad answer keys', () {
      expect(
        SeriesSampleQuestion.pickFromDailyCa([_caQuestion(table: true)]),
        isNull,
      );
      expect(
        SeriesSampleQuestion.pickFromDailyCa([_caQuestion(correct: 'z')]),
        isNull,
      );
    });

    test('returns null when no question is explained richly enough', () {
      expect(
        SeriesSampleQuestion.pickFromDailyCa([_caQuestion(rich: false)]),
        isNull,
      );
    });
  });

  group('Series home intro tab', () {
    Future<void> pump(
      WidgetTester tester, {
      SeriesBundle? bundle,
      SeriesSampleQuestion sample = SeriesSampleQuestion.fallback,
      bool owned = false,
    }) async {
      tester.view.physicalSize = const Size(390 * 2, 5200 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final b = bundle ?? _bundle();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesBundleProvider.overrideWith((ref, id) => Stream.value(b)),
            ownedSeriesIdsProvider.overrideWith(
              owned ? _Owned.new : _NotOwned.new,
            ),
            seriesStatsProvider.overrideWith(
              (ref, id) async => SeriesStats.compute(
                bundle: b,
                attemptList: const [],
                answers: const [],
              ),
            ),
            seriesInProgressProvider.overrideWith(
              (ref, id) async => <String, String>{},
            ),
            appLanguageProvider.overrideWith((ref) async => 'en'),
            testSeriesCanSellProvider.overrideWith((ref) async => true),
            seriesProductProvider.overrideWith(
              (ref, id) async => StoreProduct(
                'prelims_2027_pass',
                'desc',
                'Pass',
                299,
                '₹299',
                'INR',
              ),
            ),
            seriesSampleQuestionProvider.overrideWith((ref) async => sample),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TestSeriesHomeScreen(seriesId: 'prelims_2027'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows counts, free PYQs, sections and the price bar', (
      tester,
    ) async {
      await pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Prelims 2027 Test Series'), findsWidgets);
      // Total / FLT / subject, with the CA tests called out separately.
      expect(find.text('56'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('12 Current Affairs tests'), findsOneWidget);
      expect(find.text('See all 4 PYQ tests'), findsOneWidget);
      expect(find.text('Explanations that actually teach'), findsOneWidget);
      expect(find.text('Smarter than a score'), findsOneWidget);
      expect(find.text('₹299'), findsOneWidget);
      expect(find.text('Unlock all tests'), findsOneWidget);
    });

    testWidgets('intro is the first tab; the other tabs stay, buy bar pinned', (
      tester,
    ) async {
      await pump(tester);

      for (final label in ['Overview', 'Full-Length', 'Subjects', 'PYQ & CA']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Unlock all tests'), findsOneWidget);

      await tester.tap(find.text('Full-Length'));
      await tester.pumpAndSettle();
      expect(
        find.text('Simulate the real exam: 100 questions, 2 hours.'),
        findsOneWidget,
      );
      // The buy bar stays under every tab.
      expect(find.text('Unlock all tests'), findsOneWidget);
      expect(find.text('Smarter than a score'), findsNothing);
    });

    testWidgets('"See all PYQ tests" switches to the PYQ & CA tab', (
      tester,
    ) async {
      await pump(tester);

      await tester.ensureVisible(find.text('See all 4 PYQ tests'));
      await tester.tap(find.text('See all 4 PYQ tests'));
      await tester.pumpAndSettle();

      expect(find.text('PYQ & Current Affairs'), findsOneWidget);
    });

    testWidgets('buyers get the dashboard, not the sales page or buy bar', (
      tester,
    ) async {
      await pump(tester, owned: true);

      expect(find.text('Your Preparation Overview'), findsOneWidget);
      expect(find.text('Smarter than a score'), findsNothing);
      expect(find.text('Unlock all tests'), findsNothing);
    });

    testWidgets('hides the CA line when the series has no CA tests', (
      tester,
    ) async {
      await pump(tester, bundle: _bundle(ca: 0));
      expect(find.textContaining('Current Affairs test'), findsNothing);
    });

    testWidgets('sample question reveals the explanation on tap', (
      tester,
    ) async {
      await pump(tester);

      await tester.ensureVisible(find.text('See a real example'));
      await tester.tap(find.text('See a real example'));
      await tester.pumpAndSettle();

      expect(find.text('Sample question'), findsOneWidget);
      expect(find.text('Lord William Bentinck'), findsOneWidget);
      // One "Value addition" tile on the page behind the sheet, none yet in it.
      expect(find.text('Value addition'), findsOneWidget);

      await tester.tap(find.text('Warren Hastings'));
      await tester.pumpAndSettle();

      expect(find.text('Not quite. The answer is B'), findsOneWidget);
      expect(find.text('Value addition'), findsNWidgets(2));
    });

    testWidgets('analysis example opens with sample numbers', (tester) async {
      await pump(tester);

      await tester.ensureVisible(find.text('See an example'));
      await tester.tap(find.text('See an example'));
      await tester.pumpAndSettle();

      expect(find.text('Example with sample numbers'), findsOneWidget);
      expect(find.text('INC sessions'), findsOneWidget);
    });
  });
}
