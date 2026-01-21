import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/lesson_models.dart';
import '../widgets/lesson_audio_buttons.dart';

class AssessmentStep extends ConsumerStatefulWidget {
  final LessonStepDefinition step;
  final String lessonId;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final bool isLastStep;

  const AssessmentStep({
    super.key,
    required this.step,
    required this.lessonId,
    required this.onStepStateChanged,
    required this.isLastStep,
  });

  @override
  ConsumerState<AssessmentStep> createState() => _AssessmentStepState();
}

final _assessmentStepControllerProvider = StateNotifierProvider.autoDispose
    .family<AssessmentStepController, AssessmentStepState, String>(
      (ref, stepKey) => AssessmentStepController(),
);

class _AssessmentStepState extends ConsumerState<AssessmentStep> {
  AssessmentStepController get _controller => ref.read(
    _assessmentStepControllerProvider(
      '${widget.lessonId}:${widget.step.key}',
    ).notifier,
  );

  AssessmentStepState get _state =>
      ref.watch(
        _assessmentStepControllerProvider(
          '${widget.lessonId}:${widget.step.key}',
        ),
      );

  @override
  void initState() {
    super.initState();
    _controller.retry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(
        LessonStepUiState(
          canAdvance: false,
          isPrimaryEnabled: false,
          primaryLabel: 'Check Answers',
          onPrimaryPressed: _handleCheck,
        ),
      );
    });
  }

  void _handleCheck() {
    if (_state.hasChecked) {
      return;
    }
    final correctFlags = _buildCorrectFlags();
    final allCorrect = _controller.checkAnswers(correctFlags);
    widget.onStepStateChanged(
      LessonStepUiState(
        canAdvance: allCorrect,
        isPrimaryEnabled: true,
        primaryLabel: allCorrect
            ? (widget.isLastStep ? 'Finish' : 'Continue')
            : 'Retry',
        onPrimaryPressed: allCorrect ? null : _handleRetry,
      ),
    );
  }

  void _handleRetry() {
    _controller.retry();
    widget.onStepStateChanged(
      const LessonStepUiState(
        canAdvance: false,
        isPrimaryEnabled: false,
        primaryLabel: 'Check Answers',
      ),
    );
  }

  List<bool> _buildCorrectFlags() {
    final options = (widget.step.config['options'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    return options
        .map((item) => item['is_correct'] as bool? ?? false)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Assessment';
    final prompt =
        widget.step.config['prompt'] as String? ?? 'Choose the correct answers';
    final hint = widget.step.config['hint'] as String? ??
        'Select all correct answers, then tap "Check \nAnswers".';
    final instructionUrl =
        widget.step.config['sound_instruction_url'] as String? ?? '';
    final options = (widget.step.config['options'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            prompt,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LessonAudioInlineButton(
              sourceId: '${widget.step.key}-instruction',
              url: instructionUrl,
              label: 'Click here to listen',
              backgroundColor: Colors.pink[100], // Add pink background here
            ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.isEmpty ? 6 : options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final item = options[index];
              final label = item['label'] as String? ?? 'Item';
              final imageUrl = item['image_url'] as String? ?? '';
              final isCorrect = item['is_correct'] as bool? ?? false;
              final isSelected = _state.selectedIndices.contains(index);
              return _AssessmentOption(
                label: label,
                imageUrl: imageUrl,
                isCorrect: isCorrect,
                isSelected: isSelected,
                isChecked: _state.hasChecked,
                onTap: () {
                  _controller.toggleSelection(index);
                  if (!_state.hasChecked) {
                    final hasSelection = ref
                        .read(
                      _assessmentStepControllerProvider(
                        '${widget.lessonId}:${widget.step.key}',
                      ),
                    )
                        .selectedIndices
                        .isNotEmpty;
                    widget.onStepStateChanged(
                      LessonStepUiState(
                        canAdvance: false,
                        isPrimaryEnabled: hasSelection,
                        primaryLabel: 'Check Answers',
                        onPrimaryPressed: hasSelection ? _handleCheck : null,
                      ),
                    );
                  }
                },
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Text(
              hint,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textColor,
              ),
            ),
          ),

          // Feedback Section
          if (_state.hasChecked)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _state.isCorrect
                  ? _SuccessFeedback()
                  : _ErrorFeedback(),
            ),
        ],
      ),
    );
  }
}

class _SuccessFeedback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        border: Border(
          top: BorderSide(
            color: AppColors.successColor,
            width: 1,
          ),
          bottom: BorderSide(
            color: AppColors.successColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFF66BB6A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Excellent work!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'You identified the sounds correctly!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorFeedback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: AppColors.accentColor,
        border: Border(
          top: BorderSide(
            color: AppColors.errorColor,
            width: 1,
          ),
          bottom: BorderSide(
            color: AppColors.errorColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: AppColors.errorColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.face,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep going!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Review the correct answers above and try to \nhear the difference.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentOption extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool isCorrect;
  final bool isSelected;
  final bool isChecked;
  final VoidCallback onTap;

  const _AssessmentOption({
    required this.label,
    required this.imageUrl,
    required this.isCorrect,
    required this.isSelected,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _resolveBorderColor();
    return GestureDetector(
      onTap: isChecked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: imageUrl.isEmpty
                    ? const Icon(
                  Icons.image_outlined,
                  size: 26,
                  color: AppColors.textColor,
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _resolveBorderColor() {
    if (!isChecked) {
      return isSelected ? AppColors.primaryColor : AppColors.borderColor;
    }
    if (!isSelected) {
      return AppColors.borderColor;
    }
    return isCorrect ? AppColors.correctAnswerColor : AppColors.errorColor;
  }
}

class AssessmentStepState {
  final Set<int> selectedIndices;
  final bool hasChecked;
  final bool isCorrect;

  const AssessmentStepState({
    this.selectedIndices = const {},
    this.hasChecked = false,
    this.isCorrect = false,
  });

  AssessmentStepState copyWith({
    Set<int>? selectedIndices,
    bool? hasChecked,
    bool? isCorrect,
  }) {
    return AssessmentStepState(
      selectedIndices: selectedIndices ?? this.selectedIndices,
      hasChecked: hasChecked ?? this.hasChecked,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class AssessmentStepController extends StateNotifier<AssessmentStepState> {
  AssessmentStepController() : super(const AssessmentStepState());

  void toggleSelection(int index) {
    if (state.hasChecked) {
      return;
    }
    final updated = Set<int>.from(state.selectedIndices);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      updated.add(index);
    }
    state = state.copyWith(selectedIndices: updated);
  }

  bool checkAnswers(List<bool> correctFlags) {
    if (correctFlags.isEmpty) {
      state = state.copyWith(hasChecked: true, isCorrect: false);
      return false;
    }
    final selected = state.selectedIndices;
    if (selected.isEmpty) {
      state = state.copyWith(hasChecked: true, isCorrect: false);
      return false;
    }
    for (final index in selected) {
      if (index < 0 || index >= correctFlags.length) {
        state = state.copyWith(hasChecked: true, isCorrect: false);
        return false;
      }
      if (!correctFlags[index]) {
        state = state.copyWith(hasChecked: true, isCorrect: false);
        return false;
      }
    }
    for (var i = 0; i < correctFlags.length; i++) {
      if (correctFlags[i] && !selected.contains(i)) {
        state = state.copyWith(hasChecked: true, isCorrect: false);
        return false;
      }
    }
    state = state.copyWith(hasChecked: true, isCorrect: true);
    return true;
  }

  void retry() {
    state = const AssessmentStepState();
  }
}