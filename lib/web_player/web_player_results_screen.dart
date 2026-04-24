import 'package:flutter/material.dart';

import 'package:upsc_wars/core/deep_link/shared_session_firestore.dart';
import 'package:upsc_wars/core/presentation/session_subject_label.dart';
import 'package:upsc_wars/core/domain/entities/session_result.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';
import 'package:upsc_wars/web_player/web_player_ui_tokens.dart';

/// Post-test summary for the web player: **this run only** (no history / coach).
enum WebPlayerResultsExit { review, dangerZoneReview, reattempt }

class WebPlayerResultsScreen extends StatelessWidget {
  const WebPlayerResultsScreen({
    super.key,
    required this.result,
    required this.shareId,
    required this.participantName,
  });

  final SessionResult result;
  final String? shareId;
  final String participantName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displaySubject = displayNameForSessionSubject(result.subject);
    final modeLabel = result.mode == 'exam' ? 'Exam' : 'Learning';

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session summary',
                          style: AppTextStyles.h2().copyWith(
                            color: scheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          displaySubject,
                          style: AppTextStyles.bodySm().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$modeLabel · ${result.questionCount} question${result.questionCount == 1 ? '' : 's'}',
                          style: AppTextStyles.caption().copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xxl,
                    ),
                    children: [
                      _WebPlayerLeaderboardCard(
                        shareId: shareId,
                        participantName: participantName,
                        currentScore: result.accuracy,
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _WebPlayerConfidenceSummaryCard(result: result),
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(WebPlayerResultsExit.review),
                        style: WebPlayerUiTokens.primaryCta(context),
                        child: const Text('Review with explanations'),
                      ),
                      if (result.dangerZoneWrongCount > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _DangerZoneAttentionCard(
                          wrongCount: result.dangerZoneWrongCount,
                          estimatedMarksLost: result.dangerZoneMarksEstimate,
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(WebPlayerResultsExit.dangerZoneReview),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(WebPlayerResultsExit.reattempt),
                        style: WebPlayerUiTokens.outlineFullWidth(context),
                        child: const Text('Reattempt'),
                      ),
                    ],
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

class _DangerZoneAttentionCard extends StatelessWidget {
  const _DangerZoneAttentionCard({
    required this.wrongCount,
    required this.estimatedMarksLost,
    required this.onPressed,
  });

  final int wrongCount;
  final double estimatedMarksLost;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.wrongBgDark : AppColors.wrongBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.wrong.withValues(alpha: isDark ? 0.55 : 0.40),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.wrong.withValues(alpha: isDark ? 0.30 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.wrong.withValues(
                    alpha: isDark ? 0.24 : 0.16,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.wrong.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  'ACTION REQUIRED',
                  style: AppTextStyles.caption().copyWith(
                    color: isDark
                        ? AppColors.wrongTextDark
                        : AppColors.wrongText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.warning_amber_rounded,
                color: isDark ? AppColors.wrongTextDark : AppColors.wrongText,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Danger Zone mistakes',
            style: AppTextStyles.h3().copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$wrongCount confident wrong${wrongCount == 1 ? '' : 's'} '
            '· Estimated cost: -${estimatedMarksLost.toStringAsFixed(2)} marks',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurface,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'These are the questions you felt sure about but got wrong. '
            'Fixing these gives the biggest score jump.',
            style: AppTextStyles.bodySm().copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.wrong,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: (isDark ? Colors.white : border).withValues(alpha: 0.18),
              ),
            ),
            icon: const Icon(Icons.visibility_rounded, size: 20),
            label: const Text('Review Danger Zone now'),
          ),
        ],
      ),
    );
  }
}

class _LbRow {
  const _LbRow({required this.name, required this.score, required this.isYou});

  final String name;
  final double score;
  final bool isYou;
}

class _WebPlayerLeaderboardCard extends StatefulWidget {
  const _WebPlayerLeaderboardCard({
    required this.shareId,
    required this.participantName,
    required this.currentScore,
    required this.isDark,
  });

  final String? shareId;
  final String participantName;
  final double currentScore;
  final bool isDark;

  @override
  State<_WebPlayerLeaderboardCard> createState() =>
      _WebPlayerLeaderboardCardState();
}

class _WebPlayerLeaderboardCardState extends State<_WebPlayerLeaderboardCard> {
  late final Future<List<SharedLeaderboardEntry>> _future = _fetchLeaderboard();

