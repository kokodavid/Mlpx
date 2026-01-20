import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/lesson_models.dart';
import '../providers/lesson_audio_providers.dart';
import '../providers/lesson_providers.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/lesson_progress_header.dart';
import '../widgets/lesson_step_renderer.dart';

class LessonAttemptScreen extends ConsumerStatefulWidget {
  final LessonDefinition? lessonDefinition;
  final String? lessonId;
  final int initialStepIndex;
  final VoidCallback? onFinish;

  LessonAttemptScreen({
    super.key,
    this.lessonDefinition,
    this.lessonId,
    this.initialStepIndex = 0,
    this.onFinish,
  }) : assert(
          lessonDefinition != null || lessonId != null,
          'Provide either lessonDefinition or lessonId.',
        ),
        assert(
          lessonDefinition == null || lessonDefinition.steps.length > 0,
          'LessonDefinition must include at least one step.',
        );

  @override
  ConsumerState<LessonAttemptScreen> createState() =>
      _LessonAttemptScreenState();
}

class _LessonAttemptScreenState extends ConsumerState<LessonAttemptScreen> {
  late int _currentStepIndex;
  LessonStepUiState _stepUiState = const LessonStepUiState();
  LessonDefinition? _loadedLesson;

  LessonDefinition get _lessonDefinition =>
      _loadedLesson ?? widget.lessonDefinition!;

  LessonStepDefinition get _currentStep =>
      _lessonDefinition.steps[_currentStepIndex];

  @override
  void initState() {
    super.initState();
    if (widget.lessonDefinition != null) {
      _loadedLesson = widget.lessonDefinition;
      _currentStepIndex = widget.initialStepIndex.clamp(
        0,
        widget.lessonDefinition!.steps.length - 1,
      );
    }
  }

  void _onStepStateChanged(LessonStepUiState state) {
    setState(() {
      _stepUiState = state;
    });
  }

  bool get _isLastStep =>
      _currentStepIndex >= _lessonDefinition.steps.length - 1;

  int get _progressPercent {
    final steps = _lessonDefinition.steps;
    final requiredSteps = steps.where((step) => step.required).toList();
    if (requiredSteps.isEmpty) {
      return 0;
    }

    final currentRequiredIndex = requiredSteps.indexOf(_currentStep);
    final currentPosition = currentRequiredIndex >= 0
        ? currentRequiredIndex + 1
        : requiredSteps.length;
    final percent = (currentPosition / requiredSteps.length) * 100;
    return percent.round().clamp(0, 100);
  }

  bool _defaultCanAdvance(LessonStepDefinition step) {
    if (step.type == LessonStepType.assessment) {
      return false;
    }
    return true;
  }

  String _defaultPrimaryLabel(LessonStepDefinition step) {
    if (_isLastStep) {
      return 'Finish';
    }
    if (step.type == LessonStepType.assessment) {
      return 'Check Answers';
    }
    return 'Continue';
  }

  void _goBack() {
    ref.read(lessonAudioControllerProvider).stop();
    if (_currentStepIndex <= 0) {
      return;
    }
    setState(() {
      _currentStepIndex -= 1;
      _stepUiState = const LessonStepUiState();
    });
  }

  void _goForward() {
    ref.read(lessonAudioControllerProvider).stop();
    if (!_isLastStep) {
      setState(() {
        _currentStepIndex += 1;
        _stepUiState = const LessonStepUiState();
      });
      return;
    }
    if (widget.onFinish != null) {
      widget.onFinish!.call();
      return;
    }
    if (mounted) {
      context.push(
        '/lesson-complete-v2',
        extra: {
          'lessonId': _lessonDefinition.id,
          'moduleId': _lessonDefinition.moduleId,
          'lessonTitle': _lessonDefinition.title,
        },
      );
    }
  }

  @override
  void dispose() {
    ref.read(lessonAudioControllerProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lessonId != null) {
      ref.listen<AsyncValue<LessonDefinition?>>(
        lessonDefinitionProvider(widget.lessonId!),
        (previous, next) {
          next.whenData((lesson) {
            if (!mounted || lesson == null) {
              return;
            }
            if (_loadedLesson?.id == lesson.id) {
              return;
            }
            setState(() {
              _loadedLesson = lesson;
              _currentStepIndex = widget.initialStepIndex.clamp(
                0,
                lesson.steps.length - 1,
              );
            });
          });
        },
      );
    }
    if (widget.lessonDefinition == null && _loadedLesson == null) {
      final lessonId = widget.lessonId ?? '';
      if (lessonId.isEmpty) {
        return const Scaffold(
          body: Center(child: Text('Lesson not found')),
        );
      }
      final lessonAsync = ref.watch(lessonDefinitionProvider(lessonId));
      return Scaffold(
        backgroundColor: AppColors.sandyLight,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.black),
              onPressed: () {},
            ),
          ],
          centerTitle: true,
          title: const Text(
            'Lesson',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: lessonAsync.when(
          data: (lesson) {
            if (lesson == null) {
              return const Center(child: Text('Lesson not found'));
            }
            return const Center(child: CircularProgressIndicator());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading lesson')),
        ),
      );
    }

    final canAdvance =
        _stepUiState.canAdvance ?? _defaultCanAdvance(_currentStep);
    final isPrimaryEnabled = _stepUiState.isPrimaryEnabled ??
        (_stepUiState.onPrimaryPressed != null || canAdvance);
    final primaryLabel =
        _stepUiState.primaryLabel ?? _defaultPrimaryLabel(_currentStep);
    final showBack = _stepUiState.showBack ?? true;
    final primaryIcon = _resolvePrimaryIcon(primaryLabel);
    final primaryColor =
        primaryLabel == 'Finish' ? AppColors.correctAnswerColor : null;

    return Scaffold(
      backgroundColor: AppColors.sandyLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
        title: Text(
          _lessonDefinition.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _buildContent(
        canAdvance: canAdvance,
        isPrimaryEnabled: isPrimaryEnabled,
        primaryLabel: primaryLabel,
        primaryIcon: primaryIcon,
        primaryColor: primaryColor,
        showBack: showBack,
      ),
    );
  }

  Widget _buildContent({
    required bool canAdvance,
    required bool isPrimaryEnabled,
    required String primaryLabel,
    required IconData? primaryIcon,
    required Color? primaryColor,
    required bool showBack,
  }) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: LessonProgressHeader(
              label: _lessonDefinition.progressLabel,
              percent: _progressPercent,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey(_currentStep.key),
                child: LessonStepRenderer(
                  step: _currentStep,
                  lessonId: _lessonDefinition.id,
                  onStepStateChanged: _onStepStateChanged,
                  isLastStep: _isLastStep,
                ),
              ),
            ),
          ),
          LessonBottomActionBar(
            canGoBack: showBack && _currentStepIndex > 0,
            isPrimaryEnabled: isPrimaryEnabled,
            primaryLabel: primaryLabel,
            primaryIcon: primaryIcon,
            primaryColor: primaryColor,
            onPrimaryPressed: () {
              if (_stepUiState.onPrimaryPressed != null) {
                _stepUiState.onPrimaryPressed!.call();
                return;
              }
              if (canAdvance) {
                _goForward();
              }
            },
            onBackPressed: _goBack,
          ),
        ],
      ),
    );
  }

  IconData? _resolvePrimaryIcon(String label) {
    if (label == 'Check Answers') {
      return Icons.check;
    }
    if (label == 'Retry') {
      return Icons.refresh;
    }
    return null;
  }
}
