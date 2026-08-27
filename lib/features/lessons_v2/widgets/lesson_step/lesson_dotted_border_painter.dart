import 'package:flutter/material.dart';

class LessonDottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dotSize;
  final double dotGap;
  final double borderRadius;

  const LessonDottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dotSize,
    required this.dotGap,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final half = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          half, half, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final total = metric.length;
    final dotRadius = strokeWidth / 2;
    final step = dotSize + dotGap;

    for (double distance = 0; distance < total; distance += step) {
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          dotRadius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LessonDottedBorderPainter old) =>
      old.color != color ||
      old.dotSize != dotSize ||
      old.dotGap != dotGap ||
      old.strokeWidth != strokeWidth ||
      old.borderRadius != borderRadius;
}
