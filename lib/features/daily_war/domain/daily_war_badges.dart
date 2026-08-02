/// Consistency tiers + night awards for Daily War leaderboards.
///
/// **30-day ladder** (War nights only; Sunday never counts):
/// - Recruit 1–6 · Cadet 7–12 · Officer 13–18 · Commander 19–24 · Marshal 25–30+
///
/// Within each 6-night band, Roman grade I–IV marks progress.
///
/// **Miss rule:** one missed War night is a grace freeze. Two consecutive
/// misses demote one tier (streak days snap to the previous tier’s ceiling).
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
  static const awardMeta = <String, ({String label, String asset})>{
    'rank_1_champion': (
      label: 'Champion',
      asset: '$assetDir/rank-1-champion.png',
    ),
    'rank_2_silver': (
      label: 'Silver',
      asset: '$assetDir/rank-2-silver.png',
    ),
    'rank_3_bronze': (
      label: 'Bronze',
      asset: '$assetDir/rank-3-bronze.png',
    ),
    'clean_sweep': (
      label: 'Clean Sweep',
      asset: '$assetDir/clean-sweep.png',
    ),
    'no_blind_spots': (
      label: 'No Blind Spots',
      asset: '$assetDir/no-blind-spots.png',
    ),
    'fastest_finger': (
      label: 'Fastest Finger',
      asset: '$assetDir/fastest-finger.png',
    ),
    'nine_pm_sharp': (
      label: '9 PM Sharp',
      asset: '$assetDir/nine-pm-sharp.png',
    ),
    'climber': (
      label: 'Climber',
      asset: '$assetDir/climber.png',
    ),
    'streak_7_nights': (
      label: '7-Night Streak',
      asset: '$assetDir/streak-7-nights.png',
    ),
  };

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
}
