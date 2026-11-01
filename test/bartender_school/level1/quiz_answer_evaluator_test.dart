import 'package:coin/features/bartender_school/domain/entities/quiz.dart';
import 'package:coin/features/bartender_school/domain/services/quiz_answer_evaluator.dart';
import 'package:flutter_test/flutter_test.dart';

QuizQuestion _question({
  QuestionType type = QuestionType.singleChoice,
  int? correctAnswerIndex,
  List<int>? correctAnswerIndices,
  List<Map<String, dynamic>>? sliders,
  List<Map<String, String>>? pairs,
  List<String>? sequence,
}) {
  return QuizQuestion(
    id: 'question_1',
    type: type,
    question: 'Test question',
    correctAnswerIndex: correctAnswerIndex,
    correctAnswerIndices: correctAnswerIndices,
    explanation: 'Test explanation',
    sliders: sliders,
    pairs: pairs,
    sequence: sequence,
  );
}

void main() {
  group('QuizAnswerEvaluator', () {
    test('checks single choice answers', () {
      final question = _question(correctAnswerIndex: 2);

      expect(QuizAnswerEvaluator.isSingleChoiceCorrect(question, 2), isTrue);
      expect(QuizAnswerEvaluator.isSingleChoiceCorrect(question, 1), isFalse);
    });

    test('checks multiple choice answers as an exact set', () {
      final question = _question(
        type: QuestionType.multipleChoice,
        correctAnswerIndices: [0, 2],
      );

      expect(
        QuizAnswerEvaluator.isMultipleChoiceCorrect(question, {0, 2}),
        isTrue,
      );
      expect(
        QuizAnswerEvaluator.isMultipleChoiceCorrect(question, {0}),
        isFalse,
      );
      expect(
        QuizAnswerEvaluator.isMultipleChoiceCorrect(question, {0, 1, 2}),
        isFalse,
      );
      expect(
        QuizAnswerEvaluator.isMultipleChoiceCorrect(question, null),
        isFalse,
      );
    });

    test('checks slider values against all configured ranges', () {
      final question = _question(
        type: QuestionType.slider,
        sliders: [
          {'name': 'Sweet', 'correctMin': 0.35, 'correctMax': 0.55},
          {'name': 'Sour', 'correctMin': 0.45, 'correctMax': 0.65},
        ],
      );

      expect(
        QuizAnswerEvaluator.isSliderAnswerCorrect(question, {
          0: 0.45,
          1: 0.55,
        }),
        isTrue,
      );
      expect(
        QuizAnswerEvaluator.isSliderAnswerCorrect(question, {
          0: 0.45,
          1: 0.8,
        }),
        isFalse,
      );
    });

    test('does not accept slider questions without sliders', () {
      final question = _question(type: QuestionType.slider);

      expect(
        QuizAnswerEvaluator.isSliderAnswerCorrect(question, const {}),
        isFalse,
      );
    });

    test('checks every matching pair by its left value', () {
      final question = _question(
        type: QuestionType.matching,
        pairs: [
          {'left': 'Daiquiri', 'right': 'Lime'},
          {'left': 'Whiskey Sour', 'right': 'Lemon'},
          {'left': 'Margarita', 'right': 'Lime'},
        ],
      );

      expect(
        QuizAnswerEvaluator.isMatchingAnswerCorrect(question, const {
          'Daiquiri': 'Lime',
          'Whiskey Sour': 'Lemon',
          'Margarita': 'Lime',
        }),
        isTrue,
      );
      expect(
        QuizAnswerEvaluator.isMatchingAnswerCorrect(question, const {
          'Daiquiri': 'Lemon',
          'Whiskey Sour': 'Lime',
          'Margarita': 'Lime',
        }),
        isFalse,
      );
      expect(
        QuizAnswerEvaluator.isMatchingAnswerCorrect(question, const {
          'Daiquiri': 'Lime',
        }),
        isFalse,
      );
    });

    test('checks sequence order exactly', () {
      final question = _question(
        type: QuestionType.sequence,
        sequence: ['Taste', 'Add saline', 'Add bitters', 'Taste again'],
      );

      expect(
        QuizAnswerEvaluator.isSequenceAnswerCorrect(
          question,
          const ['Taste', 'Add saline', 'Add bitters', 'Taste again'],
        ),
        isTrue,
      );
      expect(
        QuizAnswerEvaluator.isSequenceAnswerCorrect(
          question,
          const ['Taste', 'Add bitters', 'Add saline', 'Taste again'],
        ),
        isFalse,
      );
      expect(
        QuizAnswerEvaluator.isSequenceAnswerCorrect(
          question,
          const ['Taste', 'Add saline'],
        ),
        isFalse,
      );
    });
  });
}
