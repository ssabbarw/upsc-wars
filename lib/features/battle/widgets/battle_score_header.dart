import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:upsc_wars/core/constants/app_constants.dart';
import 'package:upsc_wars/core/theme/app_colors.dart';
import 'package:upsc_wars/features/battle/domain/battle_monogram_palette.dart';
import 'package:upsc_wars/core/theme/app_radius.dart';
import 'package:upsc_wars/core/theme/app_spacing.dart';
import 'package:upsc_wars/core/theme/app_text_styles.dart';

/// Collapsible battle scores: two players in one row with compact per-question
/// outcome circles. Uses surface chrome so [AppColors.correct] chips stay
/// visually distinct from the header (primary and correct share the same hue).
class BattleScoresCollapsible extends StatelessWidget {
  const BattleScoresCollapsible({
    super.key,
    required this.opponentName,
    required this.opponentInitial,
    required this.playerInitial,
    required this.playerOutcomeByQuestion,
    required this.opponentOutcomeByQuestion,
    this.playerPhotoUrl,
    this.opponentMonogramBackground,
    this.playerMonogramBackground,
    this.initiallyExpanded = true,
    this.battleFinished = false,
  });

  final String opponentName;
  final String opponentInitial;
  final String playerInitial;
  final List<bool?> playerOutcomeByQuestion;
  final List<bool?> opponentOutcomeByQuestion;
  final String? playerPhotoUrl;

  /// When set (e.g. match screen), monogram uses this fill; when null, uses
  /// fixed translucent chips on the primary strip (battle test / results).
  final Color? opponentMonogramBackground;
  final Color? playerMonogramBackground;
  final bool initiallyExpanded;

  /// Both sides are done (submitted / timer / spectate settled).
  final bool battleFinished;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Mid-gray panels (avoid near-white in light; avoid heavy black in dark).
    final headerBg =
        isDark ? AppColors.surfaceTertiaryDark : AppColors.gray100;
    final onHeader = scheme.onSurface;
    final subtle = scheme.onSurfaceVariant;
    final border = scheme.outline.withValues(alpha: isDark ? 0.4 : 0.28);
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: headerBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: AppColors.transparent,
          listTileTheme: ListTileThemeData(tileColor: headerBg),
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: headerBg,
            collapsedBackgroundColor: headerBg,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          iconColor: subtle,
          collapsedIconColor: subtle,
          title: Row(
            children: [
              Text(
                'Scores',
                style: AppTextStyles.label().copyWith(
                  color: onHeader,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (battleFinished) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: isDark ? 0.35 : 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 13,
                        color: isDark
                            ? AppColors.infoTextDark
                            : AppColors.infoText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Battle finished',
                        style: AppTextStyles.caption().copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.infoTextDark
                              : AppColors.infoText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          children: [
            ColoredBox(
              color: headerBg,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PlayerScoreColumn(
                        alignEnd: false,
                        avatar: _MonogramAvatar(
                          letter: opponentInitial,
                          onPrimaryStrip: false,
                          backgroundColor: opponentMonogramBackground,
                          foregroundColor: opponentMonogramBackground != null
                              ? battleMatchMonogramForeground(
                                  opponentMonogramBackground!,
                                )
                              : null,
                        ),
                        title: opponentName,
                        outcomes: opponentOutcomeByQuestion,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _PlayerScoreColumn(
                        alignEnd: true,
                        avatar: _PlayerAvatarStrip(
                          initial: playerInitial,
                          photoUrl: playerPhotoUrl,
                          onPrimaryStrip: false,
                          monogramBackground: playerMonogramBackground,
                          monogramForeground: playerMonogramBackground != null
                              ? battleMatchMonogramForeground(
                                  playerMonogramBackground!,
                                )
                              : null,
                        ),
                        title: 'You',
                        outcomes: playerOutcomeByQuestion,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerScoreColumn extends StatelessWidget {
  const _PlayerScoreColumn({
    required this.alignEnd,
    required this.avatar,
    required this.title,
    required this.outcomes,
  });

  final bool alignEnd;
  final Widget avatar;
  final String title;
  final List<bool?> outcomes;

  @override
  Widget build(BuildContext context) {
    final cross = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final rowMain = alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Row(
          mainAxisAlignment: rowMain,
          children: [
            if (!alignEnd) ...[avatar, const SizedBox(width: AppSpacing.sm)],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                style: AppTextStyles.label().copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (alignEnd) ...[const SizedBox(width: AppSpacing.sm), avatar],
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 16,
              width: constraints.maxWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: alignEnd
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < outcomes.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      _TinyOutcomeCircle(
                        questionNumber: i + 1,
                        outcome: outcomes[i],
                        scheme: Theme.of(context).colorScheme,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TinyOutcomeCircle extends StatelessWidget {
  const _TinyOutcomeCircle({
    required this.questionNumber,
    required this.outcome,
    required this.scheme,
  });

  final int questionNumber;
  final bool? outcome;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final color = switch (outcome) {
      true => AppColors.correct,
      false => AppColors.wrong,
      null => scheme.surfaceContainerHighest,
    };
    final textColor = switch (outcome) {
      true => AppColors.onPrimary,
      false => AppColors.onPrimary,
      null => scheme.onSurfaceVariant,
    };
    final borderColor = switch (outcome) {
      true => AppColors.correct.withValues(alpha: 0.45),
      false => AppColors.wrong.withValues(alpha: 0.45),
      null => scheme.outline.withValues(alpha: 0.45),
    };

    return Container(
      width: 13,
      height: 13,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Text(
        '$questionNumber',
        style: TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w700,
          height: 1,
          color: textColor,
        ),
      ),
    );
  }
}

class _MonogramAvatar extends StatelessWidget {
  const _MonogramAvatar({
    required this.letter,
    required this.onPrimaryStrip,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String letter;
  final bool onPrimaryStrip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    if (backgroundColor != null && foregroundColor != null) {
      bg = backgroundColor!;
      fg = foregroundColor!;
    } else if (onPrimaryStrip) {
      bg = AppColors.onPrimary.withValues(alpha: 0.22);
      fg = AppColors.onPrimary;
    } else {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurface;
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: bg,
      child: Text(
        letter,
        style: AppTextStyles.label().copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlayerAvatarStrip extends StatelessWidget {
  const _PlayerAvatarStrip({
    required this.initial,
    this.photoUrl,
    required this.onPrimaryStrip,
    this.monogramBackground,
    this.monogramForeground,
  });

  final String initial;
  final String? photoUrl;
  final bool onPrimaryStrip;
  final Color? monogramBackground;
  final Color? monogramForeground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = AppConstants.profileImageUrlOrDefault(photoUrl);
    final cachePx =
        (36 * MediaQuery.devicePixelRatioOf(context)).round();
    return CircleAvatar(
      radius: 18,
      backgroundColor: scheme.surfaceContainerHighest,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          memCacheWidth: cachePx,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          errorWidget: (_, _, _) => _MonogramAvatar(
            letter: initial,
            onPrimaryStrip: onPrimaryStrip,
            backgroundColor: monogramBackground,
            foregroundColor: monogramForeground,
          ),
        ),
      ),
    );
  }
}
