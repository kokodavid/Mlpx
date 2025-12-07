import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/on_boarding_quiz_model.dart';

const List<String> onboardingStageOrder = [
  'letter_recognition',
  'word_recognition',
  'sentence_comprehension',
  'writing_ability',
];

final sortedOnboardingQuizProvider = Provider.family<List<OnboardingQuizModel>, List<OnboardingQuizModel>>((ref, quizzes) {
  final sorted = List<OnboardingQuizModel>.from(quizzes);
  sorted.sort((a, b) {
    final stageA = onboardingStageOrder.indexOf(a.stage);
    final stageB = onboardingStageOrder.indexOf(b.stage);
    if (stageA != stageB) {
      return stageA.compareTo(stageB);
    }
    // If same stage, sort by difficultyLevel (nulls last)
    final diffA = a.difficultyLevel ?? 9999;
    final diffB = b.difficultyLevel ?? 9999;
    return diffA.compareTo(diffB);
  });
  return sorted;
}); 