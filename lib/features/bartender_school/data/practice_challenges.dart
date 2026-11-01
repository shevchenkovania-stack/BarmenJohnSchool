/// Практические задания Мастерской.
///
/// Модели, оценщик и реестр заданий по блокам.
/// Данные заданий — в отдельных файлах: challenges/challenges_block_X.dart
library;

import 'dart:math';

import 'package:coin/features/bartender_school/data/challenges/challenges_block_a.dart';
import 'package:coin/features/bartender_school/data/challenges/challenges_block_b.dart';
import 'package:coin/features/bartender_school/data/challenges/challenges_block_c.dart';
import 'package:coin/features/bartender_school/data/challenges/challenges_block_d.dart';
import 'package:coin/features/bartender_school/data/challenges/challenges_block_e.dart';
import 'package:coin/features/bartender_school/data/challenges/challenges_block_f.dart';

// ── Модель ──────────────────────────────────────────────────────────────────

class PracticeChallenge {
  final String id;
  final String lessonId;
  final String blockId;
  final String cocktailName;
  final String cocktailEmoji;
  final String johnIntro;
  final List<String> correctIngredients;
  final List<String> wrongOptions;
  final String correctMethod;
  final Map<String, ProportionTarget> proportions;
  final PracticeFeedback feedback;

  const PracticeChallenge({
    required this.id,
    required this.lessonId,
    required this.blockId,
    required this.cocktailName,
    required this.cocktailEmoji,
    required this.johnIntro,
    required this.correctIngredients,
    required this.wrongOptions,
    required this.correctMethod,
    required this.proportions,
    required this.feedback,
  });

  /// Все ингредиенты для показа (правильные + неправильные).
  ///
  /// Порядок намеренно перемешан и стабилен для конкретного задания: без
  /// этого правильные всегда шли первыми и ответ угадывался по позиции.
  List<String> get allOptions {
    final options = [...correctIngredients, ...wrongOptions];
    options.shuffle(Random(_shuffleSeed));
    return options;
  }

  int get _shuffleSeed => id.codeUnits.fold(0, (a, c) => a * 31 + c);
}

class ProportionTarget {
  final int targetMl;
  final int toleranceMl;

  const ProportionTarget({
    required this.targetMl,
    required this.toleranceMl,
  });

  bool isWithin(int actualMl) => (actualMl - targetMl).abs() <= toleranceMl;
}

class PracticeFeedback {
  final String perfect;
  final String wrongIngredients;
  final String wrongMethod;
  final String wrongProportions;

  const PracticeFeedback({
    required this.perfect,
    required this.wrongIngredients,
    required this.wrongMethod,
    required this.wrongProportions,
  });
}

// ── Результат оценки ────────────────────────────────────────────────────────

class PracticeResult {
  final bool ingredientsCorrect;
  final bool methodCorrect;
  final bool proportionsCorrect;
  final String feedbackText;

  const PracticeResult({
    required this.ingredientsCorrect,
    required this.methodCorrect,
    required this.proportionsCorrect,
    required this.feedbackText,
  });

  int get stars {
    int s = 0;
    if (ingredientsCorrect) s++;
    if (methodCorrect) s++;
    if (proportionsCorrect) s++;
    return s;
  }
}

// ── Методы с описаниями ─────────────────────────────────────────────────────

const Map<String, MethodDescription> methodDescriptions = {
  'shake': MethodDescription(
    emoji: '🍸',
    label: 'Shake',
    description: 'Встряхни в шейкере со льдом 10-15 секунд',
  ),
  'stir': MethodDescription(
    emoji: '🥃',
    label: 'Stir',
    description: 'Перемешай барной ложкой 30 секунд',
  ),
  'build': MethodDescription(
    emoji: '🥂',
    label: 'Build',
    description: 'Налей ингредиенты прямо в бокал со льдом',
  ),
  'muddle': MethodDescription(
    emoji: '🌿',
    label: 'Muddle',
    description: 'Помни ингредиенты пестиком, затем смешай',
  ),
};

class MethodDescription {
  final String emoji;
  final String label;
  final String description;

  const MethodDescription({
    required this.emoji,
    required this.label,
    required this.description,
  });
}

// ── Реестр всех заданий ─────────────────────────────────────────────────────

/// Все задания Мастерской (28 коктейлей).
List<PracticeChallenge> get allPracticeChallenges => [
      ...challengesBlockA,
      ...challengesBlockB,
      ...challengesBlockC,
      ...challengesBlockD,
      ...challengesBlockE,
      ...challengesBlockF,
    ];

/// Обязательная практика для диплома Level 2.
const List<String> level2DiplomaChallengeIds = [
  'level2_whiskey_sour',
  'level2_old_fashioned',
  'level2_dry_martini',
  'level2_margarita',
];

/// Обязательная практика для диплома Level 1.
const List<String> level1DiplomaChallengeIds = [
  'practice_mojito',
  'practice_daiquiri',
  'practice_negroni',
];

/// Задания по блоку.
List<PracticeChallenge> challengesForBlock(String blockId) =>
    allPracticeChallenges.where((c) => c.blockId == blockId).toList();

// ── Оценщик ─────────────────────────────────────────────────────────────────

PracticeResult evaluateAttempt(
  PracticeChallenge challenge,
  Set<String> selectedIngredients,
  String selectedMethod,
  Map<String, int> proportions,
) {
  // 1. Ингредиенты
  final correctSet = challenge.correctIngredients.toSet();
  final ingredientsCorrect = selectedIngredients.length == correctSet.length &&
      selectedIngredients.every((i) => correctSet.contains(i));

  // 2. Метод
  final methodCorrect = selectedMethod == challenge.correctMethod;

  // 3. Пропорции
  bool proportionsCorrect = true;
  for (final entry in challenge.proportions.entries) {
    final actual = proportions[entry.key] ?? 0;
    if (!entry.value.isWithin(actual)) {
      proportionsCorrect = false;
      break;
    }
  }

  // Фидбэк
  final String feedbackText;
  if (ingredientsCorrect && methodCorrect && proportionsCorrect) {
    feedbackText = challenge.feedback.perfect;
  } else if (!ingredientsCorrect) {
    feedbackText = challenge.feedback.wrongIngredients;
  } else if (!methodCorrect) {
    feedbackText = challenge.feedback.wrongMethod;
  } else {
    feedbackText = challenge.feedback.wrongProportions;
  }

  return PracticeResult(
    ingredientsCorrect: ingredientsCorrect,
    methodCorrect: methodCorrect,
    proportionsCorrect: proportionsCorrect,
    feedbackText: feedbackText,
  );
}
