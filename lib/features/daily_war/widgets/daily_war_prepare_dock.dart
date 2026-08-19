import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../home/domain/create_daily_drill_session_use_case.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_phase.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';

/// Docked "STEP 2 · PREPARE" strip under the War hero (design WarBelowFold).
///
/// When Daily War RC is off, returns [SizedBox.shrink] so the home revision
/// queue can show instead.
class DailyWarPrepareDock extends HookConsumerWidget {
  const DailyWarPrepareDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(dailyWarRemoteEnabledProvider);
    return enabled.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (on) {
        if (!on) return const SizedBox.shrink();
        return const _PrepareDockBody();
      },
    );
  }
}

class _PrepareDockBody extends HookConsumerWidget {
  const _PrepareDockBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(dailyWarHomeSnapshotProvider);
    final loading = useState(false);

    // Hide dock once live / results take over the hero's primary job.
    final hide = snap.phase == DailyWarPhase.restDay ||
        snap.phase == DailyWarPhase.lobby ||
        snap.phase == DailyWarPhase.liveJoinable ||
        snap.phase == DailyWarPhase.liveLocked ||
        snap.phase == DailyWarPhase.resultsPending ||
        (snap.phase == DailyWarPhase.resultsReady &&
            snap.submission?.hasOfficialRank == true);
    if (hide) return const SizedBox.shrink();

    final topics = snap.doc?.topics ?? const [];
    final curriculumSlug =
        topics.isNotEmpty ? topics.first.subjectSlug : 'polity';
    final sessionSubject = DailyWarCopy.sessionSubjectSlug(curriculumSlug);
    final subjectName = DailyWarCopy.subjectDisplay(curriculumSlug);
    final topicHint = topics.isEmpty
        ? '10 quick MCQs on tonight\'s subject'
        : 'Tonight: ${DailyWarCopy.topicsLine(topics)}';

    Future<void> startPrepare() async {
      if (loading.value) return;
      loading.value = true;
      unawaited(
        Analytics.track(
          ref,
          DailyDrillStartedEvent(
            subject: sessionSubject,
            source: 'daily_war_prepare_dock',
            completedToday: false,
          ),
        ),
      );
      try {
        final uc =
            await ref.read(createDailyDrillSessionUseCaseProvider.future);
        final sessionId = await uc.execute(
          subject: sessionSubject,
          warTopics: topics,
        );
        if (!context.mounted) return;
        await context.push('/test/$sessionId');
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Something went wrong. Please try again.'),
            ),
          );
        }
      } finally {
        loading.value = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading.value ? null : () => unawaited(startPrepare()),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: DwColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1F000000)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP 2 · PREPARE',
                        style: DwText.dm(
                          size: 10,
                          weight: FontWeight.w700,
                          color: DwColors.crimson,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Daily Drill · $subjectName',
                        style: DwText.dm(
                          size: 14,
                          weight: FontWeight.w700,
                          color: DwColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topicHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DwText.dm(
                          size: 11,
                          color: DwColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading.value)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.chevron_right, color: DwColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
