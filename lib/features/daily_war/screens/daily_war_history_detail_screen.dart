import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';

/// One War night: personal result, leaderboard teaser, revise entry.
///
/// Data comes from [dailyWarArchiveProvider] — Firebase once after ranks are
/// ready, then SharedPreferences forever.
class DailyWarHistoryDetailScreen extends ConsumerWidget {
  const DailyWarHistoryDetailScreen({super.key, required this.dateId});

  final String dateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(dailyWarArchiveProvider(dateId));
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: DwColors.surface,
      appBar: AppBar(
        backgroundColor: DwColors.surface,
        foregroundColor: DwColors.onDark,
        title: Text(
          'War archive',
          style: DwText.dm(size: 18, weight: FontWeight.w700),
        ),
      ),
      body: archiveAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DwColors.crimsonBright),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$e',
              style: DwText.body(color: DwColors.crimsonBright),
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
          final accent =
              isGrand ? DwColors.gold : DwColors.crimsonBright;
          final canRevise = war.questionUuids.isNotEmpty;

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
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      isGrand ? 'GRAND WAR' : 'DAILY WAR',
                      style: DwText.dm(
                        size: 10,
                        weight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DailyWarCopy.formatWarDate(war.dateId),
                    style: DwText.dm(
                      size: 12,
                      weight: FontWeight.w600,
                      color: DwColors.onDarkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (subjects.isNotEmpty) ...[
                Text(
                  subjects,
                  style: DwText.dm(
                    size: 12,
                    weight: FontWeight.w600,
                    color: DwColors.crimsonBright,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                topics,
                style: DwText.dm(
                  size: 22,
                  weight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (archive.fromLocalOnly) ...[
                const SizedBox(height: 8),
                Text(
                  'Saved on this device',
                  style: DwText.meta(color: DwColors.onDarkDim),
                ),
              ],
              const SizedBox(height: 20),
              _MyResultCard(sub: sub, war: war),
              if (canRevise) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.push(
                      dailyWarHistoryReviseRoute(dateId),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: DwColors.crimson,
                      foregroundColor: DwColors.onDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Revise this paper',
                      style: DwText.cta(),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Paper not published yet',
                  style: DwText.body(),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'LEADERBOARD',
                style: DwText.eyebrow(color: DwColors.onDarkMuted),
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
      ),
    );
  }
}

class _MyResultCard extends StatelessWidget {
  const _MyResultCard({required this.sub, required this.war});

  final DailyWarSubmission? sub;
  final DailyWarDoc war;

  @override
  Widget build(BuildContext context) {
    if (sub == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DwColors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DwColors.borderOnDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR ATTEMPT', style: DwText.eyebrow()),
            const SizedBox(height: 8),
            Text(
              'Missed',
              style: DwText.dm(size: 28, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              war.ranksReady
                  ? '${war.participantCount ?? '—'} writers that night'
                  : 'You can still revise the paper',
              style: DwText.body(),
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
    final pctLabel =
        pct == null ? null : 'Better than ${pct.toStringAsFixed(0)}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1216), DwColors.surfaceRaised],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DwColors.crimson.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR ATTEMPT', style: DwText.eyebrow()),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                airLabel,
                style: DwText.dm(
                  size: 32,
                  weight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${_fmtScore(sub!.score)} pts',
                  style: DwText.dm(
                    size: 16,
                    weight: FontWeight.w600,
                    color: DwColors.crimsonBright,
                  ),
                ),
              ),
              if (pctLabel != null) ...[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(pctLabel, style: DwText.meta()),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(label: 'Correct', value: '${sub!.correct}', color: DwColors.teal),
              const SizedBox(width: 8),
              _StatPill(label: 'Wrong', value: '${sub!.wrong}', color: DwColors.crimsonBright),
              const SizedBox(width: 8),
              _StatPill(label: 'Skip', value: '${sub!.unanswered}', color: DwColors.onDarkMuted),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: DwColors.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: DwText.dm(size: 16, weight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(label, style: DwText.meta()),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: DwColors.surfaceRaised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DwColors.borderOnDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Expanded(child: _GhostPodium(height: 56, rank: 2)),
              SizedBox(width: 8),
              Expanded(child: _GhostPodium(height: 72, rank: 1, highlight: true)),
              SizedBox(width: 8),
              Expanded(child: _GhostPodium(height: 48, rank: 3)),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _GhostRow(delayIndex: i),
          ],
          const SizedBox(height: 14),
          Text(
            ranksReady
                ? 'No ranked finishers yet'
                : 'Ranks land after the War closes · All-India board fills here',
            textAlign: TextAlign.center,
            style: DwText.dm(
              size: 12,
              weight: FontWeight.w600,
              color: DwColors.onDarkMuted,
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
    this.highlight = false,
  });

  final double height;
  final int rank;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = highlight
        ? DwColors.gold.withValues(alpha: 0.35)
        : DwColors.onDark.withValues(alpha: 0.08);
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DwColors.onDark.withValues(alpha: 0.06),
            border: Border.all(
              color: highlight
                  ? DwColors.gold.withValues(alpha: 0.4)
                  : DwColors.borderOnDark,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: DwText.dm(
              size: 13,
              weight: FontWeight.w800,
              color: highlight ? DwColors.gold : DwColors.onDarkFaint,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: DwColors.onDark.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: DwColors.borderOnDark),
          ),
        ),
      ],
    );
  }
}

class _GhostRow extends StatelessWidget {
  const _GhostRow({required this.delayIndex});

  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    final nameWidth = 120.0 - (delayIndex * 18);
    return Row(
      children: [
        Container(
          width: 28,
          height: 12,
          decoration: BoxDecoration(
            color: DwColors.onDark.withValues(alpha: 0.08),
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
                color: DwColors.onDark.withValues(alpha: 0.08),
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
            color: DwColors.onDark.withValues(alpha: 0.06),
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
    final preview = lb.top.take(3).toList();
    return Material(
      color: DwColors.surfaceRaised,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(dailyWarLeaderboardRoute(dateId)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DwColors.borderOnDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Top ${lb.top.length} of ${lb.participantCount}',
                      style: DwText.meta(),
                    ),
                  ),
                  Text(
                    'Open board →',
                    style: DwText.dm(
                      size: 13,
                      weight: FontWeight.w700,
                      color: DwColors.crimsonBright,
                    ),
                  ),
                ],
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
                          style: DwText.dm(
                            size: 13,
                            weight: FontWeight.w700,
                            color: e.air <= 3
                                ? DwColors.gold
                                : DwColors.onDarkMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.uid == myUid
                              ? '${e.displayName.isEmpty ? 'Warrior' : e.displayName} (you)'
                              : (e.displayName.isEmpty
                                  ? 'Warrior'
                                  : e.displayName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DwText.dm(size: 14, weight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _MyResultCard._fmtScore(e.score),
                        style: DwText.dm(
                          size: 14,
                          weight: FontWeight.w700,
                          color: DwColors.crimsonBright,
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
                  style: DwText.dm(
                    size: 12,
                    weight: FontWeight.w700,
                    color: DwColors.crimsonBright,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

