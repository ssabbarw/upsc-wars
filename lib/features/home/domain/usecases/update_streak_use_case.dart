import 'package:intl/intl.dart';
import '../../../../core/providers/prefs_provider.dart';

class UpdateStreakUseCase {
  const UpdateStreakUseCase(this._prefs);
  final PrefsService _prefs;

  Future<void> execute() async {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
    final last = _prefs.lastActiveDate;

    if (last == today) return;
    var next = 1;
    if (last == yesterday) {
      next = (_prefs.currentStreak == 0 ? 1 : _prefs.currentStreak + 1);
    }
    _prefs.currentStreak = next;
    _prefs.lastActiveDate = today;
    if (next > _prefs.longestStreak) _prefs.longestStreak = next;
  }
}
