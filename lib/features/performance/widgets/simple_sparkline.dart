import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Minimal line chart for 0..1 (or unbounded) y values.
class SimpleSparkline extends StatelessWidget {
  const SimpleSparkline({super.key, required this.points, this.height = 72});

  final List<double> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(points: points),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.points});
  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    var minV = points.first;
    var maxV = points.first;
    for (final p in points) {
      if (p < minV) minV = p;
      if (p > maxV) maxV = p;
    }
    if (maxV == minV) {
      maxV = minV + 1e-6;
    }
    final w = size.width;
    final h = size.height;
    final n = points.length;
    if (n < 2) return;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final x = w * (i / (n - 1));
      final t = (points[i] - minV) / (maxV - minV);
      final y = h - t * h * 0.85 - h * 0.075;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
