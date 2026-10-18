/// Consistency tiers + night / effort awards for Daily War.
///
/// **30-day ladder** (War nights only; Sunday never counts):
/// - Recruit 1–6 · Cadet 7–12 · Officer 13–18 · Commander 19–24 · Marshal 25–30+
///
/// Within each 6-night band, Roman grade I–IV marks progress.
///
/// **Miss rule:** one missed War night is a grace freeze. Two consecutive
/// misses demote one tier (streak days snap to the previous tier’s ceiling).
///
/// **Effort awards** (week = Mon–Sat IST):
/// - `effort_first_war` — first submission of the week
/// - `effort_finisher` — submitted with ≥1 question attempted
/// - `effort_back_in` — submitted after missing the previous War night
/// - `effort_full_week` — submissions on all 6 War nights this week
/// - `effort_half_century` — ≥50 questions attempted this week
/// - `effort_century` — ≥100 questions attempted this week
abstract final class DailyWarBadges {
  DailyWarBadges._();

  static const assetDir = 'assets/images/daily_war/badges';

  static const tierIds = <String>[
    'recruit',
    'cadet',
    'officer',
    'commander',
    'marshal',
  ];

  static const tierLabels = <String, String>{
    'recruit': 'Recruit',
    'cadet': 'Cadet',
    'officer': 'Officer',
    'commander': 'Commander',
    'marshal': 'Marshal',
  };

  static const tierAssetById = <String, String>{
    'recruit': '$assetDir/tier-1-recruit.png',
    'cadet': '$assetDir/tier-2-cadet.png',
    'officer': '$assetDir/tier-3-officer.png',
    'commander': '$assetDir/tier-4-commander.png',
    'marshal': '$assetDir/tier-5-marshal.png',
  };

  /// Night / milestone awards (hex icons in the mock).
  static const awardMeta =
      <String, ({String label, String asset, String blurb})>{
        'rank_1_champion': (
          label: 'Champion',
          asset: '$assetDir/rank-1-champion.png',
          blurb: 'All-India Rank 1 for a night',
        ),
        'rank_2_silver': (
          label: 'Silver',
          asset: '$assetDir/rank-2-silver.png',
          blurb: 'All-India Rank 2 for a night',
        ),
        'rank_3_bronze': (
          label: 'Bronze',
          asset: '$assetDir/rank-3-bronze.png',
          blurb: 'All-India Rank 3 for a night',
        ),
        'clean_sweep': (
          label: 'Clean Sweep',
          asset: '$assetDir/clean-sweep.png',
          blurb: 'Every question correct',
        ),
        'no_blind_spots': (
          label: 'No Blind Spots',
          asset: '$assetDir/no-blind-spots.png',
          blurb: 'Attempted every question',
        ),
        'fastest_finger': (
          label: 'Fastest Finger',
          asset: '$assetDir/fastest-finger.png',
          blurb: 'Fastest live finish that night',
        ),
        'nine_pm_sharp': (
          label: '9 PM Sharp',
          asset: '$assetDir/nine-pm-sharp.png',
          blurb: 'Submitted within 3 minutes of 9 PM',
        ),
        'climber': (
          label: 'Climber',
          asset: '$assetDir/climber.png',
          blurb: 'Jumped ≥10 AIR ranks vs last battle',
        ),
        'streak_7_nights': (
          label: '7-Night Streak',
          asset: '$assetDir/streak-7-nights.png',
          blurb: '7+ battle nights in a row',
        ),
        'effort_first_war': (
          label: 'Week Opener',
          asset: '$assetDir/effort-first-war.png',
          blurb: 'First battle of the week',
        ),
        'effort_finisher': (
          label: 'Finisher',
          asset: '$assetDir/effort-finisher.png',
          blurb: 'Submitted with at least one attempt',
        ),
        'effort_back_in': (
          label: 'Back In',
          asset: '$assetDir/effort-back-in.png',
          blurb: 'Returned after missing a night',
        ),
        'effort_full_week': (
          label: 'Full Week',
          asset: '$assetDir/effort-full-week.png',
          blurb: 'Fought all six nights',
        ),
        'effort_half_century': (
          label: 'Half Century',
          asset: '$assetDir/effort-half-century.png',
          blurb: '50+ questions attempted this week',
        ),
        'effort_century': (
          label: 'Century',
          asset: '$assetDir/effort-century.png',
          blurb: '100 questions attempted this week',
        ),
      };

  /// Display order for the badges cabinet (effort → night → podium).
  static const catalogOrder = <String>[
    'effort_first_war',
    'effort_finisher',
    'effort_back_in',
    'effort_full_week',
    'effort_half_century',
    'effort_century',
    'clean_sweep',
    'no_blind_spots',
    'nine_pm_sharp',
    'fastest_finger',
    'climber',
    'streak_7_nights',
    'rank_1_champion',
    'rank_2_silver',
    'rank_3_bronze',
  ];

