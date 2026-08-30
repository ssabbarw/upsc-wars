import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../../../shared/widgets/locked_leaderboard_scrim.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../community/widgets/admin_bot_label.dart';
import '../../home/providers/auth_providers.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../domain/daily_war_schedule.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';

/// Podium for last night's War, above tonight's card on the hub.
///
/// Guests get a sign-in CTA instead of ranks; signed-in users see the frozen
/// board or an empty placeholder when that night never locked.
///
/// Which night it shows — and whether it shows at all — is
/// [dailyWarHubHeroDateIdProvider]: last night through the working day,
/// nothing through the evening build-up, tonight once ranks publish.
class DailyWarLeaderboardHero extends ConsumerWidget {
  const DailyWarLeaderboardHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateId = ref.watch(dailyWarHubHeroDateIdProvider);
    if (dateId == null) return const SizedBox.shrink();
    final heroDate = DailyWarSchedule.parseIsoDate(dateId);
    final minDate = DailyWarSchedule.dateOnly(DailyWarSchedule.calendarMinDate);
    if (heroDate.isBefore(minDate)) return const SizedBox.shrink();

    final todayDateId = ref.watch(dailyWarTodayDateIdProvider);
    final isTonight = dateId == todayDateId;
    // Sunday has no War, so Monday's hero reaches back to Saturday — say so
    // rather than calling a two-day-old board "last night".
    final daysAgo = DailyWarSchedule.parseIsoDate(
      todayDateId,
    ).difference(heroDate).inDays;
    final eyebrow = isTonight
        ? 'TONIGHT'
        : daysAgo <= 1
        ? 'LAST NIGHT'
        : 'LAST WAR';

    final user = ref.watch(authStateChangesProvider).asData?.value;
    final accountSignedIn = AuthSession.isAccountSignedIn(user);
    final myUid = user?.uid ?? '';

    Future<void> signInForBoard() async {
      final ok = await ensureAccountSignedIn(
        context: context,
        ref: ref,
        reason: 'Sign in to see the leaderboard.',
      );
      if (!ok) return;
      ref.invalidate(dailyWarArchiveProvider(dateId));
      if (isTonight) {
        await ref.read(dailyWarTodayDocProvider.notifier).refresh();
      } else {
        await ref.read(dailyWarYesterdayDocProvider.notifier).refresh();
      }
    }

    final docAsync = isTonight
        ? ref.watch(dailyWarTodayDocProvider)
        : ref.watch(dailyWarYesterdayDocProvider);
    return docAsync.when(
      loading: () => const _HeroShimmer(),
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _HeroCard(
          dateId: dateId,
          eyebrow: eyebrow,
          lb: null,
          war: null,
          myUid: myUid,
          mySubmission: null,
          locked: !accountSignedIn,
          onSignIn: () => unawaited(signInForBoard()),
        ),
      ),
      data: (doc) {
        if (doc == null || !doc.ranksReady) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _HeroCard(
              dateId: dateId,
              eyebrow: eyebrow,
              lb: null,
              war: doc,
              myUid: myUid,
              mySubmission: null,
              locked: !accountSignedIn,
              onSignIn: () => unawaited(signInForBoard()),
            ),
          );
        }
        return _ArchiveHero(
          dateId: dateId,
          eyebrow: eyebrow,
          myUid: myUid,
          war: doc,
          locked: !accountSignedIn,
          onSignIn: () => unawaited(signInForBoard()),
        );
      },
    );
  }
}

class _ArchiveHero extends ConsumerWidget {
  const _ArchiveHero({
    required this.dateId,
    required this.eyebrow,
    required this.myUid,
    required this.war,
    required this.locked,
    this.onSignIn,
  });

  final String dateId;
  final String eyebrow;
  final String myUid;
  final DailyWarDoc war;
  final bool locked;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(dailyWarArchiveProvider(dateId));

    return archiveAsync.when(
      loading: () => const _HeroShimmer(),
      error: (_, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _HeroCard(
          dateId: dateId,
          eyebrow: eyebrow,
          lb: null,
          war: war,
          myUid: myUid,
          mySubmission: null,
          locked: locked,
          onSignIn: onSignIn,
        ),
      ),
      data: (archive) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _HeroCard(
            dateId: dateId,
            eyebrow: eyebrow,
            lb: archive.leaderboard,
            war: archive.war,
            myUid: myUid,
            mySubmission: archive.submission,
            locked: locked,
            onSignIn: onSignIn,
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.dateId,
    required this.eyebrow,
    required this.lb,
    required this.war,
    required this.myUid,
    required this.mySubmission,
    required this.locked,
    this.onSignIn,
  });

  final String dateId;
  final String eyebrow;
  final DailyWarLeaderboard? lb;
  final DailyWarDoc? war;
  final String myUid;
  final DailyWarSubmission? mySubmission;
  final bool locked;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    DailyWarLeaderboardEntry? at(int air) {
      final top = lb?.top ?? const <DailyWarLeaderboardEntry>[];
      for (final e in top.take(3)) {
        if (e.air == air) return e;
      }
      return top.length >= air ? top[air - 1] : null;
    }

    final first = at(1);
    final second = at(2);
    final third = at(3);
    final qCount = war != null && war!.questionCount > 0
        ? war!.questionCount
        : DailyWarSchedule.questionCountForDate(
            DailyWarSchedule.parseIsoDate(dateId),
          );
    final maxPts = qCount * 2;
    final top = lb?.top ?? const <DailyWarLeaderboardEntry>[];
    final count = (lb?.participantCount ?? 0) > 0
        ? lb!.participantCount
        : top.length;
    final empty = top.isEmpty;
    final isGrand =
        war?.isGrand ??
        DailyWarSchedule.parseIsoDate(dateId).weekday == DateTime.saturday;

