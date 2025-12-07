import 'package:flutter/material.dart';

class CustomProgressIndicator extends StatelessWidget {
  final double progress; // Value between 0.0 and 1.0

  CustomProgressIndicator({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(10, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.0),
            height: 12.0,
            decoration: BoxDecoration(
              color: index < (progress * 10) ? Colors.orange : Colors.grey[300],
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        );
      }),
    );
  }
} 
