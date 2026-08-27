import 'package:flutter/material.dart';

class LessonStepCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Border? border;

  const LessonStepCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.elevation = 3,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06 * elevation / 3),
                    blurRadius: elevation * 4,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: padding,
        child: child,
      );
    }

    return Card(
      elevation: elevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: color,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
