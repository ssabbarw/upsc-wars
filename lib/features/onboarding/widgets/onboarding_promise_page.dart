import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/theme/app_colors.dart';
import '../../mini_games/shared/revision_games_theme.dart';
import 'onboarding_scale.dart';

class _PromiseLine {
  const _PromiseLine({
    required this.accent,
    required this.body,
    required this.tint,
    required this.accentColor,
  });

  final String accent;
  final String body;
  final Color tint;
  final Color accentColor;
}

const _kLines = [
  _PromiseLine(
    accent: 'Confidently wrong',
    body:
        'UPSC Wars helps you identify topics where you are confidently wrong '
        'so that you can revise them.',
    tint: AppColors.wrongBg,
    accentColor: RgColors.wrong,
  ),
  _PromiseLine(
    accent: 'Guesses going right',
    body:
        'It helps you find topics where your guesses are going right so that '
        'you can take more risks in the exam from that subject or topic. '
        'It gives you a detailed explanation, deep diving into statement '
        'analysis and trap explanation.',
    tint: AppColors.correctBg,
    accentColor: RgColors.tealDeep,
  ),
];

/// Screen 3 — animated promise lines with checkmarks; CTAs unlock when done.
class OnboardingPromisePage extends HookWidget {
  const OnboardingPromisePage({
    super.key,
    required this.isActive,
    required this.onGetStarted,
    required this.onSkip,
  });

  final bool isActive;
  final VoidCallback onGetStarted;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final revealed = useState(0); // how many lines fully in
    final highlight = useState(-1); // currently emphasizing
    final ready = useState(false);
    final started = useRef(false);

    useEffect(() {
      if (!isActive || started.value) return null;
      started.value = true;

      final timers = <Timer>[];

      void schedule(Duration delay, void Function() fn) {
        timers.add(Timer(delay, fn));
      }

      // Line 1 appears → highlight → settle
      schedule(const Duration(milliseconds: 280), () {
        revealed.value = 1;
        highlight.value = 0;
      });
      schedule(const Duration(milliseconds: 1400), () {
        highlight.value = -1;
      });

      // Line 2 appears → highlight → settle → unlock CTAs
      schedule(const Duration(milliseconds: 1750), () {
        revealed.value = 2;
        highlight.value = 1;
      });
      schedule(const Duration(milliseconds: 3200), () {
        highlight.value = -1;
        ready.value = true;
      });

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
                  'WHAT UPSC WARS DOES',
                  style: RgText.mono(
                    size: onb(context, 12),
                    letterSpacingEm: 0.13,
                    color: RgColors.tealDeep,
                  ),
                ),
                SizedBox(height: onb(context, 10)),
                Text(
                  'Two things that change how you prep.',
                  style: RgText.display(
                    size: onb(context, 24),
                    weight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: onb(context, 28)),
                for (var i = 0; i < _kLines.length; i++) ...[
                  if (i > 0) SizedBox(height: onb(context, 16)),
                  _AnimatedPromiseCard(
                    line: _kLines[i],
                    visible: revealed.value > i,
                    highlighted: highlight.value == i,
                    settled: revealed.value > i && highlight.value != i,
                    index: i,
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: onb(context, 14)),
        AnimatedOpacity(
          opacity: ready.value ? 1 : 0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !ready.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: onGetStarted,
                  style: RgText.pillButton(
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
                    'Get started',
                    style: RgText.body(
                      size: onb(context, 17),
                      weight: FontWeight.w700,
                      color: RgColors.onDark,
                    ),
                  ),
                ),
                SizedBox(height: onb(context, 6)),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: RgColors.muted,
                    padding: EdgeInsets.symmetric(vertical: onb(context, 12)),
                  ),
                  child: Text(
                    'Skip',
                    style: RgText.mono(
                      size: onb(context, 12),
                      letterSpacingEm: 0.06,
                      color: RgColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedPromiseCard extends StatelessWidget {
  const _AnimatedPromiseCard({
    required this.line,
    required this.visible,
    required this.highlighted,
    required this.settled,
    required this.index,
  });

  final _PromiseLine line;
  final bool visible;
  final bool highlighted;
  final bool settled;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 0.18),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        opacity: visible ? 1 : 0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 480),
          curve: Curves.easeOutBack,
          scale: highlighted ? 1.02 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.all(onb(context, 18)),
            decoration: BoxDecoration(
              color: highlighted
                  ? line.tint
                  : settled
                  ? RgColors.card
                  : line.tint.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(onb(context, 18)),
              border: Border.all(
                color: highlighted
                    ? line.accentColor.withValues(alpha: 0.45)
                    : RgColors.border,
                width: highlighted ? 1.6 : 1,
              ),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: line.accentColor.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CheckMark(
                  visible: visible,
                  highlighted: highlighted,
                  color: line.accentColor,
                  delayMs: 180,
                ),
                SizedBox(width: onb(context, 14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 280),
                        style: RgText.mono(
                          size: onb(context, 12),
                          letterSpacingEm: 0.08,
                          color: highlighted || settled
                              ? line.accentColor
                              : RgColors.mutedSoft,
                        ),
                        child: Text(
                          '${index + 1 < 10 ? '0' : ''}${index + 1}  ·  '
                          '${line.accent.toUpperCase()}',
                        ),
                      ),
                      SizedBox(height: onb(context, 8)),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 280),
                        style: RgText.body(
                          size: onb(context, 16),
                          height: 1.45,
                          weight: highlighted
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: highlighted || settled
                              ? RgColors.ink
                              : RgColors.muted,
                        ),
                        child: Text(line.body),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckMark extends HookWidget {
  const _CheckMark({
    required this.visible,
    required this.highlighted,
    required this.color,
    required this.delayMs,
  });

  final bool visible;
  final bool highlighted;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final popped = useState(false);
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 520),
    );
    final scale = useMemoized(
      () => TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 1.22).chain(
            CurveTween(curve: Curves.easeOutBack),
          ),
          weight: 70,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.22, end: 1),
          weight: 30,
        ),
      ]).animate(controller),
      [controller],
    );
    final checkProgress = useMemoized(
      () => CurvedAnimation(
        parent: controller,
        curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
      ),
      [controller],
    );

    useEffect(() {
      if (!visible || popped.value) return null;
      final t = Timer(Duration(milliseconds: delayMs), () {
        popped.value = true;
        unawaited(controller.forward());
      });
      return t.cancel;
    }, [visible]);

    final size = onb(context, 34);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.scale(
          scale: popped.value ? scale.value : 0,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: CustomPaint(
              painter: _CheckStrokePainter(
                progress: checkProgress.value,
                color: RgColors.onDark,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckStrokePainter extends CustomPainter {
  _CheckStrokePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.72, size.height * 0.34);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckStrokePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
