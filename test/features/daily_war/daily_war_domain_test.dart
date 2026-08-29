import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_wars/features/daily_war/daily_war_constants.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_copy.dart';
import 'package:upsc_wars/features/daily_war/domain/daily_war_curriculum.dart';
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

    test('Saturday is Grand War with 25 questions', () {
      final saturday = DateTime(2026, 8, 1); // Saturday
      expect(DailyWarSchedule.isGrandWarDay(saturday), isTrue);
      expect(DailyWarSchedule.isWarDay(saturday), isTrue);
      expect(DailyWarSchedule.questionCountForDate(saturday), 25);
    });

    test('Sunday is off', () {
      final sunday = DateTime(2026, 8, 2); // Sunday
      expect(DailyWarSchedule.isWarOffDay(sunday), isTrue);
      expect(DailyWarSchedule.isGrandWarDay(sunday), isFalse);
      expect(DailyWarSchedule.isWarDay(sunday), isFalse);
    });

    test('next/previous War date skips Sunday', () {
      final saturday = DateTime(2026, 8, 1);
      final sunday = DateTime(2026, 8, 2);
      final monday = DateTime(2026, 8, 3);
      expect(DailyWarSchedule.nextWarDate(saturday), monday);
      expect(DailyWarSchedule.previousWarDate(monday), saturday);
      expect(DailyWarSchedule.previousWarDate(sunday), saturday);
    });

    test('lobby opens one minute before 9 PM', () {
      final day = DateTime(2026, 7, 31);
      expect(DailyWarSchedule.lobbyOpensAt(day), DateTime(2026, 7, 31, 20, 59));
    });

    test('AIR target is 9:40 PM', () {
      final day = DateTime(2026, 7, 31);
      expect(DailyWarSchedule.rankTargetAt(day), DateTime(2026, 7, 31, 21, 40));
    });

    test('live window scales with question count', () {
      expect(DailyWarSchedule.liveWindowMinutesFor(15), 20);
      expect(DailyWarSchedule.liveWindowMinutesFor(25), 34);
      expect(
        DailyWarSchedule.liveEndsAt(DateTime(2026, 7, 31), questionCount: 15),
        DateTime(2026, 7, 31, 21, 20),
      );
      expect(
        DailyWarSchedule.liveEndsAt(DateTime(2026, 8, 1), questionCount: 25),
        DateTime(2026, 8, 1, 21, 34),
      );
    });

    test('nowIst wall clock matches schedule anchors before 9 PM', () {
      // 19:39 IST = 14:09 UTC — must still be countdown, not “war over”.
      final utc = DateTime.utc(2026, 7, 31, 14, 9);
      final ist = DailyWarSchedule.nowIst(utc);
      expect(ist.isUtc, isFalse);
      expect(ist.hour, 19);
      expect(ist.minute, 39);
      expect(ist.isBefore(DailyWarSchedule.startAtForDate(ist)), isTrue);
      expect(
        DailyWarPhaseResolver.resolve(referenceIst: ist),
        DailyWarPhase.countdown,
      );
    });

    test('offsetMsUntilIstWall aims DateTime.now() at 9:05 IST', () {
      final offset = DailyWarSchedule.offsetMsUntilIstWall(
        hour: 21,
        minute: 5,
      );
      final utc = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch + offset,
        isUtc: true,
      );
      final ist = DailyWarSchedule.nowIst(utc);
      expect(ist.hour, 21);
      expect(ist.minute, 5);
    });
  });

  group('DailyWarPhaseResolver', () {
    final day = DateTime(2026, 7, 31);

    test('rest day on Sunday', () {
      expect(
        DailyWarPhaseResolver.resolve(referenceIst: DateTime(2026, 8, 2, 12)),
        DailyWarPhase.restDay,
      );
    });

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

    test('countdown immediately before lobby opens', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 20, 58, 59),
        ),
        DailyWarPhase.countdown,
      );
    });

    test('lobby at 8:59 PM', () {
      expect(
        DailyWarPhaseResolver.resolve(
          referenceIst: DateTime(day.year, day.month, day.day, 20, 59),
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
    test('stays on polity until its topics are finished', () {
      final picked = DailyWarCurriculumPicker.pickWeekday(
        subjectRotationIndex: 0,
        topicIndexBySubject: const {},
      );
      expect(picked.subjectSlug, 'polity');
      expect(picked.topics, hasLength(2));
      expect(picked.topics[0].topic, 'Parliament');
      expect(picked.topics[1].topic, 'Judiciary');
      expect(picked.nextSubjectRotationIndex, 0);
      expect(picked.nextTopicIndexForSubject, 2);

      final next = DailyWarCurriculumPicker.pickWeekday(
        subjectRotationIndex: picked.nextSubjectRotationIndex,
        topicIndexBySubject: {'polity': picked.nextTopicIndexForSubject},
      );
      expect(next.subjectSlug, 'polity');
      expect(next.topics[0].topic, 'Fundamental Rights');
      expect(next.topics[1].topic, 'Constitutional Foundations');
      expect(next.nextSubjectRotationIndex, 0);
      expect(next.nextTopicIndexForSubject, 4);
    });

    test('last leftover topic is a singleton then next subject starts', () {
      final polity = DailyWarCurriculum.topicsBySubject['polity']!;
      expect(polity.length.isOdd, isTrue);

      final leftover = DailyWarCurriculumPicker.pickWeekday(
        subjectRotationIndex: 0,
        topicIndexBySubject: {'polity': polity.length - 1},
      );
      expect(leftover.subjectSlug, 'polity');
      expect(leftover.topics, hasLength(1));
      expect(leftover.topics[0].topic, polity.last);
      expect(leftover.nextSubjectRotationIndex, 1);
      expect(leftover.nextTopicIndexForSubject, 0);

      final economy = DailyWarCurriculumPicker.pickWeekday(
        subjectRotationIndex: leftover.nextSubjectRotationIndex,
        topicIndexBySubject: {'economy': leftover.nextTopicIndexForSubject},
      );
      expect(economy.subjectSlug, 'economy');
      expect(economy.topics, hasLength(2));
      expect(economy.topics[0].topic, 'Money and Banking');
      expect(economy.topics[1].topic, 'Global Economic Groupings');
      expect(economy.nextSubjectRotationIndex, 1);
      expect(economy.nextTopicIndexForSubject, 2);
    });

    test('restarts at first subject after the last subject finishes', () {
      final rotation = DailyWarCurriculum.subjectRotation;
      final lastSlug = rotation.last;
      final lastTopics = DailyWarCurriculum.topicsBySubject[lastSlug]!;

      final leftover = DailyWarCurriculumPicker.pickWeekday(
        subjectRotationIndex: rotation.length - 1,
        topicIndexBySubject: {lastSlug: lastTopics.length - 1},
      );
      expect(leftover.subjectSlug, lastSlug);
      expect(leftover.topics, hasLength(1));
      expect(leftover.nextSubjectRotationIndex, 0);
      expect(leftover.nextTopicIndexForSubject, 0);

      final restart = DailyWarCurriculumPicker.pickWeekday(
        subjectRotationIndex: leftover.nextSubjectRotationIndex,
        topicIndexBySubject: {
          DailyWarCurriculum.subjectRotation.first:
              leftover.nextTopicIndexForSubject,
        },
      );
      expect(restart.subjectSlug, 'polity');
      expect(restart.topics[0].topic, 'Parliament');
      expect(restart.topics[1].topic, 'Judiciary');
    });

    test('walks an entire odd-length subject two topics at a time', () {
      final polity = DailyWarCurriculum.topicsBySubject['polity']!;
      var rotationIndex = 0;
      var topicIndex = 0;
      final seen = <String>[];
      var wars = 0;
      while (rotationIndex == 0) {
        final picked = DailyWarCurriculumPicker.pickWeekday(
          subjectRotationIndex: rotationIndex,
          topicIndexBySubject: {'polity': topicIndex},
        );
        seen.addAll(picked.topics.map((t) => t.topic));
        wars += 1;
        expect(wars, lessThan(20));
        rotationIndex = picked.nextSubjectRotationIndex;
        topicIndex = picked.nextTopicIndexForSubject;
      }
      expect(seen, polity);
      expect(wars, 9);
      expect(rotationIndex, 1);
      expect(topicIndex, 0);
    });

    test('curriculum maps 125 topics', () {
      expect(DailyWarCurriculum.totalTopicCount, 125);
    });
  });

  group('DailyWarScoring', () {
    test('UPSC +2 / -2/3', () {
      final result = DailyWarScoring.score(
        selectedByUuid: {'a': 'b', 'b': 'c', 'c': ''},
        correctByUuid: {'a': 'b', 'b': 'a', 'c': 'd'},
      );
      expect(result.correct, 1);
      expect(result.wrong, 1);
      expect(result.unanswered, 1);
      expect(result.points, closeTo(2 - 2 / 3, 0.01));
    });
  });

  group('DailyWarCopy names', () {
    test('Static War is the program; Daily Battle is the weeknight event', () {
      expect(DailyWarCopy.programName, 'Static War');
      expect(DailyWarCopy.eventName(isGrand: false), 'Daily Battle');
      expect(DailyWarCopy.eventName(isGrand: true), 'Grand War');
      expect(DailyWarCopy.eventNameCaps(isGrand: false), 'DAILY BATTLE');
      expect(DailyWarCopy.eventNameCaps(isGrand: true), 'GRAND WAR');
    });
  });

  group('DailyWarConstants.fcmPhaseOpensHomeHero', () {
    test('morning and 30-min land on the home War hero', () {
      expect(DailyWarConstants.fcmPhaseOpensHomeHero('morning'), isTrue);
      expect(DailyWarConstants.fcmPhaseOpensHomeHero('reminder_30'), isTrue);
      expect(DailyWarConstants.fcmPhaseOpensHomeHero('MORNING'), isTrue);
    });

    test('lobby and results stay on the War lobby', () {
      expect(DailyWarConstants.fcmPhaseOpensHomeHero('lobby'), isFalse);
      expect(DailyWarConstants.fcmPhaseOpensHomeHero('results'), isFalse);
      expect(
        DailyWarConstants.fcmPhaseOpensHomeHero('results_personal'),
        isFalse,
      );
      expect(DailyWarConstants.fcmPhaseOpensHomeHero(null), isFalse);
    });
  });
}