    DateTime? parsed;
    try {
      parsed = DateTime.parse(dateId);
    } on Object {
      parsed = null;
    }
    final dateLabel = parsed == null
        ? dateId
        : DateFormat('d MMM').format(parsed).toUpperCase();

    int? myAir;
    if (!locked && myUid.isNotEmpty) {
      for (final e in top) {
        if (e.uid == myUid) {
          myAir = e.air;
          break;
        }
      }
      myAir ??= mySubmission?.hasOfficialRank == true
          ? mySubmission!.air
          : null;
    }

    final String statusLine;
    if (empty) {
      statusLine = war == null || war!.ranksReady
          ? '$dateLabel · No champion locked yet'
          : '$dateLabel · Ranks lock after the paper closes';
    } else {
      statusLine = '$count joined';
    }

    return Material(
      color: const Color(0xFF1A3A32),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: locked
                ? onSignIn
                : (empty || dateId.isEmpty
                      ? null
                      : () => context.push(dailyWarLeaderboardRoute(dateId))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        eyebrow,
                        style: DwText.dm(
                          size: 11,
                          weight: FontWeight.w700,
                          color: DwColors.onDarkMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${DailyWarCopy.eventNameCaps(isGrand: isGrand)} · $dateLabel',
                        style: DwText.dm(
                          size: 11,
                          weight: FontWeight.w600,
                          color: DwColors.onDarkMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLine,
                    style: DwText.dm(
                      size: 13,
                      weight: FontWeight.w700,
                      color: DwColors.onDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _Seat(
                          entry: second,
                          place: 2,
                          maxPts: maxPts,
                          myUid: myUid,
                          size: 52,
                        ),
                      ),
                      Expanded(
                        child: _Seat(
                          entry: first,
                          place: 1,
                          maxPts: maxPts,
                          myUid: myUid,
                          size: 68,
                          medal: true,
                        ),
                      ),
                      Expanded(
                        child: _Seat(
                          entry: third,
                          place: 3,
                          maxPts: maxPts,
                          myUid: myUid,
                          size: 52,
                        ),
                      ),
                    ],
                  ),
                  if (myAir != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'You · AIR $myAir',
                      textAlign: TextAlign.center,
                      style: DwText.dm(
                        size: 12,
                        weight: FontWeight.w700,
                        color: DwColors.gold,
                      ),
                    ),
                  ],
                  if (!locked && !empty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'See board',
                        style: DwText.dm(
                          size: 12,
                          weight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (!locked)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        war == null || war!.ranksReady
                            ? 'No champion yet. Ranks land here after the paper locks.'
                            : "Tonight's paper is open. Ranks show here tomorrow.",
                        textAlign: TextAlign.center,
                        style: DwText.dm(
                          size: 12,
                          weight: FontWeight.w600,
                          color: DwColors.onDarkMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (locked) LockedLeaderboardScrim(onTap: onSignIn),
        ],
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({
    required this.entry,
    required this.place,
    required this.maxPts,
    required this.myUid,
    required this.size,
    this.medal = false,
  });

  final DailyWarLeaderboardEntry? entry;
  final int place;
  final int maxPts;
  final String myUid;
  final double size;
  final bool medal;

  @override
  Widget build(BuildContext context) {
    final border = switch (place) {
      1 => DwColors.gold,
      2 => const Color(0xFFB8B8B8),
      _ => const Color(0xFFCD7F32),
    };
    final name = (entry?.displayName ?? '').trim();
    final label = entry == null ? '—' : (name.isEmpty ? 'Warrior' : name);
    final isMe = entry != null && entry!.uid == myUid;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (medal)
          Icon(
            Icons.workspace_premium_rounded,
            color: entry == null
                ? DwColors.onDarkMuted.withValues(alpha: 0.45)
                : DwColors.gold,
            size: 18,
          )
        else
          const SizedBox(height: 18),
        const SizedBox(height: 4),
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF0F2924),
            border: Border.all(
              color: isMe
                  ? AppColors.primary
                  : border.withValues(alpha: entry == null ? 0.4 : 1),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$place',
            style: DwText.dm(
              size: size * 0.38,
              weight: FontWeight.w800,
              color: border.withValues(alpha: entry == null ? 0.45 : 1),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DwText.dm(
                  size: 12,
                  weight: FontWeight.w700,
                  color: entry == null ? DwColors.onDarkMuted : DwColors.onDark,
                ),
              ),
            ),
            if (entry != null) AdminBotLabel(uid: entry!.uid),
          ],
        ),
        if (entry != null)
          Text(
            '${_fmt(entry!.score)} / $maxPts',
            style: DwText.dm(
              size: 11,
              weight: FontWeight.w600,
              color: DwColors.onDarkMuted,
            ),
          )
        else
          const SizedBox(height: 15),
      ],
    );
  }

  static String _fmt(double s) =>
      s == s.roundToDouble() ? '${s.round()}' : s.toStringAsFixed(1);
}

class _HeroShimmer extends StatelessWidget {
  const _HeroShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: ShimmerBox(
        width: double.infinity,
        height: 196,
        borderRadius: AppRadius.xl,
      ),
    );
  }
}
