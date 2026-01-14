import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:milpress/config/router.dart';
import 'package:milpress/features/course/course_models/complete_course_model.dart';
import 'package:milpress/features/course/course_models/course_model.dart';
import 'package:milpress/features/course/course_models/lesson_model.dart';
import 'package:milpress/features/course/course_models/lesson_quiz_model.dart';
import 'package:milpress/features/course/course_models/module_model.dart';
import 'package:milpress/features/on_boarding/models/on_boarding_quiz_model.dart';
import 'package:milpress/features/user_progress/models/course_progress_model.dart';
import 'package:milpress/features/user_progress/models/lesson_progress_model.dart';
import 'package:milpress/features/user_progress/models/module_progress_model.dart';
import 'package:milpress/features/reviews/models/bookmark_model.dart';
import 'package:milpress/features/assessment/models/assessment_result_model.dart';
import 'package:milpress/features/widgets/connectivity_sheet_listener.dart';
import 'package:milpress/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(CompleteCourseModelAdapter());
  Hive.registerAdapter(ModuleWithLessonsAdapter());
  Hive.registerAdapter(CourseModelAdapter());
  Hive.registerAdapter(ModuleModelAdapter());
  Hive.registerAdapter(LessonModelAdapter());
  Hive.registerAdapter(LessonQuizModelAdapter());
  Hive.registerAdapter(OnboardingQuizModelAdapter());
  Hive.registerAdapter(LessonProgressModelAdapter());
  Hive.registerAdapter(CourseProgressModelAdapter());
  Hive.registerAdapter(ModuleProgressModelAdapter());
  Hive.registerAdapter(BookmarkModelAdapter());
  Hive.registerAdapter(AssessmentResultModelAdapter());
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authStateProvider);
    
    return MaterialApp.router(
      title: 'Milpress',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ConnectivitySheetListener(
          navigatorKey: router.routerDelegate.navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
