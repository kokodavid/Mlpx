import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../models/on_boarding_quiz_model.dart';

class OnboardingQuizService {
  final SupabaseClient supabase;
  static const String hiveBoxName = 'onboarding_quiz';

  OnboardingQuizService(this.supabase);

  Future<List<OnboardingQuizModel>> fetchQuestionsFromSupabase() async {
    final response = await supabase.from('assessment_questions').select();
    return (response as List)
        .map((json) => OnboardingQuizModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveQuestionsToHive(List<OnboardingQuizModel> questions) async {
    final box = await Hive.openBox<OnboardingQuizModel>(hiveBoxName);
    await box.clear();
    await box.addAll(questions);
  }

  Future<List<OnboardingQuizModel>> loadQuestionsFromHive() async {
    final box = await Hive.openBox<OnboardingQuizModel>(hiveBoxName);
    return box.values.toList();
  }

  Future<void> clearLocalCache() async {
    final box = await Hive.openBox<OnboardingQuizModel>(hiveBoxName);
    await box.clear();
  }
} 