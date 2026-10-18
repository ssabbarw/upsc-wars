import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import 'onboarding_scale.dart';
import '../../../l10n/l10n.dart';

/// Screen 1 — thesis: Confident & Wrong vs Guess & Right.
class OnboardingThesisPage extends HookWidget {
  const OnboardingThesisPage({
    super.key,
    required this.onContinue,
    this.showContinueButton = true,
  });

  final VoidCallback onContinue;

  /// When false (e.g. Play Store demo), the bottom CTA stays hidden.
  final bool showContinueButton;

  static const _assetPrefix = 'assets/images/onboarding';

  @override
  Widget build(BuildContext context) {
    // Hold the CTA back briefly so the screen settles before it appears.
    final showCta = useState(false);
    useEffect(() {
      final t = Timer(const Duration(milliseconds: 300), () {
        showCta.value = true;
      });
      return t.cancel;
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
                  context.l10n.onbThesisEyebrow,
                  style: RgText.mono(
                    size: onb(context, 11),
                    letterSpacingEm: 0.14,
                    color: RgColors.wrong,
                  ),
                ),
                SizedBox(height: onb(context, 10)),
                _Headline(scale: onboardingScale(context)),
                SizedBox(height: onb(context, 10)),
                const _GlowingSubline(),
                SizedBox(height: onb(context, 18)),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ThesisCard(
                          bg: AppColors.wrongBg,
                          titleColor: RgColors.wrong,
                          title: context.l10n.onbConfidentWrong,
                          subtitle:
                              context.l10n.onbConfidentWrongBody,
                          top: _WarningBadge(size: onb(context, 48)),
                          bottom: _SceneImage(
                            asset: '$_assetPrefix/red_scene.png',
                            height: onb(context, 80),
                          ),
                        ),
                      ),
                      SizedBox(width: onb(context, 14)),
                      Expanded(
                        child: _ThesisCard(
                          bg: AppColors.correctBg,
                          titleColor: RgColors.tealDeep,
                          title: context.l10n.onbGuessRight,
                          subtitle:
                              context.l10n.onbGuessRightBody,
                          top: _TargetBadge(size: onb(context, 48)),
                          bottom: _SceneImage(
                            asset: '$_assetPrefix/green_scene.png',
                            height: onb(context, 80),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: onb(context, 14)),
                const _SummaryStrip(),
              ],
            ),
          ),
        ),
        if (showContinueButton) ...[
          SizedBox(height: onb(context, 12)),
          AnimatedOpacity(
            opacity: showCta.value ? 1 : 0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: IgnorePointer(
              ignoring: !showCta.value,
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
                  context.l10n.onbNext,
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
      ],
    );
  }
}

/// Subline that types itself out, then the key phrase keeps pulsing —
/// fading in and out with a soft glow. Only color/shadow animate after
/// typing, so the text never reflows.
class _GlowingSubline extends HookWidget {
  const _GlowingSubline();


  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefix = l10n.onbSublinePrefix;
    final phrase = l10n.onbSublinePhrase;
    final suffix = l10n.onbSublineSuffix;
    final total = prefix.length + phrase.length + suffix.length;
    final typing = useAnimationController(
      // ~16ms per character.
      duration: const Duration(milliseconds: 1230),
    );
    final pulse = useAnimationController(
      duration: const Duration(milliseconds: 550),
    );

    useEffect(() {
      void onStatus(AnimationStatus s) {
        if (s == AnimationStatus.completed) pulse.repeat(reverse: true);
      }

      typing.addStatusListener(onStatus);
      typing.forward();
      return () => typing.removeStatusListener(onStatus);
    }, const []);

    final base = RgText.body(
      size: onb(context, 13.5),
      height: 1.4,
      color: RgColors.muted,
    );

    String clip(String s, int count) => s.substring(0, count.clamp(0, s.length));

    return AnimatedBuilder(
      animation: Listenable.merge([typing, pulse]),
      builder: (context, _) {
        final chars = (typing.value * total).round();
        final typed = typing.isCompleted;

        final t = typed ? Curves.easeInOut.transform(pulse.value) : 1.0;
        // Fade the phrase in and out while the glow swells with it.
        final opacity = 0.3 + 0.7 * t;
        final glow = base.copyWith(
          color: RgColors.tealDeep.withValues(alpha: opacity),
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: RgColors.teal.withValues(alpha: 0.55 * t),
              blurRadius: 12,
            ),
          ],
        );

        final visible = TextSpan(
          style: base,
          children: [
            TextSpan(text: clip(prefix, chars)),
            TextSpan(
              text: clip(phrase, chars - prefix.length),
              style: glow,
            ),
            TextSpan(
              text: clip(suffix, chars - prefix.length - phrase.length),
            ),
          ],
        );

        // Invisible full text reserves the final size so the layout
        // below doesn't jump while the line types out.
        return Stack(
          children: [
            Opacity(
              opacity: 0,
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: [
                    TextSpan(text: prefix),
                    TextSpan(
                      text: phrase,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: suffix),
                  ],
                ),
              ),
            ),
            Text.rich(visible),
          ],
        );
      },
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    // Lead-in is deliberately small; the UPSC Wars line is the highlight.
    final lead = RgText.display(
      size: 15 * scale,
      weight: FontWeight.w700,
      height: 1.25,
      color: RgColors.muted,
    );
    final accent =
        RgText.display(
          size: 26 * scale,
          weight: FontWeight.w800,
          height: 1.22,
          color: RgColors.tealDeep,
        ).copyWith(
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.underline,
          decorationColor: RgColors.tealDeep,
          decorationThickness: 1.6,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.onbLead, style: lead),
        SizedBox(height: 6 * scale),
        Text(context.l10n.onbAccent, style: accent),
      ],
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
        onb(context, 14),
        onb(context, 14),
        onb(context, 12),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(onb(context, 18)),
      ),
      child: Column(
        children: [
          top,
          SizedBox(height: onb(context, 10)),
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
          SizedBox(height: onb(context, 8)),
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
        icon: Icons.trending_down_rounded,
        title: context.l10n.onbAvoidMistakes,
        caption: context.l10n.onbReviseTopics,
        bg: AppColors.wrongBg,
        fg: RgColors.wrong,
      ),
      (
        icon: Icons.trending_up_rounded,
        title: context.l10n.onbAttemptMore,
        caption: context.l10n.onbGainMarks,
        bg: AppColors.correctBg,
        fg: RgColors.tealDeep,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: onb(context, 30),
                          height: onb(context, 30),
                          decoration: BoxDecoration(
                            color: items[i].bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            items[i].icon,
                            size: onb(context, 16),
                            color: items[i].fg,
                          ),
                        ),
                        SizedBox(width: onb(context, 8)),
                        Expanded(
                          child: Text(
                            items[i].title,
                            softWrap: true,
                            style: RgText.body(
                              size: onb(context, 11.5),
                              height: 1.3,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: onb(context, 6)),
                    // Bottom-align captions so both columns line up even
                    // when titles wrap to a different number of lines.
                    const Expanded(child: SizedBox.shrink()),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        items[i].caption,
                        softWrap: true,
                        textAlign: TextAlign.center,
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
