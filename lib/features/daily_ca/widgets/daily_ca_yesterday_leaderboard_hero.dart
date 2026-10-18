import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/auth/ensure_account_sign_in.dart';
import '../../../shared/widgets/locked_leaderboard_scrim.dart';
import '../../community/widgets/admin_bot_label.dart';
import '../../home/providers/auth_providers.dart';
import '../daily_ca_admin_constants.dart';
import '../domain/daily_ca_rank_models.dart';
import '../domain/daily_ca_schedule.dart';
import '../domain/daily_ca_scoring.dart';
import '../providers/daily_ca_providers.dart';
import '../../../l10n/l10n.dart';

/// Compact podium for the CA hub: today's live board, else yesterday's.
class DailyCaYesterdayLeaderboardHero extends ConsumerWidget {
  const DailyCaYesterdayLeaderboardHero({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(dailyCaHubHeroBoardProvider);
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final accountSignedIn = AuthSession.isAccountSignedIn(user);
    final myUid = user?.uid ?? '';

    Future<void> signInForBoard() async {
      final ok = await ensureAccountSignedIn(
        context: context,
        ref: ref,
        reason: context.l10n.dcaSignInLeaderboard,
      );
      if (!ok) return;
      ref.invalidate(dailyCaHubHeroBoardProvider);
    }

    return boardAsync.maybeWhen(
      data: (board) {
        if (board == null || board.dateId.isEmpty) {
          return const SizedBox.shrink();
        }
        final mine = accountSignedIn
            ? ref.watch(dailyCaMySubmissionProvider(board.dateId)).asData?.value
            : null;
        return Padding(
          padding: EdgeInsets.only(
            bottom: compact ? AppSpacing.sm : AppSpacing.md,
          ),
          child: _HeroCard(
            lb: board.lb,
            dateId: board.dateId,
            isToday: board.isToday,
            myUid: myUid,
            myAir: mine?.air,
            compact: compact,
            locked: !accountSignedIn,
            onSignIn: () => unawaited(signInForBoard()),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.lb,
    required this.dateId,
    required this.isToday,
    required this.myUid,
    required this.compact,
    required this.locked,
    this.myAir,
    this.onSignIn,
  });

  final DailyCaLeaderboard? lb;
  final String dateId;
  final bool isToday;
  final String myUid;
  final int? myAir;
  final bool compact;
  final bool locked;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.infoBgDark : AppColors.infoText;
    final top = lb?.top ?? const <DailyCaLeaderboardEntry>[];
    final podium = top.take(3).toList();
    final first = podium.isNotEmpty ? podium[0] : null;
    final second = podium.length > 1 ? podium[1] : null;
    final third = podium.length > 2 ? podium[2] : null;
    final qCount = lb?.questionCount ?? 0;
    final count = (lb?.participantCount ?? 0) > 0
        ? lb!.participantCount
        : top.length;
    final empty = top.isEmpty;
    final frozen = lb?.isFrozen ?? false;

    DateTime? contentDate;
    try {
      if (dateId.isNotEmpty) contentDate = DateTime.parse(dateId);
    } on Object {
      contentDate = null;
    }
    final quizMorning = contentDate == null
        ? null
        : DailyCaSchedule.quizMorningDate(contentDate);
    final dateLabel = quizMorning == null
        ? dateId
        : DateFormat('d MMM').format(quizMorning);
    final eyebrow = isToday
        ? context.l10n.dcaEyebrowToday
        : (quizMorning == null
              ? context.l10n.dcaEyebrowYesterday
              : DateFormat('d MMM').format(quizMorning).toUpperCase());

    int? resolvedAir = myAir;
    if (resolvedAir == null && !locked && myUid.isNotEmpty) {
      for (final e in top) {
        if (e.uid == myUid) {
          resolvedAir = e.air;
          break;
        }
      }
    }

    final statusLine = empty
        ? (isToday
              ? context.l10n.dcaLiveFirst
              : context.l10n.dcaNoChampionYet(dateLabel))
        : isToday
        ? (frozen
              ? context.l10n.dcaJoinedLocked(dateLabel, count)
              : context.l10n.dcaJoinedLive(dateLabel, count))
        : context.l10n.dcaJoinedLocked(dateLabel, count);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: locked
                ? onSignIn
                : (empty
                      ? null
                      : () => context.push(dailyCaLeaderboardRoute(dateId))),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? AppSpacing.md : AppSpacing.lg,
                compact ? AppSpacing.sm : AppSpacing.md,
                compact ? AppSpacing.md : AppSpacing.lg,
                compact ? AppSpacing.md : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    eyebrow,
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.onPrimary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLine,
                    style: AppTextStyles.bodySm().copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _Seat(
                          place: 2,
                          entry: second,
                          questionCount: qCount,
                          highlight: second?.uid == myUid,
                          compact: compact,
                        ),
                      ),
                      Expanded(
                        child: _Seat(
                          place: 1,
                          entry: first,
                          questionCount: qCount,
                          highlight: first?.uid == myUid,
                          tall: true,
                          compact: compact,
                        ),
                      ),
                      Expanded(
                        child: _Seat(
                          place: 3,
                          entry: third,
                          questionCount: qCount,
                          highlight: third?.uid == myUid,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                  if (resolvedAir != null) ...[
                    SizedBox(height: compact ? 8 : 10),
                    Text(
                      context.l10n.dcaYouAir(resolvedAir),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSm().copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                  if (!locked && !empty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        context.l10n.dcaSeeAllRanks,
                        style: AppTextStyles.labelSm().copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    )
                  else if (!locked && isToday && empty)
                    Text(
                      context.l10n.dcaFinishToAppear,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption().copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.75),
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
    required this.place,
    required this.entry,
    required this.questionCount,
    required this.highlight,
    required this.compact,
    this.tall = false,
  });

  final int place;
  final DailyCaLeaderboardEntry? entry;
  final int questionCount;
  final bool highlight;
  final bool compact;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final name = (entry?.displayName ?? '').trim();
    final label = name.isEmpty ? '—' : name;
    final maxPts = DailyCaScoring.maxPoints(questionCount);
    final radius = compact ? (tall ? 22.0 : 18.0) : (tall ? 26.0 : 20.0);
    return Column(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: highlight
              ? AppColors.primary
              : AppColors.onPrimary.withValues(alpha: 0.15),
          child: Text(
            '$place',
            style: AppTextStyles.h3().copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: tall ? 20 : 16,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (entry != null) AdminBotLabel(uid: entry!.uid),
          ],
        ),
        if (entry != null)
          Text(
            entry!.score.toStringAsFixed(1) +
                (maxPts > 0 ? '/${maxPts.toStringAsFixed(0)}' : ''),
            style: AppTextStyles.caption().copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}
