import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/question_source_constants.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../providers/test_series_providers.dart';
import 'series_stats.dart';
import 'test_series_models.dart';

/// Opens an untimed, unscored read-through of the questions the user already
/// met in this series on one topic.
///
/// Only tests the user has completed contribute questions, so nothing from a
/// locked or unattempted test is revealed. The session uses the app's
/// existing learning mode (pick an option, then see the explanation) and the
/// `test_series_practice` analytics key with no `series_id`, so it never
/// touches series stats.
Future<void> startSeriesTopicRevision({
  required BuildContext context,
  required WidgetRef ref,
  required SeriesBundle bundle,
  required Set<String> kinds,
  required String subjectId,
  required String topic,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final local = ref.read(seriesLocalRepositoryProvider);
    final testIds = {
      for (final t in bundle.tests)
        if (kinds.contains(t.kind)) t.id,
    };
    final answers = await local.questionAnswers(bundle.info.id, testIds);
    final uuids = revisionQuestionUuids(
      answers,
      subjectId: subjectId,
      topic: topic,
    );
    if (uuids.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No questions to revise for this topic yet.')),
      );
      return;
    }
    if (!context.mounted) return;

    final create = await ref.read(createSessionUseCaseProvider.future);
    final language = await ref.read(appLanguageProvider.future);
    final sessionId = await create.execute(
      SessionConfig(
        subject: QuestionSourceConstants.testSeriesSessionSubject,
        topic: topic,
        mode: 'learning',
        questionCount: uuids.length,
        isTimed: false,
        language: language,
        specificQuestionUuids: uuids,
        analyticsFeatureKey: QuestionSourceConstants.analyticsTestSeriesPractice,
      ),
    );
    if (!context.mounted) return;
    await context.push('/test/$sessionId');
  } on Object {
    messenger.showSnackBar(
      const SnackBar(content: Text("Couldn't open this topic. Please try again.")),
    );
  }
}
