import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestionState {
  final Set<int> selectedIndices;
  final bool hasChecked;
  final bool isCorrect;

  const QuestionState({
    this.selectedIndices = const {},
    this.hasChecked = false,
    this.isCorrect = false,
  });

  QuestionState copyWith({
    Set<int>? selectedIndices,
    bool? hasChecked,
    bool? isCorrect,
  }) {
    return QuestionState(
      selectedIndices: selectedIndices ?? this.selectedIndices,
      hasChecked: hasChecked ?? this.hasChecked,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

class QuestionStateController extends StateNotifier<QuestionState> {
  QuestionStateController() : super(const QuestionState());

  void toggleSelection(int index) {
    if (state.hasChecked) return;
    final updated = Set<int>.from(state.selectedIndices);
    if (updated.contains(index)) {
      updated.remove(index);
    } else {
      updated.add(index);
    }
    state = state.copyWith(selectedIndices: updated);
  }

  /// Check selected answers against correct flags.
  /// Returns true if all correct options are selected and no incorrect ones.
  bool checkAnswers(List<bool> correctFlags) {
    if (correctFlags.isEmpty || state.selectedIndices.isEmpty) {
      state = state.copyWith(hasChecked: true, isCorrect: false);
      return false;
    }

    final selected = state.selectedIndices;

    // Every selected option must be correct
    for (final index in selected) {
      if (index < 0 || index >= correctFlags.length || !correctFlags[index]) {
        state = state.copyWith(hasChecked: true, isCorrect: false);
        return false;
      }
    }

    // Every correct option must be selected
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
    state = const QuestionState();
  }
}

/// Provider keyed by a unique question identifier (e.g. "sublevelId:questionIndex").
final questionStateProvider = StateNotifierProvider.autoDispose
    .family<QuestionStateController, QuestionState, String>(
  (ref, questionKey) => QuestionStateController(),
);
