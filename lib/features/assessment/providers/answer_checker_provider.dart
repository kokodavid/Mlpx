import 'package:flutter_riverpod/flutter_riverpod.dart';

final answerCheckerProvider = Provider<AnswerChecker>((ref) {
  return AnswerChecker();
});

class AnswerChecker {
  bool isCorrect(Map<String, dynamic> question, dynamic userAnswer) {
    final correctAnswer = question['correct_answer'];
    final type = question['question_type'];
    if (type == 'writing') {
      return (userAnswer as String).trim().toLowerCase() ==(correctAnswer as String).trim().toLowerCase();
    }
    // For all other types (multiple choice, word, letter, sentence, etc.)
    return userAnswer == correctAnswer;
  }
} 