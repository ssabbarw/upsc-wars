import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../providers/daily_drill_provider.dart';
import 'create_daily_drill_session_use_case.dart';

/// Creates and opens a static-syllabus drill.
///
/// Shared by the Today hub hero, its compact row, and the notification tap so
/// every entry point reports the same analytics and refreshes the same state.
Future<void> startDailyDrill({
  required BuildContext context,
  required WidgetRef ref,
  required String subject,
  required String source,
  required bool completedToday,
  VoidCallback? onFinished,
}) async {
  unawaited(
    Analytics.track(
      ref,
      DailyDrillStartedEvent(
        subject: subject,
        source: source,
        completedToday: completedToday,
      ),
    ),
  );
  try {
    final uc = await ref.read(createDailyDrillSessionUseCaseProvider.future);
    final sessionId = await uc.execute(subject: subject);
    if (!context.mounted) return;
    await context.push('/test/$sessionId');
    if (!context.mounted) return;
    ref.invalidate(dailyDrillProvider);
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
