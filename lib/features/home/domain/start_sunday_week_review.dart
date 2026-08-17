import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../domain/sunday_week_review.dart';
import '../providers/sunday_week_review_provider.dart';
import '../providers/today_hub_provider.dart';

/// Opens a learning session on this week's wrong answers.
Future<void> startSundayWeekReview({
  required BuildContext context,
  required WidgetRef ref,
  required List<String> uuids,
  VoidCallback? onFinished,
}) async {
  if (uuids.isEmpty) return;
  try {
    final create = await ref.read(createSessionUseCaseProvider.future);
    final prefs = await ref.read(prefsServiceProvider.future);
    final sessionId = await create.execute(
      SessionConfig(
        subject: SundayWeekReview.sessionSubject,
        mode: 'learning',
        questionCount: uuids.length,
        isTimed: false,
        timeLimitSecs: null,
        language: normalizeAppLanguage(prefs.language),
        specificQuestionUuids: uuids,
        analyticsFeatureKey: SundayWeekReview.analyticsKey,
      ),
    );
    if (!context.mounted) return;
    await context.push('/test/$sessionId');
    if (!context.mounted) return;
    ref.invalidate(sundayWeekReviewProvider);
    ref.invalidate(todayHubProvider);
    onFinished?.call();
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong. Please try again.'),
      ),
    );
  }
}
