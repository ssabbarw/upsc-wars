import '../../../../core/providers/prefs_provider.dart';
import '../daily_streak_service.dart';

class UpdateStreakUseCase {
  const UpdateStreakUseCase(this._prefs);
  final PrefsService _prefs;

  Future<void> execute() async {
    DailyStreakService.recordRingClosed(prefs: _prefs);
  }
}
