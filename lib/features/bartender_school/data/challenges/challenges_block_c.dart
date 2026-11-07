import 'package:coin/features/bartender_school/data/practice_challenges.dart';

/// Задания блока C: Сложные техники и авторские коктейли.
const List<PracticeChallenge> challengesBlockC = [
  PracticeChallenge(
    id: 'practice_mojito',
    lessonId: 'lesson_C_09',
    blockId: 'C',
    cocktailName: 'Mojito',
    cocktailEmoji: '🌿',
    johnIntro: 'Сегодня делаем Мохито. Ром, лайм, мята, сахар и содовая. '
        'Muddle — помни мяту, но не рви. Build — налей всё в бокал.',
    correctIngredients: ['Rum', 'Lime', 'Mint', 'Sugar', 'Soda water'],
    wrongOptions: ['Vodka', 'Lemon', 'Ginger', 'Tonic water'],
    correctMethod: 'muddle',
    proportions: {
      'Rum': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lime': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Soda water': ProportionTarget(targetMl: 60, toleranceMl: 10),
    },
    // Сахар и мята идут первыми: сахар защищает листья при надавливании,
    // лёд — последним перед содовой, иначе мята не отдаст аромат.
    assembly: [
      'Мята и сахар в бокал',
      'Размять пестиком',
      'Лайм и ром',
      'Лёд',
      'Содовая',
    ],
    feedback: PracticeFeedback(
      perfect: 'Мохито — мятная свежесть Кубы. Muddle освоено — мята цела.',
      wrongIngredients: 'Мохито: ром, лайм, мята, сахар, содовая. Не водка!',
      wrongMethod: 'Muddle — помни мяту с лаймом и сахаром, затем build.',
      wrongProportions: '60 мл рома, 30 мл лайма, 2 ложки сахара, содовая.',
      wrongAssembly:
          'Сначала мята с сахаром и пестик. Лайм и ром — после, лёд и содовая — в конце.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_daiquiri',
    lessonId: 'lesson_C_10',
    blockId: 'C',
    cocktailName: 'Daiquiri',
    cocktailEmoji: '🍹',
    johnIntro: 'Сегодня делаем Даикири. Три ингредиента — ром, лайм и сахар. '
        'Минимализм в лучшем виде. Баланс кислоты и сладости — ключ.',
    correctIngredients: ['Rum', 'Lime', 'Sugar'],
    wrongOptions: ['Vodka', 'Lemon', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Rum': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lime': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Sugar': ProportionTarget(targetMl: 15, toleranceMl: 3),
    },
    // Порядок не влияет на вкус, но влияет на скорость: жидкости первыми,
    // лёд последним — так шейкер закрывается с первого раза.
    assembly: [
      'Ром, лайм и сироп в шейкер',
      'Лёд до верха',
      'Shake 10–12 секунд',
      'Двойное процеживание в бокал',
    ],
    feedback: PracticeFeedback(
      perfect: 'Даикири — чистый баланс. Хемингуэй одобрил бы.',
      wrongIngredients: 'Даикири: ром, лайм, сахар. Не водка!',
      wrongMethod: 'Shake со льдом 10-12 секунд.',
      wrongProportions: '2:1:0.5 ром, лайм, сахар.',
      wrongAssembly:
          'Жидкости — в шейкер, лёд — сверху, затем shake и двойное процеживание.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_negroni',
    lessonId: 'lesson_C_11',
    blockId: 'C',
    cocktailName: 'Negroni',
    cocktailEmoji: '🍹',
    johnIntro: 'Сегодня делаем Негрони. Джин, Кампари и сладкий вермут. '
        'Равные части — равный баланс. Горький, сладкий, крепкий.',
    correctIngredients: ['Gin', 'Campari', 'Sweet vermouth'],
    wrongOptions: ['Vodka', 'Aperol', 'Lemon', 'Soda water'],
    correctMethod: 'stir',
    proportions: {
      'Gin': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Campari': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Sweet vermouth': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    // Жидкости первыми, лёд после них.
    assembly: [
      'Джин, Кампари и вермут в стакан для смешивания',
      'Лёд',
      'Stir 25–30 секунд',
      'Процедить в бокал с большим кубом',
    ],
    feedback: PracticeFeedback(
      perfect: 'Негрони — итальянская гордость. Равные части, равный баланс.',
      wrongIngredients: 'Негрони: джин, кампари, сладкий вермут. Не апероль!',
      wrongMethod: 'Stir — перемешай барной ложкой 30 секунд.',
      wrongProportions: '1:1:1 джин, кампари, вермут.',
      wrongAssembly:
          'Сначала жидкости, затем лёд, stir и процеживание в бокал с кубом.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_boulevardier',
    lessonId: 'lesson_C_11',
    blockId: 'C',
    cocktailName: 'Boulevardier',
    cocktailEmoji: '🍸',
    johnIntro: 'Сегодня делаем Бульвардье. Бурбон, Кампари и сладкий вермут. '
        'Брат Негрони, но на бурбоне. Крепче и глубже.',
    correctIngredients: ['Bourbon', 'Campari', 'Sweet vermouth'],
    wrongOptions: ['Gin', 'Aperol', 'Lemon', 'Soda water'],
    correctMethod: 'stir',
    proportions: {
      'Bourbon': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Campari': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Sweet vermouth': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect:
          'Бульвардье — бурбонная глубина. Негрони для тех, кто хочет крепче.',
      wrongIngredients: 'Бульвардье: бурбон, кампари, сладкий вермут. Не джин!',
      wrongMethod: 'Stir — перемешай 30 секунд.',
      wrongProportions: '1.5:1:1 бурбон, кампари, вермут.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_pisco_sour',
    lessonId: 'lesson_C_12',
    blockId: 'C',
    cocktailName: 'Pisco Sour',
    cocktailEmoji: '🍸',
    johnIntro: 'Сегодня делаем Писко Сауэр. Писко, лайм, сахар, яичный белок. '
        'Перуанская классика. Сухое шейкание — пенка как облако.',
    correctIngredients: ['Pisco', 'Lime', 'Sugar', 'Egg white'],
    wrongOptions: ['Vodka', 'Lemon', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Pisco': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lime': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Sugar': ProportionTarget(targetMl: 15, toleranceMl: 3),
      'Egg white': ProportionTarget(targetMl: 15, toleranceMl: 3),
    },
    feedback: PracticeFeedback(
      perfect: 'Писко Сауэр — перуанское облако. Пенка идеальна.',
      wrongIngredients: 'Писко Сауэр: писко, лайм, сахар, белок. Не водка!',
      wrongMethod: 'Dry shake (без льда), затем shake со льдом.',
      wrongProportions: '60мл писко, 30мл лайм, 15мл сахар, 15мл белок.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_mai_tai',
    lessonId: 'lesson_C_12',
    blockId: 'C',
    cocktailName: 'Mai Tai',
    cocktailEmoji: '🍹',
    johnIntro: 'Сегодня делаем Май Тай. Два рома, лайм, оранж кюрасо и оржад. '
        'Тики-классика. Два рома — глубина вкуса. Оржад — миндальная сладость.',
    correctIngredients: ['Rum', 'Lime', 'Orange curacao', 'Orgeat'],
    wrongOptions: ['Vodka', 'Lemon', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Rum': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lime': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Orange curacao': ProportionTarget(targetMl: 15, toleranceMl: 3),
      'Orgeat': ProportionTarget(targetMl: 15, toleranceMl: 3),
    },
    feedback: PracticeFeedback(
      perfect:
          'Май Тай — тики-шедевр. Два рома, миндаль, лайм — тропический рай.',
      wrongIngredients: 'Май Тай: ром, лайм, оранж кюрасо, оржад. Не водка!',
      wrongMethod: 'Shake со льдом 12-15 секунд.',
      wrongProportions:
          '60мл ром (2 вида), 30мл лайм, 15мл кюрасо, 15мл оржад.',
    ),
  ),
];
