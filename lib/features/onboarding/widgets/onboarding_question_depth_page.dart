import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import 'onboarding_scale.dart';

class _FeatureLine {
  const _FeatureLine({
    required this.title,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Color tint;
}

const _kFeatures = [
  _FeatureLine(
    title: 'Rich explanation',
    icon: Icons.menu_book_rounded,
    accent: RgColors.tealDeep,
    tint: AppColors.correctBg,
  ),
  _FeatureLine(
    title: 'Statement analysis',
    icon: Icons.fact_check_rounded,
    accent: RgColors.info,
    tint: AppColors.infoBg,
  ),
  _FeatureLine(
    title: 'Elimination technique',
    icon: Icons.filter_alt_rounded,
    accent: RgColors.warning,
    tint: AppColors.warningBg,
  ),
  _FeatureLine(
    title: 'Strong distractor option',
    icon: Icons.psychology_alt_rounded,
    accent: RgColors.wrong,
    tint: AppColors.wrongBg,
  ),
];

/// Screen 2 — what every UPSC Wars question includes.
class OnboardingQuestionDepthPage extends HookWidget {
  const OnboardingQuestionDepthPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  static const _firstDelayMs = 220;
  static const _staggerMs = 280;

  @override
  Widget build(BuildContext context) {
    final checked = useState(0);

    useEffect(() {
      final timers = <Timer>[];
      for (var i = 0; i < _kFeatures.length; i++) {
        timers.add(
          Timer(Duration(milliseconds: _firstDelayMs + _staggerMs * i), () {
            checked.value = i + 1;
          }),
        );
      }
      return () {
        for (final t in timers) {
          t.cancel();
        }
      };
    }, const []);

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
                    color: RgColors.tealDeep,
                  ),
                ),
                SizedBox(height: onb(context, 10)),
                Text(
                  'Each question in\nUPSC Wars has:',
                  style: RgText.display(
                    size: onb(context, 24),
                    weight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
                SizedBox(height: onb(context, 22)),
                for (var i = 0; i < _kFeatures.length; i++) ...[
                  if (i > 0) SizedBox(height: onb(context, 10)),
                  _FeatureRow(
                    feature: _kFeatures[i],
                    checked: checked.value > i,
                  ),
                ],
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
            'Next  →',
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.checked});

  final _FeatureLine feature;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: onb(context, 14),
        vertical: onb(context, 14),
      ),
      decoration: BoxDecoration(
        color: RgColors.card,
        borderRadius: BorderRadius.circular(onb(context, 14)),
        border: Border.all(color: RgColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: onb(context, 40),
            height: onb(context, 40),
            decoration: BoxDecoration(
              color: feature.tint,
              borderRadius: BorderRadius.circular(onb(context, 11)),
            ),
            child: Icon(
              feature.icon,
              color: feature.accent,
              size: onb(context, 21),
            ),
          ),
          SizedBox(width: onb(context, 12)),
          Expanded(
            child: Text(
              feature.title,
              style: RgText.body(
                size: onb(context, 15),
                weight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(width: onb(context, 8)),
          _AnimatedCheck(visible: checked),
        ],
      ),
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  const _AnimatedCheck({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final size = onb(context, 28);
    return AnimatedScale(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      scale: visible ? 1 : 0.2,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        opacity: visible ? 1 : 0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.correctBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            color: RgColors.tealDeep,
            size: onb(context, 18),
          ),
        ),
      ),
    );
  }
}
