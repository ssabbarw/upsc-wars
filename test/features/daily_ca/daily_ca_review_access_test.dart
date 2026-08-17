import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_ca/domain/daily_ca_draft.dart';
import 'package:upsc_wars/features/daily_ca/widgets/daily_ca_review_access.dart';

void main() {
  group('dailyCaReviewDateForNow', () {
    test('before 8 PM IST reviews yesterday, skipping Saturday', () {
      expect(
        dailyCaReviewDateForNow(referenceIst: DateTime(2026, 6, 9, 10)),
        '2026-06-08',
      );
      expect(
        dailyCaReviewDateForNow(referenceIst: DateTime(2026, 6, 7, 10)),
        '2026-06-05',
      );
    });

    test('from 8 PM IST reviews today, skipping Saturday', () {
      expect(
        dailyCaReviewDateForNow(referenceIst: DateTime(2026, 6, 8, 20)),
        '2026-06-08',
      );
      expect(
        dailyCaReviewDateForNow(referenceIst: DateTime(2026, 6, 6, 21)),
        '2026-06-05',
      );
    });

    test('uses the configured generate time, not a hard-coded 8 PM', () {
      expect(
        dailyCaReviewDateForNow(
          referenceIst: DateTime(2026, 6, 8, 19, 30),
          generateHourIst: 21,
          generateMinuteIst: 0,
        ),
        '2026-06-07',
      );
      expect(
        dailyCaReviewDateForNow(
          referenceIst: DateTime(2026, 6, 8, 21, 0),
          generateHourIst: 21,
          generateMinuteIst: 0,
        ),
        '2026-06-08',
      );
    });
  });

  group('DailyCaDraft.isFrozen', () {
    test('freezes at next morning 6 AM IST', () {
      const draft = DailyCaDraft(
        date: '2026-06-08',
        status: 'published',
        opensAt: '',
        isWeekendPack: false,
        chosenIds: [],
        questions: [],
      );
      expect(
        draft.isFrozen(referenceIst: DateTime(2026, 6, 9, 5, 59)),
        isFalse,
      );
      expect(
        draft.isFrozen(referenceIst: DateTime(2026, 6, 9, 6)),
        isTrue,
      );
    });
  });
}
