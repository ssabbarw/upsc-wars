import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../theme/daily_war_theme.dart';

/// Tonight's War on the calendar hub — timer until 9 PM, then join.
class DailyWarTodaySection extends HookConsumerWidget {
  const DailyWarTodaySection({
    super.key,
    required this.launching,
    required this.onJoinLive,
    required this.onOpenResults,
    required this.onAttemptUnranked,
  });

  final bool launching;
  final VoidCallback onJoinLive;
  final VoidCallback onOpenResults;
  final VoidCallback onAttemptUnranked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = useState(0);
    useEffect(() {
      final t = Timer.periodic(const Duration(seconds: 1), (_) => tick.value++);
      return t.cancel;
    }, const []);
    tick.value;

    final snap = ref.watch(dailyWarHomeSnapshotProvider);
    final offset = ref.watch(serverTimeOffsetMsProvider).asData?.value ?? 0;
    final utc = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now().millisecondsSinceEpoch + offset,
      isUtc: true,
    );
    final ist = DailyWarSchedule.nowIst(utc);
    final warDate = DailyWarSchedule.parseIsoDate(snap.dateId);
    final start = DailyWarSchedule.startAtForDate(warDate);
    final untilStart = start.difference(ist);
    final isGrand = snap.doc?.isGrand == true;
    final topics = snap.doc?.topics ?? const [];
    final topicsLine = DailyWarCopy.topicsLine(topics, sep: ' · ');

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final accent = isGrand ? DwColors.gold : DwColors.crimsonBright;

    final String eyebrow;
    final String headline;
    final String? cta;
    final VoidCallback? onCta;
    final bool showTimer;

    if (snap.phase == DailyWarPhase.restDay) {
      eyebrow = 'SUNDAY OFF';
      headline = 'No live paper today. Next War is Monday at 9:00 PM IST.';
      cta = null;
      onCta = null;
      showTimer = false;
    } else if (snap.submission != null) {
      eyebrow = isGrand ? 'GRAND WAR' : 'DAILY WAR';
      headline = topicsLine.isNotEmpty
          ? topicsLine
          : 'You were in tonight\'s paper.';
      cta = snap.submission!.hasOfficialRank
          ? 'See your results'
          : 'Open your attempt';
      onCta = onOpenResults;
      showTimer = false;
    } else if (snap.phase == DailyWarPhase.lobby ||
        snap.phase == DailyWarPhase.liveJoinable) {
      eyebrow = 'LIVE NOW';
      headline = topicsLine.isNotEmpty
          ? topicsLine
          : (isGrand ? 'Grand War is live.' : 'Daily War is live.');
      cta = launching ? 'Starting…' : 'Join now';
      onCta = launching ? null : onJoinLive;
      showTimer = false;
    } else if (snap.phase == DailyWarPhase.resultsPending ||
        snap.phase == DailyWarPhase.resultsReady) {
      eyebrow = isGrand ? 'GRAND WAR' : 'DAILY WAR';
      headline = 'Tonight\'s live window has closed.';
      cta = launching ? 'Starting…' : 'Attempt unranked';
      onCta = launching ? null : onAttemptUnranked;
      showTimer = false;
    } else {
      eyebrow = isGrand ? 'GRAND WAR TONIGHT' : 'TONIGHT · 9:00 PM';
      headline = topicsLine.isNotEmpty
          ? topicsLine
          : (isGrand
                ? 'Week revision. Same paper, All-India.'
                : 'All-India live paper. Lobby opens at 8:59 PM.');
      cta = untilStart.isNegative ? 'Available soon' : null;
      onCta = null;
      showTimer = !untilStart.isNegative;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? DwColors.surface : DwColors.crimsonSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            eyebrow,
            style: AppTextStyles.caption().copyWith(
              color: accent,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            headline,
            style: AppTextStyles.bodySm().copyWith(
              color: isDark ? DwColors.onDark : scheme.onSurface,
              height: 1.35,
            ),
          ),
          if (showTimer) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              DailyWarSchedule.formatCountdown(untilStart),
              textAlign: TextAlign.center,
              style: AppTextStyles.h1().copyWith(
                color: isDark ? DwColors.onDark : scheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Until tonight\'s War',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (cta != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                backgroundColor: DwColors.crimson,
                foregroundColor: Colors.white,
              ),
              child: Text(cta),
            ),
          ],
        ],
      ),
    );
  }
}
