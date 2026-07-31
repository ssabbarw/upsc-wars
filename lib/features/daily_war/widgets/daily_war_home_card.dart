import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/constants/subject_constants.dart';
import '../../../core/providers/kill_switch_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';

/// Home hero for Daily War — phase-driven copy. CTAs wire up in later phases.
class DailyWarHomeCard extends HookConsumerWidget {
  const DailyWarHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(dailyWarRemoteEnabledProvider);
    return enabled.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (on) {
        if (!on) return const SizedBox.shrink();
        return const _DailyWarHomeCardBody();
      },
    );
  }
}

class _DailyWarHomeCardBody extends HookConsumerWidget {
  const _DailyWarHomeCardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tick local UI every second; offset comes from server clock provider.
    final tick = useState(0);
    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (_) {
        tick.value++;
      });
      return t.cancel;
    }, const []);

    // Depend on tick so countdown refreshes.
    tick.value;
    final snap = ref.watch(dailyWarHomeSnapshotProvider);
    final offset =
        ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0;
    final utc = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch + offset,
      isUtc: true,
    );
    final ist = DailyWarSchedule.nowIst(utc);
    final warDate = DailyWarSchedule.warDateFor(ist);
    final start = DailyWarSchedule.startAtForDate(warDate);
    final remaining = start.difference(ist);

    final title = snap.doc?.isGrand == true ? 'Grand War' : 'Daily War';
    final topicsLine = _topicsLine(snap.doc);
    final phaseLine = _phaseLine(snap.phase, remaining, snap);
    final accent = _accentForPhase(snap.phase, isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => context.push(dailyWarLobbyRoute()),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Color.lerp(
                scheme.surfaceContainerLow,
                accent,
                isDark ? 0.18 : 0.10,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: accent.withValues(alpha: isDark ? 0.55 : 0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      title.toUpperCase(),
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '9:00 PM IST',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  topicsLine,
                  style: AppTextStyles.h3().copyWith(
                    color: scheme.onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  phaseLine,
                  style: AppTextStyles.bodySm().copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (snap.submission?.hasOfficialRank == true) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your AIR ${snap.submission!.air}',
                    style: AppTextStyles.label().copyWith(color: accent),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _topicsLine(DailyWarDoc? doc) {
    if (doc == null || doc.topics.isEmpty) {
      return 'Tonight\'s topics loading…';
    }
    final subjects = <String>{};
    final topicNames = <String>[];
    for (final t in doc.topics) {
      subjects.add(
        SubjectConstants.bySlug(t.subjectSlug)?.displayName ?? t.subjectSlug,
      );
      topicNames.add(t.topic);
    }
    final subjectPart = subjects.join(' + ');
    final topicsPart = topicNames.join(' + ');
    return '$subjectPart — $topicsPart';
  }

  String _phaseLine(
    DailyWarPhase phase,
    Duration untilStart,
    DailyWarHomeSnapshot snap,
  ) {
    final q = snap.doc?.questionCount ??
        DailyWarSchedule.questionCountForDate(snap.istNow);
    switch (phase) {
      case DailyWarPhase.preAnnounce:
        return 'War day starts at 6 AM · $q questions';
      case DailyWarPhase.morning:
        return 'Prepare these topics · War at 9 PM · $q Q';
      case DailyWarPhase.countdown:
        return 'Starts in ${DailyWarSchedule.formatCountdown(untilStart)} · $q Q';
      case DailyWarPhase.lobby:
        return 'Lobby open · Enter before 9:00';
      case DailyWarPhase.liveJoinable:
        return 'War is LIVE — you can still join';
      case DailyWarPhase.liveLocked:
        return 'In progress · Results after 9:20';
      case DailyWarPhase.resultsPending:
        return 'Calculating All-India Ranks…';
      case DailyWarPhase.resultsReady:
        if (snap.submission?.hasOfficialRank == true) {
          return 'Results ready · tap for full review';
        }
        if (snap.submission != null) {
          return 'Practiced · tap to review';
        }
        return 'Results ready · attempt unranked from History';
    }
  }

  Color _accentForPhase(DailyWarPhase phase, bool isDark) {
    switch (phase) {
      case DailyWarPhase.lobby:
      case DailyWarPhase.liveJoinable:
      case DailyWarPhase.liveLocked:
        return const Color(0xFFDC2626); // live red
      case DailyWarPhase.resultsReady:
        return AppColors.correct;
      case DailyWarPhase.resultsPending:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
