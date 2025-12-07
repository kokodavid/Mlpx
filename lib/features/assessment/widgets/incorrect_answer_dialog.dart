import 'package:flutter/material.dart';
import 'package:milpress/features/widgets/custom_button.dart';

class IncorrectAnswerDialog extends StatelessWidget {
  final String correctAnswer;
  final VoidCallback onGotIt;

  const IncorrectAnswerDialog({
    Key? key,
    required this.correctAnswer,
    required this.onGotIt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismiss by back button
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close, color: Colors.red, size: 36),
            const SizedBox(height: 12),
            const Text('Incorrect Answer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: 'The correct Answer is: ',
                style: const TextStyle(fontSize: 16),
                children: [
                  TextSpan(
                    text: correctAnswer,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Got It',
              onPressed: onGotIt,
              isFilled: true,
            ),
          ],
        ),
      ),
    );
  }
} 