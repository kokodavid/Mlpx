import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress/features/weekly_goal/providers/user_goal_providers.dart';
import 'package:milpress/utils/app_colors.dart';
import 'package:milpress/features/widgets/custom_button.dart';

class WeeklyGoalScreen extends ConsumerStatefulWidget {
  const WeeklyGoalScreen({super.key});

  @override
  ConsumerState<WeeklyGoalScreen> createState() => _WeeklyGoalScreenState();
}

class _WeeklyGoalScreenState extends ConsumerState<WeeklyGoalScreen> {
  static const int customValueKey = -1;
  static const List<int> presetValues = [5, 10, 15];

  int? _selectedValue;
  bool _isSaving = false;
  bool _didInitSelection = false;
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal() async {
    final selected = _selectedValue;
    if (selected == null) {
      _showMessage('Select a weekly goal to continue.');
      return;
    }

    int? goalValue;
    if (selected == customValueKey) {
      goalValue = int.tryParse(_customController.text.trim());
      if (goalValue == null || goalValue <= 0) {
        _showMessage('Enter a valid custom goal.');
        return;
      }
    } else {
      goalValue = selected;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final timezone = DateTime.now().timeZoneName;
      await ref.read(setWeeklyGoalProvider({
        'lessonsPerWeek': goalValue,
        'timezone': timezone,
        'weekStart': 1,
      }).future);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showMessage('Unable to save your goal. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(activeWeeklyGoalProvider);
    final selected = _selectedValue;

    ref.listen<AsyncValue>(activeWeeklyGoalProvider, (previous, next) {
      if (_didInitSelection) return;
      final goal = next.asData?.value;
      if (goal == null) return;
      final value = goal.goalValue;
      setState(() {
        _didInitSelection = true;
        if (presetValues.contains(value)) {
          _selectedValue = value;
        } else {
          _selectedValue = customValueKey;
          _customController.text = value.toString();
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.copBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Weekly goal',
          style: TextStyle(
            color: AppColors.copBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.local_fire_department,
                  color: AppColors.primaryColor,
                  size: 88,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Set your weekly goal, make a committed plan',
                style: TextStyle(
                  color: AppColors.copBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose how many lessons you want to complete each week.',
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              _GoalOptionTile(
                title: '5 lessons a week',
                subtitle: 'Baby step',
                isSelected: selected == 5,
                onTap: () => setState(() => _selectedValue = 5),
              ),
              const SizedBox(height: 10),
              _GoalOptionTile(
                title: '10 lessons a week',
                subtitle: 'Strong start',
                isSelected: selected == 10,
                onTap: () => setState(() => _selectedValue = 10),
              ),
              const SizedBox(height: 10),
              _GoalOptionTile(
                title: '15 lessons a week',
                subtitle: 'Committed',
                isSelected: selected == 15,
                onTap: () => setState(() => _selectedValue = 15),
              ),
              const SizedBox(height: 10),
              _GoalOptionTile(
                title: 'Custom goal',
                subtitle: 'Set your own number',
                isSelected: selected == customValueKey,
                onTap: () => setState(() => _selectedValue = customValueKey),
                trailing: SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                    ),
                    onTap: () => setState(() => _selectedValue = customValueKey),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  goalAsync.maybeWhen(
                    data: (goal) => goal == null
                        ? 'You will be more likely to complete lessons'
                        : 'Current goal: ${goal.goalValue} lessons this week',
                    orElse: () => 'You will be more likely to complete lessons',
                  ),
                  style: const TextStyle(
                    color: AppColors.copBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: 'I am committed',
                onPressed: _isSaving ? null : _saveGoal,
                isFilled: true,
                fillColor: _isSaving || selected == null
                    ? AppColors.textColor
                    : AppColors.primaryColor,
                textColor: Colors.white,
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(vertical: 14),
                isLoading: _isSaving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _GoalOptionTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primaryColor : AppColors.borderColor;
    final textColor = isSelected ? AppColors.copBlue : AppColors.textColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null)
              Text(
                subtitle,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
