import 'package:upsc_wars/core/domain/entities/topic_info.dart';

/// Case-insensitive topic search (used from providers, not widget [build]).
abstract final class TopicListFilter {
  TopicListFilter._();

  static List<TopicInfo> filter(List<TopicInfo> topics, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return topics;
    return topics
        .where((t) => t.displayName.toLowerCase().contains(q))
        .toList();
  }
}
