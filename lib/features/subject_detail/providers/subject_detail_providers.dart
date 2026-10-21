import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/accuracy_rules.dart';
import '../../../core/domain/entities/subject_info.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../practice_tests/providers/practice_catalog_provider.dart';
import '../data/subject_topic_danger.dart';

/// SubjectInfo for a single subject, derived from the cached subject list.
final subjectInfoProvider = FutureProvider.autoDispose
    .family<SubjectInfo?, String>((ref, subject) async {
      final subjects = await ref.watch(subjectTestListProvider.future);
      try {
        return subjects.firstWhere((s) => s.subject == subject);
      } catch (_) {
        return null;
      }
    });

/// Topics for a subject enriched with the user's attempt stats.
/// Language-aware: uses [topicTestTopicsProvider] which honours the app language.
final subjectTopicsProvider = FutureProvider.autoDispose
    .family<List<TopicInfo>, String>((ref, subject) async {
      final rawTopics = await ref.watch(
        topicTestTopicsProvider(subject).future,
      );
      final db = ref.watch(userDatabaseProvider);
      final dangerByTopic = await fetchSubjectTopicDanger(db, subject);

      final statsRows = await db.userTopicStatsDao.fetchBySubject(subject);
      final statsByTopic = {for (final row in statsRows) row.topic: row};

      final enriched = rawTopics.map((topic) {
        final stat = statsByTopic[topic.topic];
        final d = dangerByTopic[topic.topic];
        final fromUser = stat?.totalAttempted ?? 0;
        final attemptCount = fromUser > 0 ? fromUser : topic.attemptCount;
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
          dangerSureWrong: d?.sure ?? 0,
          dangerEducatedGuessWrong: d?.guess ?? 0,
        );
      }).toList();

      // Stable baseline order; [TopicsListScreen] applies [TopicListSortMode].
      enriched.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

      return enriched;
    });

/// Sure and educated-guess wrongs this season, keyed by English topic name.
final seasonTopicDangerProvider = FutureProvider.autoDispose
    .family<Map<String, ({int sure, int guess})>, String>((ref, subject) async {
      final catalog = await ref.watch(practiceCatalogProvider.future);
      final db = ref.watch(userDatabaseProvider);
      return fetchSeasonTopicDanger(db, subject, catalog.season.start);
    });

/// Completed session count for a subject (subject hub card).
final subjectCompletedSessionCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, subject) async {
      final repo = ref.watch(sessionHistoryRepositoryProvider);
      return repo.countCompletedSessionsForSubject(subject);
    });