  static const daysPerTier = 6;
  static const ladderDays = 30;

  /// Tier id for [streakDays], or null when 0.
  static String? tierIdForDays(int streakDays) {
    if (streakDays <= 0) return null;
    final clamped = streakDays > ladderDays ? ladderDays : streakDays;
    final index = ((clamped - 1) ~/ daysPerTier).clamp(0, tierIds.length - 1);
    return tierIds[index];
  }

  /// Ceiling streak days for a tier (Recruit=6 … Marshal=30).
  static int ceilingForTier(String tierId) {
    final i = tierIds.indexOf(tierId);
    if (i < 0) return 0;
    return (i + 1) * daysPerTier;
  }

  /// Previous tier id, or null if already Recruit / none.
  static String? previousTierId(String? tierId) {
    if (tierId == null) return null;
    final i = tierIds.indexOf(tierId);
    if (i <= 0) return null;
    return tierIds[i - 1];
  }

  /// Roman I–IV inside the current 6-day band.
  static int romanGradeForDays(int streakDays) {
    if (streakDays <= 0) return 0;
    final inBand = ((streakDays - 1) % daysPerTier) + 1;
    if (inBand <= 2) return 1;
    if (inBand <= 4) return 2;
    if (inBand == 5) return 3;
    return 4;
  }

  static String romanNumeral(int grade) {
    return switch (grade) {
      1 => 'I',
      2 => 'II',
      3 => 'III',
      4 => 'IV',
      _ => '',
    };
  }

  /// e.g. `Commander IV`, `Recruit I`. Empty when no streak.
  static String titleForDays(int streakDays) {
    final tier = tierIdForDays(streakDays);
    if (tier == null) return '';
    final label = tierLabels[tier] ?? tier;
    final roman = romanNumeral(romanGradeForDays(streakDays));
    return roman.isEmpty ? label : '$label $roman';
  }

  static String? assetForTier(String? tierId) =>
      tierId == null ? null : tierAssetById[tierId];

  static String? assetForAward(String awardId) => awardMeta[awardId]?.asset;

  static String labelForAward(String awardId) =>
      awardMeta[awardId]?.label ?? awardId;

  static String blurbForAward(String awardId) =>
      awardMeta[awardId]?.blurb ?? '';

  static bool isEffortAward(String awardId) => awardId.startsWith('effort_');

  /// Demote one tier after two consecutive misses.
  static int demoteStreakDays(int streakDays) {
    final tier = tierIdForDays(streakDays);
    if (tier == null) return 0;
    final prev = previousTierId(tier);
    if (prev == null) return 0; // was Recruit → drop to 0
    return ceilingForTier(prev);
  }

  /// Night awards from a finished live attempt (plus optional peer context).
  static List<String> nightAwards({
    required int air,
    required int correct,
    required int wrong,
    required int unanswered,
    required int elapsedMs,
    required int streakDays,
    required int questionCount,
    int? submittedAtMs,
    int? warStartMs,
    bool isFastestFinger = false,
    bool isClimber = false,
  }) {
    final out = <String>[];
    if (air == 1) out.add('rank_1_champion');
    if (air == 2) out.add('rank_2_silver');
    if (air == 3) out.add('rank_3_bronze');
    if (questionCount > 0 &&
        correct == questionCount &&
        wrong == 0 &&
        unanswered == 0) {
      out.add('clean_sweep');
    } else if (unanswered == 0 && (correct + wrong) >= questionCount) {
      out.add('no_blind_spots');
    }
    if (isFastestFinger) out.add('fastest_finger');
    if (submittedAtMs != null &&
        warStartMs != null &&
        submittedAtMs >= warStartMs &&
        submittedAtMs - warStartMs <= 3 * 60 * 1000) {
      out.add('nine_pm_sharp');
    }
    if (isClimber) out.add('climber');
    if (streakDays >= 7) out.add('streak_7_nights');
    return out;
  }

  /// Effort awards known at submit time (week = Mon–Sat containing [dateId]).
  ///
  /// [priorWeekAttempted] / [priorWeekNights] exclude tonight.
  /// [missedPreviousWarNight] = no submission on the previous War date.
  static List<String> effortAwards({
    required int tonightAttempted,
    required int priorWeekAttempted,
    required int priorWeekNights,
    required bool isFirstOfWeek,
    required bool missedPreviousWarNight,
  }) {
    final out = <String>[];
    if (tonightAttempted >= 1) out.add('effort_finisher');
    if (isFirstOfWeek) out.add('effort_first_war');
    if (missedPreviousWarNight) out.add('effort_back_in');
    final nights = priorWeekNights + 1;
    if (nights >= 6) out.add('effort_full_week');
    final weekQ = priorWeekAttempted + tonightAttempted;
    if (weekQ >= 50) out.add('effort_half_century');
    if (weekQ >= 100) out.add('effort_century');
    return out;
  }
}
