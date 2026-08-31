import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// One-shot demo coach: hole around the EN | हि toggle + bilingual tip.
class DemoLanguageCoachOverlay extends StatefulWidget {
  const DemoLanguageCoachOverlay({
    super.key,
    required this.toggleKey,
    required this.onDismiss,
  });

  final GlobalKey toggleKey;
  final VoidCallback onDismiss;

  @override
  State<DemoLanguageCoachOverlay> createState() =>
      _DemoLanguageCoachOverlayState();
}

class _DemoLanguageCoachOverlayState extends State<DemoLanguageCoachOverlay>
    with SingleTickerProviderStateMixin {
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

  Rect? _toggleRect() {
    final ro = widget.toggleKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenSize = MediaQuery.sizeOf(context);
    final rect = _toggleRect();
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
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.62)),
              ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDismiss,
              ),
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
                onDismiss: widget.onDismiss,
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
    required this.onDismiss,
  });

  final Rect hole;
  final Size screenSize;
  final ColorScheme scheme;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    const bubbleWidth = 300.0;
    const estimatedHeight = 196.0;
    const arrow = 10.0;
    const margin = 12.0;

    final belowY = hole.bottom + arrow + margin;
    final placeBelow = belowY + estimatedHeight < screenSize.height - 24;
    final bubbleTop = placeBelow
        ? belowY
        : hole.top - arrow - margin - estimatedHeight;
    final centreX = hole.center.dx - bubbleWidth / 2;
    final bubbleLeft = centreX.clamp(
      margin,
      screenSize.width - bubbleWidth - margin,
    );

    return Positioned(
      left: bubbleLeft,
      top: bubbleTop.clamp(
        margin,
        screenSize.height - estimatedHeight - margin,
      ),
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
              Text(
                'Tap EN | हि to Change language',
                style: AppTextStyles.label().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'भाषा बदलने के लिए EN | हि टैप करें',
                style: AppTextStyles.label().copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Questions and explanations switch instantly.\n'
                'सवाल और व्याख्या तुरंत बदल जाएंगे।',
                style: AppTextStyles.bodySm().copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onDismiss,
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
                  child: const Text(
                    'Got it · समझ गया',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
