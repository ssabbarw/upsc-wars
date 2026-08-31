import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class _ReviewCoachStep {
  const _ReviewCoachStep({
    required this.key,
    required this.title,
    required this.body,
  });

  final GlobalKey key;
  final String title;
  final String body;
}

/// One-shot demo coach: review mistakes, then review all questions.
class DemoResultsReviewCoachOverlay extends StatefulWidget {
  const DemoResultsReviewCoachOverlay({
    super.key,
    this.mistakesKey,
    required this.reviewAllKey,
    this.topicsKey,
    required this.onDismiss,
  });

  final GlobalKey? mistakesKey;
  final GlobalKey reviewAllKey;
  final GlobalKey? topicsKey;
  final VoidCallback onDismiss;

  @override
  State<DemoResultsReviewCoachOverlay> createState() =>
      _DemoResultsReviewCoachOverlayState();
}

class _DemoResultsReviewCoachOverlayState
    extends State<DemoResultsReviewCoachOverlay>
    with SingleTickerProviderStateMixin {
  late final List<_ReviewCoachStep> _steps;
  int _current = 0;
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _steps = [
      if (widget.mistakesKey != null)
        _ReviewCoachStep(
          key: widget.mistakesKey!,
          title: 'Review only your mistakes',
          body: 'Just the questions you got wrong — the ones worth going back to.',
        ),
      _ReviewCoachStep(
        key: widget.reviewAllKey,
        title: widget.mistakesKey != null
            ? 'Or review all questions'
            : 'Review all questions',
        body: 'The full paper, including the ones you got right.',
      ),
      if (widget.topicsKey != null)
        _ReviewCoachStep(
          key: widget.topicsKey!,
          title: 'You don’t have to remember this',
          body:
              'The same weak and strong topic lists live on every subject. '
              'Open a subject from Home anytime.',
        ),
    ];
    _anim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _next() {
    if (_current < _steps.length - 1) {
      _anim.reverse().then((_) async {
        if (!mounted) return;
        setState(() => _current++);
        await _ensureStepVisible(_steps[_current]);
        if (!mounted) return;
        setState(() {});
        _anim.forward();
      });
    } else {
      widget.onDismiss();
    }
  }

  Future<void> _ensureStepVisible(_ReviewCoachStep step) async {
    final ctx = step.key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.28,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Rect? _targetRect(_ReviewCoachStep step) {
    final ro = step.key.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_current >= _steps.length) return const SizedBox.shrink();
    final step = _steps[_current];
    final rect = _targetRect(step);
    final screenSize = MediaQuery.sizeOf(context);
    const pad = 8.0;
    final hole = rect?.inflate(pad);

    return FadeTransition(
      opacity: _fade,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            if (hole != null)
              CustomPaint(
                size: screenSize,
                painter: _ScrimWithHolePainter(
                  hole: hole,
                  color: Colors.black.withValues(alpha: 0.62),
                  radius: AppRadius.md,
                ),
              )
            else
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.62),
                ),
              ),
            const Positioned.fill(
              child: ModalBarrier(dismissible: false),
            ),
            if (hole != null)
              Positioned(
                left: hole.left,
                top: hole.top,
                width: hole.width,
                height: hole.height,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
            if (hole != null)
              _Bubble(
                hole: hole,
                screenSize: screenSize,
                scheme: scheme,
                title: step.title,
                body: step.body,
                current: _current + 1,
                total: _steps.length,
                onNext: _next,
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.hole,
    required this.screenSize,
    required this.scheme,
    required this.title,
    required this.body,
    required this.current,
    required this.total,
    required this.onNext,
  });

  final Rect hole;
  final Size screenSize;
  final ColorScheme scheme;
  final String title;
  final String body;
  final int current;
  final int total;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    const bubbleWidth = 300.0;
    const estimatedHeight = 188.0;
    const arrow = 10.0;
    const margin = 12.0;

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final minTop = viewPadding.top + margin;
    final maxTop =
        screenSize.height - viewPadding.bottom - estimatedHeight - margin;
    final topBound = maxTop < minTop ? minTop : maxTop;

    final belowY = hole.bottom + arrow + margin;
    final aboveY = hole.top - arrow - margin - estimatedHeight;
    final fitsBelow =
        belowY + estimatedHeight <= screenSize.height - viewPadding.bottom - margin;
    final fitsAbove = aboveY >= minTop;
    final bubbleTop = fitsBelow
        ? belowY
        : fitsAbove
            ? aboveY
            : minTop;
    final centreX = hole.center.dx - bubbleWidth / 2;
    final bubbleLeft = centreX.clamp(
      margin,
      screenSize.width - bubbleWidth - margin,
    );

    return Positioned(
      left: bubbleLeft,
      top: bubbleTop.clamp(minTop, topBound),
      width: bubbleWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.label().copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (total > 1)
                    Text(
                      '$current / $total',
                      style: AppTextStyles.caption().copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.info,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    current == total ? 'Got it' : 'Next',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrimWithHolePainter extends CustomPainter {
  const _ScrimWithHolePainter({
    required this.hole,
    required this.color,
    required this.radius,
  });

  final Rect hole;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScrimWithHolePainter old) =>
      old.hole != hole || old.color != color;
}
