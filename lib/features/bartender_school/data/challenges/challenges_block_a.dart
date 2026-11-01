import 'package:coin/features/bartender_school/data/practice_challenges.dart';

/// Задания блока A: Пробуждение вкуса.
/// Классические сауэры и базовые коктейли.
const List<PracticeChallenge> challengesBlockA = [
  PracticeChallenge(
    id: 'practice_margarita',
    lessonId: 'lesson_A_02',
    blockId: 'A',
    cocktailName: 'Margarita',
    cocktailEmoji: '🧂',
    johnIntro: 'Сегодня делаем Маргариту. Текила, лайм и тройной сек. '
        'Это база — шаблон «сауэр». Научишься балансу кислоты и сладости. Собери.',
    correctIngredients: ['Tequila', 'Lime', 'Triple sec'],
    wrongOptions: ['Gin', 'Sugar', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Tequila': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lime': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Triple sec': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect:
          'Отлично! Маргарита — королева сауэров. Баланс кислоты и сладости идеален.',
      wrongIngredients:
          'Маргарита — это текила, лайм и тройной сек. Никакого джина!',
      wrongMethod: 'Маргариту шейкают со льдом 10-15 секунд.',
      wrongProportions:
          'Пропорции сауэра: 2:1:1 (спирт:кислое:сладкое). Проверь меры.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_whiskey_sour',
    lessonId: 'lesson_A_02',
    blockId: 'A',
    cocktailName: 'Whiskey Sour',
    cocktailEmoji: '🥃',
    johnIntro:
        'Сегодня делаем Виски Сауэр. Виски, лимон, сахар и яичный белок. '
        'Яичный белок даёт шелковистую пенку — это сухое шейкание. Попробуй.',
    correctIngredients: ['Whiskey', 'Lemon', 'Sugar', 'Egg white'],
    wrongOptions: ['Gin', 'Lime', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Whiskey': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lemon': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Sugar': ProportionTarget(targetMl: 15, toleranceMl: 3),
      'Egg white': ProportionTarget(targetMl: 15, toleranceMl: 3),
    },
    feedback: PracticeFeedback(
      perfect: 'Виски Сауэр с идеальной пенкой! Сухое шейкание освоено.',
      wrongIngredients:
          'Виски Сауэр: виски, лимон, сахар, яичный белок. Без лайма!',
      wrongMethod: 'Сначала шейкай без льда (сухое), потом со льдом.',
      wrongProportions:
          'Классика: 60мл виски, 30мл лимон, 15мл сахар, 15мл белок.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_tom_collins',
    lessonId: 'lesson_A_03',
    blockId: 'A',
    cocktailName: 'Tom Collins',
    cocktailEmoji: '🍋',
    johnIntro: 'Сегодня делаем Том Коллинз. Джин, лимон, сахар и содовая. '
        'Это длинный освежающий коктейль. Главное — не перебить газом.',
    correctIngredients: ['Gin', 'Lemon', 'Sugar', 'Soda water'],
    wrongOptions: ['Vodka', 'Lime', 'Mint', 'Tonic water'],
    correctMethod: 'shake',
    proportions: {
      'Gin': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Lemon': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Sugar': ProportionTarget(targetMl: 15, toleranceMl: 3),
      'Soda water': ProportionTarget(targetMl: 90, toleranceMl: 15),
    },
    feedback: PracticeFeedback(
      perfect:
          'Том Коллинз — идеальный лонг-дринк. Освежает, но не водянистый.',
      wrongIngredients: 'Том Коллинз: джин, лимон, сахар, содовая. Не тоник!',
      wrongMethod: 'Шейкай джин, лимон, сахар. Затем долей содовую.',
      wrongProportions:
          'Баланс: 60мл джин, 30мл лимон, 15мл сахар, 90мл содовая.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_cosmopolitan',
    lessonId: 'lesson_A_03',
    blockId: 'A',
    cocktailName: 'Cosmopolitan',
    cocktailEmoji: '🍸',
    johnIntro:
        'Сегодня делаем Космополитен. Водка, тройной сек, клюква и лайм. '
        'Красивый розовый цвет. Баланс кислоты и сладости — ключ к успеху.',
    correctIngredients: ['Vodka', 'Triple sec', 'Cranberry', 'Lime'],
    wrongOptions: ['Gin', 'Lemon', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Vodka': ProportionTarget(targetMl: 45, toleranceMl: 5),
      'Triple sec': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Cranberry': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Lime': ProportionTarget(targetMl: 15, toleranceMl: 3),
    },
    feedback: PracticeFeedback(
      perfect:
          'Космополитен — элегантно и сбалансированно. Розовый цвет идеален.',
      wrongIngredients: 'Космо: водка, тройной сек, клюква, лайм. Не джин!',
      wrongMethod: 'Космополитен шейкают со льдом 10-12 секунд.',
      wrongProportions: '45мл водка, 30мл тройной сек, 30мл клюква, 15мл лайм.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_old_fashioned',
    lessonId: 'lesson_A_04',
    blockId: 'A',
    cocktailName: 'Old Fashioned',
    cocktailEmoji: '🥃',
    johnIntro: 'Сегодня делаем Олд Фэшн. Виски, сахар, биттер. '
        'Это билд-коктейль. Минимум движений — максимум вкуса. Классика.',
    correctIngredients: ['Whiskey', 'Sugar', 'Bitter'],
    wrongOptions: ['Gin', 'Lemon', 'Mint', 'Soda water'],
    correctMethod: 'build',
    proportions: {
      'Whiskey': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Sugar': ProportionTarget(targetMl: 10, toleranceMl: 2),
      'Bitter': ProportionTarget(targetMl: 2, toleranceMl: 1),
    },
    feedback: PracticeFeedback(
      perfect: 'Олд Фэшн — джентльмен среди коктейлей. Просто и благородно.',
      wrongIngredients: 'Олд Фэшн: виски, сахар, биттер. Без лимона!',
      wrongMethod: 'Олд Фэшн — билд. Налей всё в бокал со льдом.',
      wrongProportions:
          '60мл виски, 10мл сахар, 2 дэш биттер.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_last_word',
    lessonId: 'lesson_A_04',
    blockId: 'A',
    cocktailName: 'Last Word',
    cocktailEmoji: '🍸',
    johnIntro: 'Сегодня делаем Ласт Вёрд. Джин, шартрёз, мараскино и лайм. '
        'Равные части — редкий приём. Каждый ингредиент слышен. Попробуй.',
    correctIngredients: ['Gin', 'Chartreuse', 'Maraschino', 'Lime'],
    wrongOptions: ['Vodka', 'Lemon', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Gin': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Chartreuse': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Maraschino': ProportionTarget(targetMl: 30, toleranceMl: 5),
      'Lime': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect: 'Ласт Вёрд — равные части, равный баланс. Сложно и прекрасно.',
      wrongIngredients: 'Ласт Вёрд: джин, шартрёз, мараскино, лайм. Не водка!',
      wrongMethod: 'Ласт Вёрд шейкают со льдом 12-15 секунд.',
      wrongProportions: 'Равные части: по 30мл каждого ингредиента.',
    ),
  ),
  PracticeChallenge(
    id: 'practice_penicillin',
    lessonId: 'lesson_A_02',
    blockId: 'A',
    cocktailName: 'Penicillin',
    cocktailEmoji: '🍯',
    johnIntro: 'Сегодня делаем Пенициллин. Скотч, имбирь, мёд и лимон. '
        'Современная классика: дымный, пряный и ярко-кислый сауэр.',
    correctIngredients: ['Scotch', 'Ginger', 'Honey', 'Lemon'],
    wrongOptions: ['Vodka', 'Lime', 'Mint', 'Soda water'],
    correctMethod: 'shake',
    proportions: {
      'Scotch': ProportionTarget(targetMl: 60, toleranceMl: 10),
      'Ginger': ProportionTarget(targetMl: 15, toleranceMl: 3),
      'Honey': ProportionTarget(targetMl: 15, toleranceMl: 3),
      'Lemon': ProportionTarget(targetMl: 30, toleranceMl: 5),
    },
    feedback: PracticeFeedback(
      perfect:
          'Пенициллин сбалансирован: имбирь даёт остроту, мёд смягчает лимон.',
      wrongIngredients: 'Пенициллин: скотч, имбирь, мёд и лимон. Не водка!',
      wrongMethod: 'Шейкай всё со льдом 12-15 секунд.',
      wrongProportions: '60мл скотч, 15мл имбирь, 15мл мёд, 30мл лимон.',
    ),
  ),
];
