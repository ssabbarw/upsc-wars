import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/constants/daily_drill_constants.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/app_language_helpers.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/providers/prefs_provider.dart';
import '../../daily_war/domain/daily_war_models.dart';
import '../providers/daily_drill_provider.dart';
import '../providers/today_hub_provider.dart';
import 'create_daily_drill_session_use_case.dart';
import 'daily_revision.dart';

/// Creates and opens a drill on tonight's War topics (or a subject fallback).
///
/// Used by the War explainer warm-up, not the afternoon revision card.
Future<void> startDailyDrill({
  required BuildContext context,
  required WidgetRef ref,
  required String subject,
  required String source,
  required bool completedToday,
  List<DailyWarTopicRef> warTopics = const [],
  VoidCallback? onFinished,
}) async {
  unawaited(
    Analytics.track(
      ref,
      DailyDrillStartedEvent(
        subject: subject,
        source: source,
        completedToday: completedToday,
        pool: 'fresh',
      ),
    ),
  );
  try {
    final uc = await ref.read(createDailyDrillSessionUseCaseProvider.future);
    final sessionId = await uc.execute(subject: subject, warTopics: warTopics);
    if (!context.mounted) return;
    await context.push('/test/$sessionId');
    if (!context.mounted) return;
    ref.invalidate(dailyDrillProvider);
    ref.invalidate(todayHubProvider);
    onFinished?.call();
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Something went wrong. Please try again.')),
    );
  }
}

/// Opens a learning session on missed or bookmarked questions.
Future<void> startRevisionDrill({
  required BuildContext context,
  required WidgetRef ref,
  required DailyRevisionPool pool,
  required List<String> uuids,
  required String source,
  required bool completedToday,
  VoidCallback? onFinished,
}) async {
  if (uuids.isEmpty) return;
  unawaited(
    Analytics.track(
      ref,
      DailyDrillStartedEvent(
        subject: DailyRevision.analyticsSubject(pool),
        source: source,
        completedToday: completedToday,
        pool: switch (pool) {
          DailyRevisionPool.missed => 'missed',
          DailyRevisionPool.saved => 'saved',
        },
      ),
    ),
  );
  try {
    final create = await ref.read(createSessionUseCaseProvider.future);
    final prefs = await ref.read(prefsServiceProvider.future);
    final sessionId = await create.execute(
      SessionConfig(
        subject: DailyRevision.sessionSubject,
        mode: 'learning',
        questionCount: uuids.length,
        isTimed: false,
        timeLimitSecs: null,
        language: normalizeAppLanguage(prefs.language),
        specificQuestionUuids: uuids,
        analyticsFeatureKey: DailyDrillConstants.analyticsKey,
      ),
    );
    if (!context.mounted) return;
    await context.push('/test/$sessionId');
    if (!context.mounted) return;
    ref.invalidate(dailyDrillProvider);
    ref.invalidate(todayHubProvider);
    onFinished?.call();
  } on Object {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Something went wrong. Please try again.')),
    );
  }
}