  Future<List<SharedLeaderboardEntry>> _fetchLeaderboard() async {
    final shareId = widget.shareId;
    if (shareId == null || shareId.trim().isEmpty) return const [];
    final repo = SharedSessionFirestoreRepository();
    return repo.fetchTopLeaderboard(shareId: shareId);
  }

  List<_LbRow> _buildRows(List<SharedLeaderboardEntry> fetched) {
    final trimmedName = widget.participantName.trim();
    final youName = trimmedName.isEmpty ? 'You' : trimmedName;
    final you = _LbRow(name: youName, score: widget.currentScore, isYou: true);

    var markedYou = false;
    final out = <_LbRow>[];
    for (final e in fetched) {
      final rowName = e.name.trim();
      final nameMatch = rowName.toLowerCase() == you.name.trim().toLowerCase();
      final scoreMatch = (e.score - you.score).abs() < 0.01;
      final isYou = !markedYou && nameMatch && scoreMatch;
      if (isYou) markedYou = true;
      out.add(_LbRow(name: e.name, score: e.score, isYou: isYou));
    }

    // If current attempt not already present, add it (0 is valid).
    if (!markedYou) {
      out.add(you);
    }

    out.sort((a, b) => b.score.compareTo(a.score));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.correct;
    final border = Colors.white.withValues(alpha: 0.14);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border),
      ),
      child: FutureBuilder<List<SharedLeaderboardEntry>>(
        future: _future,
        builder: (context, snap) {
          final list = snap.data ?? const <SharedLeaderboardEntry>[];
          final merged = _buildRows(list);

          final top5 = merged.take(5).toList();
          final youInTop5 = top5.any((r) => r.isYou);
          final youRow = merged.firstWhere((r) => r.isYou);

          Widget rowLine(int rank, _LbRow r) {
            final nameTrimmed = r.name.trim();
            final showYouSuffix = r.isYou && nameTrimmed.toLowerCase() != 'you';
            return Container(
              padding: r.isYou
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
                  : const EdgeInsets.symmetric(vertical: 6),
              decoration: r.isYou
                  ? BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.92),
                        width: 1.4,
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '#$rank',
                      style: AppTextStyles.caption().copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      r.isYou
                          ? (showYouSuffix ? '${r.name} (you)' : r.name)
                          : r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm().copyWith(
                        color: Colors.white,
                        fontWeight: r.isYou ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${r.score.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodySm().copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Leaderboard · Top 5',
                    style: AppTextStyles.label().copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (snap.connectionState == ConnectionState.waiting)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (merged.isEmpty)
                Text(
                  "Be the first to finish this test.",
                  style: AppTextStyles.bodySm().copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                )
              else ...[
                for (var i = 0; i < top5.length; i++) rowLine(i + 1, top5[i]),
                if (!youInTop5) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Divider(color: Colors.white.withValues(alpha: 0.14)),
                  const SizedBox(height: AppSpacing.xs),
                  rowLine(0, youRow),
                ],
              ],
              const SizedBox(height: 6),
              Text(
                'Scores update after each completed run.',
                style: AppTextStyles.caption().copyWith(
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WebPlayerConfidenceSummaryCard extends StatelessWidget {
  const _WebPlayerConfidenceSummaryCard({required this.result});

  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sureTotal = result.confidenceSureTotal;
    final sureWrong =
        (result.confidenceSureTotal - result.confidenceSureCorrect).clamp(
          0,
          1 << 30,
        );
    final eduTotal = result.confidenceIntelligentTotal;
    final eduWrong =
        (result.confidenceIntelligentTotal -
                result.confidenceIntelligentCorrect)
            .clamp(0, 1 << 30);
    final anyConfidence = (sureTotal + eduTotal) > 0;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Accuracy',
              style: AppTextStyles.label().copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              '${result.accuracy.round()}% (${result.correct}/${result.questionCount})',
              style: AppTextStyles.bodyMd().copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (!anyConfidence)
              Text(
                'Try reattempting the test to see your confidence accuracy in this test',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              )
            else ...[
              Text(
                'Sure + wrong => $sureWrong',
                style: AppTextStyles.bodySm().copyWith(
                  color: isDark ? AppColors.wrongTextDark : AppColors.wrongText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Educated guess + Wrong => $eduWrong',
                style: AppTextStyles.bodySm().copyWith(
                  color: isDark ? AppColors.wrongTextDark : AppColors.wrongText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
