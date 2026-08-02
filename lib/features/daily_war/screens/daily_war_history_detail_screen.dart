import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/domain/entities/test_question.dart';
import '../daily_war_constants.dart';
import '../domain/daily_war_copy.dart';
import '../domain/daily_war_models.dart';
import '../providers/daily_war_providers.dart';
import '../theme/daily_war_theme.dart';

/// One War night: personal result, leaderboard, question list, revise entry.
///
/// Data comes from [dailyWarArchiveProvider] — Firebase once after ranks are
/// ready, then SharedPreferences forever.
class DailyWarHistoryDetailScreen extends ConsumerWidget {
  const DailyWarHistoryDetailScreen({super.key, required this.dateId});

  final String dateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(dailyWarArchiveProvider(dateId));
    final questionsAsync = ref.watch(dailyWarArchiveQuestionsProvider(dateId));
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

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            war.isGrand ? 'GRAND WAR' : 'DAILY WAR',
                            style: DwText.eyebrow(),
                          ),
                          const Spacer(),
                          Text(war.dateId, style: DwText.stamp()),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subjects,
                        style: DwText.dm(
                          size: 12,
                          weight: FontWeight.w600,
                          color: DwColors.crimsonBright,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                      if (questionsAsync.asData?.value.isNotEmpty == true) ...[
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
                      ],
                      const SizedBox(height: 28),
                      Text(
                        'LEADERBOARD',
                        style: DwText.eyebrow(color: DwColors.onDarkMuted),
                      ),
                      const SizedBox(height: 10),
                      if (lb == null || lb.top.isEmpty)
                        Text(
                          war.ranksReady
                              ? 'No ranked finishers yet'
                              : 'Ranks calculate after the War closes',
                          style: DwText.body(),
                        )
                      else
                        _LeaderboardTeaser(
                          lb: lb,
                          dateId: dateId,
                          myUid: myUid,
                          myAir: sub?.air,
                        ),
                      const SizedBox(height: 28),
                      Text(
                        'QUESTIONS',
                        style: DwText.eyebrow(color: DwColors.onDarkMuted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub == null
                            ? 'You missed this War — review the paper anyway'
                            : '${sub.correct} correct · ${sub.wrong} wrong · '
                                '${sub.unanswered} unanswered',
                        style: DwText.body(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              questionsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DwColors.crimsonBright,
                      ),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Could not load questions: $e',
                      style: DwText.body(color: DwColors.crimsonBright),
                    ),
                  ),
                ),
                data: (questions) {
                  if (questions.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                        child: Text(
                          war.questionUuids.isEmpty
                              ? 'Paper not published yet'
                              : 'Questions not available on this device yet',
                          style: DwText.body(),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverList.separated(
                      itemCount: questions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final q = questions[i];
                        return _QuestionRow(
                          index: i + 1,
                          question: q,
                          onTap: () => context.push(
                            '${dailyWarHistoryReviseRoute(dateId)}?i=$i',
                          ),
                        );
                      },
                    ),
                  );
                },
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

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.index,
    required this.question,
    required this.onTap,
  });

  final int index;
  final TestQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (question.status) {
      'correct' => ('Correct', DwColors.teal),
      'wrong' => ('Wrong', DwColors.crimsonBright),
      _ => ('Unanswered', DwColors.onDarkMuted),
    };
    final preview = question.displayText.trim();
    final short = preview.length > 90 ? '${preview.substring(0, 90)}…' : preview;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: DwColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DwColors.borderOnDark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$index',
                  style: DwText.dm(
                    size: 12,
                    weight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      short.isEmpty ? 'Question $index' : short,
                      style: DwText.dm(size: 13, weight: FontWeight.w500, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: DwText.dm(
                        size: 11,
                        weight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DwColors.onDarkDim,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
