import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

double _onbScale(BuildContext context) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  return (shortest / 390).clamp(0.78, 1.22);
}

double _onb(BuildContext context, double designPx) =>
    designPx * _onbScale(context);

class _PeekGame {
  const _PeekGame({
    required this.title,
    required this.blurb,
    required this.icon,
    required this.accent,
    required this.accentBg,
  });

  final String title;
  final String blurb;
  final IconData icon;
  final Color accent;
  final Color accentBg;
}

/// Hub-aligned catalogue for the onboarding peek (non-interactive).
const _kPeekGames = [
  _PeekGame(
    title: 'Memory Pairs',
    blurb: 'Match terms in under a minute',
    icon: Icons.grid_view_rounded,
    accent: AppColors.info,
    accentBg: AppColors.infoBg,
  ),
  _PeekGame(
    title: 'Fact or Bluff',
    blurb: 'Trust your gut against the clock',
    icon: Icons.bolt_rounded,
    accent: AppColors.primary,
    accentBg: AppColors.primaryLight,
  ),
  _PeekGame(
    title: 'Timeline Sorter',
    blurb: 'Put events in the right order',
    icon: Icons.timeline_rounded,
    accent: AppColors.warning,
    accentBg: AppColors.warningBg,
  ),
  _PeekGame(
    title: 'Odd One Out',
    blurb: 'Spot the one that doesn\'t belong',
    icon: Icons.rule_rounded,
    accent: AppColors.wrong,
    accentBg: AppColors.wrongBg,
  ),
  _PeekGame(
    title: 'Connect the Dots',
    blurb: 'Find the hidden link',
    icon: Icons.hub_rounded,
    accent: AppColors.primaryDark,
    accentBg: AppColors.primaryLight,
  ),
  _PeekGame(
    title: '1v1 Duel',
    blurb: 'One phone, two players',
    icon: Icons.military_tech_rounded,
    accent: AppColors.infoText,
    accentBg: AppColors.infoBg,
  ),
];

/// Onboarding step: static peek of all revision games (no play, just browse).
class OnboardingGamesPeekPage extends StatelessWidget {
  const OnboardingGamesPeekPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final hPad = _onb(context, 22);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, _onb(context, 4), hPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(
              horizontal: _onb(context, 8),
              vertical: _onb(context, 4),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(_onb(context, 6)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: _onb(context, 8),
                  vertical: _onb(context, 4),
                ),
                child: Text(
                  'REVISION GAMES',
                  style: GoogleFonts.dmSans(
                    fontSize: _onb(context, 10),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: _onb(context, 8)),
          Text(
            'Prep that feels like play',
            style: GoogleFonts.dmSans(
              fontSize: _onb(context, 22),
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: AppColors.onSurfaceLight,
            ),
          ),
          SizedBox(height: _onb(context, 6)),
          Text(
            'Six short games for recall between mocks — not another '
            'full-length test.',
            style: GoogleFonts.dmSans(
              fontSize: _onb(context, 14),
              height: 1.45,
              color: AppColors.onSurfaceVariantLight,
            ),
          ),
          SizedBox(height: _onb(context, 12)),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gap = _onb(context, 8);
                final colW = (constraints.maxWidth - gap) / 2;
                // Fit 3 rows of equal-height tiles into the viewport.
                final rowH = ((constraints.maxHeight - gap * 2) / 3)
                    .clamp(_onb(context, 72), _onb(context, 110));

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final game in _kPeekGames)
                      SizedBox(
                        width: colW,
                        height: rowH,
                        child: _PeekGameTile(game: game),
                      ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: _onb(context, 10)),
          FilledButton(
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: _onb(context, 14)),
              minimumSize: Size(double.infinity, _onb(context, 48)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.dmSans(
                fontSize: _onb(context, 16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: _onb(context, 4)),
        ],
      ),
    );
  }
}

class _PeekGameTile extends StatelessWidget {
  const _PeekGameTile({required this.game});

  final _PeekGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(_onb(context, 10)),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _onb(context, 32),
            height: _onb(context, 32),
            decoration: BoxDecoration(
              color: game.accentBg,
              borderRadius: BorderRadius.circular(_onb(context, 8)),
            ),
            child: Icon(
              game.icon,
              size: _onb(context, 18),
              color: game.accent,
            ),
          ),
          const Spacer(),
          Text(
            game.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: _onb(context, 13),
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceLight,
            ),
          ),
          SizedBox(height: _onb(context, 2)),
          Text(
            game.blurb,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: _onb(context, 11),
              height: 1.3,
              fontWeight: FontWeight.w400,
              color: AppColors.onSurfaceVariantLight,
            ),
          ),
        ],
      ),
    );
  }
}
