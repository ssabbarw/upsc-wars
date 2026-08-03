import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import 'onboarding_scale.dart';

/// Screen 1 — thesis: Confident & Wrong vs Guess & Right.
class OnboardingThesisPage extends StatelessWidget {
  const OnboardingThesisPage({super.key, required this.onContinue});

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
                  'THE UPSC REALITY',
                  style: RgText.mono(
                    size: onb(context, 11),
                    letterSpacingEm: 0.14,
                    color: RgColors.wrong,
                  ),
                ),
                SizedBox(height: onb(context, 10)),
                _Headline(scale: onboardingScale(context)),
                SizedBox(height: onb(context, 24)),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ThesisCard(
                          bg: AppColors.wrongBg,
                          titleColor: RgColors.wrong,
                          title: 'Confident\n& Wrong',
                          subtitle: 'Most expensive mistake.',
                          top: _WarningBadge(size: onb(context, 56)),
                          bottom: _SceneImage(
                            asset: '$_assetPrefix/red_scene.png',
                            height: onb(context, 96),
                          ),
                        ),
                      ),
                      SizedBox(width: onb(context, 14)),
                      Expanded(
                        child: _ThesisCard(
                          bg: AppColors.correctBg,
                          titleColor: RgColors.tealDeep,
                          title: 'Guess\n& Right',
                          subtitle: 'You know more than you think.',
                          top: _TargetBadge(size: onb(context, 56)),
                          bottom: _SceneImage(
                            asset: '$_assetPrefix/green_scene.png',
                            height: onb(context, 96),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: onb(context, 18)),
                const _SummaryStrip(),
              ],
            ),
          ),
        ),
        SizedBox(height: onb(context, 12)),
        FilledButton(
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
            'Continue  →',
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
      color: RgColors.tealDeep,
      fontStyle: FontStyle.italic,
      decoration: TextDecoration.underline,
      decorationColor: RgColors.tealDeep,
      decorationThickness: 1.6,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: "Prelims isn't about knowing everything.\n"),
          TextSpan(text: 'UPSC Wars helps you identify —', style: accent),
        ],
      ),
    );
  }
}

class _ThesisCard extends StatelessWidget {
  const _ThesisCard({
    required this.bg,
    required this.titleColor,
    required this.title,
    required this.subtitle,
    required this.top,
    required this.bottom,
  });

  final Color bg;
  final Color titleColor;
  final String title;
  final String subtitle;
  final Widget top;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        onb(context, 14),
        onb(context, 18),
        onb(context, 14),
        onb(context, 14),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(onb(context, 18)),
      ),
      child: Column(
        children: [
          top,
          SizedBox(height: onb(context, 12)),
          Text(
            title,
            textAlign: TextAlign.center,
            softWrap: true,
            style: RgText.display(
              size: onb(context, 16),
              weight: FontWeight.w800,
              height: 1.2,
              color: titleColor,
            ),
          ),
          SizedBox(height: onb(context, 6)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            softWrap: true,
            style: RgText.body(
              size: onb(context, 12.5),
              height: 1.35,
              color: RgColors.muted,
            ),
          ),
          // Pushes illustration down so equal-height cards align.
          const Expanded(child: SizedBox.shrink()),
          SizedBox(height: onb(context, 12)),
          bottom,
        ],
      ),
    );
  }
}

class _SceneImage extends StatelessWidget {
  const _SceneImage({required this.asset, required this.height});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _WarningBadge extends StatelessWidget {
  const _WarningBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: RgColors.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: RgColors.wrong.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.priority_high_rounded,
          color: RgColors.wrong,
          size: size * 0.48,
        ),
      ),
    );
  }
}

class _TargetBadge extends StatelessWidget {
  const _TargetBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: RgColors.card,
          shape: BoxShape.circle,
          border: Border.all(
            color: RgColors.teal.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.18),
          child: Image.asset(
            'assets/images/onboarding/target.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.bar_chart_rounded,
        'See which topics cost you marks',
        AppColors.wrongBg,
        RgColors.wrong,
      ),
      (
        Icons.explore_rounded,
        'Topics where your guesses are right',
        AppColors.correctBg,
        RgColors.tealDeep,
      ),
    ];
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: onb(context, 12),
        vertical: onb(context, 14),
      ),
      decoration: BoxDecoration(
        color: RgColors.card,
        borderRadius: BorderRadius.circular(onb(context, 14)),
        border: Border.all(color: RgColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  margin: EdgeInsets.symmetric(horizontal: onb(context, 10)),
                  color: RgColors.border,
                ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: onb(context, 32),
                      height: onb(context, 32),
                      decoration: BoxDecoration(
                        color: items[i].$3,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        items[i].$1,
                        size: onb(context, 17),
                        color: items[i].$4,
                      ),
                    ),
                    SizedBox(width: onb(context, 8)),
                    Expanded(
                      child: Text(
                        items[i].$2,
                        softWrap: true,
                        style: RgText.body(
                          size: onb(context, 11),
                          height: 1.3,
                          color: RgColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
