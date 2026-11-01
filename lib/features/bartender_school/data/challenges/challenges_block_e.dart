import 'package:coin/features/bartender_school/data/practice_challenges.dart';

/// Обязательные классики Level 2.
const List<PracticeChallenge> challengesBlockE = [
  PracticeChallenge(
    id: 'level2_whiskey_sour',
    lessonId: 'lesson_E_17',
    blockId: 'E',
    cocktailName: 'Whiskey Sour',
    cocktailEmoji: '🥃',
    johnIntro:
        'Собери опорную спецификацию Whiskey Sour. Сегодня оцениваем не высоту пены, а точность, баланс и безопасную работу.',
    correctIngredients: [
      'Bourbon',
      'Lemon',
      'Sugar syrup',
      'Pasteurized egg white',
    ],
    wrongOptions: ['Lime', 'Gin', 'Sweet vermouth', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Bourbon': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Lemon': ProportionTarget(targetMl: 25, toleranceMl: 3),
      'Sugar syrup': ProportionTarget(targetMl: 20, toleranceMl: 3),
      'Pasteurized egg white': ProportionTarget(targetMl: 15, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect: 'Баланс, shake и безопасная пена собраны в одну чистую подачу.',
      wrongIngredients:
          'Проверь bourbon, свежий лимон, сахарный сироп и пастеризованный белок учебной версии.',
      wrongMethod: 'Whiskey Sour нужно встряхнуть по стандарту урока.',
      wrongProportions:
          'Опорная база: 45 мл bourbon, 25 мл лимон, 20 мл сироп.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_old_fashioned',
    lessonId: 'lesson_E_18',
    blockId: 'E',
    cocktailName: 'Old Fashioned',
    cocktailEmoji: '🟠',
    johnIntro:
        'Минимум ингредиентов, максимум контроля. Раствори сладкую часть и сохрани whiskey главным вкусом.',
    correctIngredients: ['Whiskey', 'Sugar', 'Bitter', 'Water'],
    wrongOptions: ['Lemon', 'Gin', 'Mint', 'Soda water'],
    correctMethod: 'build',
    proportions: {
      'Whiskey': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Sugar': ProportionTarget(targetMl: 5, toleranceMl: 2),
      'Bitter': ProportionTarget(targetMl: 2, toleranceMl: 1),
      'Water': ProportionTarget(targetMl: 5, toleranceMl: 3),
    },
    feedback: PracticeFeedback(
      perfect:
          'Чистый Old Fashioned: whiskey впереди, сладость и bitters держат структуру.',
      wrongIngredients: 'Нужны whiskey, сахар, bitters и немного воды.',
      wrongMethod: 'Собери в rocks-бокале и мягко перемешай.',
      wrongProportions:
          'Опора: 45 мл whiskey и только малая доза сахара, bitters и воды.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_dry_martini',
    lessonId: 'lesson_E_19',
    blockId: 'E',
    cocktailName: 'Dry Martini',
    cocktailEmoji: '🍸',
    johnIntro:
        'Охлади бокал, проверь vermouth и собери прозрачную гладкую классику без суеты.',
    correctIngredients: ['Gin', 'Dry vermouth'],
    wrongOptions: ['Vodka', 'Sweet vermouth', 'Lemon juice', 'Sugar syrup'],
    correctMethod: 'stir',
    proportions: {
      'Gin': ProportionTarget(targetMl: 60, toleranceMl: 5),
      'Dry vermouth': ProportionTarget(targetMl: 10, toleranceMl: 2),
    },
    feedback: PracticeFeedback(
      perfect:
          'Холодный, прозрачный и точный Martini готов к немедленной подаче.',
      wrongIngredients: 'Опорная версия: gin и свежий dry vermouth.',
      wrongMethod: 'Перемешай со льдом и процеди в охлаждённый бокал.',
      wrongProportions: 'Опорная спецификация: 60 мл gin и 10 мл dry vermouth.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_margarita',
    lessonId: 'lesson_E_20',
    blockId: 'E',
    cocktailName: 'Margarita',
    cocktailEmoji: '🧂',
    johnIntro:
        'Подготовь аккуратную половинную кромку и сохрани tequila слышимой сквозь lime и triple sec.',
    correctIngredients: ['Tequila', 'Triple sec', 'Lime'],
    wrongOptions: ['Gin', 'Lemon', 'Sugar syrup', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Tequila': ProportionTarget(targetMl: 50, toleranceMl: 5),
      'Triple sec': ProportionTarget(targetMl: 20, toleranceMl: 3),
      'Lime': ProportionTarget(targetMl: 15, toleranceMl: 3),
    },
    feedback: PracticeFeedback(
      perfect:
          'Tequila, lime и orange liqueur звучат вместе; соль остаётся акцентом.',
      wrongIngredients: 'Опорная Margarita: tequila, triple sec и свежий lime.',
      wrongMethod: 'Встряхни со льдом и процеди в подготовленный бокал.',
      wrongProportions: 'Опора: 50 мл tequila, 20 мл triple sec, 15 мл lime.',
    ),
  ),
];
