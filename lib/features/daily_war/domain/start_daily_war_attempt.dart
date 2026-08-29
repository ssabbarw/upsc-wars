import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../data/daily_war_firestore_paths.dart';
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
  var paper = doc;
  try {
    if (paper.questionUuids.isEmpty) {
      paper = await _latestPaper(ref: ref, doc: paper);
    }
    if (paper.questionUuids.isEmpty &&
        DailyWarSchedule.isOnOrAfterLobby(istNow)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      paper = await _latestPaper(ref: ref, doc: paper);
    }
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not load tonight\'s paper: $e')),
    );
    return;
  }
  if (!context.mounted) return;
  if (paper.questionUuids.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tonight\'s paper isn\'t loaded yet. Try again in some time.',
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

  final warDate = DailyWarSchedule.parseIsoDate(paper.dateId);
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

  final qCount = paper.questionCount < 1
      ? DailyWarSchedule.questionCountForDate(warDate)
      : paper.questionCount;
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
        questionCount: paper.questionUuids.length,
        isTimed: true,
        timeLimitSecs: remainingSecs,
        language: lang,
        specificQuestionUuids: paper.questionUuids,
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
          isGrand: paper.isGrand,
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

Future<DailyWarDoc> _latestPaper({
  required WidgetRef ref,
  required DailyWarDoc doc,
}) async {
  DailyWarDoc? fresh;
  try {
    fresh = await _fetchPublishedWar(doc.dateId);
  } on Object catch (e) {
    debugPrint('dailyWar latestPaper ${doc.dateId}: $e');
  }
  if (fresh == null) return doc;

  try {
    final cache = await ref.read(dailyWarLocalCacheProvider.future);
    await cache.putWar(fresh);
  } on Object catch (e) {
    debugPrint('dailyWar latestPaper cache: $e');
  }

  // Don't write the Riverpod doc during this tap — History/home watch it and
  // a sync notify can throw "markNeedsBuild during build".
  final todayId = ref.read(dailyWarTodayDateIdProvider);
  if (fresh.dateId == todayId) {
    final captured = fresh;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ref.read(dailyWarTodayDocProvider.notifier).applyFetched(captured);
      } on Object catch (e) {
        debugPrint('dailyWar latestPaper bind: $e');
      }
    });
  }
  return fresh;
}

Future<DailyWarDoc?> _fetchPublishedWar(String dateId) async {
  final warRef = DailyWarFirestorePaths.warDoc(dateId);
  DocumentSnapshot<Map<String, dynamic>> snap;
  try {
    snap = await warRef.get(const GetOptions(source: Source.server));
  } on Object {
    snap = await warRef.get();
  }
  if (!snap.exists || snap.data() == null) return null;
  return DailyWarDoc.fromMap(dateId, snap.data()!);
}
