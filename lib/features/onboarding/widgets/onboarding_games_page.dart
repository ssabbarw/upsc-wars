import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import 'onboarding_scale.dart';
import '../../../l10n/l10n.dart';

class _GameLine {
  const _GameLine({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final Color tint;
}

/// Mirrors the six games in the Revision Games hub.
const _kGames = [
  _GameLine(
    title: 'Memory Pairs',
    body: 'Match terms to answers — train recall.',
    icon: Icons.grid_view_rounded,
    accent: RgColors.info,
    tint: AppColors.infoBg,
  ),
  _GameLine(
    title: 'Timeline Sorter',
    body: 'Put events in the right order.',
    icon: Icons.timeline_rounded,
    accent: RgColors.warning,
    tint: AppColors.warningBg,
  ),
  _GameLine(
    title: 'Odd One Out',
    body: 'Spot the one that doesn\u2019t belong.',
    icon: Icons.rule_rounded,
    accent: RgColors.wrong,
    tint: AppColors.wrongBg,
  ),
  _GameLine(
    title: 'Fact or Bluff',
    body: 'Ten seconds on the clock — trust your gut.',
    icon: Icons.bolt_rounded,
    accent: RgColors.teal,
    tint: AppColors.correctBg,
  ),
  _GameLine(
    title: 'Connect the Dots',
    body: 'Find the hidden link between clues.',
    icon: Icons.hub_rounded,
    accent: RgColors.tealDeep,
    tint: AppColors.primaryLight,
  ),
  _GameLine(
    title: '1v1 Duel',
    body: 'One phone, two players — fastest wins.',
    icon: Icons.military_tech_rounded,
    accent: RgColors.ink,
    tint: AppColors.gray100,
  ),
];

/// Last screen — six revision games revealed one by one; CTA unlocks when done.
class OnboardingGamesPage extends HookWidget {
  const OnboardingGamesPage({
    super.key,
    required this.isActive,
    required this.onGetStarted,
  });

  final bool isActive;
  final VoidCallback onGetStarted;

  static const _firstDelayMs = 120;
  static const _staggerMs = 120;

  @override
  Widget build(BuildContext context) {
    final revealed = useState(0); // how many rows are in
    final ready = useState(false);
    final started = useRef(false);

    useEffect(() {
      if (!isActive || started.value) return null;
      started.value = true;

      final timers = <Timer>[];
      for (var i = 0; i < _kGames.length; i++) {
        timers.add(
          Timer(Duration(milliseconds: _firstDelayMs + _staggerMs * i), () {
            revealed.value = i + 1;
          }),
        );
      }
      timers.add(
        Timer(
          Duration(
            milliseconds: _firstDelayMs + _staggerMs * _kGames.length + 100,
          ),
          () => ready.value = true,
        ),
      );

      return () {
        for (final t in timers) {
          t.cancel();
        }
      };
    }, [isActive]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: OnboardingFit(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'REVISION GAMES',
                  style: RgText.mono(
                    size: onb(context, 12),
                    letterSpacingEm: 0.13,
                    color: RgColors.tealDeep,
                  ),
                ),
                SizedBox(height: onb(context, 10)),
                Text(
                  context.l10n.obgTitle,
                  style: RgText.display(
                    size: onb(context, 24),
                    weight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: onb(context, 20)),
                for (var i = 0; i < _kGames.length; i++) ...[
                  if (i > 0) SizedBox(height: onb(context, 10)),
                  _GameRow(game: _kGames[i], visible: revealed.value > i),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: onb(context, 14)),
        AnimatedOpacity(
          opacity: ready.value ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !ready.value,
            child: FilledButton(
              onPressed: onGetStarted,
              style:
                  RgText.pillButton(
                    fill: RgColors.tealDeep,
                    verticalPadding: onb(context, 16),
                  ).copyWith(
                    minimumSize: WidgetStatePropertyAll(
                      Size(double.infinity, onb(context, 56)),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(onb(context, 14)),
                      ),
                    ),
                  ),
              child: Text(
                context.l10n.obgStart,
                style: RgText.body(
                  size: onb(context, 17),
                  weight: FontWeight.w700,
                  color: RgColors.onDark,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.game, required this.visible});

  final _GameLine game;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0.12, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        opacity: visible ? 1 : 0,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: onb(context, 14),
            vertical: onb(context, 12),
          ),
          decoration: BoxDecoration(
            color: RgColors.card,
            borderRadius: BorderRadius.circular(onb(context, 14)),
            border: Border.all(color: RgColors.border),
          ),
          child: Row(
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                scale: visible ? 1 : 0.4,
                child: Container(
                  width: onb(context, 40),
                  height: onb(context, 40),
                  decoration: BoxDecoration(
                    color: game.tint,
                    borderRadius: BorderRadius.circular(onb(context, 11)),
                  ),
                  child: Icon(
                    game.icon,
                    color: game.accent,
                    size: onb(context, 21),
                  ),
                ),
              ),
              SizedBox(width: onb(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: RgText.body(
                        size: onb(context, 15),
                        weight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: onb(context, 3)),
                    Text(
                      _gameBody(context, game),
                      style: RgText.body(
                        size: onb(context, 12.5),
                        height: 1.3,
                        color: RgColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _gameBody(BuildContext context, _GameLine game) {
  final l10n = context.l10n;
  return switch (game.title) {
    'Memory Pairs' => l10n.gmDescMemory,
    'Timeline Sorter' => l10n.gmDescTimeline,
    'Odd One Out' => l10n.obgOdd,
    'Fact or Bluff' => l10n.obgFob,
    'Connect the Dots' => l10n.obgCtd,
    '1v1 Duel' => l10n.obgDuel,
    _ => game.body,
  };
}
