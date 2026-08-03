import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import 'onboarding_scale.dart';

/// Screen 2 — explanations that spot the trap, leading into the demo MCQ.
class OnboardingTrapPage extends StatelessWidget {
  const OnboardingTrapPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static const _assetPrefix = 'assets/images/onboarding';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: OnboardingFit(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'THE UPSC EDGE',
                  style: RgText.mono(
                    size: onb(context, 11),
                    letterSpacingEm: 0.14,
                    color: RgColors.warning,
                  ),
                ),
                SizedBox(height: onb(context, 10)),
                _Headline(scale: onboardingScale(context)),
                SizedBox(height: onb(context, 24)),
                _TrapCard(assetPrefix: _assetPrefix),
                SizedBox(height: onb(context, 14)),
                const _UpNextCard(),
              ],
            ),
          ),
        ),
        SizedBox(height: onb(context, 12)),
        FilledButton(
          onPressed: onContinue,
          style: RgText.pillButton(
            fill: RgColors.tealDeep,
            verticalPadding: onb(context, 15),
          ).copyWith(
            minimumSize: WidgetStatePropertyAll(
              Size(double.infinity, onb(context, 54)),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(onb(context, 14)),
              ),
            ),
          ),
          child: Text(
            'Try one  →',
            style: RgText.body(
              size: onb(context, 16),
              weight: FontWeight.w700,
              color: RgColors.onDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final base = RgText.display(
      size: 24 * scale,
      weight: FontWeight.w800,
      height: 1.22,
    );
    final accent = base.copyWith(
      color: RgColors.warningText,
      fontStyle: FontStyle.italic,
      decoration: TextDecoration.underline,
      decorationColor: RgColors.warning,
      decorationThickness: 1.6,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Explanations that\n'),
          TextSpan(text: 'spot the trap.', style: accent),
        ],
      ),
    );
  }
}

class _TrapCard extends StatelessWidget {
  const _TrapCard({required this.assetPrefix});

  final String assetPrefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        onb(context, 18),
        onb(context, 20),
        onb(context, 18),
        onb(context, 16),
      ),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(onb(context, 18)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: onb(context, 110),
            width: double.infinity,
            child: Image.asset(
              '$assetPrefix/lens.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          SizedBox(height: onb(context, 14)),
          Text(
            'Learn the pattern, not just the answer.',
            textAlign: TextAlign.center,
            style: RgText.display(
              size: onb(context, 16),
              weight: FontWeight.w800,
              height: 1.25,
              color: RgColors.warningText,
            ),
          ),
          SizedBox(height: onb(context, 8)),
          Text(
            'Every question comes with a deep-dive explanation — '
            'statement analysis, and a name for the exact trap '
            'UPSC set for you.',
            textAlign: TextAlign.center,
            style: RgText.body(
              size: onb(context, 13),
              height: 1.5,
              color: RgColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(onb(context, 16)),
      decoration: BoxDecoration(
        color: RgColors.ink,
        borderRadius: BorderRadius.circular(onb(context, 16)),
      ),
      child: Row(
        children: [
          Container(
            width: onb(context, 40),
            height: onb(context, 40),
            decoration: BoxDecoration(
              color: RgColors.onDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: RgColors.onDark,
              size: onb(context, 20),
            ),
          ),
          SizedBox(width: onb(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP NEXT',
                  style: RgText.mono(
                    size: onb(context, 10),
                    letterSpacingEm: 0.1,
                    color: RgColors.onDark.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: onb(context, 4)),
                Text(
                  'Try one real question — and watch us name the trap.',
                  style: RgText.body(
                    size: onb(context, 13),
                    weight: FontWeight.w600,
                    height: 1.35,
                    color: RgColors.onDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
