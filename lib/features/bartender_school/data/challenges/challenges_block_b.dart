import 'package:coin/features/bartender_school/data/practice_challenges.dart';

/// Задания блока B: Руки и инструменты.
/// Классики с разными методами.
const List<PracticeChallenge> challengesBlockB = [
  PracticeChallenge(
    id: 'practice_manhattan',
    lessonId: 'lesson_B_05',
    blockId: 'B',
    cocktailName: 'Manhattan',
    cocktailEmoji: '🍸',
    johnIntro: 'Сегодня делаем Манхэттен. Виски, сладкий вермут и биттер. '
        'Это stir-коктейль. Перемешиваем, не шейкаем — прозрачность и шелк.',
    correctIngredients: ['Whiskey', 'Sweet vermouth', 'Bitter'],
    wrongOptions: ['Gin', 'Dry vermouth', 'Lemon', 'Soda water'],
    correctMethod: 'stir',
    proportions: {
      'Whiskey': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Sweet vermouth': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Bitter': ProportionTarget(targetMl: 2, toleranceMl: 1),
    },
    feedback: PracticeFeedback(
      perfect:
          'Манхэттен — stir в лучшем виде. Прозрачный, шелковистый, крепкий.',
      wrongIngredients: 'Манхэттен: виски, сладкий вермут, биттер. Не джин!',
      wrongMethod: 'Манхэттен перемешивают барной ложкой 30 секунд.',
      wrongProportions: '2:1 виски к вермуту + 2 дэш биттер.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_moscow_mule',
    lessonId: 'lesson_B_05',
    blockId: 'B',
    cocktailName: 'Moscow Mule',
    cocktailEmoji: '🍺',
    johnIntro: 'Сегодня делаем Московский Мул. Водка, лайм и имбирное пиво. '
        'Подают в медной кружке. Build — просто налей в кружку со льдом.',
    correctIngredients: ['Vodka', 'Lime', 'Ginger beer'],
    wrongOptions: ['Gin', 'Lemon', 'Tonic water', 'Mint'],
    correctMethod: 'build',
    proportions: {
      'Vodka': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lime': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Ginger beer': ProportionTarget(targetMl: 120, toleranceMl: 20),
    },
    feedback: PracticeFeedback(
      perfect: 'Московский Мул — имбирная свежесть. Медная кружка — традиция.',
      wrongIngredients: 'Мул: водка, лайм, имбирное пиво. Не тоник!',
      wrongMethod: 'Build — налей всё в медную кружку со льдом.',
      wrongProportions: '60мл водка, 30мл лайм, 120мл имбирное пиво.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_aperol_spritz',
    lessonId: 'lesson_B_06',
    blockId: 'B',
    cocktailName: 'Aperol Spritz',
    cocktailEmoji: '🍹',
    johnIntro: 'Сегодня делаем Апероль Шприц. Апероль, просекко и содовая. '
        'Итальянская классика. Равные части, но содовой чуть меньше.',
    correctIngredients: ['Aperol', 'Prosecco', 'Soda water'],
    wrongOptions: ['Campari', 'Gin', 'Lemon', 'Mint'],
    correctMethod: 'build',
    proportions: {
      'Aperol': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Prosecco': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Soda water': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect:
          'Апероль Шприц — итальянское солнце в бокале. Лёгкий и горьковатый.',
      wrongIngredients: 'Шприц: апероль, просекко, содовая. Не кампари!',
      wrongMethod: 'Build — налей в бокал вина со льдом.',
      wrongProportions: '3:3:1 (апероль:просекко:сода).',
    ),
  ),
  PracticeChallenge(
    id: 'practice_bloody_mary',
    lessonId: 'lesson_B_06',
    blockId: 'B',
    cocktailName: 'Bloody Mary',
    cocktailEmoji: '🍅',
    johnIntro: 'Сегодня делаем Блади Мэри. Водка, томатный сок, лимон, '
        'соль, перец, табаско. Build — смешай всё в бокале. brunch-король.',
    correctIngredients: ['Vodka', 'Tomato juice', 'Lemon'],
    wrongOptions: ['Gin', 'Orange juice', 'Mint', 'Soda water'],
    correctMethod: 'build',
    proportions: {
      'Vodka': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Tomato juice': ProportionTarget(targetMl: 90, toleranceMl: 15),
      'Lemon': ProportionTarget(targetMl: 15, toleranceMl: 3),
    },
    feedback: PracticeFeedback(
      perfect: 'Блади Мэри — завтрак чемпионов. Густой, пряный, бодрящий.',
      wrongIngredients: 'Мэри: водка, томатный сок, лимон. Не апельсиновый!',
      wrongMethod: 'Build — смешай всё в высоком бокале.',
      wrongProportions: '45мл водка, 90мл томат, 15мл лимон + специи.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_espresso_martini',
    lessonId: 'lesson_B_07',
    blockId: 'B',
    cocktailName: 'Espresso Martini',
    cocktailEmoji: '☕',
    johnIntro:
        'Сегодня делаем Эспрессо Мартини. Водка, кофейный ликёр и эспрессо. '
        'Shake — пенка обязательна. Кофе + алкоголь = энергия и расслабление.',
    correctIngredients: ['Vodka', 'Coffee liqueur', 'Espresso'],
    wrongOptions: ['Gin', 'Milk', 'Sugar', 'Mint'],
    correctMethod: 'shake',
    proportions: {
      'Vodka': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Coffee liqueur': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Espresso': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect:
          'Эспрессо Мартини — идеальная кофейная пенка. Бодрит и расслабляет.',
      wrongIngredients: 'Эспрессо Мартини: водка, кофейный ликёр, эспрессо.',
      wrongMethod: 'Shake со льдом 12-15 секунд — пенка обязательна!',
      wrongProportions: '45мл водка, 30мл ликёр, 30мл эспрессо.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_gin_fizz',
    lessonId: 'lesson_B_07',
    blockId: 'B',
    cocktailName: 'Gin Fizz',
    cocktailEmoji: '🍸',
    johnIntro: 'Сегодня делаем Джин Физ. Джин, лимон, сахар и содовая. '
        'Fizz-семейство. Shake джин, лимон, сахар — затем долей содовую.',
    correctIngredients: ['Gin', 'Lemon', 'Sugar', 'Soda water'],
    wrongOptions: ['Vodka', 'Lime', 'Mint', 'Tonic water'],
    correctMethod: 'shake',
    proportions: {
      'Gin': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lemon': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Sugar': ProportionTarget(targetMl: 15, toleranceMl: 3),
      'Soda water': ProportionTarget(targetMl: 60, toleranceMl: 10),
    },
    feedback: PracticeFeedback(
      perfect: 'Джин Физ — шипучая классика. Освежает, как утренний бриз.',
      wrongIngredients: 'Физ: джин, лимон, сахар, содовая. Не тоник!',
      wrongMethod: 'Shake джин, лимон, сахар. Долей содовую сверху.',
      wrongProportions: '60мл джин, 30мл лимон, 15мл сахар, 60мл сода.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_sidecar',
    lessonId: 'lesson_B_08',
    blockId: 'B',
    cocktailName: 'Sidecar',
    cocktailEmoji: '🍸',
    johnIntro: 'Сегодня делаем Сайдкар. Коньяк, тройной сек и лимон. '
        'Брат Маргариты, но на коньяке. Элегантный и крепкий.',
    correctIngredients: ['Cognac', 'Triple sec', 'Lemon'],
    wrongOptions: ['Gin', 'Lime', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Cognac': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Triple sec': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Lemon': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect: 'Сайдкар — коньячная элегантность. Сахарный ободок — традиция.',
      wrongIngredients: 'Сайдкар: коньяк, тройной сек, лимон. Не джин!',
      wrongMethod: 'Shake со льдом 10-12 секунд.',
      wrongProportions: '2:1:1 коньяк, тройной сек, лимон.',
    ),
  ),
];
