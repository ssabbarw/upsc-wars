import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../daily_war_constants.dart';
import '../providers/daily_war_providers.dart';
import 'daily_war_models.dart';
import 'daily_war_schedule.dart';

/// Starts a live or unranked Daily War paper and opens the test flow.
///
/// Requires a real (non-anonymous) account before the paper opens so submit
/// cannot fail mid-attempt for guests.
Future<void> startDailyWarAttempt({
  required BuildContext context,
  required WidgetRef ref,
  required DailyWarDoc doc,
  required bool unranked,
  required DateTime istNow,
}) async {
  if (doc.questionUuids.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          unranked
              ? 'Paper not available yet.'
              : 'Questions publish just before 9 PM. Try again shortly.',
        ),
      ),
    );
    return;
  }

  final signedIn = await ensureAccountSignedIn(
    context: context,
    ref: ref,
    reason: unranked
        ? 'Sign in to attempt this War.'
        : 'Sign in to join tonight\'s War.',
  );
  if (!signedIn || !context.mounted) return;

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null || uid.isEmpty) return;

  // Account may have changed (anonymous → Google); refresh tonight's attempt.
  if (doc.dateId == ref.read(dailyWarTodayDateIdProvider)) {
    await ref.read(dailyWarTodaySubmissionProvider.notifier).refresh();
  }

  final cache = await ref.read(dailyWarLocalCacheProvider.future);
  final existing = cache.getSubmission(uid, doc.dateId) ??
      (doc.dateId == ref.read(dailyWarTodayDateIdProvider)
          ? ref.read(dailyWarTodaySubmissionProvider).asData?.value
          : null);
  if (existing != null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing.isLive
              ? 'You already submitted this War.'
              : 'You already practiced this War.',
        ),
      ),
    );
    return;
  }

  final warDate = DailyWarSchedule.parseIsoDate(doc.dateId);
  final start = DailyWarSchedule.startAtForDate(warDate);
  if (!unranked && istNow.isBefore(start)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Battle starts at 9:00 PM IST · '
          '${DailyWarSchedule.formatCountdown(start.difference(istNow))} left.',
        ),
      ),
    );
    return;
  }

  final qCount = doc.questionCount < 1
      ? DailyWarSchedule.questionCountForDate(warDate)
      : doc.questionCount;
  final windowSecs = DailyWarSchedule.liveWindowMinutesFor(qCount) * 60;
  final liveEnd = DailyWarSchedule.liveEndsAt(warDate, questionCount: qCount);
  final remainingSecs = unranked
      ? windowSecs
      : liveEnd.difference(istNow).inSeconds.clamp(60, windowSecs);

  try {
    final create = await ref.read(createSessionUseCaseProvider.future);
    final lang = await ref.read(appLanguageProvider.future);
    final sessionId = await create.execute(
      SessionConfig(
        subject: DailyWarConstants.sessionSubject,
        topic: doc.dateId,
        mode: 'exam',
        questionCount: doc.questionUuids.length,
        isTimed: true,
        timeLimitSecs: remainingSecs,
        language: lang,
        specificQuestionUuids: doc.questionUuids,
        analyticsFeatureKey: unranked
            ? DailyWarConstants.analyticsUnranked
            : DailyWarConstants.analyticsLive,
      ),
    );
    unawaited(
      Analytics.track(
        ref,
        DailyWarAttemptedEvent(
          dateId: doc.dateId,
          mode: unranked ? 'unranked' : 'live',
          isGrand: doc.isGrand,
        ),
      ),
    );
    if (!context.mounted) return;
    context.go('/test/$sessionId');
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not start War: $e')));
  }
}
