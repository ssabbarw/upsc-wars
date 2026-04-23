import 'package:hooks_riverpod/hooks_riverpod.dart' show FutureProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/accuracy_rules.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/user_database_provider.dart';
import '../../subject_detail/data/subject_topic_danger_last30.dart';
import '../domain/topic_list_filter.dart';

part 'topic_test_ui_providers.g.dart';

@Riverpod(keepAlive: true)
class TopicTestSelectedSubjectSlug extends _$TopicTestSelectedSubjectSlug {
  @override
  String build() => SubjectConstants.ordered.first.slug;

  void setSlug(String slug) => state = slug;
}

@Riverpod(keepAlive: true)
class TopicTestSearchQuery extends _$TopicTestSearchQuery {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

@riverpod
Future<List<TopicInfo>> topicTestDisplayedTopics(Ref ref) async {
  final subject = ref.watch(topicTestSelectedSubjectSlugProvider);
  final query = ref.watch(topicTestSearchQueryProvider);
  final raw = await ref.watch(topicTestTopicsProvider(subject).future);
  final filtered = TopicListFilter.filter(raw, query);
  final db = ref.watch(userDatabaseProvider);
  final dangerByTopic = await fetchSubjectTopicDangerLast30(db, subject);
  final statsRows = await db.userTopicStatsDao.fetchBySubject(subject);
  final statsByTopic = {for (final row in statsRows) row.topic: row};

  final merged = filtered
      .map((topic) {
        final stat = statsByTopic[topic.topic];
        final d = dangerByTopic[topic.topic];
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
          dangerSureWrongLast30: d?.sure ?? 0,
          dangerEducatedGuessWrongLast30: d?.guess ?? 0,
        );
      })
      .toList();

  merged.sort((a, b) {
    final aAttempted = a.attemptCount > 0;
    final bAttempted = b.attemptCount > 0;
    if (aAttempted != bAttempted) return aAttempted ? -1 : 1;

    if (!aAttempted && !bAttempted) {
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    }

    final aAccuracy = a.accuracyPercent ?? 0.0;
    final bAccuracy = b.accuracyPercent ?? 0.0;
    final byAccuracy = aAccuracy.compareTo(bAccuracy);
    if (byAccuracy != 0) return byAccuracy;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });

  return merged;
}

final topicRevisionQueueCountsByTopicProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      final subject = ref.watch(topicTestSelectedSubjectSlugProvider);
      final db = ref.watch(userDatabaseProvider);
      return db.revisionQueueDao.getActiveQueueCountByTopic(subject);
    });
