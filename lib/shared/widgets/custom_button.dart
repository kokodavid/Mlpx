import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isPrimary;
  final bool isFullWidth;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isPrimary = true,
    this.isFullWidth = false,
    this.width,
    this.height = 48.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    this.backgroundColor,
    this.textColor,
    this.fontSize = 16.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? theme.primaryColor,
            foregroundColor: textColor ?? theme.colorScheme.onPrimary,
            padding: padding,
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8.0),
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: textColor ?? theme.primaryColor,
            padding: padding,
            side: BorderSide(color: theme.primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(8.0),
            ),
          );

    final button = isPrimary
        ? ElevatedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: buttonStyle,
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
            ),
          );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    }

    if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return SizedBox(
      height: height,
      child: button,
    );
  }
}
