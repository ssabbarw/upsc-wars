import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/domain/entities/session_config.dart';
import '../../../core/providers/catalog_providers.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';

class DailyWarLobbyScreen extends HookConsumerWidget {
  const DailyWarLobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final snap = ref.watch(dailyWarHomeSnapshotProvider);
    final launching = useState(false);
    final tick = useState(0);

    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        tick.value++;
      });
      return t.cancel;
    }, const []);
    tick.value;

    final offset = ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0;
    final utc = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch + offset,
      isUtc: true,
    );
    final ist = DailyWarSchedule.nowIst(utc);
    final warDate = DailyWarSchedule.warDateFor(ist);
    final start = DailyWarSchedule.startAtForDate(warDate);
    final liveEnd = DailyWarSchedule.liveEndsAt(warDate);
    final untilStart = start.difference(ist);
    final canEnter = snap.phase == DailyWarPhase.lobby ||
        snap.phase == DailyWarPhase.liveJoinable;
    final alreadyDone = snap.submission != null;

    final topics = snap.doc?.topics ?? const [];
    final topicLines = topics
        .map((t) {
          final sub =
              SubjectConstants.bySlug(t.subjectSlug)?.displayName ??
              t.subjectSlug;
          return '$sub · ${t.topic}';
        })
        .toList();

    Future<void> enterWar({required bool unranked}) async {
      if (launching.value) return;
      final doc = snap.doc;
      if (doc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tonight\'s War is not ready yet.')),
        );
        return;
      }
      if (!unranked && doc.questionUuids.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questions publish just before 9 PM. Try again shortly.'),
          ),
        );
        return;
      }
      if (unranked && doc.questionUuids.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paper not available yet.')),
        );
        return;
      }

      launching.value = true;
      try {
        final create = await ref.read(createSessionUseCaseProvider.future);
        final lang = await ref.read(appLanguageProvider.future);
        final remainingSecs = unranked
            ? DailyWarSchedule.liveWindowMinutes * 60
            : liveEnd.difference(ist).inSeconds.clamp(60, 20 * 60);

        final sessionId = await create.execute(
          SessionConfig(
            subject: DailyWarConstants.sessionSubject,
            topic: snap.dateId,
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
        if (!context.mounted) return;
        context.go('/test/$sessionId');
      } on Object catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start War: $e')),
          );
        }
      } finally {
        launching.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          snap.doc?.isGrand == true ? 'Grand War' : 'Daily War',
          style: AppTextStyles.h3(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(dailyWarHistoryRoute()),
            child: const Text('History'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            snap.dateId,
            style: AppTextStyles.caption().copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...topicLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(line, style: AppTextStyles.h3()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  canEnter
                      ? (snap.phase == DailyWarPhase.lobby
                            ? 'Lobby open · starts in ${DailyWarSchedule.formatCountdown(untilStart)}'
                            : 'War is LIVE · join now')
                      : _statusCopy(snap.phase),
                  style: AppTextStyles.label(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${snap.doc?.questionCount ?? 15} questions · 20 min · −1/3 wrong · one live attempt',
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (alreadyDone)
            FilledButton(
              onPressed: () => context.push(dailyWarHistoryRoute()),
              child: Text(
                snap.submission?.hasOfficialRank == true
                    ? 'See your AIR ${snap.submission!.air}'
                    : 'Open History',
              ),
            )
          else if (canEnter)
            FilledButton(
              onPressed: launching.value
                  ? null
                  : () => unawaited(enterWar(unranked: false)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                minimumSize: const Size.fromHeight(48),
              ),
              child: launching.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('I\'m ready'),
            )
          else if (snap.phase == DailyWarPhase.resultsReady ||
              snap.phase == DailyWarPhase.resultsPending)
            OutlinedButton(
              onPressed: launching.value
                  ? null
                  : () => unawaited(enterWar(unranked: true)),
              child: const Text('Attempt unranked'),
            )
          else
            Text(
              'Come back at 8:45 PM IST to enter the lobby.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }

  String _statusCopy(DailyWarPhase phase) {
    switch (phase) {
      case DailyWarPhase.preAnnounce:
      case DailyWarPhase.morning:
      case DailyWarPhase.countdown:
        return 'Prepare today · lobby opens 8:45 PM';
      case DailyWarPhase.liveLocked:
        return 'Late join closed · results after 9:20';
      case DailyWarPhase.resultsPending:
        return 'Ranks calculating…';
      case DailyWarPhase.resultsReady:
        return 'Results ready';
      case DailyWarPhase.lobby:
      case DailyWarPhase.liveJoinable:
        return 'Ready';
    }
  }
}
