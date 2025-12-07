import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/answer_checker_provider.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'assessment_feedback_section.dart';

class WritingAbilityOptions extends ConsumerStatefulWidget {
  final Map<String, dynamic> question;
  final void Function(bool isCorrect, {int attemptNumber}) onOptionSelected;

  const WritingAbilityOptions({
    Key? key,
    required this.question,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  ConsumerState<WritingAbilityOptions> createState() => _WritingAbilityOptionsState();
}

class _WritingAbilityOptionsState extends ConsumerState<WritingAbilityOptions> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;
  bool _hasChecked = false;
  bool _isCorrect = false;
  bool _showFeedback = false;
  int _currentAttempt = 1;
  List<String> _previousAttempts = [];
  bool _canRetry = true;

  @override
  void initState() {
    super.initState();
    print('Writing Ability: Widget initialized');
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(WritingAbilityOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('Writing Ability: Widget updated - old question: ${oldWidget.question['id']}, new question: ${widget.question['id']}');
    
    // Reset state when question changes
    if (oldWidget.question['id'] != widget.question['id']) {
      print('Writing Ability: Question changed, resetting state');
      setState(() {
        _controller.clear();
        _hasText = false;
        _hasChecked = false;
        _isCorrect = false;
        _showFeedback = false;
        _currentAttempt = 1;
        _previousAttempts.clear();
        _canRetry = true;
      });
    }
  }

  @override
  void dispose() {
    print('Writing Ability: Widget disposed');
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  String _normalizeText(String text) {
    // Convert to lowercase, remove punctuation, normalize whitespace
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove all punctuation
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Replace multiple spaces with single space
  }

  void _submit() {
    final userAnswer = _controller.text.trim();
    final correctAnswer = widget.question['correct_answer']?.toString().trim() ?? '';
    
    // Normalize both answers for comparison
    final normalizedUserAnswer = _normalizeText(userAnswer);
    final normalizedCorrectAnswer = _normalizeText(correctAnswer);
    
    final isCorrect = normalizedUserAnswer == normalizedCorrectAnswer;
    
    print('Writing Ability: Answer submitted - userAnswer: $userAnswer, correctAnswer: $correctAnswer');
    print('Writing Ability: Normalized - userAnswer: $normalizedUserAnswer, correctAnswer: $normalizedCorrectAnswer, isCorrect: $isCorrect, attempt: $_currentAttempt');
    
    setState(() {
      _hasChecked = true;
      _isCorrect = isCorrect;
      _showFeedback = true;
    });

    if (isCorrect) {
      print('Writing Ability: Correct answer, calling callback');
      widget.onOptionSelected(true, attemptNumber: _currentAttempt);
    } else {
      _previousAttempts.add(userAnswer);
    }
  }

  void _handleTryAgain() {
    setState(() {
      _controller.clear();
      _hasText = false;
      _hasChecked = false;
      _isCorrect = false;
      _showFeedback = false;
      _currentAttempt++;
    });
  }

  void _handleGiveUp() {
    // Show correct answer and let user continue manually
    setState(() {
      _currentAttempt = 2; // Set to final attempt to show correct answer
    });
  }

  void _handleContinue() {
    setState(() {
      _showFeedback = false;
    });
    // Move to next question with final attempt number
    widget.onOptionSelected(false, attemptNumber: _currentAttempt);
  }

  @override
  Widget build(BuildContext context) {
    final correctAnswer = widget.question['correct_answer'] ?? '';

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attempt counter
            if (_currentAttempt > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Attempt $_currentAttempt of 2',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              maxLines: 10,
              enabled: !_hasChecked,
              decoration: InputDecoration(
                hintText: _hasChecked ? 'Answer submitted' : 'Type here...',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _isCorrect ? AppColors.successColor : AppColors.errorColor,
                    width: 2,
                  ),
                ),
                filled: _hasChecked,
                fillColor: _hasChecked 
                    ? (_isCorrect ? AppColors.successColor.withOpacity(0.1) : AppColors.errorColor.withOpacity(0.1))
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            if (!_hasChecked)
              CustomButton(
                onPressed: _hasText ? _submit : null,
                text: 'Done writing',
                fillColor: _hasText ? AppColors.primaryColor : AppColors.textColor,
              ),
            if (_showFeedback && !_isCorrect)
              AssessmentFeedbackSection(
                isCorrect: false,
                correctAnswer: correctAnswer,
                onTryAgain: _currentAttempt < 2 ? _handleTryAgain : null,
                onGiveUp: _currentAttempt < 2 ? _handleGiveUp : _handleContinue,
                showCorrectAnswer: _currentAttempt >= 2,
                customMessage: _currentAttempt < 2 
                    ? 'That\'s not quite right. You have ${2 - _currentAttempt} more attempts.'
                    : 'You are out of attempts.',
              ),
          ],
        ),
      ),
    );
  }
} 