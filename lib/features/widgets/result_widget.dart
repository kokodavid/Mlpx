import 'package:flutter/material.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';

class ResultWidget extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final VoidCallback onContinue;

  ResultWidget({
    required this.isCorrect,
    required this.correctAnswer,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isCorrect ? AppColors.sandColor : AppColors.errorLightShade,
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? 'Correct answer' : 'Incorrect answer',
            style: TextStyle(
              color: isCorrect ? AppColors.primaryColor : AppColors.errorColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            isCorrect ? 'Reason why; to be typed here' : 'The correct Answer is: $correctAnswer',
            style: TextStyle(
              color: isCorrect ? AppColors.primaryColor : AppColors.errorColor,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16.0),
          CustomButton(
            onPressed: onContinue,
            text: 'Continue',
            fillColor: isCorrect ? AppColors.primaryColor : AppColors.errorColor,
          ),
          
        ],
      ),
    );
  }
}
