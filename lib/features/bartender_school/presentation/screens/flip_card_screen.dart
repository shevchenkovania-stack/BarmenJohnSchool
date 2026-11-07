import 'package:flutter/material.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:coin/features/bartender_school/presentation/widgets/lesson_teaser.dart';

class FlipCardScreen extends StatefulWidget {
  final Lesson lesson;

  const FlipCardScreen({super.key, required this.lesson});

  @override
  State<FlipCardScreen> createState() => _FlipCardScreenState();
}

class _FlipCardScreenState extends State<FlipCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  JohnSchoolRoom get _room => JohnRoomStyle.roomForBlock(widget.lesson.blockId);

  Color _panelTextColor(JohnRoomStyle style) => style.onDark;

  String get _lessonIconAsset => switch (widget.lesson.blockId) {
        'A' => 'images/ui_icon_balance_precision.png',
        'B' => 'images/ui_icon_tool_station.png',
        'C' => 'images/ui_icon_term_medal.png',
        _ => 'images/ui_icon_book_theory.png',
      };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _showGlossary() {
    final room = _room;
    final style = JohnRoomStyle.forRoom(room);
    final textColor = _panelTextColor(style);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [style.surfaceLight, style.surface],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: style.accent, width: 1.5)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: style.accent.withAlpha(150),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: style.accent.withAlpha(35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: style.accent.withAlpha(100)),
                      ),
                      child: Image.asset('images/ui_icon_book_theory.png',
                          width: 24, height: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Термины урока',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                              color: textColor,
                            ),
                          ),
                          Text(
                            '${widget.lesson.terms.length} терминов для изучения',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textColor.withAlpha(190)),
                    ),
                  ],
                ),
              ),
              Divider(color: style.accent.withAlpha(95), height: 1),
              Expanded(
                child: widget.lesson.terms.isEmpty
                    ? Center(
                        child: Text(
                          'В этом уроке нет новых терминов',
                          style: TextStyle(color: textColor.withAlpha(180)),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: widget.lesson.terms.length,
                        itemBuilder: (context, index) {
                          final term = widget.lesson.terms[index];
                          return _GlossaryTermCard(
                            room: room,
                            term: term,
                            definition: _getTermDefinition(term),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTermDefinition(String term) {
    final definitions = {
      'Сладость':
          'Вкус + текстура. Сахар строит «тело» коктейля, делает его бархатистым.',
      'Кислота':
          'Лимон, лайм — 15-30 мл. Будит рецепторы, даёт яркость. Только свежевыжатый!',
      'Горечь':
          'Горькие настойки, Кампари. 1-2 капли связывают вкус, добавляют глубину. Это не ошибка!',
      'Соль': 'Усилитель вкуса. Солевой раствор 20% — 1 капля раскрывает вкус.',
      'Умами':
          '«Мясо» вкуса. Помидор, мисо, копчёности. Даёт долгое послевкусие.',
      'Тело':
          'Плотность и вязкость коктейля во рту. Зависит от сиропа и алкоголя.',
      'Дэш': '2-3 капли из дозатора. Очень маленькая доза, как щепотка специй.',
      'Солевой раствор':
          '20% соль в воде. 1 капля = контролируемая щепотка без хруста.',
      'Кислотный баланс':
          'Правильное соотношение кислоты и сладости. Ключ к питкости коктейля.',
      'Кислотный профиль':
          'Характер кислоты (лимонная, яблочная) и как она влияет на вкус.',
      'Свежевыжатый сок':
          'Только что выжатый сок. Бутилированный = мёртвый вкус через 3 дня!',
      'Мексиканский локоть':
          'Ручной пресс для цитрусовых. Лучший инструмент для сока.',
      'Простой сироп 1:1':
          'Равные части сахара и воды. Основа большинства коктейлей.',
      'Густой сироп 2:1': 'Густой сироп, больше «тела». Для крепких коктейлей.',
      'Агава': 'Мягкий подсластитель с карамелью. Для текилы.',
      'Мёд': 'Сложный аромат. Разогрей с водой 1:1 чтобы растворился.',
      'Горькая настойка':
          'Биттеры — ароматические настойки. 1-2 капли добавляют глубину.',
      'Ангостура': 'Пряная горькая настойка. База для 70% коктейлей.',
      'Апельсиновая настойка':
          'Цитрусовая горькая настойка. Освежает ароматику.',
      'Капля': '0.05 мл. Для точечной коррекции вкуса.',
      'Подготовка': '«Ми-зан-пляс» — всё на месте до первой продажи.',
      'Рабочая станция':
          'Организованное рабочее пространство с зонами для каждого элемента.',
      'Зоны станции':
          'Зоны льда, спиртов, цитрусовых, настоек, сиропов, гарниров.',
      'Мерный стаканчик':
          'Двусторонняя мера 30/60 мл. Убирает гадание «на глаз».',
      'Мениск':
          'Изогнутая поверхность жидкости. Заполняй до верхнего края изгиба!',
      'Унция': 'Мера объёма. 1 унция = 30 мл (в баре).',
      'Шейкер': '«Встрясыватель» для коктейлей. Бостон — стандарт профи.',
      'Встряхивание':
          '4 операции за раз: смешать + охладить + разбавить + аэрировать.',
      'Сухой шейк': 'Встряхивание без льда для аэрации белка или сливок.',
      'Разбавление': 'Талая вода от льда (20-25%). Делает коктейль питким.',
      'Аэрация':
          'Пузырьки воздуха создают текстуру. Результат правильного встряхивания.',
      'Чаша': 'Металлическая часть шейкера Бостон.',
      'Стакан': 'Стеклянная часть шейкера Бостон (используется как крышка).',
      'Талая вода':
          'Вода от растаявшего льда. Основа контролируемого разбавления.',
      'Шейк': 'Встряхивание со льдом.',
      'Размешивание':
          'Для прозрачных коктейлей без аэрации. Охлаждает без пузырьков.',
      'Дроблёный лёд': 'Мелко разбитый лёд. Для быстрого охлаждения.',
      'Кубики льда': 'Стандартный лёд 2.5 см для большинства коктейлей.',
      'Мадл': 'Раздавливание мяты, лайма, фруктов. 6-8 мягких нажатий!',
      'Мадлер':
          'Палочка для раздавливания. Плоский конец, чтобы не порвать листья.',
      'Сборка': 'Метод приготовления прямо в бокале. Для лонг-дринков.',
      'Долей содовую':
          'Добавить газированную воду сверху в конце приготовления.',
      'Двойное процеживание':
          'Через два сита. Убирает крошку и мякоть для чистоты.',
      'Ситечко': 'Стрейнер на шейкере для процеживания.',
      'Мелкое сито': 'Тонкое сито для финальной фильтрации.',
      'Кампари':
          'Горький красный ликёр. Даёт горечь и цвет. Главный в Негрони.',
      'Цедра апельсина':
          'Полоска кожуры без белой части. Выжать масло над коктейлем.',
      'Барная ложка':
          'Длинная ложка для размешивания. 30-40 оборотов для Негрони.',
      'Смесительный стакан':
          'Прозрачный стакан для размешивания. Чтобы видеть процесс.',
      'Экзамен':
          '15 вопросов, 70% для прохождения. Проверка всех знаний Level 1.',
      'Диплом Level 1':
          'Подтверждает базовые знания бармена и честно сданную практику.',
    };
    return definitions[term] ?? 'Термин из урока. Подробнее в материалах.';
  }

  String _getExtendedDescription() {
    final id = widget.lesson.id.toLowerCase();
    final title = widget.lesson.title.toLowerCase();

    if (id.contains('lesson_a_01') || title.contains('5 вкусов')) {
      return '''Коктейль — это не магия, а наука управления 5 вкусами.

Что это: Каждый коктейль — это танец из 5 элементов: сладкое, кислое, горькое, солёное и умами. Умами (японский — «пикантный») — вкус глубины и насыщенности, как у бульона или соевого соуса. Не обязательно все сразу, но баланс между ними создаёт «не хочешь оторваться» эффект.

Зачем: Гость не скажет «здесь идеальное соотношение». Он скажет «вкусно, ещё один». Твоя задача — создать это ощущение.

Как работает:
• Кислота будит рецепторы — делает вкус ярким
• Сладость «обнимает» спирт — делает крепкий напиток мягким
• Горечь связывает всё воедино — даёт глубину
• Соль раскрывает вкус — 1 капля, и всё «играет»
• Умами даёт послевкусие — хочется ещё''';
    }

    if (id.contains('lesson_a_02') || title.contains('кислот')) {
      return '''Кислота — это «искра» коктейля.

Что это: Лимон, лайм, иногда апельсин или уксус. Кислый вкус будит рецепторы, создаёт яркость и структуру.

Зачем: Без кислоты коктейль «плоский», водянистый, без характера. Кислота — первое, что гость чувствует.

Важно:
• Только свежевыжатый сок! Бутилированный = мёртвый вкус
• Лимон = чистая лимонная кислота
• Лайм = кислота + лёгкая горчинка цедры
• Рабочая зона: 15-30 мл на коктейль''';
    }

    if (id.contains('lesson_a_03') ||
        title.contains('сладость') ||
        title.contains('сироп')) {
      return '''Сладость — это «тело» коктейля.

Что это: Сиропы, ликёры, мёд. Не просто вкус — это текстура и плотность напитка.

Зачем: Без сладости крепкий коктейль «режет» язык. Сладость смягчает спирт, делает напиток питким.

Виды:
• Простой сироп 1:1 — лёгкий, быстрый. Основа большинства коктейлей
• Густой сироп 2:1 — густой, больше «тела». Для виски, крепких напитков
• Мёд — сложный аромат. Разогрей с водой 1:1
• Агава — мягкий, для текилы''';
    }

    if (id.contains('lesson_a_04') ||
        title.contains('горечь') ||
        title.contains('баланс')) {
      return '''Горечь — секретное оружие профи.

Что это: Горькие настойки, цедра, кофе, хина. Не «делать горько», а добавлять глубину и связывать вкусы.

Зачем: Горечь — это «сумо» вкуса. Она не доминирует, а собирает все элементы вместе.

Как использовать:
• 1 дэш (2-3 капли) = меняет ароматику (почти незаметно)
• 2 дэша = влияет на вкус и послевкусие
• 3+ дэша = меняет характер коктейля

Виды:
• Ангостура — пряная, травяная. База для большинства коктейлей
• Апельсиновая — цитрусовая, освежающая
• Пейшо — анисовая, для классики''';
    }

    if (id.contains('lesson_b_05') ||
        title.contains('mise') ||
        title.contains('подготовк')) {
      return '''ПОДГОТОВКА — философия «всё на месте»!

Что это: Французский термин «ми-зан-пляс». Всё подготовлено ДО первой продажи.

Как организовать станцию:

ЗОНА ЛЬДА
Ближе всего к доминирующей руке (20 см).
Кубики, дроблёный, сферы — всё рядом.

ЗОНА СПИРТОВ
Бутылки по алфавиту или категориям.
Этикетки наружу — видно что где.

ЗОНА ЦИТРУСОВЫХ
Свежевыжатый сок, цедра.
Холодильник или лёд рядом.

ЗОНА ГОРЬКИХ НАСТОЕК
Ангостура, апельсиновая, Пейшо.
Плотно закрыты, под рукой.

ЗОНА СИРОПОВ
Простой 1:1, густой 2:1, мёд, агава.
Всё подписано!

РЕЗУЛЬТАТ:
• Без подготовки: 3-4 минуты на коктейль
• С подготовкой: 45-60 секунд!''';
    }

    if (id.contains('lesson_b_06') ||
        title.contains('джиггер') ||
        title.contains('мерный')) {
      return '''МЕРНЫЙ СТАКАНЧИК — твой калибр точности!

Как выглядит: Форма песочных часов — две колбочки соединены вместе.
• Маленькая сторона = 30 мл (1 унция)
• Большая сторона = 60 мл (2 унции)

Зачем он нужен:
Без него бармен «на глаз» наливает 20-45 мл вместо нужных 30.
Это разница между идеальным и «кислым» коктейлем.

Как правильно наливать:
1. Держи мерный стаканчик на уровне глаз
2. Смотри на изогнутую поверхность — это МЕНИСК
3. Наполняй ДО верхнего края мениска, НЕ до краёв!

Размеры для запоминания:
• 15 мл = дэш (2-3 капли) горьких настоек
• 30 мл = стандартная мера
• 45 мл = классика (Дайкири, Маргарита)
• 60 мл = двойная мера

Скорость с практикой: 2-3 секунды!''';
    }

    if (id.contains('lesson_b_07') || title.contains('шейкер')) {
      return '''ШЕЙКЕР — это «встрясыватель» для коктейлей.

Как выглядит (Бостон): Два стакана: большой металлический + стеклянный.
Ставятся друг на друга и получается герметичная чаша.

Что он делает (4 операции за раз!):
1. Смешивает все ингредиенты
2. Охлаждает до 0°C
3. Разбавляет льдом (20-25%)
4. Аэрирует (пузырьки = текстура)

Виды шейкеров:
• Бостон — стандарт профи (90% барменов)
• Кобблер — 3 части, проще, для дома
• Френч — металл-металл, для стиля

Техника Бостон:
1. Лёд в металлическую чашу на 2/3
2. Влей ингредиенты
3. Надень стакан, сожми
4. Встряхивай «туда-сюда» 10-15 раз
5. Открой — звук «чпок» = хорошо!''';
    }

    if (id.contains('lesson_b_08') || title.contains('лёд')) {
      return '''ЛЁД — это не просто охлаждение!

Лёд делает 3 вещи:
1. Охлаждает (с 20°C до 0°C)
2. Разбавляет (талая вода = 20-25% коктейля)
3. Создаёт текстуру (пузырьки в шэйкнутых)

Сколько льда тает:
• Встряхивание 10-15 сек = 25-35 мл талой воды
• Размешивание 30-40 оборотов = 20-30 мл талой воды
• Сборка (без охлаждения) = почти 0

Виды льда:
• Кубики 2.5 см — стандарт для шейка
• Дроблёный — быстрое охлаждение (Мохито)
• Шар — медленное таяние (виски он зэ рокс)
• Блок — для особых случаев

ГИГИЕНА:
• НИКОГДА не трогай руками!
• Храни в чистом ведре с крышкой
• Лёд с запахом — выбросить!''';
    }

    if (id.contains('lesson_c_09') ||
        title.contains('mojito') ||
        title.contains('мохито')) {
      return '''МОХИТО — летний коктейль с мятой!

Как выглядит: Высокий стакан с дроблёным льдом, белым ромом, лаймом, мятой и содовой.

Как делать (метод сборки):
1. Положи мяту + сахар
2. Выжми лайм (25 мл)
3. Налей ром (60 мл)
4. Заполни дроблёным льдом
5. Долей содовую

Техника раздавливания (мадл):
• НЕ дави как сумасшедший!
• 6-8 лёгких нажатий мадлером
• Сахар защищает листья
• Сильное давление = горечь + мутность!

ОШИБКИ:
• Выдержанный ром вместо белого = неправильный вкус
• Взбить в шейкере = ломает мяту!
• Сильное раздавливание = горький и мутный коктейль''';
    }

    if (id.contains('lesson_c_10') ||
        title.contains('daiquiri') ||
        title.contains('дайкири')) {
      return '''ДАЙКИРИ — «тест бармена»!

Как выглядит: Маленький элегантный бокал (купе) без льда. Подаётся ледяным, прозрачным, с лёгким «туманом» от пузырьков.

Формула 60:30:20 (запомни!):
• Ром 60 мл (2 части) — база
• Лайм 30 мл (1 часть) — кислота
• Сироп 20 мл — сладость

Как делать:
1. Лёд в шейкер на 2/3
2. Все ингредиенты
3. ВСТРЯХИВАЙ 10-15 раз
4. ДВОЙНОЕ ПРОЦЕЖИВАНИЕ в купе

Двойное процеживание — это два сита:
• Сначала через ситечко (отделить лёд)
• Потом через мелкое сито (убрать крошку)
• Результат: ШЁЛКОВЫЙ, КРИСТАЛЬНО ЧИСТЫЙ!

Проверка после встряхивания:
• Коктейль ЛЕДЯНОЙ (0°C)
• Много мелких пузырьков
• Лёд частично растоплен (30-40%)''';
    }

    if (id.contains('lesson_c_11') ||
        title.contains('negroni') ||
        title.contains('негрони')) {
      return '''НЕГРОНИ — горькая итальянская классика!

Как выглядит: Рокс стакан с одним большим кубиком льда. Оранжево-красный цвет от Кампари.

Формула 1:1:1 (равные части):
• Джин 30 мл — травяная сложность
• Кампари 30 мл — горький ликёр, красный цвет
• Вермут 30 мл — сладкий, итальянский

Почему РАЗМЕШИВАНИЕ, а не встряхивание:
• Нет цитруса, яиц, сливок
• Нужна ПРОЗРАЧНОСТЬ и шёлковая текстура
• Аэрация не нужна

Как делать:
1. Лёд в смесительный стакан
2. Все ингредиенты
3. РАЗМЕШИВАЙ 30-40 оборотов
4. Процеди в рокс с большим кубиком

Гарниш: Апельсиновая цедра!
Выжми над коктейлем — цитрусовое масло полетит на поверхность!''';
    }

    if (id.contains('lesson_c_12')) {
      return '''ФИНАЛЬНЫЙ ЭКЗАМЕН — проверь себя!

Что это: Все знания уровня «Для начинающих» в одном тесте.

Что включено:
• 5 вкусов и баланс
• Кислота и сладость
• Горечь и горькие настойки
• Инструменты (мерный стаканчик, шейкер)
• Подготовка
• Лёд и разбавление
• 3 классических коктейля

Формат:
• 15 вопросов
• 80% для прохождения
• Случайная выборка из пула

Подготовка:
• Пересмотри все уроки
• Пробуй на практике (с водой!)
• Запомни формулы и техники

Удачи!''';
    }

    return '''${widget.lesson.title}

${widget.lesson.shortDescription}

В этом уроке ты узнаешь:
${widget.lesson.keyPoints.map((p) => '• $p').join('\n')}

Практикуйся после урока — это закрепляет знание!''';
  }

  @override
  Widget build(BuildContext context) {
    final room = _room;
    final style = JohnRoomStyle.forRoom(room);
    final textColor = _panelTextColor(style);
    return Scaffold(
      backgroundColor: const Color(0xFF120B08),
      body: JohnRoomBackground(
        room: room,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                JohnWoodPanel(
                  room: room,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Карточка урока',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                      if (widget.lesson.terms.isNotEmpty)
                        TextButton.icon(
                          onPressed: _showGlossary,
                          icon: Image.asset(
                            'images/ui_icon_book_theory.png',
                            width: 18,
                            height: 18,
                          ),
                          label: Text('${widget.lesson.terms.length}'),
                          style: TextButton.styleFrom(
                            foregroundColor: style.accent,
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: _flip,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final angle = _animation.value * 3.14159;
                        final showBack = _animation.value >= 0.5;

                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(angle),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: style.accent.withAlpha(
                                    (60 + 40 * (1 - (angle / 3.14159).abs()))
                                        .toInt()
                                        .clamp(30, 100),
                                  ),
                                  blurRadius: 20 + 20 * (angle / 3.14159).abs(),
                                  spreadRadius: 2 * (angle / 3.14159).abs(),
                                  offset: Offset(
                                      0, 8 - 4 * (angle / 3.14159).abs()),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(showBack ? 3.14159 : 0),
                                  child:
                                      showBack ? _buildBack() : _buildFront(),
                                ),
                                Positioned(
                                  bottom: 12,
                                  left: 0,
                                  right: 0,
                                  child: AnimatedOpacity(
                                    opacity: 0.7,
                                    duration: const Duration(milliseconds: 200),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.touch_app,
                                          size: 16,
                                          color: Color(0xFFD0A24C),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Нажмите чтобы ${showBack ? 'вернуться' : 'узнать больше'}',
                                          style: TextStyle(
                                            color: textColor.withAlpha(190),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFront() => _buildJohnStoryFront();

  String get _johnAssetPath {
    switch (widget.lesson.blockId) {
      case 'B':
        return 'images/barista_john_practice.png';
      case 'C':
        return 'images/barista_john_exam.png';
      default:
        return 'images/barista_john_teach.png';
    }
  }

  void _openLesson() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonTeaserGate(
          title: widget.lesson.title.toUpperCase(),
          // Сцена дышит перед уроком: Джон начинает разговор, а не
          // вываливает слайды сразу.
          line: widget.lesson.historicalStory?.trim().isNotEmpty == true
              ? _firstSentence(widget.lesson.historicalStory!.trim())
              : 'За стойкой нет мелочей. Начнём с того, без чего не '
                  'работает ни один коктейль.',
          child: LessonScreen(lesson: widget.lesson),
        ),
      ),
    );
  }

  /// Первое предложение истории — его хватает на заставку.
  static String _firstSentence(String text) {
    final flat = text.replaceAll('\n', ' ').trim();
    final dot = flat.indexOf('. ');
    if (dot > 40 && dot < 160) return flat.substring(0, dot + 1);
    return flat.length <= 160 ? flat : '${flat.substring(0, 157)}…';
  }

  Widget _buildJohnStoryFront() {
    final room = _room;
    final style = JohnRoomStyle.forRoom(room);
    final textColor = _panelTextColor(style);
    final story = widget.lesson.historicalStory?.trim().isNotEmpty == true
        ? widget.lesson.historicalStory!.trim()
        : 'Первый навык бармена - не рецепт. Первый навык - понять, зачем этот урок нужен за настоящей стойкой.';

    return SizedBox.expand(
      child: JohnWoodPanel(
        room: room,
        highlighted: true,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: style.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: style.accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: style.accent.withAlpha(75),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    _johnAssetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      color: Color(0xFFD0A24C),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Бармен Джон',
                        style: TextStyle(
                          color: style.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.lesson.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    JohnParchmentPanel(
                      room: room,
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        story,
                        style: TextStyle(
                          color: style.ink,
                          fontFamily: 'serif',
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.lesson.shortDescription,
                      style: TextStyle(
                        color: textColor.withAlpha(190),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _LessonMetaChip(
                          room: room,
                          icon:
                              Icon(Icons.timer, size: 13, color: style.accent),
                          label: '${widget.lesson.estimatedMinutes} мин',
                        ),
                        if (widget.lesson.terms.isNotEmpty)
                          _LessonMetaChip(
                            room: room,
                            icon: Image.asset(
                              'images/ui_icon_book_theory.png',
                              width: 13,
                              height: 13,
                            ),
                            label: '${widget.lesson.terms.length} терминов',
                            onTap: _showGlossary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openLesson,
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Начать урок',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: style.accent,
                  foregroundColor: style.ink,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: _flip,
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text('К ключевым точкам'),
              style: TextButton.styleFrom(
                foregroundColor: style.accent,
                minimumSize: const Size.fromHeight(34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    final room = _room;
    final style = JohnRoomStyle.forRoom(room);
    final textColor = _panelTextColor(style);
    return JohnWoodPanel(
      room: room,
      highlighted: true,
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: style.accent.withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: style.accent.withAlpha(110)),
                  ),
                  child: Image.asset(
                    _lessonIconAsset,
                    width: 34,
                    height: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.lesson.title,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            JohnParchmentPanel(
              room: room,
              padding: const EdgeInsets.all(16),
              child: Text(
                _getExtendedDescription(),
                style: TextStyle(
                  color: style.ink,
                  fontFamily: 'serif',
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _flip,
              icon: const Icon(Icons.arrow_back, size: 14),
              label: const Text('К ключевым точкам'),
              style: TextButton.styleFrom(
                foregroundColor: style.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonMetaChip extends StatelessWidget {
  final JohnSchoolRoom room;
  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  const _LessonMetaChip({
    required this.room,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    final textColor = style.onDark;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.accent.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.accent.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: textColor.withAlpha(210),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlossaryTermCard extends StatelessWidget {
  final JohnSchoolRoom room;
  final String term;
  final String definition;

  const _GlossaryTermCard({
    required this.room,
    required this.term,
    required this.definition,
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: JohnParchmentPanel(
        room: room,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: style.accent.withAlpha(35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: style.accent.withAlpha(110)),
              ),
              child: Text(
                term,
                style: TextStyle(
                  color: style.ink,
                  fontFamily: 'serif',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              definition,
              style: TextStyle(
                color: style.ink,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
