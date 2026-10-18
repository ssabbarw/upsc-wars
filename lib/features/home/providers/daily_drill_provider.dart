import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/presentation/session_subject_label.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../daily_war/domain/daily_war_schedule.dart';
import '../domain/daily_revision.dart';
import '../domain/today_hero.dart';

class DailyDrillState {
  const DailyDrillState({
    required this.subject,
    required this.subjectDisplayName,
    required this.completedToday,
    required this.wrongCount,
    required this.bookmarkCount,
    required this.wrongUuids,
    required this.bookmarkUuids,
  });

  final String subject;
  final String subjectDisplayName;
  final bool completedToday;
  final int wrongCount;
  final int bookmarkCount;
  final List<String> wrongUuids;
  final List<String> bookmarkUuids;

  bool get hasWrongs => wrongUuids.isNotEmpty;
  bool get hasBookmarks => bookmarkUuids.isNotEmpty;
  bool get hasAnyPool => hasWrongs || hasBookmarks;

  List<String> uuidsFor(DailyRevisionPool pool) => switch (pool) {
    DailyRevisionPool.missed => wrongUuids,
    DailyRevisionPool.saved => bookmarkUuids,
  };
}

final dailyDrillProvider = FutureProvider<DailyDrillState?>((ref) async {
  // Show the revision card regardless of activation state — the card handles
  // empty queues gracefully and teaches new users what the queue is for.
  final prefs = await ref.watch(prefsServiceProvider.future);
  final subject = prefs.dailyPracticeSubject;
  final db = ref.watch(userDatabaseProvider);

  final ist = DailyWarSchedule.nowIst();
  final completedToday = await db.sessionsDao.hasCompletedDailyDrillBetween(
    startInclusive: TodayHero.hubWindowStart(ist),
    endExclusive: TodayHero.hubWindowEnd(ist),
  );

  final wrongCount = await DailyRevision.countWrongUuids(db);
  final bookmarkCount = await DailyRevision.countBookmarks(db);
  final wrongUuids = await DailyRevision.queryWrongUuids(db);
  final bookmarkUuids = await DailyRevision.queryBookmarkUuids(db);

  return DailyDrillState(
    subject: subject,
    subjectDisplayName: displayNameForSessionSubject(subject),
    completedToday: completedToday,
    wrongCount: wrongCount,
    bookmarkCount: bookmarkCount,
    wrongUuids: wrongUuids,
    bookmarkUuids: bookmarkUuids,
  );
});
