import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/accuracy_rules.dart';
import '../../../core/domain/entities/session_summary.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';

/// SubjectInfo for a single subject, derived from the cached subject list.
final subjectInfoProvider =
    FutureProvider.autoDispose.family<SubjectInfo?, String>((ref, subject) async {
  final subjects = await ref.watch(subjectTestListProvider.future);
  try {
    return subjects.firstWhere((s) => s.subject == subject);
  } catch (_) {
    return null;
  }
});

/// Topics for a subject enriched with the user's attempt stats.
/// Language-aware: uses [topicTestTopicsProvider] which honours the app language.
final subjectTopicsProvider =
    FutureProvider.autoDispose.family<List<TopicInfo>, String>((ref, subject) async {
  final rawTopics = await ref.watch(topicTestTopicsProvider(subject).future);
  final db = ref.watch(userDatabaseProvider);
  final statsRows = await db.userTopicStatsDao.fetchBySubject(subject);
  final statsByTopic = {for (final row in statsRows) row.topic: row};

  final enriched = rawTopics.map((topic) {
    final stat = statsByTopic[topic.topic];
    final fromUser = stat?.totalAttempted ?? 0;
    final attemptCount =
        fromUser > 0 ? fromUser : topic.attemptCount;
    final double? accuracyPercent;
    if (fromUser > 0) {
      accuracyPercent = stat!.accuracyPercentage;
    } else if (topic.attemptCount > 0) {
      accuracyPercent = topic.accuracyPercent;
    } else {
      accuracyPercent = null;
    }
    return TopicInfo(
      topic: topic.topic,
      subject: topic.subject,
      displayName: topic.displayName,
      questionCount: topic.questionCount,
      attemptCount: attemptCount,
      accuracyPercent: accuracyPercent,
      accuracyTier: AccuracyRules.tierFor(
        attemptCount: attemptCount,
        accuracyPercent: accuracyPercent,
      ),
    );
  }).toList();

  enriched.sort((a, b) {
    final aAttempted = a.attemptCount > 0;
    final bAttempted = b.attemptCount > 0;
    if (aAttempted != bAttempted) return aAttempted ? -1 : 1;
    if (!aAttempted && !bAttempted) {
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    }
    final byAccuracy =
        (a.accuracyPercent ?? 0).compareTo(b.accuracyPercent ?? 0);
    if (byAccuracy != 0) return byAccuracy;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });

  return enriched;
});

/// Past completed sessions for a subject, most recent first.
final subjectHistoryProvider =
    FutureProvider.autoDispose.family<List<SessionSummary>, String>((ref, subject) async {
  final uc = ref.watch(getSessionListUseCaseProvider);
  final all = await uc.execute(subject: subject);
  return all.where((s) => s.status == 'completed').toList();
});
