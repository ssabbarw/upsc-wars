import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/question_source_constants.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';
import '../providers/test_series_providers.dart';
import 'test_series_models.dart';
import '../../../l10n/l10n.dart';

/// Why a series test could not be opened.
class SeriesTestOpenException implements Exception {
  const SeriesTestOpenException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Makes sure every current-affairs question of [test] is in the local bank.
///
/// Static and PYQ questions ship with the app; CA questions are fetched day by
/// day (the same documents the Daily CA test uses) and cached.
Future<void> _ensureCaQuestionsCached(WidgetRef ref, SeriesTest test) async {
  final caRefs = test.questions.where((q) => q.isCa).toList();
  if (caRefs.isEmpty) return;

  final local = ref.read(seriesLocalRepositoryProvider);
  final present = await local.existingQuestionUuids(
    caRefs.map((q) => q.uuid).toList(),
  );
  final missingDates = <String>{
    for (final q in caRefs)
      if (!present.contains(q.uuid) && q.date != null) q.date!,
  }.toList()..sort();
  if (missingDates.isEmpty) return;

  final repo = ref.read(dailyCaRepositoryProvider);
  const parallel = 4;
  for (var i = 0; i < missingDates.length; i += parallel) {
    final batch = missingDates.skip(i).take(parallel);
    await Future.wait(batch.map(repo.ensureCachedForDate));
  }
}

/// Starts (or resumes) a scored attempt of [test], or an unscored practice
/// run when [practice] is true. Returns after the test screen closes.
///
/// Callers must have checked entitlement and unlock state already.
Future<void> startSeriesTest({
  required BuildContext context,
  required WidgetRef ref,
  required SeriesTest test,
  bool practice = false,
}) async {
  final seriesId = test.seriesId;
  final local = ref.read(seriesLocalRepositoryProvider);

  try {
    if (!practice) {
      // Resume an unfinished scored attempt instead of starting a second one.
      final inProgress = await local.inProgressSessions(seriesId);
      final resumeId = inProgress[test.id];
      if (resumeId != null) {
        if (!context.mounted) return;
        await context.push('/test/$resumeId');
        if (context.mounted) refreshSeriesLocalState(ref, seriesId);
        return;
      }
    }

    await _ensureCaQuestionsCached(ref, test);
    if (!context.mounted) return;

    final create = await ref.read(createSessionUseCaseProvider.future);
    final language = await ref.read(appLanguageProvider.future);
    final uuids = test.questions.map((q) => q.uuid).toList();

    final sessionId = await create.execute(
      SessionConfig(
        subject: QuestionSourceConstants.testSeriesSessionSubject,
        topic: test.id,
        // Scored attempts are timed exam papers. Practice is untimed learning
        // with explanations and never counts towards series stats.
        mode: practice ? 'learning' : 'exam',
        questionCount: uuids.length,
        isTimed: !practice,
        timeLimitSecs: practice ? null : test.durationMins * 60,
        language: language,
        specificQuestionUuids: uuids,
        requireAllSpecificUuids: true,
        analyticsFeatureKey: practice
            ? QuestionSourceConstants.analyticsTestSeriesPractice
            : QuestionSourceConstants.analyticsTestSeries,
        seriesId: practice ? null : seriesId,
        seriesTestId: practice ? null : test.id,
      ),
    );
    if (!context.mounted) return;
    await context.push('/test/$sessionId');
    if (context.mounted) refreshSeriesLocalState(ref, seriesId);
  } on MissingQuestionsException catch (e, st) {
    developer.log(
      'Series test ${test.id}: ${e.found}/${e.wanted} questions local',
      name: 'TestSeries',
      stackTrace: st,
    );
    throw SeriesTestOpenException(appL10n.tsMissingQs);
  }
}
