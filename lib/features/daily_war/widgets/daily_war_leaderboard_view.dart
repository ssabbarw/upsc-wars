import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../community/widgets/admin_bot_label.dart';
import '../domain/daily_war_badges.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../theme/daily_war_theme.dart';
import 'daily_war_badge_chip.dart';
import 'daily_war_warrior_sheet.dart';
import '../../../l10n/l10n.dart';

/// Full leaderboard: green podium header, list 4+, sticky “you” footer.
class DailyWarLeaderboardView extends StatelessWidget {
  const DailyWarLeaderboardView({
    super.key,
    required this.lb,
    required this.dateId,
    required this.myUid,
    required this.questionCount,
    this.mySubmission,
    this.isGrand = false,
  });

  final DailyWarLeaderboard lb;
  final String dateId;
  final String myUid;
  final int questionCount;
  final DailyWarSubmission? mySubmission;
  final bool isGrand;

  @override
  Widget build(BuildContext context) {
    final top = lb.top;
    final podium = top.take(3).toList();
    final rest = top.length > 3
        ? top.sublist(3)
        : const <DailyWarLeaderboardEntry>[];
    DailyWarLeaderboardEntry? meEntry;
    for (final e in top) {
      if (e.uid == myUid) {
        meEntry = e;
        break;
      }
    }
    final meOutside =
        meEntry == null &&
        mySubmission != null &&
        mySubmission!.hasOfficialRank;

    DateTime? parsed;
    try {
      parsed = DateTime.parse(dateId);
    } on Object {
      parsed = null;
    }
    final dateLabel = parsed == null
        ? dateId
        : DateFormat('d MMM').format(parsed).toUpperCase();

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _PodiumHeader(
                  dateLabel: dateLabel,
                  isGrand: isGrand,
                  joined: lb.participantCount,
                  podium: podium,
                  questionCount: questionCount,
                  myUid: myUid,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final e = rest[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _LbCard(
                        entry: e,
                        questionCount: questionCount,
                        isMe: e.uid == myUid,
                      ),
                    );
                  }, childCount: rest.length),
                ),
              ),
            ],
          ),
        ),
        if (meEntry != null || meOutside)
          _StickyYou(
            entry: meEntry,
            submission: mySubmission,
            questionCount: questionCount,
            participantCount: lb.participantCount,
          ),
      ],
    );
  }
}

class _PodiumHeader extends StatelessWidget {
  const _PodiumHeader({
    required this.dateLabel,
    required this.isGrand,
    required this.joined,
    required this.podium,
    required this.questionCount,
    required this.myUid,
  });

  final String dateLabel;
  final bool isGrand;
  final int joined;
  final List<DailyWarLeaderboardEntry> podium;
  final int questionCount;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    DailyWarLeaderboardEntry? at(int air) {
      for (final e in podium) {
        if (e.air == air) return e;
      }
      return podium.length >= air ? podium[air - 1] : null;
    }

