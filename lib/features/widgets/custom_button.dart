import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:milpress/utils/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isFilled;
  final Color? fillColor;
  final Color? outlineColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double borderWidth;
  final TextStyle? textStyle;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFilled = true, // Default to filled
    this.fillColor,
    this.outlineColor,
    this.textColor,
    this.borderRadius = 12.0, // Consistent rounded corners
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderWidth = 2.0,
    this.textStyle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on isFilled and provided parameters
    final Color effectiveBackgroundColor = isFilled
        ? (fillColor ?? AppColors.primaryColor)
        : Colors.transparent; // Outlined button has transparent background

    final Color effectiveTextColor = textColor ??
        (isFilled ? AppColors.backgroundColor : (outlineColor ?? AppColors.primaryColor));

    final Color effectiveBorderColor = outlineColor ?? AppColors.primaryColor;

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: isFilled
              ? null // No border for filled button
              : Border.all(
                  color: effectiveBorderColor,
                  width: borderWidth,
                ),
          // boxShadow: isFilled // Optional: Add shadow to filled button for depth
          //     ? [
          //         BoxShadow(
          //           color: AppColors.primaryColor.withOpacity(0.3),
          //           spreadRadius: 1,
          //           blurRadius: 5,
          //           offset: const Offset(0, 3), // changes position of shadow
          //         ),
          //       ]
          //     : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      effectiveTextColor,
                    ),
                  ),
                )
              : Text(
                  text,
                  style: textStyle ??
                      TextStyle(
                        color: effectiveTextColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                ),
        ),
      ),
    );
  }
}
