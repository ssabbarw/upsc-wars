import 'package:flutter/material.dart';

/// Soft primary glow + slight scale pulse while [active], for unread chat hints.
class UnreadPulseWrapper extends StatefulWidget {
  const UnreadPulseWrapper({
    super.key,
    required this.active,
    required this.scheme,
    required this.child,
  });

  final bool active;
  final ColorScheme scheme;
  final Widget child;

  @override
  State<UnreadPulseWrapper> createState() => _UnreadPulseWrapperState();
}

class _UnreadPulseWrapperState extends State<UnreadPulseWrapper>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _startPulse();
    }
  }

  @override
  void didUpdateWidget(UnreadPulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _startPulse();
    } else if (!widget.active && oldWidget.active) {
      _stopPulse();
    }
  }

  void _startPulse() {
    _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _controller!.repeat(reverse: true);
  }

  void _stopPulse() {
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _controller == null) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller!.value);
        final primaryGlow = 0.28 + 0.32 * t;
        final blur = 10.0 + 12.0 * t;
        final scale = 1.0 + 0.055 * t;
        return Transform.scale(
          alignment: Alignment.center,
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: widget.scheme.primary.withValues(
                    alpha: primaryGlow * 0.55,
                  ),
                  blurRadius: blur,
                  spreadRadius: 0.8 * t,
                ),
                BoxShadow(
                  color: widget.scheme.error.withValues(alpha: 0.12 + 0.1 * t),
                  blurRadius: 6 + 4 * t,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
