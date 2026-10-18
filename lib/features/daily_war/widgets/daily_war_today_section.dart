import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/home/providers/auth_providers.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_phase.dart';
import '../domain/daily_war_schedule.dart';
import '../providers/daily_war_providers.dart';
import '../providers/server_clock_provider.dart';
import '../../../l10n/l10n.dart';

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
    final accountSignedIn = AuthSession.isAccountSignedIn(
      ref.watch(authStateChangesProvider).asData?.value,
    );
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
    final info = isDark ? AppColors.infoTextDark : AppColors.infoText;
    final infoSoft = isDark ? AppColors.infoBgDark : AppColors.infoBg;

    final String eyebrow;
    final String headline;
    final String? cta;
    final VoidCallback? onCta;
    final IconData ctaIcon;
    final String subtext;

    if (snap.phase == DailyWarPhase.restDay) {
      eyebrow = context.l10n.dwSundayOff;
      headline = context.l10n.dwNoLivePaper;
      subtext = context.l10n.dwNextEventMonday(DailyWarCopy.dailyEventName);
      cta = null;
      onCta = null;
      ctaIcon = Icons.play_arrow_rounded;
    } else if (snap.submission != null) {
      eyebrow = DailyWarCopy.eventNameCaps(isGrand: isGrand);
      headline = topicsLine.isNotEmpty ? topicsLine : context.l10n.dwYouWereIn;
      subtext = snap.submission!.hasOfficialRank
          ? context.l10n.dwOpenRankExpl
          : context.l10n.dwAttemptInResultsFollow;
      cta = snap.submission!.hasOfficialRank
          ? context.l10n.dcaViewResults
          : context.l10n.dwOpenAttempt;
      onCta = onOpenResults;
      ctaIcon = Icons.replay_rounded;
    } else if (snap.phase == DailyWarPhase.lobby) {
      eyebrow = context.l10n.dwLobbyOpen;
      headline = topicsLine.isNotEmpty
          ? topicsLine
          : (isGrand
                ? context.l10n.dwEventLobbyOpen(DailyWarCopy.grandEventName)
                : context.l10n.dwEventLobbyOpen(DailyWarCopy.dailyEventName));
      subtext = context.l10n.dwPaperStarts9;
      cta = untilStart.isNegative
          ? context.l10n.dwStarting
          : context.l10n.dwStartsIn(
              DailyWarSchedule.formatCountdown(untilStart),
            );
      onCta = null;
      ctaIcon = Icons.schedule_rounded;
    } else if (snap.phase == DailyWarPhase.liveJoinable) {
      eyebrow = context.l10n.dwLiveNow;
      headline = topicsLine.isNotEmpty
          ? topicsLine
          : (isGrand
                ? '${DailyWarCopy.grandEventName}.'
                : '${DailyWarCopy.dailyEventName}.');
      subtext = context.l10n.dwLiveJoinBefore;
      cta = launching
          ? context.l10n.dwStarting
          : accountSignedIn
          ? context.l10n.dwJoinNow
          : context.l10n.dwSignInJoin;
      onCta = launching ? null : onJoinLive;
      ctaIcon = accountSignedIn
          ? Icons.play_arrow_rounded
          : Icons.login_rounded;
    } else if (snap.phase == DailyWarPhase.liveLocked) {
      eyebrow = context.l10n.dwInProgress;
      headline = topicsLine.isNotEmpty
          ? topicsLine
          : context.l10n.dwEventIsLive(
              DailyWarCopy.eventName(isGrand: isGrand),
            );
      subtext = context.l10n.dwEntryClosedRanks;
      cta = context.l10n.dwLateJoinClosed;
      onCta = null;
      ctaIcon = Icons.lock_outline_rounded;
    } else if (snap.phase == DailyWarPhase.resultsPending ||
        snap.phase == DailyWarPhase.resultsReady) {
      eyebrow = DailyWarCopy.eventNameCaps(isGrand: isGrand);
      headline = context.l10n.dwWindowClosed;
      subtext = context.l10n.dwStillUnranked;
      cta = launching
          ? context.l10n.dwStarting
          : accountSignedIn
          ? context.l10n.dwAttemptUnranked
          : context.l10n.dwSignInAttempt;
      onCta = launching ? null : onAttemptUnranked;
      ctaIcon = accountSignedIn
          ? Icons.play_arrow_rounded
          : Icons.login_rounded;
    } else {
      eyebrow = isGrand
          ? context.l10n.dwEventTonight(DailyWarCopy.grandEventNameCaps)
          : DailyWarCopy.dailyEventNameCaps;
      headline = topicsLine.isNotEmpty
          ? topicsLine
          : (isGrand
                ? context.l10n.dwWeekRevision
                : context.l10n.dwLobbyOpens859);
      subtext = isGrand
          ? context.l10n.dwSatEventStarts(DailyWarCopy.grandEventName)
          : context.l10n.dwEventStarts(DailyWarCopy.dailyEventName);
      cta = untilStart.isNegative
          ? context.l10n.dwStarting
          : context.l10n.dwStartsIn(
              DailyWarSchedule.formatCountdown(untilStart),
            );
      onCta = null;
      ctaIcon = Icons.schedule_rounded;
    }

    final waitingForTonightStart =
        snap.phase == DailyWarPhase.lobby ||
        snap.phase == DailyWarPhase.morning ||
        snap.phase == DailyWarPhase.countdown ||
        snap.phase == DailyWarPhase.preAnnounce;

    final nextStart =
        (!untilStart.isNegative && snap.phase != DailyWarPhase.restDay)
        ? start
        : DailyWarSchedule.startAtForDate(DailyWarSchedule.nextWarDate(ist));
    final untilNext = nextStart.difference(ist);
    final nextIsTonight =
        DailyWarSchedule.dateOnly(nextStart) == DailyWarSchedule.dateOnly(ist);
    final nextIsGrand = nextStart.weekday == DateTime.saturday;
    final nextEvent = DailyWarCopy.eventName(isGrand: nextIsGrand);
    final footerLabel = nextIsTonight
        ? context.l10n.dwFooterTonight(nextEvent)
        : nextStart.weekday == DateTime.monday
        ? context.l10n.dwFooterMonday(nextEvent)
        : context.l10n.dwFooterNext(nextEvent);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray900.withValues(alpha: isDark ? 0.35 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: info,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isGrand
                        ? Icons.workspace_premium_rounded
                        : Icons.bolt_rounded,
                    size: 13,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  eyebrow,
                  style: AppTextStyles.caption().copyWith(
                    color: info,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              headline,
              style: AppTextStyles.h2().copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: info,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtext,
              style: AppTextStyles.caption().copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (cta != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: launching ? null : onCta,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.45,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: launching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onPrimary,
                          ),
                        )
                      : Icon(ctaIcon, size: 20),
                  label: Text(
                    cta,
                    style: AppTextStyles.label().copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
            if (!waitingForTonightStart) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      footerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: infoSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      DailyWarSchedule.formatCountdown(
                        untilNext.isNegative ? Duration.zero : untilNext,
                      ),
                      style: AppTextStyles.caption().copyWith(
                        color: info,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
