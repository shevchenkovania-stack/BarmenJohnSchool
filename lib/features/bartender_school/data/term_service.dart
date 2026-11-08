/// Unified term database for the Bartender School.
/// Single source of truth — replaces hardcoded terms in GlossaryScreen and LessonScreen.
///
/// Each term has:
/// - Russian name (as used in lesson JSON)
/// - English name (for display)
/// - Definition, example, category
/// - Quiz questions for testing knowledge
import 'dart:math';

class TermService {
  static final TermService _instance = TermService._internal();
  factory TermService() => _instance;
  TermService._internal();

  /// All terms indexed by Russian name (matches lesson JSON `terms` field).
  /// Also indexed by English name for lookup flexibility.
  late final Map<String, TermData> _byRussianName = {
    for (final t in allTerms) t.russianName: t,
  };

  late final Map<String, TermData> _byEnglishName = {
    for (final t in allTerms) t.englishName.toLowerCase(): t,
  };

  /// Look up a term by either Russian or English name.
  TermData? getTerm(String name) {
    final lower = name.toLowerCase().trim();
    return _byRussianName[name] ??
        _byRussianName[lower] ??
        _byEnglishName[lower];
  }

  /// Get all terms for a lesson (by lesson's `terms` list from JSON).
  List<TermData> termsForLesson(List<String> lessonTermNames) {
    return lessonTermNames
        .map((name) => getTerm(name))
        .whereType<TermData>()
        .toList();
  }

  /// Get all terms grouped by category.
  Map<String, List<TermData>> get termsByCategory {
    final map = <String, List<TermData>>{};
    for (final t in allTerms) {
      map.putIfAbsent(t.category, () => []);
      map[t.category]!.add(t);
    }
    return map;
  }

  /// Generate quiz questions for a lesson's terms.
  ///
  /// [skipLearned] — термины, которые уже засчитаны прогрессом. Раньше все
  /// вопросы просто перемешивались и из них брались первые N: для урока с 8
  /// терминами гейт приходилось проходить 3–4 раза по случайности
  /// (TERM-FARM). Теперь берётся по одному вопросу на каждый невыученный
  /// термин, а обратные вопросы добавляются только если остались слоты.
  ///
  /// Перемешивание детерминированное ([seed]): иначе каждая перерисовка
  /// экрана и каждый повтор квиза давали новый набор вариантов, и выученный
  /// термин не узнавался. С тем же seed набор всегда один и тот же.
  List<TermQuizQuestion> generateQuiz(List<String> lessonTermNames,
      {int maxQuestions = 5,
      Set<String> skipLearned = const {},
      int? seed}) {
    final lessonTerms = termsForLesson(lessonTermNames);
    if (lessonTerms.isEmpty) return [];

    final rnd = Random(seed);

    final pending =
        lessonTerms.where((t) => !skipLearned.contains(t.russianName)).toList();
    // Всё выучено, но гейт всё равно открыли — не оставляем его без вопросов.
    final terms = pending.isEmpty ? lessonTerms : pending;

    final forward = <TermQuizQuestion>[];
    final reverse = <TermQuizQuestion>[];

    for (final term in terms) {
      // For each term, create a "what is it?" question
      final wrongAnswers = allTerms
          .where((t) =>
              t.englishName != term.englishName &&
              t.definition != term.definition)
          .toList()
        ..shuffle(rnd);

      final options = [
        term.definition,
        ...wrongAnswers.take(2).map((t) => t.definition)
      ]..shuffle(rnd);

      forward.add(TermQuizQuestion(
        question: 'Что такое "${term.russianName}"?',
        correctAnswer: term.definition,
        options: options,
        termName: term.russianName,
      ));
    }

    // Also add reverse questions: definition → term name
    for (final term in terms) {
      final wrongNames = allTerms
          .where((t) =>
              t.russianName != term.russianName &&
              t.definition != term.definition)
          .toList()
        ..shuffle(rnd);

      final options = [
        term.russianName,
        ...wrongNames.take(2).map((t) => t.russianName),
      ]..shuffle(rnd);

      reverse.add(TermQuizQuestion(
        question: 'Как называется: "${term.definition}"?',
        correctAnswer: term.russianName,
        options: options,
        termName: term.russianName,
      ));
    }

    return [...forward, ...reverse].take(maxQuestions).toList();
  }

  // ── Complete term database ──────────────────────────────────────────────

