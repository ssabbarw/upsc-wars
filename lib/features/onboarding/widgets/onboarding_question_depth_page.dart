import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import 'onboarding_scale.dart';
import '../../../l10n/l10n.dart';

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

List<_FeatureLine> _kFeatures(AppLocalizations l10n) => [
  _FeatureLine(
    title: l10n.onbFeatureExplanation,
    icon: Icons.menu_book_rounded,
    accent: RgColors.tealDeep,
    tint: AppColors.correctBg,
  ),
  _FeatureLine(
    title: l10n.onbFeatureStatement,
    icon: Icons.fact_check_rounded,
    accent: RgColors.info,
    tint: AppColors.infoBg,
  ),
  _FeatureLine(
    title: l10n.onbFeatureElimination,
    icon: Icons.filter_alt_rounded,
    accent: RgColors.warning,
    tint: AppColors.warningBg,
  ),
  _FeatureLine(
    title: l10n.onbFeatureDistractor,
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
    final features = _kFeatures(context.l10n);
    final checked = useState(0);

    useEffect(() {
      final timers = <Timer>[];
      for (var i = 0; i < features.length; i++) {
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

    final allChecked = checked.value >= features.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: OnboardingFit(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.onbDepthEyebrow,
                  style: RgText.mono(
                    size: onb(context, 11),
                    letterSpacingEm: 0.14,
                    color: RgColors.tealDeep,
                  ),
                ),
                SizedBox(height: onb(context, 10)),
                Text(
                  context.l10n.onbDepthTitle,
                  style: RgText.display(
                    size: onb(context, 24),
                    weight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
                SizedBox(height: onb(context, 22)),
                for (var i = 0; i < features.length; i++) ...[
                  if (i > 0) SizedBox(height: onb(context, 10)),
                  _FeatureRow(feature: features[i], checked: checked.value > i),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: onb(context, 12)),
        _BottomCta(visible: allChecked, onContinue: onContinue),
      ],
    );
  }
}

class _BottomCta extends HookWidget {
  const _BottomCta({required this.visible, required this.onContinue});

  final bool visible;
  final VoidCallback onContinue;

  static const _ctaDelay = Duration(milliseconds: 120);

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showButton = useState(reduceMotion && visible);

    useEffect(() {
      if (!visible) {
        showButton.value = false;
        return null;
      }
      if (reduceMotion) {
        showButton.value = true;
        return null;
      }
      final t = Timer(_ctaDelay, () => showButton.value = true);
      return t.cancel;
    }, [visible, reduceMotion]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: onb(context, 12)),
        AnimatedOpacity(
          opacity: showButton.value ? 1 : 0,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !showButton.value,
            child: FilledButton(
              onPressed: onContinue,
              style:
                  RgText.pillButton(
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
                context.l10n.demoLetsGo,
                style: RgText.body(
                  size: onb(context, 16),
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
