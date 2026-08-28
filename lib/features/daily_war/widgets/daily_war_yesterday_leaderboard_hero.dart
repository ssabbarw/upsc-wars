import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
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
class DailyWarYesterdayLeaderboardHero extends ConsumerWidget {
  const DailyWarYesterdayLeaderboardHero({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateId = ref.watch(dailyWarYesterdayDateIdProvider);
    final yesterdayDate = DailyWarSchedule.parseIsoDate(dateId);
    final minDate = DailyWarSchedule.dateOnly(DailyWarSchedule.calendarMinDate);
    if (yesterdayDate.isBefore(minDate)) return const SizedBox.shrink();

    final docAsync = ref.watch(dailyWarYesterdayDocProvider);
    return docAsync.when(
      loading: () => const _HeroShimmer(),
      error: (_, _) => const SizedBox.shrink(),
      data: (doc) {
        if (doc == null || !doc.ranksReady) return const SizedBox.shrink();
        return _ArchiveHero(dateId: dateId);
      },
    );
  }
}

class _ArchiveHero extends ConsumerWidget {
  const _ArchiveHero({required this.dateId});

  final String dateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(dailyWarArchiveProvider(dateId));
    final myUid = ref.watch(authStateChangesProvider).asData?.value?.uid ?? '';

    return archiveAsync.when(
      loading: () => const _HeroShimmer(),
      error: (_, _) => const SizedBox.shrink(),
      data: (archive) {
        final lb = archive.leaderboard;
        if (lb == null || lb.top.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _HeroCard(
            lb: lb,
            war: archive.war,
            dateId: dateId,
            myUid: myUid,
            mySubmission: archive.submission,
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.lb,
    required this.war,
    required this.dateId,
    required this.myUid,
    required this.mySubmission,
  });

  final DailyWarLeaderboard lb;
  final DailyWarDoc war;
  final String dateId;
  final String myUid;
  final DailyWarSubmission? mySubmission;

  @override
  Widget build(BuildContext context) {
    DailyWarLeaderboardEntry? at(int air) {
      for (final e in lb.top.take(3)) {
        if (e.air == air) return e;
      }
      return lb.top.length >= air ? lb.top[air - 1] : null;
    }

    final first = at(1);
    final second = at(2);
    final third = at(3);
    final qCount = war.questionCount > 0
        ? war.questionCount
        : DailyWarSchedule.questionCountForDate(
            DailyWarSchedule.parseIsoDate(dateId),
          );
    final maxPts = qCount * 2;
    final count = lb.participantCount > 0 ? lb.participantCount : lb.top.length;
    final isGrand = war.isGrand;

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
    if (myUid.isNotEmpty) {
      for (final e in lb.top) {
        if (e.uid == myUid) {
          myAir = e.air;
          break;
        }
      }
      myAir ??= mySubmission?.hasOfficialRank == true
          ? mySubmission!.air
          : null;
    }

    return Material(
      color: const Color(0xFF1A3A32),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(dailyWarLeaderboardRoute(dateId)),
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
                    'LAST NIGHT',
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
                '$count joined',
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
              ),
            ],
          ),
        ),
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
    if (entry == null) {
      return SizedBox(height: size + 40);
    }
    final e = entry!;
    final border = switch (place) {
      1 => DwColors.gold,
      2 => const Color(0xFFB8B8B8),
      _ => const Color(0xFFCD7F32),
    };
    final name = e.displayName.isEmpty ? 'Warrior' : e.displayName;
    final isMe = e.uid == myUid;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (medal)
          const Icon(
            Icons.workspace_premium_rounded,
            color: DwColors.gold,
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
              color: isMe ? AppColors.primary : border,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$place',
            style: DwText.dm(
              size: size * 0.38,
              weight: FontWeight.w800,
              color: border,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DwText.dm(size: 12, weight: FontWeight.w700),
              ),
            ),
            AdminBotLabel(uid: e.uid),
          ],
        ),
        Text(
          '${_fmt(e.score)} / $maxPts',
          style: DwText.dm(
            size: 11,
            weight: FontWeight.w600,
            color: DwColors.onDarkMuted,
          ),
        ),
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
