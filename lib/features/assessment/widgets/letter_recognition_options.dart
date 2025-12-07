import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/answer_checker_provider.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/widgets/custom_button.dart';
import 'assessment_feedback_section.dart';

class LetterRecognitionOptions extends ConsumerStatefulWidget {
  final Map<String, dynamic> question;
  final void Function(bool isCorrect, {int attemptNumber}) onOptionSelected;

  const LetterRecognitionOptions({
    Key? key,
    required this.question,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  ConsumerState<LetterRecognitionOptions> createState() => _LetterRecognitionOptionsState();
}

class _LetterRecognitionOptionsState extends ConsumerState<LetterRecognitionOptions> with SingleTickerProviderStateMixin {
  String? _selectedOption;
  bool _hasChecked = false;
  bool _isCorrect = false;
  bool _showFeedback = false;
  int _currentAttempt = 1;
  List<String> _previousAttempts = [];
  bool _canRetry = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(LetterRecognitionOptions oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reset state when question changes
    if (oldWidget.question['id'] != widget.question['id']) {
      setState(() {
        _selectedOption = null;
        _hasChecked = false;
        _isCorrect = false;
        _showFeedback = false;
        _currentAttempt = 1;
        _previousAttempts.clear();
        _canRetry = true;
      });
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(String option, bool isCorrect) {
    setState(() {
      _selectedOption = option;
      _isCorrect = isCorrect;
      _hasChecked = true;
      _showFeedback = true;
    });

    if (isCorrect) {
      _animationController.forward().then((_) {
        widget.onOptionSelected(true, attemptNumber: _currentAttempt);
      });
    } else {
      _previousAttempts.add(option);
    }
  }

  void _handleTryAgain() {
    setState(() {
      _selectedOption = null;
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
    final options = List<String>.from(widget.question['options'] ?? []);
    final answerChecker = ref.read(answerCheckerProvider);
    final correctAnswer = widget.question['correct_answer'] ?? '';


    return Column(
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
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: options.map((option) {
                final bool isOptionCorrect = answerChecker.isCorrect(widget.question, option);
                final bool isSelected = _selectedOption == option;
                final bool isDisabled = _hasChecked && !isSelected;


                return GestureDetector(
                  onTap: _hasChecked || _selectedOption != null
                      ? null
                      : () => _handleOptionSelected(option, isOptionCorrect),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (_isCorrect ? AppColors.successColor : AppColors.errorColor)
                          : (isDisabled ? Colors.grey[200] : Colors.white),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected
                            ? (_isCorrect ? AppColors.successShadowColor : AppColors.errorShadowColor)
                            : AppColors.borderColor,
                        width: isSelected ? 5 : 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 32,
                        color: isSelected
                            ? Colors.white
                            : (isDisabled ? Colors.grey : Colors.black),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
    );
  }
} 