import 'package:coin/features/bartender_school/domain/entities/quiz.dart';

/// Pure quiz answer checks used by the bartender school UI and unit tests.
class QuizAnswerEvaluator {
  const QuizAnswerEvaluator._();

  static bool isSingleChoiceCorrect(QuizQuestion question, int selectedIndex) {
    return selectedIndex == question.correctAnswerIndex;
  }

  static bool isMultipleChoiceCorrect(
    QuizQuestion question,
    Set<int>? selectedIndices,
  ) {
    final correctSet = question.correctAnswerIndices?.toSet() ?? {};
    if (selectedIndices == null) return false;

    return selectedIndices.length == correctSet.length &&
        selectedIndices.every(correctSet.contains);
  }

  static bool isSliderAnswerCorrect(
    QuizQuestion question,
    Map<int, double> sliderValues, {
    double defaultValue = 0.5,
  }) {
    final sliders = question.sliders;
    if (sliders == null || sliders.isEmpty) return false;

    return sliders.asMap().entries.every((entry) {
      final value = sliderValues[entry.key] ?? defaultValue;
      final slider = entry.value;
      final correctMin = (slider['correctMin'] as num).toDouble();
      final correctMax = (slider['correctMax'] as num).toDouble();

      return value >= correctMin && value <= correctMax;
    });
  }

  static bool isMatchingAnswerCorrect(
    QuizQuestion question,
    Map<String, String> selectedPairs,
  ) {
    final pairs = question.pairs;
    if (pairs == null || pairs.isEmpty) return false;

    return pairs.every((pair) {
      final left = pair['left'];
      final right = pair['right'];
      return left != null && right != null && selectedPairs[left] == right;
    });
  }

  static bool isSequenceAnswerCorrect(
    QuizQuestion question,
    List<String> selectedSequence,
  ) {
    final sequence = question.sequence;
    if (sequence == null || sequence.isEmpty) return false;
    if (selectedSequence.length != sequence.length) return false;

    for (var index = 0; index < sequence.length; index++) {
      if (selectedSequence[index] != sequence[index]) return false;
    }
    return true;
  }
}
