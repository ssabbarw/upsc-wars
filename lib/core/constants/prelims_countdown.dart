import '../../l10n/l10n.dart';
import 'prelims_motivation_quotes.dart';

class PrelimsCountdown {
  PrelimsCountdown._();
  // UPSC Prelims start time (local device time). Fallback when Remote Config
  // `prelims_date` is missing — keep in sync with kill_switch defaults.
  static final DateTime prelimsDate = DateTime(2027, 5, 23, 9, 30);

  static Duration remaining({DateTime? now, DateTime? targetDate}) {
    final current = now ?? DateTime.now();
    final target = targetDate ?? prelimsDate;
    final diff = target.difference(current);
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  static int daysLeft({DateTime? now, DateTime? targetDate}) {
    final diff = remaining(now: now, targetDate: targetDate);
    if (diff.inSeconds <= 0) return 0;
    final fullDays = diff.inDays;
    final hasRemainder = diff - Duration(days: fullDays) > Duration.zero;
    return hasRemainder ? fullDays + 1 : fullDays;
  }

  static String daysLabel({DateTime? now, DateTime? targetDate}) {
    final days = daysLeft(now: now, targetDate: targetDate);
    if (days == 0) return appL10n.prelimsToday;
    return appL10n.prelimsDaysTo(days);
  }

  static String quoteForDate({DateTime? now}) {
    return PrelimsMotivationQuotes.quoteForDate(now ?? DateTime.now());
  }

  static String timerLabel({DateTime? now, DateTime? targetDate}) {
    final diff = remaining(now: now, targetDate: targetDate);
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    final seconds = diff.inSeconds.remainder(60);

    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(days)}:${two(hours)}:${two(minutes)}:${two(seconds)}';
  }

  /// Big title line for the Android persistent notif (system renders titles larger).
  static String persistentNotificationTitle({
    DateTime? now,
    DateTime? targetDate,
  }) {
    final days = daysLeft(now: now, targetDate: targetDate);
    if (days <= 0) return 'Exam day';
    if (days == 1) return '1 day';
    return '$days days';
  }

  /// Supporting line under the big day count — cycles a quote each calendar day.
  static String persistentNotificationBody({
    DateTime? now,
    DateTime? targetDate,
  }) {
    final current = now ?? DateTime.now();
    final days = daysLeft(now: current, targetDate: targetDate);

    if (days <= 0) {
      return "You've prepared for this — breathe and execute.";
    }
    return quoteForDate(now: current);
  }
}
