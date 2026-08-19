import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../../community/widgets/admin_bot_label.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../domain/start_daily_war_attempt.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../theme/daily_war_theme.dart';

/// One War night: personal result, leaderboard teaser, revise entry.
///
/// Data comes from [dailyWarArchiveProvider] — Firebase once after ranks are
/// ready, then SharedPreferences forever.
Future<void> showDailyWarDaySheet({
  required BuildContext context,
  required String dateId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DismissOnScrimTap(
      child: DailyWarHistoryDetailScreen(dateId: dateId, asSheet: true),
    ),
  );
}

class DailyWarHistoryDetailScreen extends HookConsumerWidget {
  const DailyWarHistoryDetailScreen({
    super.key,
    required this.dateId,
    this.asSheet = false,
  });

  final String dateId;
  final bool asSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(dailyWarArchiveProvider(dateId));
    final snap = ref.watch(dailyWarHomeSnapshotProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final launching = useState(false);
    final scheme = Theme.of(context).colorScheme;

    final body = archiveAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '$e',
            style: AppTextStyles.body().copyWith(color: AppColors.wrong),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (archive) {
        final war = archive.war;
        final sub = archive.submission;
        final lb = archive.leaderboard;
        final subjects = DailyWarCopy.subjectsLine(war.topics);
        final topics = DailyWarCopy.topicsLine(war.topics);
        final isGrand = war.isGrand;
        final accent = isGrand ? DwColors.gold : DwColors.crimson;
        final canRevise = war.questionUuids.isNotEmpty;
        final isTonight = snap.dateId == dateId;
        final liveTonight =
            isTonight &&
            (snap.phase == DailyWarPhase.lobby ||
                snap.phase == DailyWarPhase.liveJoinable);
        final canAttempt = sub == null && war.questionsVisible;

        Future<void> startAttempt() async {
          if (launching.value) return;
          launching.value = true;
          try {
            final offset =
                ref.read(serverTimeOffsetMsProvider).asData?.value ?? 0;
            final ist = DailyWarSchedule.nowIst(
              DateTime.fromMillisecondsSinceEpoch(
                DateTime.now().millisecondsSinceEpoch + offset,
                isUtc: true,
              ),
            );
            await startDailyWarAttempt(
              context: context,
              ref: ref,
              doc: war,
              unranked: !liveTonight,
              istNow: ist,
            );
          } finally {
            launching.value = false;
          }
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    isGrand ? 'GRAND WAR' : 'DAILY WAR',
                    style: AppTextStyles.caption().copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DailyWarCopy.formatWarDate(war.dateId),
                  style: AppTextStyles.caption().copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (subjects.isNotEmpty) ...[
              Text(
                subjects,
                style: AppTextStyles.caption().copyWith(
                  fontWeight: FontWeight.w600,
                  color: DwColors.crimson,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              topics.isEmpty ? (isGrand ? 'Grand War' : 'Daily War') : topics,
              style: AppTextStyles.h1().copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                height: 1.2,
              ),
            ),
            if (archive.fromLocalOnly) ...[
              const SizedBox(height: 8),
              Text(
                'Saved on this device',
                style: AppTextStyles.caption().copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (canAttempt || (sub == null && !war.questionsVisible)) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: canAttempt && !launching.value
                      ? () => startAttempt()
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    launching.value
                        ? 'Starting…'
                        : !war.questionsVisible
                        ? 'Paper not published yet'
                        : liveTonight
                        ? 'Join now'
                        : 'Start this day\'s test',
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                      color: canAttempt
                          ? AppColors.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _MyResultCard(sub: sub, war: war),
            if (sub != null && canRevise) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () =>
                      context.push(dailyWarHistoryReviseRoute(dateId)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    'Revise this paper',
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'LEADERBOARD',
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            if (lb == null || lb.top.isEmpty)
              _LeaderboardPlaceholder(ranksReady: war.ranksReady)
            else
              _LeaderboardTeaser(
                lb: lb,
                dateId: dateId,
                myUid: myUid,
                myAir: sub?.air,
              ),
          ],
        );
      },
    );

    if (asSheet) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.sm,
          0,
          AppSpacing.sm,
          sheetBottomPadding(context, base: AppSpacing.sm),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.86,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('War archive')),
      body: body,
    );
  }
}

class _MyResultCard extends StatelessWidget {
  const _MyResultCard({required this.sub, required this.war});

