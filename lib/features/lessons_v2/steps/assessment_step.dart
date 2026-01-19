import 'package:flutter/material.dart';
import 'package:milpress/utils/app_colors.dart';
import '../models/lesson_models.dart';
import '../widgets/lesson_audio_buttons.dart';

class AssessmentStep extends StatefulWidget {
  final LessonStepDefinition step;
  final ValueChanged<LessonStepUiState> onStepStateChanged;
  final bool isLastStep;

  const AssessmentStep({
    super.key,
    required this.step,
    required this.onStepStateChanged,
    required this.isLastStep,
  });

  @override
  State<AssessmentStep> createState() => _AssessmentStepState();
}

class _AssessmentStepState extends State<AssessmentStep> {
  bool _hasChecked = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepStateChanged(
        LessonStepUiState(
          canAdvance: false,
          isPrimaryEnabled: true,
          primaryLabel: 'Check Answers',
          onPrimaryPressed: _handleCheck,
        ),
      );
    });
  }

  void _handleCheck() {
    if (_hasChecked) {
      return;
    }
    setState(() {
      _hasChecked = true;
    });
    widget.onStepStateChanged(
      LessonStepUiState(
        canAdvance: true,
        isPrimaryEnabled: true,
        primaryLabel: widget.isLastStep ? 'Finish' : 'Continue',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.step.config['title'] as String? ?? 'Assessment';
    final prompt =
        widget.step.config['prompt'] as String? ?? 'Choose the correct answers';
    final hint = widget.step.config['hint'] as String? ??
        'Select all correct answers, then tap "Check Answers".';
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
              color: AppColors.accentColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LessonAudioInlineButton(
              sourceId: '${widget.step.key}-instruction',
              url: instructionUrl,
              label: 'Click here to listen',
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
              final isSelected = _selectedIndices.contains(index);
              return _AssessmentOption(
                label: label,
                imageUrl: imageUrl,
                isSelected: isSelected,
                isChecked: _hasChecked,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIndices.remove(index);
                    } else {
                      _selectedIndices.add(index);
                    }
                  });
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
        ],
      ),
    );
  }
}

class _AssessmentOption extends StatelessWidget {
  final String label;
  final String imageUrl;
  final bool isSelected;
  final bool isChecked;
  final VoidCallback onTap;

  const _AssessmentOption({
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primaryColor
        : AppColors.borderColor;
    return GestureDetector(
      onTap: isChecked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
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
                          fit: BoxFit.contain,
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
}