    final first = at(1);
    final second = at(2);
    final third = at(3);
    final maxPts = questionCount * 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A3A32),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${DailyWarCopy.eventNameCaps(isGrand: isGrand)} · $dateLabel',
                style: DwText.dm(
                  size: 11,
                  weight: FontWeight.w700,
                  color: DwColors.onDarkMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 14,
                      color: DwColors.onDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_commas(joined)} joined',
                      style: DwText.dm(
                        size: 11,
                        weight: FontWeight.w600,
                        color: DwColors.onDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PodiumSlot(
                  entry: second,
                  place: 2,
                  maxPts: maxPts,
                  myUid: myUid,
                  size: 64,
                ),
              ),
              Expanded(
                child: _PodiumSlot(
                  entry: first,
                  place: 1,
                  maxPts: maxPts,
                  myUid: myUid,
                  size: 84,
                  medal: true,
                ),
              ),
              Expanded(
                child: _PodiumSlot(
                  entry: third,
                  place: 3,
                  maxPts: maxPts,
                  myUid: myUid,
                  size: 64,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _commas(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
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
      return SizedBox(height: size + 48);
    }
    final e = entry!;
    final border = switch (place) {
      1 => DwColors.gold,
      2 => const Color(0xFFB8B8B8),
      _ => const Color(0xFFCD7F32),
    };
    final name = e.displayName.isEmpty ? 'Warrior' : e.displayName;
    final short = name.length > 12 ? '${name.substring(0, 11)}…' : name;

    return GestureDetector(
      onTap: () => showDailyWarWarriorSheet(
        context: context,
        entry: e,
        questionCount: maxPts ~/ 2,
        isMe: e.uid == myUid,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (medal)
            const Icon(
              Icons.workspace_premium_rounded,
              color: DwColors.gold,
              size: 20,
            )
          else
            const SizedBox(height: 20),
          const SizedBox(height: 4),
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2924),
              border: Border.all(color: border, width: 3),
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
          const SizedBox(height: 8),
          Text(
            short,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DwText.dm(size: 12, weight: FontWeight.w700),
          ),
          AdminBotLabel(uid: e.uid),
          Text(
            '${_fmt(e.score)} / $maxPts',
            style: DwText.dm(
              size: 11,
              weight: FontWeight.w600,
              color: DwColors.onDarkMuted,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double s) =>
      s == s.roundToDouble() ? '${s.round()}' : s.toStringAsFixed(1);
}

class _LbCard extends StatelessWidget {
  const _LbCard({
    required this.entry,
    required this.questionCount,
    required this.isMe,
  });

  final DailyWarLeaderboardEntry entry;
  final int questionCount;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final name = entry.displayName.isEmpty ? 'Warrior' : entry.displayName;
    final title = entry.streakDays > 0
        ? DailyWarBadges.titleForDays(entry.streakDays)
        : '';
    final elapsed = _fmtElapsed(entry.elapsedMs);
    final subtitle = [
      if (title.isNotEmpty) title,
      if (elapsed.isNotEmpty) elapsed,
    ].join(' · ');
    final chipIds = _chipBadgeIds(entry);
    final initials = _initials(name);

    return Material(
      color: isMe
          ? DwColors.crimson.withValues(alpha: 0.12)
          : DwColors.surfaceRaised,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showDailyWarWarriorSheet(
          context: context,
          entry: entry,
          questionCount: questionCount,
          isMe: isMe,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMe
                  ? DwColors.crimson.withValues(alpha: 0.35)
                  : DwColors.borderOnDark,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${entry.air}',
                  style: DwText.dm(
                    size: 18,
                    weight: FontWeight.w800,
                    color: DwColors.onDarkMuted,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DwColors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initials,
                  style: DwText.dm(
                    size: 12,
                    weight: FontWeight.w800,
                    color: DwColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isMe ? context.l10n.resultsNameYou(name) : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DwText.dm(size: 14, weight: FontWeight.w700),
                          ),
                        ),
                        AdminBotLabel(uid: entry.uid),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DwText.dm(
                          size: 11,
                          weight: FontWeight.w500,
                          color: DwColors.onDarkMuted,
                        ),
                      ),
                    ],
                    if (chipIds.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final id in chipIds.take(4)) ...[
                            DailyWarBadgeChip(badgeId: id, size: 20),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _fmtScore(entry.score),
                style: DwText.dm(
                  size: 18,
                  weight: FontWeight.w800,
                  color: DwColors.onDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<String> _chipBadgeIds(DailyWarLeaderboardEntry e) {
    final out = <String>[];
    final tier = e.tierId ?? DailyWarBadges.tierIdForDays(e.streakDays);
    if (tier != null) out.add(tier);
    for (final b in e.badges) {
      if (DailyWarBadges.tierIds.contains(b)) continue;
      if (!out.contains(b)) out.add(b);
    }
    return out;
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
  }

  static String _fmtElapsed(int ms) {
    if (ms <= 0) return '';
    final totalSec = (ms / 1000).round();
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  static String _fmtScore(double score) {
    if (score == score.roundToDouble()) return '${score.round()}';
    return score.toStringAsFixed(1);
  }
}

class _StickyYou extends StatelessWidget {
  const _StickyYou({
    required this.entry,
    required this.submission,
    required this.questionCount,
    required this.participantCount,
  });

  final DailyWarLeaderboardEntry? entry;
  final DailyWarSubmission? submission;
  final int questionCount;
  final int participantCount;

  @override
  Widget build(BuildContext context) {
    final air = entry?.air ?? submission?.air ?? 0;
    final score = entry?.score ?? submission?.score ?? 0;
    final streak = entry?.streakDays ?? submission?.streakDays ?? 0;
    final title = streak > 0 ? DailyWarBadges.titleForDays(streak) : '';
    final name = entry?.displayName.isNotEmpty == true
        ? entry!.displayName
        : (submission?.displayName?.isNotEmpty == true
              ? submission!.displayName!
              : 'You');
    final synthetic =
        entry ??
        DailyWarLeaderboardEntry(
          uid: submission?.uid ?? '',
          displayName: name,
          score: score,
          elapsedMs: submission?.elapsedMs ?? 0,
          air: air,
          streakDays: streak,
          tierId: submission?.tierId,
          badges: submission?.badges ?? const [],
        );

    // Rough “up N ranks” tease vs mid-pack when we lack previous AIR.
    final mid = (participantCount / 2).round().clamp(1, participantCount);
    final delta = mid - air;
    final deltaLabel = delta > 0 ? context.l10n.dwUpRanks(delta) : title;

    return Material(
      color: const Color(0xFF1A3A32),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => showDailyWarWarriorSheet(
            context: context,
            entry: synthetic,
            questionCount: questionCount,
            isMe: true,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$air',
                    style: DwText.dm(size: 18, weight: FontWeight.w800),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'YO',
                    style: DwText.dm(size: 12, weight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You',
                        style: DwText.dm(size: 14, weight: FontWeight.w800),
                      ),
                      Text(
                        [
                          if (title.isNotEmpty) title,
                          if (deltaLabel.isNotEmpty && deltaLabel != title)
                            deltaLabel,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: DwText.dm(
                          size: 11,
                          weight: FontWeight.w500,
                          color: DwColors.onDarkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if ((entry?.tierId ?? DailyWarBadges.tierIdForDays(streak)) !=
                    null) ...[
                  DailyWarBadgeChip(
                    badgeId:
                        entry?.tierId ?? DailyWarBadges.tierIdForDays(streak)!,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  score == score.roundToDouble()
                      ? '${score.round()}'
                      : score.toStringAsFixed(1),
                  style: DwText.dm(size: 18, weight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
