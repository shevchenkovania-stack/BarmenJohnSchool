import 'package:coin/features/bartender_school/data/practice_challenges.dart';

/// Задания блока F: Prep, бриф гостя, сервис в запару, экзамен.
/// Level 2 — финальный блок перед дипломом.
const List<PracticeChallenge> challengesBlockF = [
  PracticeChallenge(
    id: 'level2_espresso_martini',
    lessonId: 'lesson_F_21',
    blockId: 'F',
    cocktailName: 'Espresso Martini',
    cocktailEmoji: '☕',
    johnIntro:
        'Espresso Martini — водка, кофейный ликёр, эспрессо. '
        'Prep важен: эспрессо должен быть свежим, ликёр — холодным. Маркировка — ключ.',
    correctIngredients: ['Vodka', 'Coffee liqueur', 'Espresso'],
    wrongOptions: ['Gin', 'Amaretto', 'Simple syrup', 'Milk'],
    correctMethod: 'shake',
    proportions: {
      'Vodka': ProportionTarget(targetMl: 40, toleranceMl: 5),
      'Coffee liqueur': ProportionTarget(targetMl: 20, toleranceMl: 3),
      'Espresso': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect: 'Espresso Martini — prep выполнен. Пенка идеальна.',
      wrongIngredients: 'Espresso Martini: водка, кофейный ликёр, эспрессо.',
      wrongMethod: 'Shake со льдом 12-15 секунд, fine strain.',
      wrongProportions: '40мл водка, 20мл ликёр, 30мл эспрессо.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_aperol_spritz',
    lessonId: 'lesson_F_22',
    blockId: 'F',
    cocktailName: 'Aperol Spritz',
    cocktailEmoji: '🍹',
    johnIntro:
        'Aperol Spritz — апероль, просекко, содовая. Лёгкий итальянский аперитив. '
        'Бриф гостя: объясни, что это 3:2:1. Подавай с апельсином.',
    correctIngredients: ['Aperol', 'Prosecco', 'Soda water'],
    wrongOptions: ['Campari', 'Champagne', 'Tonic water'],
    correctMethod: 'build',
    proportions: {
      'Aperol': ProportionTarget(targetMl: 90, toleranceMl: 10),
      'Prosecco': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Soda water': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect: 'Aperol Spritz — итальянский аперитив. Бриф выполнен.',
      wrongIngredients: 'Aperol Spritz: апероль, просекко, содовая.',
      wrongMethod: 'Build в винный бокал со льдом, 3:2:1.',
      wrongProportions: '90мл апероль, 60мл просекко, 30мл сода.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_moscow_mule',
    lessonId: 'lesson_F_23',
    blockId: 'F',
    cocktailName: 'Moscow Mule',
    cocktailEmoji: '🍺',
    johnIntro:
        'Moscow Mule — водка, лайм, имбирное пиво. Запару — работай быстро. '
        'Copper mug охлаждается мгновенно. Build и подавай сразу.',
    correctIngredients: ['Vodka', 'Lime', 'Ginger beer'],
    wrongOptions: ['Gin', 'Lemon', 'Ginger ale', 'Tonic water'],
    correctMethod: 'build',
    proportions: {
      'Vodka': ProportionTarget(targetMl: 50, toleranceMl: 5),
      'Lime': ProportionTarget(targetMl: 20, toleranceMl: 3),
      'Ginger beer': ProportionTarget(targetMl: 120, toleranceMl: 15),
    },
    feedback: PracticeFeedback(
      perfect: 'Moscow Mule — сервис в запаре. Copper mug освоен.',
      wrongIngredients: 'Moscow Mule: водка, лайм, ginger beer.',
      wrongMethod: 'Build в copper mug со льдом.',
      wrongProportions: '50мл водка, 20мл лайм, 120мл ginger beer.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_bloody_mary',
    lessonId: 'lesson_F_24',
    blockId: 'F',
    cocktailName: 'Bloody Mary',
    cocktailEmoji: '🍅',
    johnIntro:
        'Bloody Mary — водка, томатный сок, лимон, специи. '
        'Финальный экзамен: баланс, prep, сервис. Build и подавай с сельдереем.',
    correctIngredients: ['Vodka', 'Tomato juice', 'Lemon', 'Worcestershire sauce'],
    wrongOptions: ['Gin', 'Orange juice', 'Lime', 'Tabasco'],
    correctMethod: 'build',
    proportions: {
      'Vodka': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Tomato juice': ProportionTarget(targetMl: 90, toleranceMl: 10),
      'Lemon': ProportionTarget(targetMl: 15, toleranceMl: 3),
      'Worcestershire sauce': ProportionTarget(targetMl: 5, toleranceMl: 2),
    },
    feedback: PracticeFeedback(
      perfect: 'Bloody Mary — финальный экзамен сдан. Баланс, prep, сервис.',
      wrongIngredients: 'Bloody Mary: водка, томатный сок, лимон, worcestershire.',
      wrongMethod: 'Build в highball со льдом, stir.',
      wrongProportions: '45мл водка, 90мл томат, 15мл лимон, 5мл worcestershire.',
    ),
  ),
];
