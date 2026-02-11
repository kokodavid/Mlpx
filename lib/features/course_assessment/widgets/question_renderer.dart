import 'package:flutter/material.dart';
import '../models/question_model.dart';
import 'multiple_choice_image_question.dart';
import 'letter_recognition_question.dart';
import 'word_matching_question.dart';
import 'fill_in_blank_question.dart';
import 'true_false_question.dart';
import 'matching_options.dart';

class QuestionRenderer extends StatelessWidget {
  final AssessmentQuestion question;
  final String questionKey;
  final void Function(bool isCorrect)? onAnswerChecked;

  const QuestionRenderer({
    super.key,
    required this.question,
    required this.questionKey,
    this.onAnswerChecked,
  });

  @override
  Widget build(BuildContext context) {
    return switch (question.type) {
      'multiple_choice_image' => MultipleChoiceImageQuestion(
          question: question,
          questionKey: questionKey,
          onAnswerChecked: onAnswerChecked,
        ),
      'letter_recognition' => LetterRecognitionQuestion(
          question: question,
          questionKey: questionKey,
          onAnswerChecked: onAnswerChecked,
        ),
      'word_matching' => WordMatchingQuestion(
          question: question,
          questionKey: questionKey,
          onAnswerChecked: onAnswerChecked,
        ),
      'fill_in_blank' => FillInBlankQuestion(
          question: question,
          questionKey: questionKey,
          onAnswerChecked: onAnswerChecked,
        ),
      'true_false' => TrueFalseQuestion(
          question: question,
          questionKey: questionKey,
          onAnswerChecked: onAnswerChecked,
        ),
      'matching_options' => MatchingOptions(
          question: question,
          questionKey: questionKey,
          onAnswerChecked: onAnswerChecked,
        ),
      _ => _UnsupportedQuestionPlaceholder(type: question.type),
    };
  }
}

class _UnsupportedQuestionPlaceholder extends StatelessWidget {
  final String type;

  const _UnsupportedQuestionPlaceholder({required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Question type "$type" is not supported yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
