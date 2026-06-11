import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/session_subject_label.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import 'home_activation_provider.dart';

class DailyDrillState {
  const DailyDrillState({
    required this.subject,
    required this.subjectDisplayName,
    required this.completedToday,
  });

  final String subject;
  final String subjectDisplayName;
  final bool completedToday;
}

DateTime localDayStart(DateTime reference) =>
    DateTime(reference.year, reference.month, reference.day);

final dailyDrillProvider = FutureProvider.autoDispose<DailyDrillState?>((
  ref,
) async {
  final activation = await ref.watch(homeActivationProvider.future);
  if (!activation.activationComplete) return null;

  final prefs = await ref.watch(prefsServiceProvider.future);
  final subject = prefs.dailyPracticeSubject;
  final db = ref.watch(userDatabaseProvider);

  final now = DateTime.now();
  final start = localDayStart(now);
  final completedToday = await db.sessionsDao.hasCompletedDailyDrillBetween(
    startInclusive: start,
    endExclusive: start.add(const Duration(days: 1)),
  );

  return DailyDrillState(
    subject: subject,
    subjectDisplayName: displayNameForSessionSubject(subject),
    completedToday: completedToday,
  );
});