  static final List<TermData> allTerms = [
    // ─── Block A: Taste & Flavor ──────────────────────────────────────────
    TermData(
      russianName: 'Сладость',
      englishName: 'Sweetness',
      category: 'Вкус',
      definition: 'Один из 5 базовых вкусов. Сахар, сиропы, фрукты.',
      example: 'Simple syrup 1:1 — основной подсластитель в коктейлях.',
      lessonId: 'lesson_A_01',
    ),
    TermData(
      russianName: 'Кислота',
      englishName: 'Acidity',
      category: 'Вкус',
      definition: 'Кислый вкус. Цитрусовые, кислоты, ферменты.',
      example: 'Лимонный сок — главный источник кислоты в саурах.',
      lessonId: 'lesson_A_01',
    ),
    TermData(
      russianName: 'Горечь',
      englishName: 'Bitterness',
      category: 'Вкус',
      definition: 'Горький вкус. Тоники, биттеры, цедра, травы.',
      example: 'Angostura bitters — 2-3 дэша для глубины вкуса.',
      lessonId: 'lesson_A_01',
    ),
    TermData(
      russianName: 'Соль',
      englishName: 'Salt',
      category: 'Вкус',
      definition: 'Солёный вкус. Усиливает другие вкусы, балансирует горечь.',
      example: 'Saline solution — 1 капля 20% раствора раскрывает вкус.',
      lessonId: 'lesson_A_01',
    ),
    TermData(
      russianName: 'Умами',
      englishName: 'Umami',
      category: 'Вкус',
      definition: 'Пятый базовый вкус. Ощущение «вкусности», глубины.',
      example: 'Томатный сок в Bloody Mary — природный умами.',
      lessonId: 'lesson_A_01',
    ),
    TermData(
      russianName: 'Солевой раствор',
      englishName: 'Saline Solution',
      category: 'Ингредиент',
      definition:
          'Концентрированный раствор соли в воде. Используется для усиления вкуса.',
      example:
          '20% раствор: 20г соли на 100мл воды. 1 капля — и вкус заиграет.',
      lessonId: 'lesson_A_01',
    ),
    TermData(
      russianName: 'Кислотный баланс',
      englishName: 'Acid Balance',
      category: 'Вкус',
      definition: 'Баланс кислоты со сладостью. Основа формулы саура.',
      example:
          'Классический сауэр: 2 parts spirit, 1 part sour, 0.75 part sweet.',
      lessonId: 'lesson_A_02',
    ),
    TermData(
      russianName: 'Кислотный профиль',
      englishName: 'Acid Profile',
      category: 'Вкус',
      definition:
          'Характер кислоты: мягкая (лимон) vs резкая (лайм) vs нежная (яблоко).',
      example: 'Лайм даёт более резкую кислоту чем лимон.',
      lessonId: 'lesson_A_02',
    ),
    TermData(
      russianName: 'Свежевыжатый сок',
      englishName: 'Fresh Juice',
      category: 'Вкус',
      definition: 'Сок выжатый непосредственно перед использованием.',
      example: 'Всегда используй свежевыжатый лимонный сок — не из бутылки.',
      lessonId: 'lesson_A_02',
    ),
    TermData(
      russianName: 'Мексиканский локоть',
      englishName: 'Mexican Elbow',
      category: 'Инструмент',
      definition:
          'Ручной пресс для цитрусовых: рычаг нажимают ладонью сверху, а плод держит чаша. Даёт стабильный выход сока без эфирных масел из кожуры.',
      example: 'Из одного лимона ≈ 30 мл сока, из лайма ≈ 15 мл.',
      lessonId: 'lesson_A_02',
    ),
    TermData(
      russianName: 'Простой сироп 1:1',
      englishName: 'Simple Syrup',
      category: 'Ингредиент',
      definition: 'Сахар + вода в равных частях, растворённые нагревом.',
      example: '100г сахара + 100мл воды — стандартный сироп для коктейлей.',
      lessonId: 'lesson_A_03',
    ),
    TermData(
      russianName: 'Густой сироп 2:1',
      englishName: 'Rich Syrup',
      category: 'Ингредиент',
      definition:
          '2 части сахара на 1 часть воды. Более сладкий, дольше хранится.',
      example: 'Rich syrup лучше для коктейлей где нужна плотная сладость.',
      lessonId: 'lesson_A_03',
    ),
    TermData(
      russianName: 'Тело',
      englishName: 'Body',
      category: 'Вкус',
      definition: 'Ощущение плотности и насыщенности напитка во рту.',
      example: 'Яичный белок добавляет тело коктейлю без изменения вкуса.',
      lessonId: 'lesson_A_03',
    ),
    TermData(
      russianName: 'Агава',
      englishName: 'Agave',
      category: 'Ингредиент',
      definition: 'Сироп из растения агава. Более мягкая сладость чем сахар.',
      example: 'Agave nectar — альтернатива simple syrup с цветочным оттенком.',
      lessonId: 'lesson_A_03',
    ),
    TermData(
      russianName: 'Мёд',
      englishName: 'Honey',
      category: 'Ингредиент',
      definition:
          'Натуральный подсластитель. Требует разведения водой или сиропом.',
      example: 'Honey syrup: мёд + горячая вода 1:1, иначе не смешается.',
      lessonId: 'lesson_A_03',
    ),
    TermData(
      russianName: 'Горькая настойка (биттеры)',
      englishName: 'Bitters',
      category: 'Ингредиент',
      definition: 'Ароматические настойки на травах и специях.',
      example: 'Angostura, Orange bitters, Peychaud\'s — по 2-3 дэша.',
      lessonId: 'lesson_A_04',
    ),
    TermData(
      russianName: 'Дэш',
      englishName: 'Dash',
      category: 'Измерение',
      definition: 'Минимальная мера жидкости. ~0.5-1 мл из флакона биттеров.',
      example: '2 dashes Angostura в Old Fashioned.',
      lessonId: 'lesson_A_04',
    ),
    TermData(
      russianName: 'Капля',
      englishName: 'Drop',
      category: 'Измерение',
      definition:
          'Меньше дэша. Используется для концентрированных ингредиентов.',
      example: '1 капля saline solution для усиления вкуса.',
      lessonId: 'lesson_A_04',
    ),
    TermData(
      russianName: 'Ангостура',
      englishName: 'Angostura',
      category: 'Ингредиент',
      definition:
          'Самый известный биттер. Травяной, пряный, с нотами горечавки.',
      example: 'Old Fashioned, Manhattan, Trinidad Sour — везде Angostura.',
      lessonId: 'lesson_A_04',
    ),
    TermData(
      russianName: 'Апельсиновая настойка',
      englishName: 'Orange Bitters',
      category: 'Ингредиент',
      definition: 'Биттер с ароматом апельсиновой цедры.',
      example: 'Добавь 1 dash в Daiquiri для ароматической глубины.',
      lessonId: 'lesson_A_04',
    ),

    // ─── Block B: Tools & Technique ──────────────────────────────────────
    TermData(
      russianName: 'Подготовка (ми-зан-пляс)',
      englishName: 'Mise en Place',
      category: 'Техника',
      definition:
          'Французский термин: «всё на своём месте». Подготовка рабочего места.',
      example:
          'Перед сервисом: нарежь гарниши, наполни ice well, проверь сиропы.',
      lessonId: 'lesson_B_05',
    ),
    TermData(
      russianName: 'Рабочая станция',
      englishName: 'Work Station',
      category: 'Техника',
      definition:
          'Организованное пространство бармена для приготовления коктейлей.',
      example: 'Speed rail, ice bin, garnish tray — всё под рукой.',
      lessonId: 'lesson_B_05',
    ),
    TermData(
      russianName: 'Зоны станции',
      englishName: 'Station Zones',
      category: 'Техника',
      definition:
          'Логическое деление рабочего пространства: prep, build, service.',
      example: 'Зона приготовления → зона сборки → зона отдачи.',
      lessonId: 'lesson_B_05',
    ),
    // Урок B_09 говорит про станцию своими словами — без этих записей
    // тест терминов не запускался вовсе и гейт словаря обходился молча.
    TermData(
      russianName: 'Speed rack',
      englishName: 'Speed Rack',
      category: 'Инструмент',
      definition:
          'Ряд самых частых бутылок прямо перед барменом. Порядок — по частоте, а не по цене.',
      example: 'Ром, джин, водка и текила уходят в 80% заказов — они впереди.',
      lessonId: 'lesson_B_09',
    ),
    TermData(
      russianName: 'Чек-лист',
      englishName: 'Checklist',
      category: 'Техника',
      definition:
          'Короткий список проверок открытия и закрытия смены. Страховка от «забыл подписать сок».',
      example:
          'Лёд → соки и сиропы → гарниш → бутылки → инструмент → станция → стекло.',
      lessonId: 'lesson_B_09',
    ),
    TermData(
      russianName: 'Мерный стаканчик (джиггер)',
      englishName: 'Jigger',
      category: 'Инструмент',
      definition:
          'Двусторонний мерный стаканчик. Обычно 30/60 мл или 25/50 мл.',
      example: 'Наполняй до мениска — не до краёв, для точности.',
      lessonId: 'lesson_B_06',
    ),
    TermData(
      russianName: 'Мениск',
      englishName: 'Meniscus',
      category: 'Измерение',
      definition:
          'Выпуклая поверхность жидкости. Наливай до верхней точки мениска.',
      example: 'Правильный налив по мениску = точная дозировка.',
      lessonId: 'lesson_B_06',
    ),
    TermData(
      russianName: 'Унция (oz)',
      englishName: 'Ounce (oz)',
      category: 'Измерение',
      definition: 'Единица измерения в барной системе. 1 oz ≈ 30 мл.',
      example: 'Стандартные рецепты: 2 oz spirit, 1 oz sour, 0.75 oz sweet.',
      lessonId: 'lesson_B_06',
    ),
    TermData(
      russianName: 'Шейкер',
      englishName: 'Shaker',
      category: 'Инструмент',
      definition: 'Устройство для встряхивания коктейлей со льдом.',
      example: 'Boston shaker (2 части) — профессиональный выбор.',
      lessonId: 'lesson_B_07',
    ),
    TermData(
      russianName: 'Встряхивание (шейк)',
      englishName: 'Shake',
      category: 'Техника',
      definition:
          'Энергичное встряхивание со льдом. Охлаждает, разбавляет, аэрирует.',
      example: 'Daiquiri, Margarita — все коктейли с цитрусом требуют шейк.',
      lessonId: 'lesson_B_07',
    ),
    TermData(
      russianName: 'Сухой шейк',
      englishName: 'Dry Shake',
      category: 'Техника',
      definition:
          'Встряхивание БЕЗ льда. Для эмульгации яичного белка или сливок.',
      example: 'Pisco Sour: сначала 20 сек dry shake, потом со льдом.',
      lessonId: 'lesson_B_07',
    ),
    TermData(
      russianName: 'Разбавление',
      englishName: 'Dilution',
      category: 'Техника',
      definition:
          'Талая вода из льда, попадающая в коктейль при шейке или стире.',
      example: '20-25% разбавление — норма для shaken коктейля.',
      lessonId: 'lesson_B_07',
    ),
    TermData(
      russianName: 'Аэрация',
      englishName: 'Aeration',
      category: 'Техника',
      definition: 'Насыщение коктейля пузырьками воздуха при встряхивании.',
      example:
          'Shake даёт мелкую аэрацию — коктейль становится мутным и лёгким.',
      lessonId: 'lesson_B_07',
    ),
    TermData(
      russianName: 'Чаша',
      englishName: 'Cup',
      category: 'Инструмент',
      definition: 'Часть шейкера или бокала. Также мера объёма.',
      example: 'Boston shaker имеет две чаши: металлическую и стеклянную.',
      lessonId: 'lesson_B_07',
    ),
    TermData(
      russianName: 'Стакан',
      englishName: 'Glass',
      category: 'Инструмент',
      definition: 'Ёмкость для подачи или приготовления коктейля.',
      example: 'Mixing glass — для stir, highball glass — для long drinks.',
      lessonId: 'lesson_B_07',
    ),
    TermData(
      russianName: 'Талая вода',
      englishName: 'Melt Water',
      category: 'Техника',
      definition: 'Вода от тающего льда. Ключевой компонент баланса коктейля.',
      example: 'Слишком много талой воды = водянистый коктейль.',
      lessonId: 'lesson_B_08',
    ),
    TermData(
      russianName: 'Размешивание',
      englishName: 'Stir',
      category: 'Техника',
      definition:
          'Аккуратное размешивание барной ложкой. Охлаждает без аэрации.',
      example: 'Manhattan, Negroni, Martini — только stir, никогда shake.',
      lessonId: 'lesson_B_08',
    ),
    TermData(
      russianName: 'Дроблёный лёд',
      englishName: 'Crushed Ice',
      category: 'Инструмент',
      definition: 'Лёд мелкой фракции. Для julep, tiki, некоторых highball.',
      example: 'Mint Julep — только crushed ice для правильного охлаждения.',
      lessonId: 'lesson_B_08',
    ),
    TermData(
      russianName: 'Шейк',
      englishName: 'Shake',
      category: 'Техника',
      definition: 'Синоним встряхивания. Интенсивное смешивание со льдом.',
      example: 'Shake 10-15 секунд — стандарт для большинства коктейлей.',
      lessonId: 'lesson_B_08',
    ),
    TermData(
      russianName: 'Кубики льда',
      englishName: 'Ice Cubes',
      category: 'Инструмент',
      definition: 'Стандартная форма льда. Большие кубики медленнее тают.',
      example: 'Для stir используй большие кубики — меньше разбавления.',
      lessonId: 'lesson_B_08',
    ),

    // ─── Block C: First Cocktails ────────────────────────────────────────
    TermData(
      russianName: 'Сборка',
      englishName: 'Build',
      category: 'Техника',
      definition: 'Метод: собрать ингредиенты прямо в бокале со льдом.',
      example: 'Mojito, Tom Collins — build method, без шейкера.',
      lessonId: 'lesson_C_09',
    ),
    TermData(
      russianName: 'Мадл',
      englishName: 'Muddle',
      category: 'Техника',
      definition: 'Раздавливание ингредиентов мадлером. Мята, лайм, фрукты.',
      example: 'Mojito: мягко раздави мяту с лаймом и сахаром.',
      lessonId: 'lesson_C_09',
    ),
    TermData(
      russianName: 'Белый ром',
      englishName: 'White Rum',
      category: 'Ингредиент',
      definition: 'Лёгкий ром без выдержки. Основа для Mojito и Daiquiri.',
      example:
          'Havana Club 3, Bacardi Superior — классика для латиноамериканских коктейлей.',
      lessonId: 'lesson_C_09',
    ),
    TermData(
      russianName: 'Встряхивание',
      englishName: 'Shaking',
      category: 'Техника',
      definition: 'Интенсивное встряхивание в шейкере со льдом 10-15 секунд.',
      example: 'Daiquiri: shake 12 секунд до полного охлаждения.',
      lessonId: 'lesson_C_10',
    ),
    TermData(
      russianName: 'Двойное процеживание',
      englishName: 'Double Strain',
      category: 'Техника',
      definition: 'Процеживание через Hawthorne strainer + fine mesh strainer.',
      example: 'Daiquiri: double strain убирает мелкие кусочки льда и мякоть.',
      lessonId: 'lesson_C_10',
    ),
    TermData(
      russianName: 'Купе',
      englishName: 'Coupe',
      category: 'Инструмент',
      definition: 'Бокал на ножке с широкой чашей. Для коктейлей без льда.',
      example: 'Daiquiri, Manhattan — подаются в coupe glass.',
      lessonId: 'lesson_C_10',
    ),
    TermData(
      russianName: 'Кампари',
      englishName: 'Campari',
      category: 'Ингредиент',
      definition: 'Итальянский горький аперитив. Настойка на травах и фруктах.',
      example: 'Negroni = равные части Gin + Campari + Sweet Vermouth.',
      lessonId: 'lesson_C_11',
    ),
    TermData(
      russianName: 'Вермут',
      englishName: 'Vermouth',
      category: 'Ингредиент',
      definition: 'Креплёное вино, ароматизированное травами и специями.',
      example: 'Sweet vermouth — для Negroni и Manhattan. Dry — для Martini.',
      lessonId: 'lesson_C_11',
    ),
  ];
}

/// Complete data for a single term.
class TermData {
  final String russianName; // As used in lesson JSON
  final String englishName; // For display
  final String category; // Вкус, Инструмент, Техника, Ингредиент, Измерение
  final String definition;
  final String example;
  final String lessonId; // Which lesson introduces this term

  const TermData({
    required this.russianName,
    required this.englishName,
    required this.category,
    required this.definition,
    required this.example,
    required this.lessonId,
  });

  /// Display name: "English (Русский)" or just Russian if no English.
  String get displayName => '$englishName ($russianName)';
}

/// A quiz question about a term.
class TermQuizQuestion {
  final String question;
  final String correctAnswer;
  final List<String> options;
  final String termName; // For tracking which term was tested

  const TermQuizQuestion({
    required this.question,
    required this.correctAnswer,
    required this.options,
    required this.termName,
  });
}
