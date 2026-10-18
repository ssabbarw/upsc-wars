import 'dart:developer' as developer;

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/kill_switch_provider.dart';
import '../../daily_ca/domain/daily_ca_schedule.dart';
import '../../daily_ca/providers/daily_ca_providers.dart';
import '../domain/series_sample_question.dart';

/// The question behind "See an example" on the test series intro.
///
/// Tries the latest published Daily CA paper (yesterday's news) and picks its
/// best-explained question. Never fails: when current affairs is switched off,
/// not published, offline, or has nothing rich enough, it returns
/// [SeriesSampleQuestion.fallback].
final seriesSampleQuestionProvider =
    FutureProvider.autoDispose<SeriesSampleQuestion>((ref) async {
      try {
        final enabled = await ref.watch(dailyCaRemoteEnabledProvider.future);
        if (!enabled) return SeriesSampleQuestion.fallback;

        final now = DailyCaSchedule.nowIst();
        final date =
            DailyCaSchedule.paperQuizContentDate(referenceIst: now) ??
            DailyCaSchedule.previousPaperQuizContentDate(referenceIst: now);
        if (date == null) return SeriesSampleQuestion.fallback;

        final doc = await ref
            .watch(dailyCaRepositoryProvider)
            .fetchDay(DailyCaSchedule.formatIsoDate(date))
            .timeout(const Duration(seconds: 8));
        if (doc == null) return SeriesSampleQuestion.fallback;

        return SeriesSampleQuestion.pickFromDailyCa(doc.questions) ??
            SeriesSampleQuestion.fallback;
      } on Object catch (e) {
        developer.log(
          'Sample question fell back to GS: $e',
          name: 'TestSeries',
        );
        return SeriesSampleQuestion.fallback;
      }
    });
