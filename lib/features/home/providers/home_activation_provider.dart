import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/analytics/activation_milestones.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';

part 'home_activation_provider.g.dart';

String _todayYyyyMmDd() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

String _tomorrowYyyyMmDd() {
  final t = DateTime.now().add(const Duration(days: 1));
  return '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';
}

/// Trailing consecutive calendar days with sessions (most recent run).
int consecutiveActivationSessionDays(List<String> sortedDays) {
  if (sortedDays.isEmpty) return 0;
  final unique = sortedDays.toSet().toList()..sort();
  var streak = 1;
  for (var i = unique.length - 1; i > 0; i--) {
    final curr = DateTime.parse(unique[i]);
    final prev = DateTime.parse(unique[i - 1]);
    if (curr.difference(prev).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

class HomeActivationState {
  const HomeActivationState({
    required this.activationComplete,
    required this.getStartedDiagnosticAttempted,
    required this.getStartedCardSnoozedToday,
    required this.completedSessionCount,
    required this.consecutiveSessionDays,
  });

  final bool activationComplete;

  /// Submitted the Get Started demo (home card or post-onboarding sheet).
  final bool getStartedDiagnosticAttempted;

  /// User chose "remind me tomorrow" — hidden until the next local calendar day.
  final bool getStartedCardSnoozedToday;

  final int completedSessionCount;
  final int consecutiveSessionDays;

  /// Show daily until the user finishes any first test (or the demo).
  /// Snooze only hides for the rest of today.
  bool get shouldShowGetStartedCard =>
      !activationComplete &&
      !getStartedDiagnosticAttempted &&
      !getStartedCardSnoozedToday &&
      completedSessionCount == 0;
}

@Riverpod(keepAlive: true)
class HomeActivation extends _$HomeActivation {
  @override
  Future<HomeActivationState> build() async {
    final prefs = await ref.watch(prefsServiceProvider.future);
    final db = ref.watch(userDatabaseProvider);

    final completedCount = await db.sessionsDao.countCompletedSessions();
    var activationComplete = prefs.homeActivationComplete;

    if (!activationComplete && completedCount > 0) {
      final hasConfidence = await db.sessionQuestionsDao
          .hasSureOrEducatedOnCompletedSessions();
      if (hasConfidence) {
        markHomeActivationComplete(prefs);
        activationComplete = true;
      }
    }

    final sessionDays = prefs.activationSessionDays;
    final consecutiveDays = consecutiveActivationSessionDays(sessionDays);
    final snoozedUntil = prefs.getStartedCardSnoozedUntil;
    final snoozedToday =
        snoozedUntil.isNotEmpty && _todayYyyyMmDd().compareTo(snoozedUntil) < 0;

    return HomeActivationState(
      activationComplete: activationComplete,
      getStartedDiagnosticAttempted: prefs.getStartedDiagnosticAttempted,
      getStartedCardSnoozedToday: snoozedToday,
      completedSessionCount: completedCount,
      consecutiveSessionDays: consecutiveDays,
    );
  }

  Future<void> recordSessionDay() async {
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.appendActivationSessionDay(_todayYyyyMmDd());
    ref.invalidateSelf();
  }

  Future<void> markActivationComplete() async {
    final prefs = await ref.read(prefsServiceProvider.future);
    markHomeActivationComplete(prefs);
    ref.invalidateSelf();
  }

  /// Hide Get Started until tomorrow; returns daily until the user finishes a test.
  Future<void> snoozeGetStartedCardUntilTomorrow() async {
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.getStartedCardSnoozedUntil = _tomorrowYyyyMmDd();
    // Clear legacy permanent-dismiss so the daily reminder can return.
    if (prefs.getStartedCardDismissed) {
      prefs.getStartedCardDismissed = false;
    }
    ref.invalidateSelf();
  }
}
