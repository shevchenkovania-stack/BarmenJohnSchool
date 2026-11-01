import 'package:coin/features/bartender_school/data/practice_challenges.dart';

/// Задания блока D: Уровень 2 — уроки 13-16.
/// Темы: спецификация, замена ингредиентов, текстура, температура.
const List<PracticeChallenge> challengesBlockD = [
  PracticeChallenge(
    id: 'level2_negroni',
    lessonId: 'lesson_D_13',
    blockId: 'D',
    cocktailName: 'Negroni',
    cocktailEmoji: '🍷',
    johnIntro:
        'Сегодня делаем Негрони. Джин, Кампари, красный вермут — равные части. '
            'Это классика чтения спецификации. Каждый ингредиент слышен.',
    correctIngredients: ['Gin', 'Campari', 'Sweet vermouth'],
    wrongOptions: ['Vodka', 'Triple sec', 'Lime', 'Soda water'],
    correctMethod: 'stir',
    proportions: {
      'Gin': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Campari': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Sweet vermouth': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect:
          'Негрони — равные части, равный баланс. Горький, сложный, элегантный.',
      wrongIngredients: 'Негрони: джин, Кампари, красный вермут. Не водка!',
      wrongMethod: 'Негрони — стир. 20-25 секунд со льдом.',
      wrongProportions: 'Равные части: по 30мл каждого ингредиента.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_gimlet',
    lessonId: 'lesson_D_14',
    blockId: 'D',
    cocktailName: 'Gimlet',
    cocktailEmoji: '🍸',
    johnIntro:
        'Сегодня делаем Гимлет. Джин и лайм-кордиал. '
            'Простой коктейль, но замена кордиала на свежий лайм — это уже другая история.',
    correctIngredients: ['Gin', 'Lime cordial'],
    wrongOptions: ['Vodka', 'Lemon', 'Sugar', 'Mint'],
    correctMethod: 'shake',
    proportions: {
      'Gin': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lime cordial': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect: 'Гимлет — классика замены ингредиентов. Кордиал даёт уникальную сладость.',
      wrongIngredients: 'Гимлет: джин и лайм-кордиал. Не свежий лайм!',
      wrongMethod: 'Гимлет шейкают со льдом 10-12 секунд.',
      wrongProportions: 'Классика: 60мл джин, 30мл кордиал.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_clover_club',
    lessonId: 'lesson_D_15',
    blockId: 'D',
    cocktailName: 'Clover Club',
    cocktailEmoji: '🍓',
    johnIntro:
        'Сегодня делаем Кловер Клаб. Джин, лимон, малиновый сироп и яичный белок. '
            'Текстура — ключ. Белок даёт шелковистую пенку.',
    correctIngredients: ['Gin', 'Lemon', 'Raspberry syrup', 'Egg white'],
    wrongOptions: ['Vodka', 'Lime', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Gin': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Lemon': ProportionTarget(targetMl: 20, toleranceMl: 3),
      'Raspberry syrup': ProportionTarget(targetMl: 20, toleranceMl: 3),
      'Egg white': ProportionTarget(targetMl: 15, toleranceMl: 3),
    },
    feedback: PracticeFeedback(
      perfect: 'Кловер Клаб с идеальной пенкой! Текстура шелковистая.',
      wrongIngredients: 'Кловер Клаб: джин, лимон, малиновый сироп, белок.',
      wrongMethod: 'Сначала сухое шейкание (без льда), потом со льдом.',
      wrongProportions: '45мл джин, 20мл лимон, 20мл сироп, 15мл белок.',
    ),
  ),
  PracticeChallenge(
    id: 'level2_hot_toddy',
    lessonId: 'lesson_D_16',
    blockId: 'D',
    cocktailName: 'Hot Toddy',
    cocktailEmoji: '☕',
    johnIntro:
        'Сегодня делаем Хот Тодди. Виски, мёд, лимон и горячая вода. '
            'Температура — ключ. Подавай горячим, но не обжигающим.',
    correctIngredients: ['Whiskey', 'Honey', 'Lemon', 'Hot water'],
    wrongOptions: ['Gin', 'Lime', 'Mint', 'Soda water'],
    correctMethod: 'build',
    proportions: {
      'Whiskey': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Honey': ProportionTarget(targetMl: 20, toleranceMl: 3),
      'Lemon': ProportionTarget(targetMl: 20, toleranceMl: 3),
      'Hot water': ProportionTarget(targetMl: 120, toleranceMl: 20),
    },
    feedback: PracticeFeedback(
      perfect: 'Хот Тодди — согревает и лечит. Температура идеальна.',
      wrongIngredients: 'Хот Тодди: виски, мёд, лимон, горячая вода.',
      wrongMethod: 'Хот Тодди — билд. Налей всё в бокал.',
      wrongProportions: '45мл виски, 20мл мёд, 20мл лимон, 120мл горячая вода.',
    ),
  ),
];
