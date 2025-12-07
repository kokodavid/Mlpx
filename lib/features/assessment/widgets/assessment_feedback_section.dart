import 'package:flutter/material.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'package:milpress/utils/app_colors.dart';

class AssessmentFeedbackSection extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  final VoidCallback? onTryAgain;
  final VoidCallback onGiveUp;
  final String? customMessage;
  final bool showCorrectAnswer;

  const AssessmentFeedbackSection({
    Key? key,
    required this.isCorrect,
    required this.correctAnswer,
    required this.onTryAgain,
    required this.onGiveUp,
    this.customMessage,
    this.showCorrectAnswer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCorrect) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Correct!',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Great job! You got it right.',
              style: TextStyle(
                color: Colors.green[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Feedback header
          Row(
            children: [
              Icon(Icons.close, color: Colors.red[600], size: 24),
              const SizedBox(width: 8),
              Text(
                'Incorrect answer',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Custom message or default
          Text(
            customMessage ?? 'That\'s not quite right. Try again or continue to see the correct answer.',
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 14,
            ),
          ),
          
          // Only show correct answer if showCorrectAnswer is true
          if (showCorrectAnswer) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The correct answer is:',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    correctAnswer,
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              if (onTryAgain != null) ...[
                Expanded(
                  child: CustomButton(
                    text: 'Try Again',
                    onPressed: onTryAgain,
                    isFilled: true,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: CustomButton(
                  text: onTryAgain != null ? 'Next' : 'Continue',
                  onPressed: onGiveUp,
                  isFilled: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 