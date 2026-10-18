import 'package:flutter/material.dart';

import '../../../core/layout/system_insets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/dismissible_modal_sheet.dart';
import '../../community/widgets/admin_bot_label.dart';
import '../domain/daily_war_badges.dart';
import '../domain/daily_war_models.dart';
import '../theme/daily_war_theme.dart';
import 'daily_war_badge_chip.dart';
import '../../../l10n/l10n.dart';

/// Profile bottom sheet for a leaderboard warrior — name + badges.
Future<void> showDailyWarWarriorSheet({
  required BuildContext context,
  required DailyWarLeaderboardEntry entry,
  required int questionCount,
  bool isMe = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DismissOnScrimTap(
      child: _WarriorSheet(
        entry: entry,
        questionCount: questionCount,
        isMe: isMe,
      ),
    ),
  );
}

class _WarriorSheet extends StatelessWidget {
  const _WarriorSheet({
    required this.entry,
    required this.questionCount,
    required this.isMe,
  });

  final DailyWarLeaderboardEntry entry;
  final int questionCount;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = entry.displayName.isEmpty
        ? (isMe ? 'You' : 'Warrior')
        : (isMe
              ? context.l10n.resultsNameYou(entry.displayName)
              : entry.displayName);
    final initials = _initials(
      entry.displayName.isEmpty ? 'YO' : entry.displayName,
    );
    final title = entry.streakDays > 0
        ? DailyWarBadges.titleForDays(entry.streakDays)
        : '';
    final tierId =
        entry.tierId ?? DailyWarBadges.tierIdForDays(entry.streakDays);
    final awardIds = entry.badges
        .where((id) => !DailyWarBadges.tierIds.contains(id))
        .toList();
    // Prefer explicit awards; if empty and AIR ≤ 3, still show podium badge.
    final displayAwards = [if (tierId != null) tierId, ...awardIds];

    final elapsed = _fmtElapsed(entry.elapsedMs);
    final scoreLabel = questionCount > 0
        ? '${_fmtScore(entry.score)} / ${questionCount * 2}'
        : _fmtScore(entry.score);

    return Padding(
      padding: EdgeInsets.only(bottom: sheetBottomPadding(context)),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    _Avatar(initials: initials, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: AppTextStyles.h3().copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: scheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              AdminBotLabel(uid: entry.uid),
                            ],
                          ),
                          if (title.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: AppTextStyles.bodySm().copyWith(
                                color: DwColors.teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'AIR ${entry.air} · $scoreLabel · $elapsed',
                            style: AppTextStyles.caption().copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tierId != null)
                      DailyWarBadgeChip(badgeId: tierId, size: 52),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Badges',
                  style: AppTextStyles.label().copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                if (displayAwards.isEmpty)
                  Text(
                    context.l10n.dwNoBadgesNight,
                    style: AppTextStyles.bodySm().copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                    children: [
                      for (final id in displayAwards)
                        DailyWarBadgeTile(badgeId: id),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.dwTiersNote,
                  style: AppTextStyles.caption().copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    if (ms <= 0) return '—';
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, this.size = 40});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DwColors.teal.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: DwColors.teal.withValues(alpha: 0.45)),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          color: DwColors.teal,
        ),
      ),
    );
  }
}
