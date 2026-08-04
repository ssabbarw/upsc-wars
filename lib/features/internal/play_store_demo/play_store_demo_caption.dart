import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'play_store_demo_script.dart';

/// Big, beat-specific overlay copy — placement varies so it never fights the UI.
///
/// Designed to sit as a direct [Stack] child (uses [Positioned.fill]).
class PlayStoreDemoCaptionOverlay extends StatelessWidget {
  const PlayStoreDemoCaptionOverlay({required this.step, super.key});

  final PlayStoreDemoStep step;

  @override
  Widget build(BuildContext context) {
    if (step.anchor == DemoCaptionAnchor.none) {
      return const SizedBox.shrink();
    }

    final pad = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final bubble = _CaptionBubble(
      key: ValueKey('${step.beat}-caption'),
      caption: step.caption,
      subCaption: step.subCaption,
      accent: step.accent,
      align: _textAlignFor(step.anchor),
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            switch (step.anchor) {
              DemoCaptionAnchor.none => const SizedBox.shrink(),
              DemoCaptionAnchor.top => Positioned(
                left: 20,
                right: 20,
                top: pad.top + 16,
                child: bubble,
              ),
              DemoCaptionAnchor.topLeft => Positioned(
                left: 18,
                right: width * 0.28,
                top: pad.top + 18,
                child: bubble,
              ),
              DemoCaptionAnchor.topRight => Positioned(
                left: width * 0.28,
                right: 18,
                top: pad.top + 18,
                child: bubble,
              ),
              DemoCaptionAnchor.center => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: bubble,
                ),
              ),
              DemoCaptionAnchor.bottom => Positioned(
                left: 20,
                right: 20,
                bottom: pad.bottom + 28,
                child: bubble,
              ),
              DemoCaptionAnchor.bottomLeft => Positioned(
                left: 18,
                right: width * 0.22,
                bottom: pad.bottom + 32,
                child: bubble,
              ),
            },
          ],
        ),
      ),
    );
  }

  static TextAlign _textAlignFor(DemoCaptionAnchor anchor) {
    return switch (anchor) {
      DemoCaptionAnchor.topRight => TextAlign.right,
      DemoCaptionAnchor.topLeft ||
      DemoCaptionAnchor.bottomLeft => TextAlign.left,
      DemoCaptionAnchor.top ||
      DemoCaptionAnchor.bottom ||
      DemoCaptionAnchor.center ||
      DemoCaptionAnchor.none => TextAlign.center,
    };
  }
}

class _CaptionBubble extends StatelessWidget {
  const _CaptionBubble({
    super.key,
    required this.caption,
    required this.subCaption,
    required this.accent,
    required this.align,
  });

  final String caption;
  final String? subCaption;
  final Color accent;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final cross = switch (align) {
      TextAlign.right => CrossAxisAlignment.end,
      TextAlign.left => CrossAxisAlignment.start,
      _ => CrossAxisAlignment.center,
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: cross,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: cross,
              children: [
                Text(
                  caption,
                  textAlign: align,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 28,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subCaption != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subCaption!,
                    textAlign: align,
                    style: GoogleFonts.dmSans(
                      fontSize: subCaption!.length > 42 ? 13 : 14,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
