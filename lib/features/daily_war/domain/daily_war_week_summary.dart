import 'daily_war_badges.dart';
import 'daily_war_models.dart';
import 'daily_war_schedule.dart';

/// One cell in the Sunday week strip (Mon–Sun of the current IST week).
class DailyWarWeekDayCell {
  const DailyWarWeekDayCell({
    required this.date,
    required this.label,
    required this.isRest,
    required this.isGrand,
    this.war,
    this.submission,
  });

  final DateTime date;
  final String label;
  final bool isRest;
  final bool isGrand;
  final DailyWarDoc? war;
  final DailyWarSubmission? submission;

  bool get attempted => submission != null;

  /// e.g. `12/15` or null when not attempted / no war.
  String? get scoreLabel {
    if (isRest) return 'rest';
    final sub = submission;
    final w = war;
    if (sub == null || w == null) return null;
    final q = w.questionCount > 0 ? w.questionCount : 15;
    return '${sub.correct}/$q';
  }
}

/// Count of how many times a badge was earned in the week.
class DailyWarBadgeCount {
  const DailyWarBadgeCount({required this.badgeId, required this.count});

  final String badgeId;
  final int count;

  String get label {
    if (DailyWarBadges.tierIds.contains(badgeId)) {
      return DailyWarBadges.tierLabels[badgeId] ?? badgeId;
    }
    return DailyWarBadges.labelForAward(badgeId);
  }
}

/// Mon–Sat War week rollup for the Sunday home card + progress sheet.
class DailyWarWeekSummary {
  const DailyWarWeekSummary({
    required this.monday,
    required this.days,
    required this.attemptedNights,
    required this.warNights,
    required this.liveAttempts,
    required this.unrankedAttempts,
    required this.topicsCovered,
    required this.missedTopics,
    required this.correct,
    required this.wrong,
    required this.unanswered,
    required this.accuracyPct,
    required this.avgScore,
    required this.avgElapsedMs,
    required this.bestAir,
    required this.worstAir,
    required this.avgPercentile,
    required this.playedGrand,
    required this.badgeCounts,
    required this.peakStreakDays,
    required this.weekNumber,
  });

  final DateTime monday;
  final List<DailyWarWeekDayCell> days;
  final int attemptedNights;
  final int warNights;
  final int liveAttempts;
  final int unrankedAttempts;
  final int topicsCovered;
  final List<DailyWarTopicRef> missedTopics;
  final int correct;
  final int wrong;
  final int unanswered;
  final double? accuracyPct;
  final double? avgScore;
  final int? avgElapsedMs;
  final int? bestAir;
  final int? worstAir;
  final double? avgPercentile;
  final bool playedGrand;
  final List<DailyWarBadgeCount> badgeCounts;
  final int peakStreakDays;
  final int weekNumber;

  int get totalQuestions => correct + wrong + unanswered;

  bool get attemptedNone => attemptedNights == 0;
  bool get attemptedAll => warNights > 0 && attemptedNights >= warNights;
  bool get attemptedPartial =>
      attemptedNights > 0 && attemptedNights < warNights;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static DailyWarWeekSummary build({
    required DateTime sundayIst,
    required List<DailyWarDoc> wars,
    required Map<String, DailyWarSubmission> submissions,
    int syllabusTopicsCovered = 0,
  }) {
    final sunday = DailyWarSchedule.dateOnly(sundayIst);
    final monday = sunday.subtract(Duration(days: sunday.weekday - 1));

    final byId = <String, DailyWarDoc>{for (final w in wars) w.dateId: w};

    final days = <DailyWarWeekDayCell>[];
    var attempted = 0;
    var warNights = 0;
    var live = 0;
    var unranked = 0;
    var correct = 0;
    var wrong = 0;
    var unanswered = 0;
    var scoreSum = 0.0;
    var elapsedSum = 0;
    var percentileSum = 0.0;
    var percentileN = 0;
    int? bestAir;
    int? worstAir;
    var playedGrand = false;
    var peakStreak = 0;
    final badgeTally = <String, int>{};
    final coveredKeys = <String>{};
    final missed = <DailyWarTopicRef>[];
    final missedKeys = <String>{};

    for (var i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      final id = DailyWarSchedule.formatIsoDate(day);
      final isRest = DailyWarSchedule.isWarOffDay(day);
      final isGrand = DailyWarSchedule.isGrandWarDay(day);
      final war = byId[id];
      final sub = submissions[id];

      if (!isRest) {
        warNights++;
        if (sub != null) {
          attempted++;
          if (sub.isLive) {
            live++;
          } else {
            unranked++;
          }
          if (isGrand) playedGrand = true;
          correct += sub.correct;
          wrong += sub.wrong;
          unanswered += sub.unanswered;
          scoreSum += sub.score;
          elapsedSum += sub.elapsedMs;
          if (sub.streakDays > peakStreak) peakStreak = sub.streakDays;
          final air = sub.air;
          if (air != null) {
            if (bestAir == null || air < bestAir) bestAir = air;
            if (worstAir == null || air > worstAir) worstAir = air;
          }
          final pct = sub.percentile;
          if (pct != null) {
            percentileSum += pct;
            percentileN++;
          }
          final tier =
              sub.tierId ?? DailyWarBadges.tierIdForDays(sub.streakDays);
          if (tier != null) {
            badgeTally[tier] = (badgeTally[tier] ?? 0) + 1;
          }
          for (final b in sub.badges) {
            if (DailyWarBadges.tierIds.contains(b)) continue;
            badgeTally[b] = (badgeTally[b] ?? 0) + 1;
          }
          for (final t in war?.topics ?? const <DailyWarTopicRef>[]) {
            coveredKeys.add('${t.subjectSlug}::${t.topic}');
          }
        } else if (war != null) {
          for (final t in war.topics) {
            final key = '${t.subjectSlug}::${t.topic}';
            if (missedKeys.add(key)) missed.add(t);
          }
        }
      }

      days.add(
        DailyWarWeekDayCell(
          date: day,
          label: _labels[i],
          isRest: isRest,
          isGrand: isGrand,
          war: war,
          submission: sub,
        ),
      );
    }

    final answered = correct + wrong + unanswered;
    final accuracy = answered > 0 ? (correct / answered) * 100 : null;
    final weekNumber = syllabusTopicsCovered > 0
        ? ((syllabusTopicsCovered / 12).floor() + 1).clamp(1, 99)
        : 1;

    final badgeCounts =
        badgeTally.entries
            .map((e) => DailyWarBadgeCount(badgeId: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

    return DailyWarWeekSummary(
      monday: monday,
      days: days,
      attemptedNights: attempted,
      warNights: warNights,
      liveAttempts: live,
      unrankedAttempts: unranked,
      topicsCovered: coveredKeys.length,
      missedTopics: missed,
      correct: correct,
      wrong: wrong,
      unanswered: unanswered,
      accuracyPct: accuracy,
      avgScore: attempted > 0 ? scoreSum / attempted : null,
      avgElapsedMs: attempted > 0 ? (elapsedSum / attempted).round() : null,
      bestAir: bestAir,
      worstAir: worstAir,
      avgPercentile: percentileN > 0 ? percentileSum / percentileN : null,
      playedGrand: playedGrand,
      badgeCounts: badgeCounts,
      peakStreakDays: peakStreak,
      weekNumber: weekNumber,
    );
  }
}
