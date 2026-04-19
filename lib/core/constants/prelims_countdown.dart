import 'package:intl/intl.dart';

class PrelimsCountdown {
  PrelimsCountdown._();

  // UPSC Prelims start time (local device time): 24 May, 09:30 AM.
  static final DateTime prelimsDate = DateTime(2026, 5, 24, 9, 30);

  static const String motivationQuote =
      '“The trouble is, you think you have time.”\n- Buddha';

  static Duration remaining({DateTime? now}) {
    final current = now ?? DateTime.now();
    final diff = prelimsDate.difference(current);
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  static int daysLeft({DateTime? now}) {
    final diff = remaining(now: now);
    if (diff.inSeconds <= 0) return 0;
    final fullDays = diff.inDays;
    final hasRemainder = diff - Duration(days: fullDays) > Duration.zero;
    return hasRemainder ? fullDays + 1 : fullDays;
  }

  static String daysLabel({DateTime? now}) {
    final days = daysLeft(now: now);
    if (days == 0) return 'Prelims is today';
    return '$days days to UPSC Prelims';
  }

  static String quoteForDate({DateTime? now}) {
    return motivationQuote;
  }

  static String timerLabel({DateTime? now}) {
    final diff = remaining(now: now);
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(days)}:${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  /// Title for the Android persistent prelims notification (days-only UI).
  static String persistentNotificationTitle() => 'UPSC Prelims';

  /// Body for the persistent notification: days remaining only (no quote, no H:M:S).
  static String persistentNotificationBody({DateTime? now}) {
    final days = daysLeft(now: now);

    if (days <= 0) {
      return 'It\'s the exam day,\nYou\'ve prepared for this — breathe and execute.';
    }
    if (days == 1) {
      return '1 day to go,\nOne calm session at a time.';
    }
    return '$days days to go\nSmall steps, every day — that\'s the edge.';
  }
}
