import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../domain/did_you_know_cards.dart';

part 'home_activation_provider.g.dart';

/// Minimum completed sessions between Did You Know cards.
const kDidYouKnowMinSessionsBetweenCards = 3;

/// Minimum days between Did You Know cards.
const kDidYouKnowMinDaysBetweenCards = 3;

/// Stop Did You Know drip after this many completed sessions.
const kDidYouKnowMaxSessions = 10;

/// Stop Did You Know drip after this many consecutive session-days.
const kDidYouKnowMaxConsecutiveSessionDays = 4;

String _todayYyyyMmDd() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
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
    required this.completedSessionCount,
    required this.consecutiveSessionDays,
    required this.shouldShowDidYouKnow,
    required this.nextDidYouKnowCardId,
  });

  final bool activationComplete;
  final int completedSessionCount;
  final int consecutiveSessionDays;
  final bool shouldShowDidYouKnow;
  final String? nextDidYouKnowCardId;
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
      final hasConfidence =
          await db.sessionQuestionsDao.hasSureOrEducatedOnCompletedSessions();
      if (hasConfidence) {
        prefs.homeActivationComplete = true;
        activationComplete = true;
      }
    }

    final sessionDays = prefs.activationSessionDays;
    final consecutiveDays = consecutiveActivationSessionDays(sessionDays);

    final dismissed = prefs.didYouKnowDismissedIds;
    final nextCard = nextDidYouKnowCard(dismissed);

    final dripStopped = activationComplete &&
        (completedCount >= kDidYouKnowMaxSessions ||
            consecutiveDays >= kDidYouKnowMaxConsecutiveSessionDays ||
            nextCard == null);

    var shouldShow = activationComplete && !dripStopped && nextCard != null;

    if (shouldShow && prefs.didYouKnowLastShownAt != null) {
      final sessionsSince =
          completedCount - prefs.didYouKnowSessionsAtLastShow;
      final daysSince = DateTime.now()
          .difference(prefs.didYouKnowLastShownAt!)
          .inDays;
      final lastCardShown = dismissed.isNotEmpty;
      if (lastCardShown &&
          sessionsSince < kDidYouKnowMinSessionsBetweenCards &&
          daysSince < kDidYouKnowMinDaysBetweenCards) {
        shouldShow = false;
      }
    }

    return HomeActivationState(
      activationComplete: activationComplete,
      completedSessionCount: completedCount,
      consecutiveSessionDays: consecutiveDays,
      shouldShowDidYouKnow: shouldShow,
      nextDidYouKnowCardId: shouldShow ? nextCard?.id : null,
    );
  }

  Future<void> recordSessionDay() async {
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.appendActivationSessionDay(_todayYyyyMmDd());
    ref.invalidateSelf();
  }

  Future<void> markActivationComplete() async {
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.homeActivationComplete = true;
    ref.invalidateSelf();
  }

  Future<void> dismissDidYouKnowCard(String cardId) async {
    final prefs = await ref.read(prefsServiceProvider.future);
    prefs.addDidYouKnowDismissedId(cardId);
    ref.invalidateSelf();
  }

  Future<void> markDidYouKnowShown(String cardId) async {
    final prefs = await ref.read(prefsServiceProvider.future);
    final db = ref.read(userDatabaseProvider);
    final completedCount = await db.sessionsDao.countCompletedSessions();
    prefs.didYouKnowLastShownAt = DateTime.now();
    prefs.didYouKnowSessionsAtLastShow = completedCount;
    ref.invalidateSelf();
  }
}
