import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_curriculum_picker.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_phase.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_phase_resolver.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_schedule.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_scoring.dart';

void main() {
  group('DailyWarSchedule', () {
    test('formats ISO date', () {
      expect(
        DailyWarSchedule.formatIsoDate(DateTime(2026, 7, 31)),
        '2026-07-31',
      );
    });

    test('Sunday is Grand War with 25 questions', () {
      final sunday = DateTime(2026, 8, 2); // Sunday
      expect(DailyWarSchedule.isGrandWarDay(sunday), isTrue);
      expect(DailyWarSchedule.questionCountForDate(sunday), 25);
    });

    test('lobby opens 15 minutes before 9 PM', () {
      final day = DateTime(2026, 7, 31);
      expect(
        DailyWarSchedule.lobbyOpensAt(day),
        DateTime(2026, 7, 31, 20, 45),
      );
    });

    test('live window scales with question count', () {
      expect(DailyWarSchedule.liveWindowMinutesFor(15), 20);
      expect(DailyWarSchedule.liveWindowMinutesFor(25), 34);
      expect(
        DailyWarSchedule.liveEndsAt(DateTime(2026, 7, 31), questionCount: 15),
        DateTime(2026, 7, 31, 21, 20),
      );
      expect(
        DailyWarSchedule.liveEndsAt(DateTime(2026, 8, 2), questionCount: 25),
        DateTime(2026, 8, 2, 21, 34),
      );
    });
  });

  group('DailyWarPhaseResolver', () {
    final day = DateTime(2026, 7, 31);

    test('morning at 10 AM', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 10),
        ),
        DailyWarPhase.morning,
      );
    });

    test('countdown at 5 PM', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 17),
        ),
        DailyWarPhase.countdown,
      );
    });

    test('lobby at 8:50 PM', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 20, 50),
        ),
        DailyWarPhase.lobby,
      );
    });

    test('live joinable at 9:05 PM', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 21, 5),
        ),
        DailyWarPhase.liveJoinable,
      );
    });

    test('live locked at 9:15 PM', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 21, 15),
        ),
        DailyWarPhase.liveLocked,
      );
    });

    test('results pending after live without ranked status', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 21, 30),
        ),
        DailyWarPhase.resultsPending,
      );
    });

    test('results ready when ranked', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 21, 30),
          firestoreStatus: 'ranked',
        ),
        DailyWarPhase.resultsReady,
      );
    });
  });

  group('DailyWarCurriculumPicker', () {
    test('picks two sequential polity topics and advances index', () {
      final picked = DailyWarCurriculumPicker.pickWeekday(
        subjectRotationIndex: 0,
        topicIndexBySubject: const {},
      );
      expect(picked.subjectSlug, 'polity');
      expect(picked.topics, hasLength(2));
      expect(picked.topics[0].topic, 'Parliament');
      expect(picked.topics[1].topic, 'Judiciary');
      expect(picked.nextSubjectRotationIndex, 1);
      expect(picked.nextTopicIndexForSubject, 2);
    });
  });

  group('DailyWarScoring', () {
    test('UPSC +2 / -2/3', () {
      final result = DailyWarScoring.score(
        selectedByUuid: {
          'a': 'b',
          'b': 'c',
          'c': '',
        },
        correctByUuid: {
          'a': 'b',
          'b': 'a',
          'c': 'd',
        },
      );
      expect(result.correct, 1);
      expect(result.wrong, 1);
      expect(result.unanswered, 1);
      expect(result.points, closeTo(2 - 2 / 3, 0.01));
    });
  });
}
