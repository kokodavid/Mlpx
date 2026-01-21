import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TracingCanvasController {
  VoidCallback? _clear;

  void _bindClear(VoidCallback clear) {
    _clear = clear;
  }

  void clear() {
    _clear?.call();
  }
}

class TracingCanvas extends StatefulWidget {
  final Color strokeColor;
  final double strokeWidth;
  final TracingCanvasController? controller;

  const TracingCanvas({
    super.key,
    this.strokeColor = const Color(0xFF142C44),
    this.strokeWidth = 4,
    this.controller,
  });

  @override
  State<TracingCanvas> createState() => _TracingCanvasState();
}

class _TracingCanvasState extends State<TracingCanvas> {
  final List<Offset?> _points = [];
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  ScrollHoldController? _scrollHold;

  @override
  void initState() {
    super.initState();
    widget.controller?._bindClear(_clearCanvas);
  }

  void _clearCanvas() {
    _points.clear();
    _repaint.value++;
  }

  void _startScrollHold() {
    _scrollHold ??= Scrollable.of(context)?.position.hold(() {});
  }

  void _endScrollHold() {
    _scrollHold?.cancel();
    _scrollHold = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: GestureDetector(
            onPanStart: (details) {
              _startScrollHold();
              _points.add(details.localPosition);
              _repaint.value++;
            },
            onPanUpdate: (details) {
              _points.add(details.localPosition);
              _repaint.value++;
            },
            onPanEnd: (_) {
              _endScrollHold();
              _points.add(null);
              _repaint.value++;
            },
            onPanCancel: () {
              _endScrollHold();
            },
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: CustomPaint(
                painter: _TracingPainter(
                  points: _points,
                  strokeColor: widget.strokeColor,
                  strokeWidth: widget.strokeWidth,
                  repaint: _repaint,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _endScrollHold();
    _repaint.dispose();
    super.dispose();
  }
}

class _TracingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;
  final double strokeWidth;

  _TracingPainter({
    required this.points,
    required this.strokeColor,
    required this.strokeWidth,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TracingPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
