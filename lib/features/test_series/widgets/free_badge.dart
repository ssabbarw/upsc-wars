import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Red scalloped "FREE" seal, used on free tests and in the series pitch.
///
/// Drawn in code so it stays sharp at any size and needs no asset.
class FreeBadge extends StatelessWidget {
  const FreeBadge({super.key, this.size = 32});

  /// Width and height of the seal.
  final double size;

  static const _red = Color(0xFFE4262D);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Free',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _SealPainter(_red),
          child: Center(
            child: Text(
              'FREE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.27,
                height: 1,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  const _SealPainter(this.color);

  final Color color;

  static const _bumps = 12;
  static const _depth = 0.07; // how deep the scallops cut, as a share of radius

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final path = Path();
    const steps = 144;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final radius = r * (1 - _depth + _depth * math.cos(_bumps * t));
      final p = Offset(
        c.dx + radius * math.cos(t),
        c.dy + radius * math.sin(t),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SealPainter old) => old.color != color;
}
