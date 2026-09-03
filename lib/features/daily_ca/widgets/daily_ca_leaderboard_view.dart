import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../community/widgets/admin_bot_label.dart';
import '../domain/daily_ca_rank_models.dart';
import '../domain/daily_ca_scoring.dart';

/// Top 100 snapshot plus a sticky "you" row when you are outside the list.
class DailyCaLeaderboardView extends StatelessWidget {
  const DailyCaLeaderboardView({
    super.key,
    required this.lb,
    required this.dateId,
    required this.myUid,
    required this.questionCount,
    this.mySubmission,
    this.isFrozen = false,
  });

  final DailyCaLeaderboard lb;
  final String dateId;
  final String myUid;
  final int questionCount;
  final DailyCaSubmission? mySubmission;
  final bool isFrozen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final top = lb.top;
    final podium = top.take(3).toList();
    final rest = top.length > 3
        ? top.sublist(3)
        : const <DailyCaLeaderboardEntry>[];

    DailyCaLeaderboardEntry? meEntry;
    for (final e in top) {
      if (e.uid == myUid) {
        meEntry = e;
        break;
      }
    }
    final meOutside =
        meEntry == null && mySubmission != null && mySubmission!.hasOfficialRank;

    DateTime? parsed;
    try {
      parsed = DateTime.parse(dateId);
    } on Object {
      parsed = null;
    }
    final dateLabel = parsed == null
        ? dateId
        : DateFormat('d MMM yyyy').format(parsed);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  dateLabel: dateLabel,
                  joined: lb.participantCount,
                  podium: podium,
                  questionCount: questionCount,
                  myUid: myUid,
                  isFrozen: isFrozen,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final e = rest[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RowCard(
                          entry: e,
                          questionCount: questionCount,
                          isMe: e.uid == myUid,
                        ),
                      );
                    },
                    childCount: rest.length,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (meOutside && mySubmission != null)
          Material(
            elevation: 8,
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _RowCard(
                  entry: DailyCaLeaderboardEntry(
                    uid: mySubmission!.uid,
                    displayName: mySubmission!.displayName ?? 'You',
                    score: mySubmission!.score,
                    elapsedMs: mySubmission!.elapsedMs,
                    air: mySubmission!.air ?? 0,
                    percentile: mySubmission!.percentile,
                    correct: mySubmission!.correct,
                    wrong: mySubmission!.wrong,
                    unanswered: mySubmission!.unanswered,
                    email: mySubmission!.email,
                  ),
                  questionCount: questionCount,
                  isMe: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.dateLabel,
    required this.joined,
    required this.podium,
    required this.questionCount,
    required this.myUid,
    required this.isFrozen,
  });

  final String dateLabel;
  final int joined;
  final List<DailyCaLeaderboardEntry> podium;
  final int questionCount;
  final String myUid;
  final bool isFrozen;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.infoBgDark : const Color(0xFF0C447C);
    final first = podium.isNotEmpty ? podium.first : null;
    final second = podium.length > 1 ? podium[1] : null;
    final third = podium.length > 2 ? podium[2] : null;

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Text(
            dateLabel.toUpperCase(),
            style: AppTextStyles.caption().copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$joined joined',
            style: AppTextStyles.bodySm().copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            isFrozen
                ? 'Champion is locked for this paper.'
                : 'Pull to refresh. Champion locks at 6 AM.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption().copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumSeat(
                  place: 2,
                  entry: second,
                  questionCount: questionCount,
                  highlight: second?.uid == myUid,
                ),
              ),
              Expanded(
                child: _PodiumSeat(
                  place: 1,
                  entry: first,
                  questionCount: questionCount,
                  highlight: first?.uid == myUid,
                  tall: true,
                ),
              ),
              Expanded(
                child: _PodiumSeat(
                  place: 3,
                  entry: third,
                  questionCount: questionCount,
                  highlight: third?.uid == myUid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumSeat extends StatelessWidget {
  const _PodiumSeat({
    required this.place,
    required this.entry,
    required this.questionCount,
    required this.highlight,
    this.tall = false,
  });

  final int place;
  final DailyCaLeaderboardEntry? entry;
  final int questionCount;
  final bool highlight;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    final medal = place == 1
        ? '1'
        : place == 2
        ? '2'
        : '3';
    final name = (entry?.displayName ?? '').trim();
    final label = name.isEmpty ? '—' : name;
    final maxPts = DailyCaScoring.maxPoints(questionCount);
    return Column(
      children: [
        CircleAvatar(
          radius: tall ? 28 : 22,
          backgroundColor: highlight
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.15),
          child: Text(
            medal,
            style: AppTextStyles.h3().copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
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
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (entry != null) AdminBotLabel(uid: entry!.uid),
          ],
        ),
        if (entry != null)
          Text(
            entry!.score.toStringAsFixed(2) +
                (maxPts > 0 ? '/${maxPts.toStringAsFixed(0)}' : ''),
            style: AppTextStyles.caption().copyWith(color: Colors.white70),
          ),
      ],
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.entry,
    required this.questionCount,
    required this.isMe,
  });

  final DailyCaLeaderboardEntry entry;
  final int questionCount;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxPts = DailyCaScoring.maxPoints(questionCount);
    final name = entry.displayName.trim().isEmpty ? 'Aspirant' : entry.displayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary.withValues(alpha: 0.12)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isMe
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.air}',
              style: AppTextStyles.label().copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    isMe ? '$name (you)' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm().copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                AdminBotLabel(uid: entry.uid),
              ],
            ),
          ),
          Text(
            entry.score.toStringAsFixed(2) +
                (maxPts > 0 ? '/${maxPts.toStringAsFixed(0)}' : ''),
            style: AppTextStyles.label().copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
