import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topics_subtopics_catalog_provider.g.dart';

/// `{ subject: { topic: [subtopic, ...] } }` from question-bank metadata.
typedef TopicsSubtopicsCatalog = Map<String, Map<String, List<String>>>;

/// Loads [TopicsSubtopicsCatalog] once from bundled JSON.
@Riverpod(keepAlive: true)
Future<TopicsSubtopicsCatalog> topicsSubtopicsCatalog(Ref ref) async {
  final raw =
      await rootBundle.loadString('assets/data/topics_and_subtopics.json');
  final decoded = json.decode(raw) as Map<String, dynamic>;
  return {
    for (final subjectEntry in decoded.entries)
      subjectEntry.key: {
        for (final topicEntry in (subjectEntry.value as Map<String, dynamic>)
            .entries)
          topicEntry.key: List<String>.from(topicEntry.value as List),
      },
  };
}
