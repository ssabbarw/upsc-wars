abstract final class CommunityBucketUtils {
  static const bucketWindowHours = 3;

  /// Recents walks 3-hour buckets this far back, then shows “That's all”.
  ///
  /// Offsets are `0 … lookbackHours/3` so the last fetch is exactly
  /// [lookbackHours] ago (not one window short).
  static const lookbackHours = 72;
  static const maxBucketLookback = lookbackHours ~/ bucketWindowHours + 1;

  static String bucketForTimestamp(int timestampMillis) {
    final hour = DateTime.fromMillisecondsSinceEpoch(timestampMillis).hour;
    if (hour < 3) return '0';
    if (hour < 6) return '3';
    if (hour < 9) return '6';
    if (hour < 12) return '9';
    if (hour < 15) return '12';
    if (hour < 18) return '15';
    if (hour < 21) return '18';
    return '21';
  }

  static String yearMonthDocIdForTimestamp(int timestampMillis) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    return '${date.year}-${date.month}';
  }
}
