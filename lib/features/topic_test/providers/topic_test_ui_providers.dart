import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/topic_info.dart';
import '../../../core/providers/catalog_providers.dart';
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
  return TopicListFilter.filter(raw, query);
}