  final DailyWarSubmission? sub;
  final DailyWarDoc war;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (sub == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR ATTEMPT',
              style: AppTextStyles.caption().copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Not attempted',
              style: AppTextStyles.h1().copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              war.ranksReady
                  ? '${war.participantCount ?? '—'} warriors that night'
                  : 'Start the test above to take this paper.',
              style: AppTextStyles.bodySm().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final airLabel = sub!.hasOfficialRank
        ? 'AIR ${sub!.air}'
        : sub!.mode == 'unranked'
        ? 'Practice'
        : 'Pending rank';
    final pct = sub!.percentile;
    final pctLabel = pct == null
        ? null
        : 'Better than ${pct.toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.infoBgDark : AppColors.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR ATTEMPT',
            style: AppTextStyles.caption().copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                airLabel,
                style: AppTextStyles.h1().copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${_fmtScore(sub!.score)} pts',
                  style: AppTextStyles.label().copyWith(
                    fontWeight: FontWeight.w700,
                    color: DwColors.crimson,
                  ),
                ),
              ),
              if (pctLabel != null) ...[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    pctLabel,
                    style: AppTextStyles.caption().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(
                label: 'Correct',
                value: '${sub!.correct}',
                color: AppColors.correct,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Wrong',
                value: '${sub!.wrong}',
                color: AppColors.wrong,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Skip',
                value: '${sub!.unanswered}',
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtScore(double s) {
    if (s == s.roundToDouble()) return '${s.toInt()}';
    return s.toStringAsFixed(2);
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.label().copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ghost podium + rows while ranks are still cooking (or empty after close).
class _LeaderboardPlaceholder extends StatelessWidget {
  const _LeaderboardPlaceholder({required this.ranksReady});

  final bool ranksReady;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _GhostPodium(height: 56, rank: 2, muted: muted)),
              const SizedBox(width: 8),
              Expanded(
                child: _GhostPodium(
                  height: 72,
                  rank: 1,
                  highlight: true,
                  muted: muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _GhostPodium(height: 48, rank: 3, muted: muted)),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _GhostRow(delayIndex: i, muted: muted),
          ],
          const SizedBox(height: 14),
          Text(
            ranksReady
                ? 'No ranked finishers yet'
                : 'Ranks land after the War closes · All-India board fills here',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostPodium extends StatelessWidget {
  const _GhostPodium({
    required this.height,
    required this.rank,
    required this.muted,
    this.highlight = false,
  });

  final double height;
  final int rank;
  final bool highlight;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = highlight ? DwColors.gold.withValues(alpha: 0.28) : muted;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: muted,
            border: Border.all(
              color: highlight ? DwColors.gold.withValues(alpha: 0.45) : muted,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: AppTextStyles.labelSm().copyWith(
              fontWeight: FontWeight.w800,
              color: highlight ? DwColors.gold : scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: muted,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
        ),
      ],
    );
  }
}

class _GhostRow extends StatelessWidget {
  const _GhostRow({required this.delayIndex, required this.muted});

  final int delayIndex;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final nameWidth = 120.0 - (delayIndex * 18);
    return Row(
      children: [
        Container(
          width: 28,
          height: 12,
          decoration: BoxDecoration(
            color: muted,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: nameWidth,
              height: 12,
              decoration: BoxDecoration(
                color: muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 36,
          height: 12,
          decoration: BoxDecoration(
            color: muted,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTeaser extends StatelessWidget {
  const _LeaderboardTeaser({
    required this.lb,
    required this.dateId,
    required this.myUid,
    required this.myAir,
  });

  final DailyWarLeaderboard lb;
  final String dateId;
  final String myUid;
  final int? myAir;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final preview = lb.top.take(3).toList();
    final hasMore = lb.participantCount > 3 || lb.top.length > 3;
    final count = lb.participantCount > 0 ? lb.participantCount : lb.top.length;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.isEmpty
                  ? 'Leaderboard'
                  : 'Top ${preview.length} of $count',
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final e in preview) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#${e.air}',
                        style: AppTextStyles.labelSm().copyWith(
                          fontWeight: FontWeight.w700,
                          color: e.air <= 3
                              ? DwColors.gold
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              e.uid == myUid
                                  ? '${e.displayName.isEmpty ? 'Warrior' : e.displayName} (you)'
                                  : (e.displayName.isEmpty
                                        ? 'Warrior'
                                        : e.displayName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm().copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          AdminBotLabel(uid: e.uid),
                        ],
                      ),
                    ),
                    Text(
                      _MyResultCard._fmtScore(e.score),
                      style: AppTextStyles.label().copyWith(
                        fontWeight: FontWeight.w700,
                        color: DwColors.crimson,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (myAir != null && !lb.top.any((e) => e.uid == myUid)) ...[
              const SizedBox(height: 4),
              Text(
                'You · AIR $myAir',
                style: AppTextStyles.labelSm().copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
            if (hasMore)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      context.push(dailyWarLeaderboardRoute(dateId)),
                  child: Text(
                    'See all $count',
                    style: AppTextStyles.labelSm().copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
