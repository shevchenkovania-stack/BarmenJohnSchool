import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/quest_flow.dart';
import 'package:coin/features/bartender_school/data/guest_echo.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/screens/quiz_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/workshop_bridge.dart';
import 'package:coin/features/bartender_school/presentation/widgets/quest_investigation_view.dart';
import 'package:coin/features/bartender_school/presentation/widgets/quest_serve_view.dart';
import 'package:coin/features/bartender_school/presentation/widgets/quest_scene_view.dart';
import 'package:coin/features/bartender_school/presentation/widgets/wisdom_visuals.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

class GlossaryTerm {
  final String term;
  final String definition;
  final String example;

  GlossaryTerm({
    required this.term,
    required this.definition,
    this.example = '',
  });
}

/// Full-screen lesson viewer with PageView.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  /// С какого слайда открыть. Нужно тестам и возврату «на тот же экран».
  final int initialSlide;

  const LessonScreen({
    super.key,
    required this.lesson,
    this.initialSlide = 0,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final start = widget.initialSlide;
    final valid = start > 0 && start < widget.lesson.slides.length;
    _pageController = PageController(initialPage: valid ? start : 0);
    _currentPage = valid ? start : 0;
  }

  bool get _isWisdomLesson => widget.lesson.blockId == 'W';

  /// Итог квеста. Финал и итоговый экран — разные слайды, поэтому
  /// результат живёт здесь, а не внутри экрана подачи.
  QuestEnding? _questEnding;
  QuestServeOption? _questOption;

  /// Сколько фактов собрал игрок — для текста итога.
  int _questEvidence = 0;

  void _onQuestEnding(QuestEnding ending, QuestServeOption option) {
    setState(() {
      _questEnding = ending;
      _questOption = option;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < widget.lesson.slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last slide - go to quiz
      _goToQuiz();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToQuiz() {
    final progress = context.read<ProgressService>();

    if (widget.lesson.blockId == 'W') {
      progress.completeLesson(widget.lesson.id, xpEarned: 25);
      Navigator.pop(context);
      return;
    }
    // Всегда один квиз. Вопросы по терминам идут первым блоком того же
    // экрана (раньше это были два экрана подряд: термины и квиз).
    // Маршрут именованный: квиз снимает себя с навигатора по имени
    // (`_QuizScreenState.routeName`), не трогая экран урока.
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: QuizScreen.routeName),
        builder: (_) => QuizScreen(lessonId: widget.lesson.id),
      ),
    );
  }

  void _openGlossary() {
    final lessonTerms = widget.lesson.terms;
    if (lessonTerms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('В этом уроке нет новых терминов'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final glossaryTerms = _getGlossaryTermsForLesson(lessonTerms);
    // Шторка живёт в палитре комнаты урока: раньше она была на старом
    // фиолетово-синем `AppColors.background`/`surface` и на фоне тёплого
    // урока читалась как экран из прошлой версии приложения.
    final style = JohnRoomStyle.forRoom(
      JohnRoomStyle.roomForBlock(widget.lesson.blockId),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [style.surfaceLight, style.surface],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: style.accent.withAlpha(120), width: 1.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: style.accent.withAlpha(120),
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
                        color: style.accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: style.accent.withAlpha(110)),
                      ),
                      child: Image.asset(
                        'images/ui_icon_book_theory.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Словарик урока',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'serif',
                              color: style.onDark,
                            ),
                          ),
                          Text(
                            '${glossaryTerms.length} терминов',
                            style: TextStyle(
                              fontSize: 14,
                              color: style.onDark.withAlpha(190),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: style.onDark),
                    ),
                  ],
                ),
              ),
              Divider(color: style.accent.withAlpha(70), height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: glossaryTerms.length,
                  itemBuilder: (context, index) {
                    final term = glossaryTerms[index];
                    return _LessonTermCard(term: term, style: style);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<GlossaryTerm> _getGlossaryTermsForLesson(List<String> lessonTermNames) {
    final allGlossaryTerms = <String, GlossaryTerm>{
      'Build': GlossaryTerm(
        term: 'Build',
        definition:
            'Метод приготовления: собрать все ингредиенты прямо в бокале.',
        example:
            'Tom Collins, Highball — ингредиенты добавляются прямо в стакан со льдом.',
      ),
      'Shake': GlossaryTerm(
        term: 'Shake',
        definition: 'Встряхивание со льдом в шейкере. Охлаждает и аэрирует.',
        example: 'Daiquiri, Margarita, Cosmopolitan — все цитрусовые коктейли.',
      ),
      'Stir': GlossaryTerm(
        term: 'Stir',
        definition:
            'Размешивание в стакане для джин-тона. Охлаждает без аэрации.',
        example: 'Manhattan, Negroni, Martini — крепкие коктейли без цитруса.',
      ),
      'Dry Shake': GlossaryTerm(
        term: 'Dry Shake',
        definition:
            'Встряхивание БЕЗ льда для аэрации яичных белков или сливок.',
        example: 'Pisco Sour, Ramos Gin Fizz — сначала 20-30 сек без льда.',
      ),
      'Muddle': GlossaryTerm(
        term: 'Muddle',
        definition:
            'Раздавливание ингредиентов (мята, лайм, фрукты) в стакане.',
        example:
            'Mojito, Caipirinha — раздавить мяту и лайм перед добавлением спирта.',
      ),
      'Double Strain': GlossaryTerm(
        term: 'Double Strain',
        definition:
            'Процеживание через Hawthorne strainer + fine mesh strainer.',
        example: 'Яичные коктейли, Pina Colada — для идеальной чистоты.',
      ),
      'ABV': GlossaryTerm(
        term: 'ABV',
        definition: 'Alcohol By Volume — процент алкоголя в напитке.',
        example: 'Стандартные спирты имеют 40% ABV.',
      ),
      'Dash': GlossaryTerm(
        term: 'Dash / Dashes',
        definition:
            '2-3 капли биттеров или другого ароматического ингредиента.',
        example: '2 dashes Angostura bitters в Old Fashioned.',
      ),
      'Bitters': GlossaryTerm(
        term: 'Bitters',
        definition: 'Ароматические настойки на травах и специях. 2-3 дэша.',
        example: 'Angostura bitters, Orange bitters, Peychaud\'s.',
      ),
      'Syrup': GlossaryTerm(
        term: 'Syrup',
        definition: 'Подсластитель. Simple 1:1 или Rich 2:1.',
        example: 'Simple syrup — равные части сахара и воды.',
      ),
      'Spirit': GlossaryTerm(
        term: 'Spirit',
        definition:
            'Основной крепкий алкоголь: джин, водка, ром, виски, текила.',
        example: 'Spirit forward = коктейль где спирт доминирует.',
      ),
      'Liqueur': GlossaryTerm(
        term: 'Liqueur',
        definition: 'Ликёр — ароматизированный спирт с добавлением сахара.',
        example: 'Triple Sec, Kahlua, Baileys, Grand Marnier.',
      ),
      'Garnish': GlossaryTerm(
        term: 'Garnish',
        definition: 'Украшение коктейля. Влияет на аромат и подачу.',
        example: 'Цедра лимона, вишня, мята, оливка.',
      ),
      'Saline': GlossaryTerm(
        term: 'Saline',
        definition: '20% раствор соли в воде. 1 капля раскрывает вкус.',
        example: 'Добавить 1 каплю в коктейль для усиления вкуса.',
      ),
      'Float': GlossaryTerm(
        term: 'Float',
        definition: 'Слой ликёра или крепкого напитка поверх коктейля.',
        example: 'B-52 — три слоя: Kahlua, Baileys, Grand Marnier.',
      ),
      'Jigger': GlossaryTerm(
        term: 'Jigger',
        definition: 'Мерный стаканчик для точного измерения. Обычно 30/60 мл.',
        example: 'Наполнять до мениска, не до краёв.',
      ),
      'Shaker': GlossaryTerm(
        term: 'Shaker',
        definition: 'Шейкер для встряхивания коктейлей со льдом.',
        example: 'Boston shaker (2 части), Cobbler (3 части).',
      ),
      'Hawthorne Strainer': GlossaryTerm(
        term: 'Hawthorne Strainer',
        definition: 'Стрейнер для процеживания из шейкера.',
        example: 'Надевается на шейкер для отделения льда.',
      ),
      'Fine Mesh Strainer': GlossaryTerm(
        term: 'Fine Mesh Strainer',
        definition: 'Тонкое сито для финальной фильтрации.',
        example: 'Используется вместе с Hawthorne для двойного процеживания.',
      ),
      'Barspoon': GlossaryTerm(
        term: 'Barspoon',
        definition: 'Длинная ложка для размешивания и создания слоёв.',
        example: 'Длина 25-40 см для доставания до дна высоких бокалов.',
      ),
      'Coupe': GlossaryTerm(
        term: 'Coupe',
        definition:
            'Бокал для подачи без льда. Идеален для элегантных коктейлей.',
        example: 'Martini, Manhattan — coupe или martini glass.',
      ),
      'Highball': GlossaryTerm(
        term: 'Highball',
        definition: 'Высокий стакан для лонг-дринков с содовой.',
        example: 'Tom Collins, Gin & Tonic — 300-350 мл.',
      ),
      'Rocks': GlossaryTerm(
        term: 'Rocks',
        definition: 'Низкий стакан для коктейлей со льдом.',
        example: 'Old Fashioned, Negroni — 200-250 мл.',
      ),
      'Flute': GlossaryTerm(
        term: 'Flute',
        definition: 'Высокий тонкий бокал для игристых вин.',
        example: 'Champagne Cocktail, Aperol Spritz.',
      ),
      'Twist': GlossaryTerm(
        term: 'Twist',
        definition: 'Спираль цедры. Выкручивается над коктейлем для аромата.',
        example: 'Twist of lemon — классический garnish для Martini.',
      ),
      'Flame': GlossaryTerm(
        term: 'Flame',
        definition: 'Поджигание цедры для ароматизации дымом.',
        example: 'Cascade flame — цедра над пламенем, собирает масла.',
      ),
      'Fizz': GlossaryTerm(
        term: 'Fizz',
        definition: 'Коктейль с содовой. Лёгкий, освежающий.',
        example: 'Gin Fizz, Silver Fizz — джин + лимон + сироп + сода.',
      ),
      'Crusta': GlossaryTerm(
        term: 'Crusta',
        definition: 'Сахарная кромка на краю бокала.',
        example: 'Lemon Crusta — сахар + лимонный сок на ободке.',
      ),
      'Fat Wash': GlossaryTerm(
        term: 'Fat Wash',
        definition: 'Техника: жир впитывает аромат спирта за 2-24 часа.',
        example: 'Кокосовый ром: ром + кокосовое масло в морозилке.',
      ),
      'Infusion': GlossaryTerm(
        term: 'Infusion',
        definition: 'Настаивание спирта на травах, фруктах, специях.',
        example: 'Огуречный джин: джин + огурец на 4 часа.',
      ),
      'Batching': GlossaryTerm(
        term: 'Batching',
        definition:
            'Приготовление коктейльной смеси впрок в большом количестве.',
        example: 'Negroni batch для мероприятия на 100 гостей.',
      ),
    };

    return lessonTermNames
        .map((name) => allGlossaryTerms[name])
        .whereType<GlossaryTerm>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isWisdomLesson = _isWisdomLesson;
    final isLevelOne = const ['A', 'B', 'C'].contains(widget.lesson.blockId);
    final schoolRoom =
        isLevelOne ? JohnRoomStyle.roomForBlock(widget.lesson.blockId) : null;
    final schoolStyle =
        schoolRoom == null ? null : JohnRoomStyle.forRoom(schoolRoom);
    return Scaffold(
      backgroundColor:
          isWisdomLesson ? const Color(0xFFF5E7C4) : AppColors.background,
      appBar: AppBar(
        backgroundColor: isWisdomLesson
            ? WisdomPalette.wood
            : schoolStyle?.surface ?? Colors.transparent,
        elevation: isWisdomLesson || isLevelOne ? 8 : 0,
        shadowColor: isWisdomLesson || isLevelOne ? Colors.black : null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.lesson.title,
          style: TextStyle(
            fontSize: 16,
            color: isWisdomLesson
                ? WisdomPalette.parchmentLight
                : schoolStyle?.onDark,
            fontFamily: isWisdomLesson || isLevelOne ? 'serif' : null,
            fontWeight: isWisdomLesson || isLevelOne
                ? FontWeight.w800
                : FontWeight.normal,
          ),
        ),
        iconTheme: IconThemeData(
          color: isWisdomLesson
              ? WisdomPalette.parchmentLight
              : schoolStyle?.onDark ?? AppColors.textPrimary,
        ),
        foregroundColor: isWisdomLesson
            ? WisdomPalette.parchmentLight
            : schoolStyle?.onDark ?? AppColors.textPrimary,
        actions: [
          if (widget.lesson.terms.isNotEmpty)
            IconButton(
              onPressed: _openGlossary,
              icon: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 2, top: 1),
                    child: Image.asset(
                      'images/ui_icon_book_theory.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${widget.lesson.terms.length}',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              tooltip: 'Словарик урока',
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (isWisdomLesson)
              const Positioned.fill(child: _WisdomLessonBackdrop()),
            if (schoolRoom != null)
              Positioned.fill(
                child: JohnRoomBackground(
                  room: schoolRoom,
                  child: const SizedBox.expand(),
                ),
              ),
            Column(
              children: [
                // Progress bar
                _ProgressBar(
                  currentSlide: _currentPage + 1,
                  totalSlides: widget.lesson.slides.length,
                  isWisdomLesson: isWisdomLesson,
                  schoolRoom: schoolRoom,
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // Disable swipe, use buttons
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: widget.lesson.slides.length,
                    itemBuilder: (context, index) {
                      final slide = widget.lesson.slides[index];
                      return _SlideWidget(
                        slide: slide,
                        lessonId: widget.lesson.id,
                        quest: widget.lesson.quest,
                        onQuestEnding: _onQuestEnding,
                        questEnding: _questEnding,
                        questOption: _questOption,
                        questEvidence: _questEvidence,
                        onQuestEvidence: (n) => setState(() => _questEvidence = n),
                        lessonMentor: widget.lesson.mentor,
                        isFirstSlide: index == 0,
                        isWisdomLesson: isWisdomLesson,
                        schoolRoom: schoolRoom,
                        // Сцена-квест листает сама, после своего финала.
                        onGoNext: index < widget.lesson.slides.length - 1
                            ? _nextPage
                            : null,
                      );
                    },
                  ),
                ),

                // Navigation buttons
                _NavigationButtons(
                  currentIndex: _currentPage,
                  totalPages: widget.lesson.slides.length,
                  onNext: _nextPage,
                  onPrevious: _previousPage,
                  isLastPage: _currentPage == widget.lesson.slides.length - 1,
                  isWisdomLesson: isWisdomLesson,
                  schoolRoom: schoolRoom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WisdomLessonBackdrop extends StatelessWidget {
  const _WisdomLessonBackdrop();

  @override
  Widget build(BuildContext context) {
    return const WisdomMapBackground(child: SizedBox.expand());
  }
}

/// Progress bar at the top.
class _ProgressBar extends StatelessWidget {
  final int currentSlide;
  final int totalSlides;
  final bool isWisdomLesson;
  final JohnSchoolRoom? schoolRoom;

  const _ProgressBar({
    required this.currentSlide,
    required this.totalSlides,
    required this.isWisdomLesson,
    this.schoolRoom,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentSlide / totalSlides;
    final schoolStyle =
        schoolRoom == null ? null : JohnRoomStyle.forRoom(schoolRoom!);
    final bgColor = isWisdomLesson
        ? WisdomPalette.wood
        : schoolStyle?.surface ?? AppColors.background;
    final titleColor = isWisdomLesson
        ? WisdomPalette.parchmentLight
        : schoolStyle?.onDark ?? AppColors.textSecondary;
    final accent = isWisdomLesson
        ? WisdomPalette.antiqueGold
        : schoolStyle?.accent ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isWisdomLesson || schoolRoom != null
          ? BoxDecoration(
              color: bgColor.withAlpha(230),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(
                bottom: BorderSide(color: accent.withAlpha(45)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // На системном масштабе 2.0 строка «Слайд N из M» перестаёт
              // помещаться рядом с процентами — даём ей сжиматься.
              Expanded(
                child: Text(
                  isWisdomLesson
                      ? 'СТРАНИЦА $currentSlide ИЗ $totalSlides'
                      : 'Слайд $currentSlide из $totalSlides',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: isWisdomLesson || schoolRoom != null
                        ? FontWeight.w900
                        : FontWeight.normal,
                    letterSpacing:
                        isWisdomLesson || schoolRoom != null ? 1 : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isWisdomLesson
                  ? WisdomPalette.darkInk
                  : schoolStyle?.ink ?? AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: isWisdomLesson || schoolRoom != null ? 7 : 6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual slide widget.
class _SlideWidget extends StatelessWidget {
  final LessonSlide slide;
  final LessonMentor? lessonMentor;
  final bool isFirstSlide;
  final bool isWisdomLesson;
  final JohnSchoolRoom? schoolRoom;

  /// Урок, которому принадлежит слайд. Нужен мостику в Мастерскую:
  /// задания фильтруются по `lessonId`.
  final String lessonId;

  /// Квест урока. `null` — обычный урок; слайды рисуются как раньше.
  final QuestFlow? quest;

  /// Итог квеста: нужен финалу и итоговому экрану, которые рисуются
  /// разными слайдами.
  final void Function(QuestEnding ending, QuestServeOption option)?
      onQuestEnding;

  /// Уже выбранный финал. `null` — квест ещё не пройден.
  final QuestEnding? questEnding;
  final QuestServeOption? questOption;

  /// Сколько фактов собрано и где об этом сказать.
  final int questEvidence;
  final void Function(int count)? onQuestEvidence;

  /// Перелистнуть на следующий слайд. `null` на последнем слайде: листать
  /// некуда, и сцена не показывает лишнюю кнопку.
  final VoidCallback? onGoNext;

  const _SlideWidget({
    required this.slide,
    required this.lessonId,
    this.quest,
    this.onQuestEnding,
    this.questEnding,
    this.questOption,
    this.questEvidence = 0,
    this.onQuestEvidence,
    this.lessonMentor,
    this.isFirstSlide = false,
    this.isWisdomLesson = false,
    this.schoolRoom,
    this.onGoNext,
  });

  String? get _mentorText {
    if (slide.mentorNote != null && slide.mentorNote!.trim().isNotEmpty) {
      return slide.mentorNote;
    }

    final mentor = lessonMentor;
    if (isFirstSlide && mentor != null && mentor.intro.trim().isNotEmpty) {
      return mentor.intro;
    }

    return null;
  }

  String get _mentorAssetPath {
    switch (slide.type) {
      case SlideType.practice:
      case SlideType.toolVisual:
      case SlideType.balanceTrainer:
      case SlideType.interactive:
        return 'images/barista_john_practice.png';
      case SlideType.investigation:
        return 'images/barista_john_practice.png';
      case SlideType.checklist:
      case SlideType.story:
      case SlideType.result:
        return 'images/barista_john_exam.png';
      case SlideType.theory:
      case SlideType.termAnimation:
      case SlideType.barTip:
      case SlideType.failure:
      case SlideType.quote:
      case SlideType.observation:
      case SlideType.silence:
      case SlideType.choice:
        return 'images/barista_john_teach.png';
    }
  }

  /// Финал квеста: что сказал гость и что заметил Джон.
  ///
  /// Гость не хвалит. Он может допить и промолчать — это часть истории.
  Widget _buildQuestStory(QuestFlow flow, JohnSchoolRoom room) {
    final style = JohnRoomStyle.forRoom(room);
    final rule = _questRule(flow);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: JohnWoodPanel(
        room: room,
        highlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (slide.content.trim().isNotEmpty) ...[
              Text(
                slide.content,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: style.onDark.withAlpha(195),
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (rule == null)
              Text(
                'Сцена ещё не разыграна.',
                style: TextStyle(color: style.onDark.withAlpha(150)),
              )
            else ...[
              Container(
                key: const Key('quest_story_reaction'),
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: style.surfaceLight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                  border: Border.all(color: style.accent.withAlpha(95)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ГОСТЬ',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w800,
                        color: style.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rule.guestText,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.6,
                        color: style.onDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                rule.johnText,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.6,
                  fontFamily: 'serif',
                  color: style.onDark.withAlpha(210),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Итог: метка финала, факты, XP из спеке.
  Widget _buildQuestResult(QuestFlow flow, JohnSchoolRoom room) {
    final style = JohnRoomStyle.forRoom(room);
    final ending = questEnding;
    final reward = ending == null ? null : flow.rewardFor(ending);
    final label = _questRule(flow)?.resultLabel ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: JohnWoodPanel(
        room: room,
        highlighted: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              slide.content,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: style.onDark.withAlpha(200),
              ),
            ),
            const SizedBox(height: 20),
            if (ending != null) ...[
              Container(
                key: const Key('quest_result_label'),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: style.accent.withAlpha(26),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: style.accent.withAlpha(95)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: style.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ResultRow(
                      icon: Icons.fact_check_outlined,
                      text: 'Собрано фактов: $questEvidence из '
                          '${flow.investigation.items.length}',
                      style: style,
                    ),
                    if (reward != null)
                      _ResultRow(
                        icon: Icons.star_border,
                        text: 'Опыт: +${reward.xp} XP',
                        style: style,
                      ),
                    if (reward != null && reward.journalEntry.isNotEmpty)
                      _ResultRow(
                        icon: Icons.menu_book_outlined,
                        text: reward.journalEntry,
                        style: style,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Урок засчитан. Следующий откроется сразу — плохой финал '
                'не закрывает курс.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: style.onDark.withAlpha(160),
                ),
              ),
            ] else
              Text(
                'Итог появится после сцены.',
                style: TextStyle(color: style.onDark.withAlpha(150)),
              ),
          ],
        ),
      ),
    );
  }

  /// Правило, которое сработало — для текстов гостя и Джона.
  QuestEndingRule? _questRule(QuestFlow flow) {
    final ending = questEnding;
    if (ending == null) return null;
    for (final rule in flow.rules) {
      if (rule.ending == ending) return rule;
    }
    return null;
  }

  Widget _withMentor(Widget child) {
    final mentorText = _mentorText;
    if (mentorText == null) return child;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: _MentorNoteCard(
            text: mentorText,
            assetPath: _mentorAssetPath,
            schoolRoom: schoolRoom,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isWisdomLesson) {
      return _buildWisdomSlide(context);
    }

    // Сцена-квест рисуется своим виджетом: у неё своё состояние
    // (вопросы, выбор, реакция гостя), которого нет у обычной теории.
    // Уроки без сцены идут тем же путём, что и раньше.
    // Квест урока: расследование, подача, финал по правилам.
    // Слайды без questRef рисуются как обычно, поэтому теория внутри
    // квеста попадает в тот же путь, что и раньше.
    final flow = quest;
    if (flow != null && flow.isValid) {
      final ref = slide.questRef ?? '';
      final room = schoolRoom ?? JohnSchoolRoom.flavorLab;
      if (slide.type == SlideType.investigation) {
        return _withMentor(
          QuestInvestigationView(
            investigation: flow.investigation,
            room: room,
            onProgress: onQuestEvidence,
            onContinue: onGoNext,
          ),
        );
      }
      if (ref.endsWith('.serve')) {
        return _withMentor(
          QuestServeView(
            flow: flow,
            room: room,
            onFinished: onQuestEnding,
            onContinue: onGoNext,
          ),
        );
      }
      if (slide.type == SlideType.story) {
        return _withMentor(_buildQuestStory(flow, room));
      }
      if (slide.type == SlideType.result) {
        return _withMentor(_buildQuestResult(flow, room));
      }
    }

    if (slide.questScene != null && slide.questScene!.isValid) {
      return QuestSceneView(
        scene: slide.questScene!,
        room: schoolRoom ?? JohnSchoolRoom.flavorLab,
        onFinished: (option) {
          final echo = context.read<GuestEchoService>();
          echo.remember(
            sceneTitle: slide.questScene!.title,
            choiceText: option.text,
            wasRight: option.isRight,
          );
        },
        onContinue: onGoNext,
      );
    }

    if (slide.type == SlideType.practice) {
      return _withMentor(
        WorkshopBridge(lessonId: lessonId, schoolRoom: schoolRoom),
      );
    }

    if (slide.type == SlideType.barTip) {
      return _withMentor(_buildBarTipSlide());
    }

    if (slide.type == SlideType.balanceTrainer) {
      return _withMentor(
        _BalanceTrainerSlide(slide: slide, schoolRoom: schoolRoom),
      );
    }

    if (slide.type == SlideType.toolVisual) {
      return _withMentor(
        _ToolVisualSlide(slide: slide, schoolRoom: schoolRoom),
      );
    }

    if (slide.type == SlideType.interactive) {
      if (slide.title.contains('Кислот')) {
        return _withMentor(
          _AcidCalibrationSlide(slide: slide, schoolRoom: schoolRoom),
        );
      } else if (slide.title.contains('сладость') ||
          slide.title.contains('Сладость')) {
        return _withMentor(
          _SweetnessCalibrationSlide(slide: slide, schoolRoom: schoolRoom),
        );
      } else if (slide.title.contains('горечь') ||
          slide.title.contains('Горечь') ||
          slide.title.contains('биттер')) {
        return _withMentor(
          _BitterCalibrationSlide(slide: slide, schoolRoom: schoolRoom),
        );
      } else if (slide.title.contains('станцию') ||
          slide.title.contains('Собери')) {
        return _withMentor(
          _StationBuilderSlide(slide: slide, schoolRoom: schoolRoom),
        );
      } else if (slide.title.contains('джиггер') ||
          slide.title.contains('налей') ||
          (slide.title.contains('Практика') &&
              slide.content.contains('джиггер'))) {
        return _withMentor(
          _JiggerMeasurementSlide(slide: slide, schoolRoom: schoolRoom),
        );
      } else if (slide.title.contains('шейк') ||
          slide.title.contains('тайминг') ||
          slide.title.contains('встрях')) {
        return _withMentor(
          _ShakeTimingSlide(slide: slide, schoolRoom: schoolRoom),
        );
      } else if (slide.title.contains('dilution') ||
          slide.title.contains('Дильюш')) {
        return _withMentor(
          _DilutionCalculatorSlide(slide: slide, schoolRoom: schoolRoom),
        );
      } else if (slide.title.contains('Практика') &&
          slide.content.contains('Шаг')) {
        return _withMentor(
          _CocktailBuilderSlide(slide: slide, schoolRoom: schoolRoom),
        );
      }
      // Фоллбэк тоже получает room: без него тренажёр рисовался прямо
      // на фоне комнаты и слайд читался как «прозрачный».
      return _withMentor(
        _AcidCalibrationSlide(slide: slide, schoolRoom: schoolRoom),
      );
    }

    final schoolStyle =
        schoolRoom == null ? null : JohnRoomStyle.forRoom(schoolRoom!);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          slide.title,
          style: TextStyle(
            color: schoolStyle?.onDark ?? AppColors.textPrimary,
            fontFamily: schoolRoom == null ? null : 'serif',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 20),

        if (_mentorText != null) ...[
          _MentorNoteCard(
            text: _mentorText!,
            assetPath: _mentorAssetPath,
            schoolRoom: schoolRoom,
          ),
          const SizedBox(height: 20),
        ],

        // Content
        if (slide.type == SlideType.quote) ...[
          // «Золотое правило»: цитата выглядит как цитата, а не как теория.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: (schoolStyle?.accent ?? AppColors.primary).withAlpha(24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (schoolStyle?.accent ?? AppColors.primary).withAlpha(90),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '“',
                  style: TextStyle(
                    color: schoolStyle?.accent ?? AppColors.primary,
                    fontFamily: 'serif',
                    fontSize: 46,
                    height: 0.7,
                  ),
                ),
                Text(
                  slide.content,
                  style: TextStyle(
                    color: schoolStyle?.onDark ?? AppColors.textPrimary,
                    fontFamily: 'serif',
                    fontSize: 19,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                if (slide.author != null && slide.author!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '— ${slide.author}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: schoolStyle?.onDark.withAlpha(190) ??
                          AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else
          Text(
            slide.content,
            style: TextStyle(
              color:
                  schoolStyle?.onDark.withAlpha(205) ?? AppColors.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),

        // Bullet points
        if (slide.bulletPoints != null && slide.bulletPoints!.isNotEmpty)
          const SizedBox(height: 24),

        if (slide.bulletPoints != null && slide.bulletPoints!.isNotEmpty)
          ...slide.bulletPoints!.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: schoolStyle?.accent ?? AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          color: schoolStyle?.onDark ?? AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: schoolRoom == null
          ? content
          : JohnWoodPanel(
              room: schoolRoom!,
              highlighted: true,
              child: content,
            ),
    );
  }

  Widget _buildWisdomSlide(BuildContext context) {
    final iconAsset = switch (slide.type) {
      SlideType.theory => 'images/ui_icon_book_theory.png',
      SlideType.barTip => 'images/ui_icon_tip_citrus.png',
      SlideType.practice => 'images/ui_icon_practice_motion.png',
      SlideType.checklist => 'images/ui_icon_checklist.png',
      SlideType.toolVisual => 'images/ui_icon_tool_station.png',
      SlideType.termAnimation => 'images/ui_icon_term_medal.png',
      SlideType.balanceTrainer => 'images/ui_icon_balance_precision.png',
      SlideType.interactive => 'images/ui_icon_play_card.png',
      SlideType.failure => 'images/ui_icon_book_theory.png',
      SlideType.quote => 'images/ui_icon_term_medal.png',
      SlideType.observation => 'images/ui_icon_balance_precision.png',
      SlideType.choice => 'images/ui_icon_play_card.png',
      SlideType.investigation => 'images/ui_icon_play_card.png',
      SlideType.story => 'images/ui_icon_book_theory.png',
      SlideType.result => 'images/ui_icon_term_medal.png',
      SlideType.silence => 'images/ui_icon_tip_citrus.png',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _WisdomPaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: WisdomPalette.oldGold.withAlpha(28),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: WisdomPalette.oldGold.withAlpha(110),
                        ),
                      ),
                      child: Image.asset(iconAsset),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ИЗ ЗАПИСНОЙ КНИЖКИ ДЖОНА',
                            style: TextStyle(
                              color: WisdomPalette.oldGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.15,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            slide.title,
                            style: const TextStyle(
                              color: WisdomPalette.darkInk,
                              fontFamily: 'serif',
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                ),
                const SizedBox(height: 16),
                const WisdomOrnamentDivider(),
                const SizedBox(height: 18),
                if (_mentorText != null) ...[
                  _WisdomMentorNoteCard(
                    text: _mentorText!,
                    assetPath: _mentorAssetPath,
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  slide.content,
                  style: TextStyle(
                    color: WisdomPalette.ink,
                    fontFamily: 'serif',
                    fontSize: slide.type == SlideType.quote ? 20 : 17,
                    fontStyle: slide.type == SlideType.quote
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.72,
                  ),
                ),
                if (slide.author != null && slide.author!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '— ${slide.author}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: WisdomPalette.oldGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (slide.bulletPoints != null &&
                    slide.bulletPoints!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ...slide.bulletPoints!.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: WisdomPalette.oldGold.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: WisdomPalette.wax,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '◆',
                              style: TextStyle(
                                color: WisdomPalette.wax,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                point,
                                style: const TextStyle(
                                  color: WisdomPalette.ink,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // Сцена выбора: без этого блока варианты терялись и
                // слайд читался как обычная теория с вопросом в конце.
                if (slide.choices != null && slide.choices!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _WisdomChoiceList(choices: slide.choices!),
                ],
              ],
            ),
          ),
          const Positioned(
            right: 14,
            top: -10,
            child: WisdomWaxSeal(size: 54),
          ),
        ],
      ),
    );
  }

  Widget _buildBarTipSlide() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar Tip header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(40),
                  AppColors.primary.withAlpha(20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withAlpha(100),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'images/ui_icon_tip_citrus.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'БАРНЫЙ ЛАЙФХАК',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slide.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              slide.content,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          // Bullet points
          if (slide.bulletPoints != null && slide.bulletPoints!.isNotEmpty)
            const SizedBox(height: 20),

          if (slide.bulletPoints != null && slide.bulletPoints!.isNotEmpty)
            ...slide.bulletPoints!.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}

class _LessonTermCard extends StatelessWidget {
  final GlossaryTerm term;
  final JohnRoomStyle style;

  const _LessonTermCard({required this.term, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.accent.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: style.accent.withAlpha(34),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: style.accent.withAlpha(110)),
                ),
                child: Text(
                  term.term,
                  style: TextStyle(
                    color: style.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            term.definition,
            style: TextStyle(
              color: style.onDark,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (term.example.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: style.accent.withAlpha(50)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'images/ui_icon_tip_citrus.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      term.example,
                      style: TextStyle(
                        color: style.onDark.withAlpha(190),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MentorNoteCard extends StatelessWidget {
  final String text;
  final String assetPath;
  final JohnSchoolRoom? schoolRoom;

  const _MentorNoteCard({
    required this.text,
    this.assetPath = 'images/barista_john_teach.png',
    this.schoolRoom,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        schoolRoom == null ? null : JohnRoomStyle.forRoom(schoolRoom!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style?.surfaceLight ?? AppColors.primary.withAlpha(24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              style?.accent.withAlpha(145) ?? AppColors.primary.withAlpha(90),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: style?.accent ?? AppColors.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
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
                    color: style?.accent ?? AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: style?.onDark ?? AppColors.textPrimary,
                    fontFamily: schoolRoom == null ? null : 'serif',
                    fontSize: 15,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WisdomPaperCard extends StatelessWidget {
  final Widget child;

  const _WisdomPaperCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return WisdomParchmentPanel(
      highlighted: true,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      child: child,
    );
  }
}

class _WisdomMentorNoteCard extends StatelessWidget {
  final String text;
  final String assetPath;

  const _WisdomMentorNoteCard({
    required this.text,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 13),
          padding: const EdgeInsets.fromLTRB(82, 15, 14, 15),
          decoration: BoxDecoration(
            color: WisdomPalette.wood.withAlpha(225),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: WisdomPalette.antiqueGold, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(75),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ДЖОН ГОВОРИТ',
                style: TextStyle(
                  color: WisdomPalette.antiqueGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                style: const TextStyle(
                  color: WisdomPalette.parchmentLight,
                  fontFamily: 'serif',
                  fontSize: 15,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 10,
          top: 0,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WisdomPalette.parchmentLight,
              border: Border.all(color: WisdomPalette.antiqueGold, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
        const Positioned(
          left: 56,
          bottom: -9,
          child: WisdomWaxSeal(size: 34),
        ),
      ],
    );
  }
}

/// Список вариантов одного сценарного слайда Мудрости.
///
/// Держит единственный выбор на слайд. Раньше каждая карточка
/// раскрывалась отдельно, и верный ответ можно было просто прочитать.
class _WisdomChoiceList extends StatefulWidget {
  final List<SlideChoice> choices;

  const _WisdomChoiceList({required this.choices});

  @override
  State<_WisdomChoiceList> createState() => _WisdomChoiceListState();
}

class _WisdomChoiceListState extends State<_WisdomChoiceList> {
  /// Индекс выбранного варианта. `null` — выбора ещё нет.
  int? _picked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.choices.length; i++)
          _WisdomChoiceCard(
            key: Key('wisdom_choice_${i + 1}'),
            index: i + 1,
            choice: widget.choices[i],
            isResolved: _picked != null,
            isPicked: _picked == i,
            onPick: () => setState(() => _picked = i),
          ),
      ],
    );
  }
}

/// Карточка одного хода в сценарном слайде Мудрости (`SlideType.choice`).
///
/// Раньше это был аккордеон: можно было раскрыть все варианты и прочитать,
/// какой верный. Выбора не было — было чтение ответов. Теперь выбор
/// настоящий: нажал на один — остальные только показывают точку ответа.
///
/// В прогресс по-прежнему не идёт: это размышление, а не экзамен.
class _WisdomChoiceCard extends StatelessWidget {
  final int index;
  final SlideChoice choice;

  /// `true`, когда ученик уже сделал выбор на этом слайде.
  final bool isResolved;

  /// `true`, если выбран именно этот вариант.
  final bool isPicked;

  final VoidCallback onPick;

  const _WisdomChoiceCard({
    super.key,
    required this.index,
    required this.choice,
    required this.isResolved,
    required this.isPicked,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    // До выбора карточка нейтральна: разбор скрыт, чтобы не подсказывать.
    // После выбора выбранная раскрывается, остальные тускнеют — видно,
    // что решать уже поздно, а не «попробуй ещё».
    final dim = isResolved && !isPicked;
    final open = isPicked && choice.explanation.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isResolved ? null : onPick,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPicked
                ? WisdomPalette.oldGold.withAlpha(26)
                : Colors.white.withAlpha(dim ? 45 : 90),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: WisdomPalette.oldGold
                  .withAlpha(isPicked ? 130 : (dim ? 35 : 80)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WisdomPalette.oldGold
                          .withAlpha(isPicked ? 120 : (dim ? 25 : 60)),
                    ),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: dim
                            ? WisdomPalette.ink.withAlpha(110)
                            : WisdomPalette.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      choice.text,
                      style: TextStyle(
                        color: dim
                            ? WisdomPalette.ink.withAlpha(115)
                            : WisdomPalette.ink,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isResolved
                        ? (isPicked
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked)
                        : Icons.touch_app_outlined,
                    size: 18,
                    color: WisdomPalette.oldGold
                        .withAlpha(isPicked ? 220 : (dim ? 70 : 160)),
                  ),
                ],
              ),
              if (open) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      choice.isCorrect
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      size: 16,
                      color: choice.isCorrect
                          ? const Color(0xFF2F6B3A)
                          : WisdomPalette.wax,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        choice.explanation,
                        style: const TextStyle(
                          color: WisdomPalette.ink,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Slide type icon.
class _SlideTypeIcon extends StatelessWidget {
  final SlideType type;

  const _SlideTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    String assetPath;
    switch (type) {
      case SlideType.theory:
        assetPath = 'images/ui_icon_book_theory.png';
        break;
      case SlideType.toolVisual:
        assetPath = 'images/ui_icon_tool_station.png';
        break;
      case SlideType.termAnimation:
        assetPath = 'images/ui_icon_term_medal.png';
        break;
      case SlideType.practice:
        assetPath = 'images/ui_icon_practice_motion.png';
        break;
      case SlideType.barTip:
        assetPath = 'images/ui_icon_tip_citrus.png';
        break;
      case SlideType.balanceTrainer:
        assetPath = 'images/ui_icon_balance_precision.png';
        break;
      case SlideType.checklist:
        assetPath = 'images/ui_icon_checklist.png';
        break;
      case SlideType.interactive:
        assetPath = 'images/ui_icon_play_card.png';
        break;
      case SlideType.investigation:
        assetPath = 'images/ui_icon_play_card.png';
        break;
      case SlideType.story:
        assetPath = 'images/ui_icon_book_theory.png';
        break;
      case SlideType.result:
        assetPath = 'images/ui_icon_term_medal.png';
        break;
      case SlideType.failure:
        assetPath = 'images/ui_icon_book_theory.png';
        break;
      case SlideType.quote:
        assetPath = 'images/ui_icon_term_medal.png';
        break;
      case SlideType.observation:
        assetPath = 'images/ui_icon_balance_precision.png';
        break;
      case SlideType.choice:
        assetPath = 'images/ui_icon_play_card.png';
        break;
      case SlideType.silence:
        assetPath = 'images/ui_icon_tip_citrus.png';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset(
        assetPath,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Navigation buttons at the bottom.
class _NavigationButtons extends StatelessWidget {
  final int currentIndex;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool isLastPage;
  final bool isWisdomLesson;
  final JohnSchoolRoom? schoolRoom;

  const _NavigationButtons({
    required this.currentIndex,
    required this.totalPages,
    required this.onNext,
    required this.onPrevious,
    required this.isLastPage,
    required this.isWisdomLesson,
    this.schoolRoom,
  });

  @override
  Widget build(BuildContext context) {
    final wisdomButtonColor = WisdomPalette.wax;
    final wisdomPanelColor = WisdomPalette.wood;
    final schoolStyle =
        schoolRoom == null ? null : JohnRoomStyle.forRoom(schoolRoom!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWisdomLesson
            ? wisdomPanelColor.withAlpha(245)
            : schoolStyle?.surface ?? AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isWisdomLesson
                ? wisdomButtonColor.withAlpha(28)
                : schoolStyle?.accent.withAlpha(90) ?? AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          if (currentIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Назад'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isWisdomLesson
                      ? WisdomPalette.parchmentLight
                      : schoolStyle?.onDark ?? AppColors.textSecondary,
                  side: BorderSide(
                    color: isWisdomLesson
                        ? WisdomPalette.antiqueGold
                        : schoolStyle?.accent ?? AppColors.divider,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (currentIndex > 0) const SizedBox(width: 12),

          // Next/Finish button
          Expanded(
            flex: currentIndex == 0 ? 2 : 1,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(isLastPage ? Icons.emoji_events : Icons.arrow_forward),
              label: Text(isLastPage
                  ? (isWisdomLesson ? 'Забрать мудрость' : 'К тесту')
                  : 'Далее'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor:
                    isWisdomLesson ? wisdomButtonColor : schoolStyle?.accent,
                foregroundColor: isWisdomLesson
                    ? WisdomPalette.parchmentLight
                    : schoolStyle?.ink,
                side: isWisdomLesson
                    ? const BorderSide(color: WisdomPalette.antiqueGold)
                    : schoolStyle == null
                        ? null
                        : BorderSide(color: schoolStyle.onDark.withAlpha(120)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolVisualSlide extends StatelessWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  JohnRoomStyle? get schoolStyle =>
      schoolRoom == null ? null : JohnRoomStyle.forRoom(schoolRoom!);

  const _ToolVisualSlide({required this.slide, this.schoolRoom});

  Map<String, String> _getToolParts() {
    final title = slide.title.toLowerCase();
    if (title.contains('джиггер') || title.contains('jigger')) {
      return {
        'Большая сторона': '45-60 мл (1.5-2 oz)',
        'Малая сторона': '30 мл (1 oz)',
        'Как выглядит': 'Двусторонний стаканчик в форме песочных часов',
      };
    }
    if (title.contains('шейкер') || title.contains('shaker')) {
      if (title.contains('cobbler')) {
        return {
          'Чаша': 'Нижняя металлическая часть',
          'Ситечко': 'Средняя часть с фильтром',
          'Крышка': 'Верхняя часть с носиком',
        };
      }
      return {
        'Tin A': 'Металлическая чаша (большая)',
        'Tin B': 'Стеклянный стакан (используется как крышка)',
      };
    }
    if (title.contains('сок') || title.contains('пресс')) {
      return {
        'Mexican elbow': 'Ручной пресс для цитрусовых',
        'Электрический': 'Для большого объёма',
      };
    }
    return {};
  }

  /// Арт по смыслу инструмента. Картинка заменяет эмодзи из данных
  /// урока: эмодзи-лимон рядом с гравюрами читался как заплатка, а
  /// иллюстрация держит стиль комнаты.
  String? get _artAsset {
    final title = slide.title.toLowerCase();
    if (title.contains('сок') ||
        title.contains('пресс') ||
        title.contains('цитрус') ||
        title.contains('лимон') ||
        title.contains('лайм')) {
      return 'images/lesson_a_02_acid.jpg';
    }
    if (title.contains('джиггер') || title.contains('jigger')) {
      return 'images/lesson_b_06_precision.jpg';
    }
    if (title.contains('шейкер') || title.contains('shaker')) {
      return 'images/lesson_b_07_shake.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final parts = _getToolParts();
    final style = schoolStyle;
    final artAsset = _artAsset;

    // Панель обязательна: без неё сквозь текст просвечивает картинка
    // комнаты, и слайд читается как «прозрачный».
    final body = Column(
      children: [
        // Заголовок инструмента. Раньше здесь был эмодзи 80 px — на этом
        // слайде это был огромный мультяшный лимон, не совпадающий
        // с гравюрным стилем урока, поэтому вместо него арт инструмента
        // (или значок станции, если арта нет).
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (style?.accent ?? AppColors.primary).withAlpha(52),
                (style?.accent ?? AppColors.primary).withAlpha(18),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (style?.accent ?? AppColors.primary).withAlpha(95),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              if (artAsset == null)
                Image.asset(
                  'images/ui_icon_tool_station.png',
                  width: 56,
                  height: 56,
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    artAsset,
                    width: 132,
                    height: 132,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                slide.title,
                style: TextStyle(
                  color: style?.onDark ?? const Color(0xFFFCEAB9),
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Tool parts if available
        if (parts.isNotEmpty) ...[
          Text(
            'Из чего состоит:',
            style: TextStyle(
              color: style?.accent ?? AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...parts.entries.map((entry) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                // Тёплая «кожаная» плашка вместо фиолетово-синей `surface`:
                // на дереве синий читался как деталь из другой темы.
                decoration: BoxDecoration(
                  color: (style?.accent ?? AppColors.primary).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (style?.accent ?? AppColors.primary).withAlpha(70),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: style?.accent ?? AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${entry.key}: ',
                              style: TextStyle(
                                color: style?.onDark ?? const Color(0xFFFCEAB9),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: entry.value,
                              style: TextStyle(
                                color:
                                    (style?.onDark ?? const Color(0xFFFCEAB9))
                                        .withAlpha(200),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
        ],

        // Описание инструмента. Короткий вводный абзац идёт отдельной
        // «строчкой подписи» прямо под иллюстрацией: тело слайда не
        // дублируется, а незнакомый инструмент показан картинкой, а не
        // эмодзи, который выбивался из гравюрного стиля комнаты.
        Text(
          slide.content,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                (schoolStyle?.onDark ?? AppColors.textPrimary).withAlpha(180),
            fontFamily: 'serif',
            fontSize: 13.5,
            fontStyle: FontStyle.italic,
            height: 1.45,
          ),
        ),

        // Bullet points
        if (slide.bulletPoints != null && slide.bulletPoints!.isNotEmpty) ...[
          const SizedBox(height: 24),
          ...slide.bulletPoints!.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: style?.accent ?? AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: TextStyle(
                          color: style?.onDark ?? AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: schoolRoom == null
          ? body
          : JohnWoodPanel(
              room: schoolRoom!,
              highlighted: true,
              child: body,
            ),
    );
  }
}

class _BalanceTrainerSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _BalanceTrainerSlide({required this.slide, this.schoolRoom});

  @override
  State<_BalanceTrainerSlide> createState() => _BalanceTrainerSlideState();
}

class CocktailTemplate {
  final String name;
  final String emoji;
  final String description;
  final String style;
  final List<String> ingredients;
  final double sweetness;
  final double acid;
  final double bitter;
  final double salt;
  final double umami;

  const CocktailTemplate({
    required this.name,
    required this.emoji,
    required this.description,
    required this.style,
    required this.ingredients,
    required this.sweetness,
    required this.acid,
    required this.bitter,
    required this.salt,
    required this.umami,
  });
}

class _BalanceTrainerSlideState extends State<_BalanceTrainerSlide> {
  // Палитра комнаты урока: тренажёры раньше были на старой фиолетово-синей
  // теме `AppColors` и на дереве читались как экран из другой версии.
  JohnRoomStyle get _roomStyle =>
      JohnRoomStyle.forRoom(widget.schoolRoom ?? JohnSchoolRoom.flavorLab);
  Color get _ink => _roomStyle.onDark;
  Color get _inkMuted => _roomStyle.onDark.withAlpha(190);
  Color get _accent => _roomStyle.accent;
  static const List<CocktailTemplate> _cocktails = [
    CocktailTemplate(
      name: 'Daiquiri',
      emoji: '🥃',
      description:
          'Классический кубинский коктейль. Чистый, освежающий Sour с лёгким тропическим характером.',
      style: 'Кисло-сладкий, лёгкий, цитрусовый',
      ingredients: [
        'Белый ром 50мл',
        'Лаймовый сок 25мл',
        'Сахарный сироп 20мл'
      ],
      sweetness: 50,
      acid: 55,
      bitter: 10,
      salt: 15,
      umami: 10,
    ),
    CocktailTemplate(
      name: 'Margarita',
      emoji: '🍹',
      description:
          'Мексиканская классика. Яркая, солоноватая, с текилой и лаймом.',
      style: 'Кислый, солёный, бодрящий',
      ingredients: [
        'Текила 50мл',
        'Трипл Сек 25мл',
        'Лаймовый сок 25мл',
        'Соль на ободке'
      ],
      sweetness: 40,
      acid: 60,
      bitter: 15,
      salt: 35,
      umami: 10,
    ),
    CocktailTemplate(
      name: 'Old Fashioned',
      emoji: '🥃',
      description:
          'Американская классика. Глубокий, богатый, с характером виски.',
      style: 'Горький, дымный, комплексный',
      ingredients: [
        'Бурбон 60мл',
        'Ангостура биттер',
        'Сахар 1 кубик',
        'Апельсиновая цедра'
      ],
      sweetness: 30,
      acid: 10,
      bitter: 50,
      salt: 20,
      umami: 30,
    ),
  ];

  int _selectedCocktailIndex = 0;
  double _sweetness = 0;
  double _acid = 0;
  double _bitter = 0;
  double _salt = 0;
  double _umami = 0;
  bool _showRecipe = false;

  void _resetSliders() {
    setState(() {
      _sweetness = 0;
      _acid = 0;
      _bitter = 0;
      _salt = 0;
      _umami = 0;
      _showRecipe = false;
    });
  }

  void _selectCocktail(int index) {
    setState(() {
      _selectedCocktailIndex = index;
      _resetSliders();
    });
  }

  void _toggleRecipe() {
    setState(() {
      _showRecipe = !_showRecipe;
    });
  }

  String _getHint(double current, double target) {
    final diff = current - target;
    if (diff.abs() <= 5) return '✓';
    if (diff > 20) return '⬆️⬆️';
    if (diff > 10) return '⬆️';
    if (diff < -20) return '⬇️⬇️';
    if (diff < -10) return '⬇️';
    return '≈';
  }

  Color _getHintColor(double current, double target) {
    final diff = (current - target).abs();
    if (diff <= 5) return Colors.green;
    if (diff <= 15) return Colors.orange;
    return Colors.red;
  }

  String _getTasteDescription() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    final score = _getMatchScore();

    if (score >= 95) {
      return '🎉 Идеально! ${cocktail.name} собран!';
    }
    if (score >= 80) {
      return '✨ Почти完美! Попробуй ещё немного подстроить.';
    }
    if (score >= 60) {
      return '💪 Хороший коктейль! Ещё чуть-чуть до идеала.';
    }
    return '🔧 Настраивай вкус, подсказки помогут!';
  }

  int _getMatchScore() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    int score = 100;

    score -= ((_sweetness - cocktail.sweetness).abs() * 0.5).toInt();
    score -= ((_acid - cocktail.acid).abs() * 0.5).toInt();
    score -= ((_bitter - cocktail.bitter).abs() * 0.5).toInt();
    score -= ((_salt - cocktail.salt).abs() * 0.5).toInt();
    score -= ((_umami - cocktail.umami).abs() * 0.5).toInt();

    return score.clamp(0, 100);
  }

  Color _getScoreColor() {
    final score = _getMatchScore();
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final cocktail = _cocktails[_selectedCocktailIndex];

    // Панель обязательна: без неё сквозь текст просвечивает картинка
    // комнаты, и слайд читается как «прозрачный».
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideTypeIcon(type: widget.slide.type),
        const SizedBox(height: 16),
        Text(
          widget.slide.title,
          style: TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.slide.content,
          style: TextStyle(
            color: _inkMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildCocktailSelector(),
        const SizedBox(height: 16),
        _buildTaskCard(cocktail),
        const SizedBox(height: 16),
        _buildControlButtons(cocktail),
        const SizedBox(height: 20),
        _buildSliderWithHint(
            '🍬 Сладость',
            _sweetness,
            (v) => setState(() => _sweetness = v),
            'Мягко',
            'Сильно',
            cocktail.sweetness),
        _buildSliderWithHint('🍋 Кислота', _acid,
            (v) => setState(() => _acid = v), 'Мягко', 'Ярко', cocktail.acid),
        _buildSliderWithHint(
            '🌿 Горечь',
            _bitter,
            (v) => setState(() => _bitter = v),
            'Нет',
            'Много',
            cocktail.bitter),
        _buildSliderWithHint('🧂 Соль', _salt, (v) => setState(() => _salt = v),
            'Нет', 'Щепотка', cocktail.salt),
        _buildSliderWithHint(
            '🍄 Умами',
            _umami,
            (v) => setState(() => _umami = v),
            'Лёгкое',
            'Глубокое',
            cocktail.umami),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: widget.schoolRoom == null
          ? body
          : JohnWoodPanel(
              room: widget.schoolRoom!,
              highlighted: true,
              child: body,
            ),
    );
  }

  Widget _buildTaskCard(CocktailTemplate cocktail) {
    final score = _getMatchScore();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withAlpha(40),
            _accent.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(cocktail.emoji, style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cocktail.style,
                        style: TextStyle(
                          fontSize: 12,
                          color: _accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 70,
                height: 70,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 6,
                      backgroundColor: _roomStyle.accent.withAlpha(90),
                      valueColor: AlwaysStoppedAnimation(_getScoreColor()),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _roomStyle.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  score >= 80
                      ? Icons.check_circle
                      : (score >= 50 ? Icons.hourglass_empty : Icons.refresh),
                  color: _getScoreColor(),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getTasteDescription(),
                    style: TextStyle(
                      fontSize: 14,
                      color: _ink,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(CocktailTemplate cocktail) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetSliders,
            icon: Icon(Icons.refresh, size: 18),
            label: const Text('Начать заново'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _inkMuted,
              side: BorderSide(color: _roomStyle.accent.withAlpha(90)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _toggleRecipe,
            icon: Icon(_showRecipe ? Icons.visibility_off : Icons.visibility,
                size: 18),
            label: Text(_showRecipe ? 'Скрыть рецепт' : 'Показать рецепт'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withAlpha(100)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderWithHint(
      String label,
      double value,
      ValueChanged<double> onChanged,
      String minLabel,
      String maxLabel,
      double target) {
    final hint = _getHint(value, target);
    final hintColor = _getHintColor(value, target);
    final isCorrect = hint == '✓';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hintColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hint,
                      style: TextStyle(
                        fontSize: 14,
                        color: hintColor,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.withAlpha(30)
                      : _accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : _accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isCorrect ? Colors.green : _accent,
              inactiveTrackColor: _roomStyle.accent.withAlpha(90),
              thumbColor: isCorrect ? Colors.green : _accent,
              overlayColor: (isCorrect ? Colors.green : _accent).withAlpha(30),
              trackHeight: 6,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel, style: TextStyle(fontSize: 11, color: _inkMuted)),
              if (_showRecipe)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'цель: ${target.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Text(maxLabel,
                    style: TextStyle(fontSize: 11, color: _inkMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCocktailSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _roomStyle.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _roomStyle.accent.withAlpha(90)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCocktailIndex,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: _accent),
          items: _cocktails.asMap().entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Text(entry.value.emoji, style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                        Text(
                          entry.value.style,
                          style: TextStyle(
                            fontSize: 11,
                            color: _inkMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) _selectCocktail(value);
          },
        ),
      ),
    );
  }
}

class _AcidCalibrationSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _AcidCalibrationSlide({required this.slide, this.schoolRoom});

  @override
  State<_AcidCalibrationSlide> createState() => _AcidCalibrationSlideState();
}

class CocktailAcidTemplate {
  final String name;
  final String emoji;
  final String faceEmpty;
  final String faceOk;
  final String faceTooMuch;
  final String descriptionEmpty;
  final String descriptionOk;
  final String descriptionTooMuch;
  final double minGood;
  final double maxGood;
  final double optimal;

  const CocktailAcidTemplate({
    required this.name,
    required this.emoji,
    required this.faceEmpty,
    required this.faceOk,
    required this.faceTooMuch,
    required this.descriptionEmpty,
    required this.descriptionOk,
    required this.descriptionTooMuch,
    required this.minGood,
    required this.maxGood,
    required this.optimal,
  });
}

class _AcidCalibrationSlideState extends State<_AcidCalibrationSlide> {
  JohnRoomStyle? get _style => widget.schoolRoom == null
      ? null
      : JohnRoomStyle.forRoom(widget.schoolRoom!);

  Color get _ink => _style?.onDark ?? AppColors.textPrimary;

  Color get _inkMuted =>
      (_style?.onDark ?? AppColors.textPrimary).withAlpha(190);

  Color get _accent => _style?.accent ?? AppColors.primary;

  static const List<CocktailAcidTemplate> _cocktails = [
    CocktailAcidTemplate(
      name: 'Daiquiri',
      emoji: '🥃',
      faceEmpty: '😐',
      faceOk: '😊',
      faceTooMuch: '😖',
      descriptionEmpty: 'Плоский, водянистый',
      descriptionOk: 'Идеально!',
      descriptionTooMuch: 'Слишком кисло',
      minGood: 18,
      maxGood: 23,
      optimal: 20,
    ),
    CocktailAcidTemplate(
      name: 'Gin Rickey',
      emoji: '🍸',
      faceEmpty: '😐',
      faceOk: '😊',
      faceTooMuch: '😖',
      descriptionEmpty: 'Безвкусный',
      descriptionOk: 'Освежающе!',
      descriptionTooMuch: 'Режет язык',
      minGood: 20,
      maxGood: 30,
      optimal: 25,
    ),
    CocktailAcidTemplate(
      name: 'Margarita',
      emoji: '🍹',
      faceEmpty: '😐',
      faceOk: '😊',
      faceTooMuch: '😖',
      descriptionEmpty: 'Слишком сладко',
      descriptionOk: 'Сбалансированно!',
      descriptionTooMuch: 'Кисло до боли',
      minGood: 18,
      maxGood: 25,
      optimal: 22,
    ),
  ];

  int _selectedCocktailIndex = 0;
  double _acidMl = 10;
  bool _showResult = false;

  void _reset() {
    setState(() {
      _acidMl = 10;
      _showResult = false;
    });
  }

  void _checkAll() {
    setState(() {
      _showResult = true;
    });
  }

  String _getFace() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    if (_acidMl < cocktail.minGood) return cocktail.faceEmpty;
    if (_acidMl > cocktail.maxGood) return cocktail.faceTooMuch;
    return cocktail.faceOk;
  }

  String _getDescription() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    if (_acidMl < cocktail.minGood) return cocktail.descriptionEmpty;
    if (_acidMl > cocktail.maxGood) return cocktail.descriptionTooMuch;
    return cocktail.descriptionOk;
  }

  Color _getColor() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    if (_acidMl < cocktail.minGood) return Colors.orange;
    if (_acidMl > cocktail.maxGood) return Colors.red;
    return Colors.green;
  }

  bool _isInGoodZone() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    return _acidMl >= cocktail.minGood && _acidMl <= cocktail.maxGood;
  }

  Color _getLiquidColor() {
    final ratio = _acidMl / 40;
    if (ratio < 0.3) return const Color(0xFFE8D4B8);
    if (ratio < 0.5) return const Color(0xFFF0E070);
    if (ratio < 0.7) return const Color(0xFFD4E040);
    return const Color(0xFFB8D420);
  }

  @override
  Widget build(BuildContext context) {
    final cocktail = _cocktails[_selectedCocktailIndex];

    // Панель обязательна: без неё сквозь текст просвечивает комната,
    // и слайд читается как «прозрачный» — ровно как было на слайде 3
    // урока A_02 (единственный тренажёр, которому не передавали schoolRoom).
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlideTypeIcon(type: widget.slide.type),
        const SizedBox(height: 16),
        Text(
          widget.slide.title,
          style: TextStyle(
            color: _ink,
            fontFamily: _style == null ? null : 'serif',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.slide.content,
          style: TextStyle(
            color: _inkMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        _buildCocktailSelector(),
        const SizedBox(height: 20),
        _buildCocktailCard(cocktail),
        const SizedBox(height: 20),
        _buildSlider(cocktail),
        const SizedBox(height: 20),
        _buildControlButtons(),
        if (_showResult) ...[
          const SizedBox(height: 20),
          _buildResultsSummary(),
        ],
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: widget.schoolRoom == null
          ? body
          : JohnWoodPanel(
              room: widget.schoolRoom!,
              highlighted: true,
              child: body,
            ),
    );
  }

  Widget _buildCocktailSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _style?.surfaceLight ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _style == null ? AppColors.divider : _accent.withAlpha(120),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCocktailIndex,
          isExpanded: true,
          dropdownColor: _style?.surface,
          icon: Icon(Icons.keyboard_arrow_down, color: _accent),
          items: _cocktails.asMap().entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Text(entry.value.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCocktailIndex = value;
                _reset();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCocktailCard(CocktailAcidTemplate cocktail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withAlpha(40),
            _accent.withAlpha(16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withAlpha(110)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Text(cocktail.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withAlpha(34),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Зона: ${cocktail.minGood.toInt()}-${cocktail.maxGood.toInt()} мл',
                        style: TextStyle(
                          fontSize: 12,
                          color: _accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getLiquidColor(),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: _style == null
                        ? AppColors.divider
                        : _accent.withAlpha(120),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getFace(),
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ],
          ),
          // Результат пробы светлый плашкой с тёмным текстом: статусные
          // цвета остаются читаемыми и на тёплом дереве, и в светлой теме.
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _style == null
                  ? _getColor().withAlpha(30)
                  : const Color(0xFFFCEAB9).withAlpha(235),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isInGoodZone() ? Icons.check_circle : Icons.warning,
                    color: _statusColor(), size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _getDescription(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      color: _statusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Цвет статуса, читаемый на светлой плашке.
  Color _statusColor() {
    final color = _getColor();
    if (_style == null) return color;
    return Color.lerp(color, Colors.black, 0.25)!;
  }

  Widget _buildSlider(CocktailAcidTemplate cocktail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _style?.surfaceLight ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            _style == null ? null : Border.all(color: _accent.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Заголовок сжимается, а бейдж со значением держит размер:
              // иначе пара «🍋 Кислота (мл)» + «N мл» вылезала на 66 px.
              Flexible(
                child: Text(
                  '🍋 Кислота (мл)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getColor().withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_acidMl.toInt()} мл',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: _style == null
                      ? AppColors.divider
                      : const Color(0xFF120B08).withAlpha(120),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: (cocktail.minGood * 2.5).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(100),
                          borderRadius:
                              BorderRadius.horizontal(left: Radius.circular(6)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex:
                          ((cocktail.maxGood - cocktail.minGood) * 2.5).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(150),
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(6)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((40 - cocktail.maxGood) * 2.5).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(100),
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10', style: TextStyle(fontSize: 12, color: _inkMuted)),
              Text('${cocktail.minGood.toInt()}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold)),
              Text('${cocktail.maxGood.toInt()}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
              Text('40', style: TextStyle(fontSize: 12, color: _inkMuted)),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getColor(),
              inactiveTrackColor: AppColors.divider,
              thumbColor: _getColor(),
              overlayColor: _getColor().withAlpha(30),
              trackHeight: 8,
            ),
            child: Slider(
              value: _acidMl,
              min: 10,
              max: 40,
              divisions: 6,
              onChanged: (v) => setState(() => _acidMl = v),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Мягко', style: TextStyle(fontSize: 11, color: _inkMuted)),
              Text('Ярко', style: TextStyle(fontSize: 11, color: _inkMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Сброс'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _inkMuted,
              side: BorderSide(
                color:
                    _style == null ? AppColors.divider : _accent.withAlpha(110),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _checkAll,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Проверить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _style == null ? null : _accent,
              foregroundColor: _style == null ? null : const Color(0xFF2A1708),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSummary() {
    int successCount = 0;
    for (final c in _cocktails) {
      if (_acidMl >= c.minGood && _acidMl <= c.maxGood) {
        successCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: successCount == 3
            ? Colors.green.withAlpha(30)
            : Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: successCount == 3 ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                successCount == 3 ? Icons.emoji_events : Icons.info,
                color: successCount == 3 ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                successCount == 3
                    ? '🎉 Отлично! Все зоны пойманы!'
                    : '💪 $successCount/3 зон поймано',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: successCount == 3 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _cocktails.map((c) {
              final isOk = _acidMl >= c.minGood && _acidMl <= c.maxGood;
              return Column(
                children: [
                  Text(isOk ? '✅' : '❌', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(c.name, style: TextStyle(fontSize: 12, color: _ink)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Подбери ${_cocktails[_selectedCocktailIndex].name}: ${_acidMl.toInt()} мл — оптимально ${_cocktails[_selectedCocktailIndex].optimal.toInt()} мл',
            style: TextStyle(
              fontSize: 13,
              color: _inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SweetnessCalibrationSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _SweetnessCalibrationSlide({required this.slide, this.schoolRoom});

  @override
  State<_SweetnessCalibrationSlide> createState() =>
      _SweetnessCalibrationSlideState();
}

class SweetnessCocktailTemplate {
  final String name;
  final String emoji;
  final String syrupType;
  final double minGood;
  final double maxGood;
  final double optimal;

  const SweetnessCocktailTemplate({
    required this.name,
    required this.emoji,
    required this.syrupType,
    required this.minGood,
    required this.maxGood,
    required this.optimal,
  });
}

class _SweetnessCalibrationSlideState
    extends State<_SweetnessCalibrationSlide> {
  // Палитра комнаты урока: тренажёры раньше были на старой фиолетово-синей
  // теме `AppColors` и на дереве читались как экран из другой версии.
  JohnRoomStyle get _roomStyle =>
      JohnRoomStyle.forRoom(widget.schoolRoom ?? JohnSchoolRoom.flavorLab);
  Color get _ink => _roomStyle.onDark;
  Color get _inkMuted => _roomStyle.onDark.withAlpha(190);
  Color get _accent => _roomStyle.accent;
  static const List<SweetnessCocktailTemplate> _cocktails = [
    SweetnessCocktailTemplate(
      name: 'Daiquiri',
      emoji: '🥃',
      syrupType: '1:1',
      minGood: 15,
      maxGood: 20,
      optimal: 18,
    ),
    SweetnessCocktailTemplate(
      name: 'Old Fashioned',
      emoji: '🥃',
      syrupType: '2:1',
      minGood: 10,
      maxGood: 15,
      optimal: 12,
    ),
    SweetnessCocktailTemplate(
      name: "Bee's Knees",
      emoji: '🍯',
      syrupType: 'Мёд',
      minGood: 20,
      maxGood: 25,
      optimal: 22,
    ),
  ];

  int _selectedCocktailIndex = 0;
  String _selectedSyrup = '1:1';
  double _dosageMl = 10;
  bool _showResult = false;

  void _reset() {
    setState(() {
      _dosageMl = 10;
      _selectedSyrup = '1:1';
      _showResult = false;
    });
  }

  void _checkAll() {
    setState(() {
      _showResult = true;
    });
  }

  String _getFace() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    if (_dosageMl < cocktail.minGood) return '😐';
    if (_dosageMl > cocktail.maxGood) return '😖';
    if (_selectedSyrup != cocktail.syrupType) return '😐';
    return '😊';
  }

  String _getDescription() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    if (_selectedSyrup != cocktail.syrupType) return 'Неправильный сироп!';
    if (_dosageMl < cocktail.minGood) return 'Не хватает тела';
    if (_dosageMl > cocktail.maxGood) return 'Слишком липко';
    return 'Идеально!';
  }

  Color _getColor() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    if (_selectedSyrup != cocktail.syrupType) return Colors.red;
    if (_dosageMl < cocktail.minGood) return Colors.orange;
    if (_dosageMl > cocktail.maxGood) return Colors.red;
    return Colors.green;
  }

  bool _isInGoodZone() {
    final cocktail = _cocktails[_selectedCocktailIndex];
    return _selectedSyrup == cocktail.syrupType &&
        _dosageMl >= cocktail.minGood &&
        _dosageMl <= cocktail.maxGood;
  }

  Color _getLiquidColor() {
    final ratio = _dosageMl / 30;
    if (ratio < 0.4) return const Color(0xFFE8F4FF);
    if (ratio < 0.6) return const Color(0xFFF0E8D4);
    if (ratio < 0.8) return const Color(0xFFD4C090);
    return const Color(0xFFB89650);
  }

  @override
  Widget build(BuildContext context) {
    final cocktail = _cocktails[_selectedCocktailIndex];

    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: JohnWoodPanel(
          room: widget.schoolRoom ?? JohnSchoolRoom.flavorLab,
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SlideTypeIcon(type: widget.slide.type),
              const SizedBox(height: 16),
              Text(
                widget.slide.title,
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.slide.content,
                style: TextStyle(
                  color: _inkMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildCocktailSelector(),
              const SizedBox(height: 20),
              _buildCocktailCard(cocktail),
              const SizedBox(height: 20),
              _buildSyrupSelector(cocktail),
              const SizedBox(height: 16),
              _buildSlider(cocktail),
              const SizedBox(height: 20),
              _buildControlButtons(),
              if (_showResult) ...[
                const SizedBox(height: 20),
                _buildResultsSummary(),
              ],
            ],
          ),
        ));
  }

  Widget _buildCocktailSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _roomStyle.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _roomStyle.accent.withAlpha(90)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCocktailIndex,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: _accent),
          items: _cocktails.asMap().entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Text(entry.value.emoji, style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCocktailIndex = value;
                _reset();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildCocktailCard(SweetnessCocktailTemplate cocktail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accent.withAlpha(40),
            _accent.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(cocktail.emoji, style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // Подпись «Сироп: …, NN-NN мл» длинная: на узком
                      // экране она вылезала на 102 px вправо.
                      child: Text(
                        'Сироп: ${cocktail.syrupType}, ${cocktail.minGood.toInt()}-${cocktail.maxGood.toInt()} мл',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: _accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getLiquidColor(),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                      color: _roomStyle.accent.withAlpha(90), width: 3),
                ),
                child: Center(
                  child: Text(
                    _getFace(),
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getColor().withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isInGoodZone() ? Icons.check_circle : Icons.warning,
                    color: _getColor(), size: 20),
                const SizedBox(width: 8),
                // Описание зоны не влезало в строку и рисовало
                // жёлто-чёрную штриховку overflow — даём перенос.
                Expanded(
                  child: Text(
                    _getDescription(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _getColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyrupSelector(SweetnessCocktailTemplate cocktail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _roomStyle.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🍯 Тип сиропа',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['1:1', '2:1', 'Мёд', 'Агава'].map((syrup) {
              final isSelected = _selectedSyrup == syrup;
              final isCorrect = syrup == cocktail.syrupType;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSyrup = syrup),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isCorrect ? Colors.green : _accent)
                            : (isCorrect
                                ? Colors.green.withAlpha(30)
                                : _roomStyle.accent.withAlpha(90)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? (isCorrect ? Colors.green : _accent)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        syrup,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(SweetnessCocktailTemplate cocktail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _roomStyle.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Заголовок сжимается, бейдж держит размер: иначе пара
              // «📏 Дозировка (мл)» + «N мл» вылезала на 102 px.
              Flexible(
                child: Text(
                  '📏 Дозировка (мл)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getColor().withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_dosageMl.toInt()} мл',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: _roomStyle.accent.withAlpha(90),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: (cocktail.minGood * 2).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(100),
                          borderRadius:
                              BorderRadius.horizontal(left: Radius.circular(6)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((cocktail.maxGood - cocktail.minGood) * 2).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(150),
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(6)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((30 - cocktail.maxGood) * 2).toInt(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(100),
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10', style: TextStyle(fontSize: 12, color: _inkMuted)),
              Text('${cocktail.minGood.toInt()}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold)),
              Text('${cocktail.maxGood.toInt()}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
              Text('30', style: TextStyle(fontSize: 12, color: _inkMuted)),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getColor(),
              inactiveTrackColor: _roomStyle.accent.withAlpha(90),
              thumbColor: _getColor(),
              overlayColor: _getColor().withAlpha(30),
              trackHeight: 8,
            ),
            child: Slider(
              value: _dosageMl,
              min: 10,
              max: 30,
              divisions: 4,
              onChanged: (v) => setState(() => _dosageMl = v),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Мягко', style: TextStyle(fontSize: 11, color: _inkMuted)),
              Text('Плотно', style: TextStyle(fontSize: 11, color: _inkMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _reset,
            icon: Icon(Icons.refresh, size: 18),
            label: const Text('Сброс'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _inkMuted,
              side: BorderSide(color: _roomStyle.accent.withAlpha(90)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _checkAll,
            icon: Icon(Icons.check_circle, size: 18),
            label: const Text('Проверить'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSummary() {
    int successCount = 0;
    for (final c in _cocktails) {
      if (_selectedSyrup == c.syrupType &&
          _dosageMl >= c.minGood &&
          _dosageMl <= c.maxGood) {
        successCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: successCount == 3
            ? Colors.green.withAlpha(30)
            : Colors.orange.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: successCount == 3 ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                successCount == 3 ? Icons.emoji_events : Icons.info,
                color: successCount == 3 ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                successCount == 3
                    ? '🎉 Отлично! Все зоны пойманы!'
                    : '💪 $successCount/3 зон поймано',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: successCount == 3 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _cocktails.map((c) {
              final isOk = _selectedSyrup == c.syrupType &&
                  _dosageMl >= c.minGood &&
                  _dosageMl <= c.maxGood;
              return Column(
                children: [
                  Text(isOk ? '✅' : '❌', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(c.name, style: TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Подбери ${_cocktails[_selectedCocktailIndex].name}: ${_selectedSyrup}, ${_dosageMl.toInt()} мл — оптимально ${_cocktails[_selectedCocktailIndex].optimal.toInt()} мл',
            style: TextStyle(
              fontSize: 13,
              color: _inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BitterCalibrationSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _BitterCalibrationSlide({required this.slide, this.schoolRoom});
  @override
  State<_BitterCalibrationSlide> createState() =>
      _BitterCalibrationSlideState();
}

class _BitterCalibrationSlideState extends State<_BitterCalibrationSlide> {
  // Палитра комнаты урока: тренажёры раньше были на старой фиолетово-синей
  // теме `AppColors` и на дереве читались как экран из другой версии.
  JohnRoomStyle get _roomStyle =>
      JohnRoomStyle.forRoom(widget.schoolRoom ?? JohnSchoolRoom.flavorLab);
  Color get _ink => _roomStyle.onDark;
  Color get _inkMuted => _roomStyle.onDark.withAlpha(190);
  Color get _accent => _roomStyle.accent;
  static final _cocktails = <Map<String, dynamic>>[
    {
      'name': 'Old Fashioned',
      'emoji': '🥃',
      'bitter': 'Angostura',
      'min': 1.5,
      'max': 2.5,
      'opt': 2.0
    },
    {
      'name': 'Manhattan',
      'emoji': '🍷',
      'bitter': 'Angostura',
      'min': 1.5,
      'max': 2.5,
      'opt': 2.0
    },
    {
      'name': 'Jungle Bird',
      'emoji': '🦜',
      'bitter': 'Angostura',
      'min': 1.0,
      'max': 2.0,
      'opt': 1.5
    },
  ];

  int _idx = 0;
  double _dashes = 0.5;
  bool _show = false;

  void _reset() => setState(() {
        _dashes = 0.5;
        _show = false;
      });
  void _check() => setState(() {
        _show = true;
      });

  Color _color() {
    final c = _cocktails[_idx];
    if (_dashes < (c['min'] as double)) return Colors.orange;
    if (_dashes > (c['max'] as double)) return Colors.red;
    return Colors.green;
  }

  String _face() {
    final c = _cocktails[_idx];
    if (_dashes < (c['min'] as double)) return '😐';
    if (_dashes > (c['max'] as double)) return '😖';
    return '😊';
  }

  String _desc() {
    final c = _cocktails[_idx];
    if (_dashes < (c['min'] as double)) return 'Плоский, нет характера';
    if (_dashes > (c['max'] as double)) return 'Вяжущий, перебор';
    return 'Идеальная связка!';
  }

  @override
  Widget build(BuildContext context) {
    final c = _cocktails[_idx];
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: JohnWoodPanel(
          room: widget.schoolRoom ?? JohnSchoolRoom.flavorLab,
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SlideTypeIcon(type: widget.slide.type),
              const SizedBox(height: 16),
              Text(widget.slide.title,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 8),
              Text(widget.slide.content,
                  style:
                      TextStyle(fontSize: 14, color: _inkMuted, height: 1.5)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                    color: _roomStyle.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _roomStyle.accent.withAlpha(90))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _idx,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: _accent),
                    items: _cocktails
                        .asMap()
                        .entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Row(children: [
                                Text(e.value['emoji'] as String,
                                    style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(e.value['name'] as String,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: _ink))),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null)
                        setState(() {
                          _idx = v;
                          _reset();
                        });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [_accent.withAlpha(40), _accent.withAlpha(20)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accent.withAlpha(80))),
                child: Column(children: [
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: _accent,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(c['emoji'] as String,
                            style: TextStyle(fontSize: 28))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(c['name'] as String,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _ink)),
                          const SizedBox(height: 4),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: _accent.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                  '${c['bitter']}: ${c['min']}-${c['max']} дэша',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _accent,
                                      fontWeight: FontWeight.w500))),
                        ])),
                    Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                            color: Color.lerp(
                                const Color(0xFFE8D4B8),
                                const Color(0xFF8B4513),
                                (_dashes - 0.5) / 2.5)!,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                                color: _roomStyle.accent.withAlpha(90),
                                width: 3)),
                        child: Center(
                            child:
                                Text(_face(), style: TextStyle(fontSize: 40)))),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _color().withAlpha(30),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                _dashes >= (c['min'] as double) &&
                                        _dashes <= (c['max'] as double)
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: _color(),
                                size: 20),
                            const SizedBox(width: 8),
                            // Описание зоны бывает длинным — отдаём ему всю
                            // оставшуюся ширину, иначе строка вылезает
                            // за карточку штриховкой overflow.
                            Expanded(
                              child: Text(_desc(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: _color(),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ])),
                ]),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: _roomStyle.surface,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Заголовок сжимается, бейдж со значением держит размер:
                        // иначе пара не помещалась и вылезала на 145 px.
                        Flexible(
                          child: Text('🌿 Дэши биттеров',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _ink)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                                color: _color().withAlpha(30),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('${_dashes.toStringAsFixed(1)} дэша',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _color()))),
                      ]),
                  const SizedBox(height: 20),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _color(),
                        inactiveTrackColor: _roomStyle.accent.withAlpha(90),
                        thumbColor: _color(),
                        overlayColor: _color().withAlpha(30),
                        trackHeight: 8),
                    child: Slider(
                        value: _dashes,
                        min: 0.5,
                        max: 3,
                        divisions: 5,
                        onChanged: (v) => setState(() => _dashes = v)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Мягко',
                            style: TextStyle(fontSize: 11, color: _inkMuted)),
                        Text('Насыщенно',
                            style: TextStyle(fontSize: 11, color: _inkMuted)),
                      ]),
                ]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _reset,
                        icon: Icon(Icons.refresh, size: 18),
                        label: const Text('Сброс'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _inkMuted,
                            side: BorderSide(
                                color: _roomStyle.accent.withAlpha(90)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))))),
                const SizedBox(width: 12),
                Expanded(
                    child: ElevatedButton.icon(
                        onPressed: _check,
                        icon: Icon(Icons.check_circle, size: 18),
                        label: const Text('Проверить'),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))))),
              ]),
              if (_show) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange, width: 2)),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.info, color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      // Текст в Row без Expanded вылезал за карточку
                      // на 10 px при узком экране — даём ему переноситься.
                      Expanded(
                        child: Text(
                            'Текущий: ${_dashes.toStringAsFixed(1)} дэша — оптимально ${c['opt']} дэша',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Три колонки в Row без Expanded вылезали за карточку
                    // на 10 px: названия коктейлей длиннее своей доли.
                    Row(
                        children: _cocktails.map((x) {
                      final ok = _dashes >= (x['min'] as double) &&
                          _dashes <= (x['max'] as double);
                      return Expanded(
                        child: Column(children: [
                          Text(ok ? '✅' : '❌', style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(x['name'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12))
                        ]),
                      );
                    }).toList()),
                  ]),
                ),
              ],
            ],
          ),
        ));
  }
}

class _StationBuilderSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _StationBuilderSlide({required this.slide, this.schoolRoom});
  @override
  State<_StationBuilderSlide> createState() => _StationBuilderSlideState();
}

class _StationBuilderSlideState extends State<_StationBuilderSlide> {
  // Палитра комнаты урока: тренажёры раньше были на старой фиолетово-синей
  // теме `AppColors` и на дереве читались как экран из другой версии.
  JohnRoomStyle get _roomStyle =>
      JohnRoomStyle.forRoom(widget.schoolRoom ?? JohnSchoolRoom.flavorLab);
  Color get _ink => _roomStyle.onDark;
  Color get _inkMuted => _roomStyle.onDark.withAlpha(190);
  static final _elements = <Map<String, String>>[
    {'name': 'Angostura bitters', 'zone': 'bitter', 'icon': '🌿'},
    {'name': 'Лёд кубики', 'zone': 'ice', 'icon': '🧊'},
    {'name': 'Simple syrup', 'zone': 'syrup', 'icon': '🍯'},
    {'name': 'Лаймовый сок', 'zone': 'citrus', 'icon': '🍋'},
    {'name': 'Джиггер', 'zone': 'tools', 'icon': '⚗️'},
    {'name': 'Orange Bitters', 'zone': 'bitter', 'icon': '🍊'},
    {'name': 'Медовый сироп', 'zone': 'syrup', 'icon': '🍯'},
    {'name': 'Лимонный сок', 'zone': 'citrus', 'icon': '🍋'},
    {'name': 'Шейкер', 'zone': 'tools', 'icon': '🥤'},
    {'name': 'Мята', 'zone': 'garnish', 'icon': '🌿'},
  ];

  // Цвета зон подобраны в тёплой палитре комнаты: раньше лёд был
  // холодно-голубым, а инструменты — серо-синими, и зоны читались как
  // плашки из старого фиолетового приложения.
  static final _zones = <Map<String, dynamic>>[
    {'id': 'ice', 'name': '🧊 Лёд', 'color': 0xFFD8E4E0},
    {'id': 'bitter', 'name': '🌿 Биттеры', 'color': 0xFF8D6E63},
    {'id': 'syrup', 'name': '🍯 Сиропы', 'color': 0xFFFFB74D},
    {'id': 'citrus', 'name': '🍋 Цитрус', 'color': 0xFFE8D9A0},
    {'id': 'tools', 'name': '⚗️ Инструменты', 'color': 0xFFB09A7A},
    {'id': 'garnish', 'name': '🌸 Гарниры', 'color': 0xFFA5C08A},
  ];

  final Map<String, String> _placements = {};

  @override
  void initState() {
    super.initState();
    for (var e in _elements) {
      _placements[e['name']!] = '';
    }
  }

  int _score() {
    int correct = 0;
    for (var e in _elements) {
      if (_placements[e['name']!] == e['zone']) correct++;
    }
    return (correct * 100 / _elements.length).round();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: JohnWoodPanel(
          room: widget.schoolRoom ?? JohnSchoolRoom.flavorLab,
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SlideTypeIcon(type: widget.slide.type),
              const SizedBox(height: 16),
              Text(widget.slide.title,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 8),
              Text(widget.slide.content,
                  style:
                      TextStyle(fontSize: 14, color: _inkMuted, height: 1.5)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.green.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green)),
                child: Row(children: [
                  Icon(Icons.emoji_events, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Цель: расставить все элементы по зонам',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Результат: ${_score()}%',
                            style: TextStyle(
                                color: _score() >= 80
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ])),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Элементы:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _elements.map((e) {
                  final selected = _placements[e['name']!]!;
                  final isCorrect =
                      selected.isNotEmpty && selected == e['zone'];
                  final isWrong = selected.isNotEmpty && selected != e['zone'];
                  return GestureDetector(
                    onTap: () => _showZoneSelector(e['name']!, e['zone']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withAlpha(30)
                            : (isWrong
                                ? Colors.red.withAlpha(30)
                                : _roomStyle.surface),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isCorrect
                                ? Colors.green
                                : (isWrong
                                    ? Colors.red
                                    : _roomStyle.accent.withAlpha(90)),
                            width: 2),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(e['icon']!, style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(e['name']!,
                            style: TextStyle(
                                color: _ink,
                                fontWeight: isCorrect
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        if (selected.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Icon(isCorrect ? Icons.check_circle : Icons.close,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: 16),
                        ],
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Зоны станции:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 12),
              ..._zones.map((z) {
                final items = _elements
                    .where((e) => _placements[e['name']!] == z['id'])
                    .toList();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(z['color'] as int).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(z['color'] as int)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(z['name'] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(z['color'] as int))),
                        if (items.isEmpty)
                          Text('Пусто',
                              style: TextStyle(color: _inkMuted, fontSize: 12))
                        else
                          Wrap(
                              spacing: 6,
                              children: items
                                  .map((e) => Chip(
                                        label: Text('${e['icon']} ${e['name']}',
                                            style: TextStyle(fontSize: 11)),
                                        backgroundColor: _roomStyle.surface,
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList()),
                      ]),
                );
              }),
            ],
          ),
        ));
  }

  void _showZoneSelector(String name, String correctZone) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Выбери зону для $name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _zones
                      .map((z) => ChoiceChip(
                            label: Text(z['name'] as String),
                            selected: _placements[name] == z['id'],
                            onSelected: (_) {
                              setState(
                                  () => _placements[name] = z['id'] as String);
                              Navigator.pop(ctx);
                            },
                            selectedColor:
                                Color(z['color'] as int).withAlpha(100),
                          ))
                      .toList()),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена')),
            ]),
      ),
    );
  }
}

class _JiggerMeasurementSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _JiggerMeasurementSlide({required this.slide, this.schoolRoom});
  @override
  State<_JiggerMeasurementSlide> createState() =>
      _JiggerMeasurementSlideState();
}

class _JiggerMeasurementSlideState extends State<_JiggerMeasurementSlide> {
  // Палитра комнаты урока: тренажёры раньше были на старой фиолетово-синей
  // теме `AppColors` и на дереве читались как экран из другой версии.
  JohnRoomStyle get _roomStyle =>
      JohnRoomStyle.forRoom(widget.schoolRoom ?? JohnSchoolRoom.flavorLab);
  Color get _ink => _roomStyle.onDark;
  Color get _inkMuted => _roomStyle.onDark.withAlpha(190);
  Color get _accent => _roomStyle.accent;
  double _fillLevel = 0;
  final int _target = 30;
  bool _checked = false;
  bool _correct = false;

  int get _current => (_fillLevel * 60).round();

  @override
  void initState() {
    super.initState();
    _fillLevel = _target / 60;
  }

  void _check() {
    final diff = (_current - _target).abs();
    setState(() {
      _checked = true;
      _correct = diff <= 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: JohnWoodPanel(
          room: widget.schoolRoom ?? JohnSchoolRoom.flavorLab,
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SlideTypeIcon(type: widget.slide.type),
              const SizedBox(height: 16),
              Text(widget.slide.title,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 8),
              Text(widget.slide.content.split('Цель:')[0],
                  style:
                      TextStyle(fontSize: 14, color: _inkMuted, height: 1.5)),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        color: _roomStyle.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _roomStyle.accent.withAlpha(90), width: 3),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: double.infinity,
                            height: 160 * _fillLevel,
                            decoration: BoxDecoration(
                              color: _checked
                                  ? (_correct
                                      ? Colors.green.withAlpha(180)
                                      : Colors.red.withAlpha(180))
                                  : _accent.withAlpha(180),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          Center(
                            child: Text(
                              '$_current мл',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _fillLevel > 0.5 ? Colors.white : _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('0',
                            style: TextStyle(color: _inkMuted, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text('🧪 60 мл',
                            style: TextStyle(color: _inkMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Потяни, чтобы налить:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _ink)),
                    const SizedBox(height: 12),
                    Slider(
                      value: _fillLevel,
                      min: 0,
                      max: 1,
                      divisions: 60,
                      activeColor: _checked
                          ? (_correct ? Colors.green : Colors.red)
                          : _accent,
                      onChanged: (v) {
                        setState(() {
                          _fillLevel = v;
                          _checked = false;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Цель: $_target мл (±3 мл)',
                      style: TextStyle(color: _inkMuted, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _check,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _checked
                            ? (_correct ? Colors.green : Colors.red)
                            : _accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      child: Text(_checked
                          ? (_correct ? '✓ Верно!' : 'Попробуй ещё')
                          : 'Проверить'),
                    ),
                    if (_checked && !_correct) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(30),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          'Твоя оценка: $_current мл. Нужно: $_target мл. Разница: ${(_current - _target).abs()} мл.',
                          style: TextStyle(fontSize: 13, color: Colors.orange),
                        ),
                      ),
                    ],
                    if (_checked && _correct) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.green.withAlpha(30),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text(
                          'Отлично! Ты попал в цель ±3 мл. Это профессиональная точность!',
                          style: TextStyle(fontSize: 13, color: Colors.green),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class _ShakeTimingSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _ShakeTimingSlide({required this.slide, this.schoolRoom});
  @override
  State<_ShakeTimingSlide> createState() => _ShakeTimingSlideState();
}

class _ShakeTimingSlideState extends State<_ShakeTimingSlide>
    with SingleTickerProviderStateMixin {
  // Палитра комнаты урока: тренажёры раньше были на старой фиолетово-синей
  // теме `AppColors` и на дереве читались как экран из другой версии.
  JohnRoomStyle get _roomStyle =>
      JohnRoomStyle.forRoom(widget.schoolRoom ?? JohnSchoolRoom.flavorLab);
  Color get _ink => _roomStyle.onDark;
  Color get _inkMuted => _roomStyle.onDark.withAlpha(190);
  Color get _accent => _roomStyle.accent;
  bool _isShaking = false;
  int _count = 0;
  DateTime? _startTime;

  void _startShake() {
    setState(() {
      _isShaking = true;
      _count = 0;
      _startTime = DateTime.now();
    });
  }

  void _tap() {
    if (!_isShaking) return;
    setState(() => _count++);
  }

  void _stopShake() {
    if (_startTime == null) return;
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    setState(() => _isShaking = false);

    String feedback;
    Color color;
    if (_count >= 10 && _count <= 18 && duration >= 8 && duration <= 20) {
      feedback =
          'Идеально! $_count движений за $duration секунд — профессиональный shake!';
      color = Colors.green;
    } else if (_count < 10) {
      feedback =
          'Маловато: $_count движений. Нужно 12-15 движений за 10-15 секунд.';
      color = Colors.orange;
    } else if (duration < 8) {
      feedback =
          'Слишком быстро! $duration секунд. Темп хороший, но следи за временем.';
      color = Colors.orange;
    } else {
      feedback =
          'Перестарался: $_count движений за $duration секунд. Лёд уже растаял!';
      color = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(feedback),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: JohnWoodPanel(
          room: widget.schoolRoom ?? JohnSchoolRoom.flavorLab,
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SlideTypeIcon(type: widget.slide.type),
              const SizedBox(height: 16),
              Text(widget.slide.title,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 8),
              Text(
                widget.slide.content
                    .split('Попробуй')[0]
                    .replaceAll('Тренируй ритм!', ''),
                style: TextStyle(fontSize: 14, color: _inkMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _tap,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isShaking ? _accent : _roomStyle.surface,
                          border: Border.all(
                            color: _isShaking
                                ? _accent
                                : _roomStyle.accent.withAlpha(90),
                            width: 4,
                          ),
                          boxShadow: _isShaking
                              ? [
                                  BoxShadow(
                                    color: _accent.withAlpha(100),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isShaking ? '$_count' : '🥃',
                                style: TextStyle(
                                  fontSize: _isShaking ? 48 : 64,
                                  fontWeight: FontWeight.bold,
                                  color: _isShaking ? Colors.white : _ink,
                                ),
                              ),
                              if (_isShaking)
                                const Text('движений',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Нажимай на шейкер, имитируя движения\n10-15 раз — идеальный shake!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: _inkMuted),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isShaking)
                          ElevatedButton.icon(
                            onPressed: _startShake,
                            icon: Icon(Icons.play_arrow),
                            label: const Text('Начать shake'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _stopShake,
                            icon: Icon(Icons.stop),
                            label: const Text('Стоп'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _roomStyle.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text('Формула идеального shake:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: _ink)),
                          SizedBox(height: 4),
                          Text('12-15 движений за 10-15 секунд',
                              style: TextStyle(color: _inkMuted)),
                          Text('≈ движение каждые 0.8-1 секунда',
                              style: TextStyle(color: _inkMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class _DilutionCalculatorSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _DilutionCalculatorSlide({required this.slide, this.schoolRoom});
  @override
  State<_DilutionCalculatorSlide> createState() =>
      _DilutionCalculatorSlideState();
}

class _DilutionCalculatorSlideState extends State<_DilutionCalculatorSlide> {
  // Палитра комнаты урока: тренажёры раньше были на старой фиолетово-синей
  // теме `AppColors` и на дереве читались как экран из другой версии.
  JohnRoomStyle get _roomStyle =>
      JohnRoomStyle.forRoom(widget.schoolRoom ?? JohnSchoolRoom.flavorLab);
  Color get _ink => _roomStyle.onDark;
  Color get _inkMuted => _roomStyle.onDark.withAlpha(190);
  Color get _accent => _roomStyle.accent;
  int _selectedIce = 30;
  String _selectedMethod = 'shake';
  final Map<String, int> _dilutionMap = {
    'shake': 30,
    'stir': 25,
    'build': 0,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: JohnWoodPanel(
          room: widget.schoolRoom ?? JohnSchoolRoom.flavorLab,
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SlideTypeIcon(type: widget.slide.type),
              const SizedBox(height: 16),
              Text(widget.slide.title,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 8),
              Text(
                widget.slide.content.split('Цель:')[0],
                style: TextStyle(fontSize: 14, color: _inkMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text('Выбери метод приготовления:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _ink)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MethodButton(
                          label: 'Shake',
                          icon: '🥤',
                          selected: _selectedMethod == 'shake',
                          style: _roomStyle,
                          onTap: () => setState(() {
                            _selectedMethod = 'shake';
                            _dilutionMap['shake'] = 30;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _MethodButton(
                          label: 'Stir',
                          icon: '🥄',
                          selected: _selectedMethod == 'stir',
                          style: _roomStyle,
                          onTap: () => setState(() {
                            _selectedMethod = 'stir';
                            _dilutionMap['stir'] = 25;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _MethodButton(
                          label: 'Build',
                          icon: '🧊',
                          selected: _selectedMethod == 'build',
                          style: _roomStyle,
                          onTap: () => setState(() {
                            _selectedMethod = 'build';
                            _dilutionMap['build'] = 0;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Количество льда:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _ink)),
                    const SizedBox(height: 8),
                    Slider(
                      value: _selectedIce.toDouble(),
                      min: 10,
                      max: 50,
                      divisions: 8,
                      label: '$_selectedIce кусков',
                      onChanged: (v) =>
                          setState(() => _selectedIce = v.round()),
                    ),
                    Text('$_selectedIce кусков льда',
                        style: TextStyle(color: _inkMuted)),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _accent),
                      ),
                      child: Column(
                        children: [
                          Text('💧 Dilution',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _accent)),
                          const SizedBox(height: 8),
                          Text(
                            '${_calculateDilution()} мл',
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _accent),
                          ),
                          Text('талой воды',
                              style: TextStyle(color: _inkMuted)),
                          const SizedBox(height: 12),
                          _DilutionIndicator(dilution: _calculateDilution()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: _roomStyle.surface,
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          Text('Справка:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: _ink)),
                          const SizedBox(height: 4),
                          Text(
                              'Shake (10-15 сек): ~30 мл | Stir (30-40 об.): ~25 мл | Build: 0 мл',
                              style: TextStyle(color: _inkMuted, fontSize: 12)),
                          Text('Цель: 20-25% dilution от объёма коктейля',
                              style: TextStyle(color: _inkMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  int _calculateDilution() {
    double iceFactor = _selectedIce / 30;
    int baseDilution = _dilutionMap[_selectedMethod] ?? 25;
    int result = (baseDilution * iceFactor).round();
    return result.clamp(0, 50);
  }
}

class _MethodButton extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;
  final JohnRoomStyle style;

  const _MethodButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap,
      required this.style});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? style.accent : style.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? style.accent : style.accent.withAlpha(90)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    // На золотой плашке нужен тёмный текст комнаты.
                    color: selected ? style.ink : style.onDark,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DilutionIndicator extends StatelessWidget {
  final int dilution;

  const _DilutionIndicator({required this.dilution});

  @override
  Widget build(BuildContext context) {
    String level;
    Color color;
    if (dilution < 15) {
      level = 'Низкое — коктейль будет жёстким';
      color = Colors.red;
    } else if (dilution <= 35) {
      level = 'Оптимальное — сбалансированный вкус';
      color = Colors.green;
    } else {
      level = 'Высокое — коктейль водянистый';
      color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
      child: Text(level,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _CocktailBuilderSlide extends StatefulWidget {
  final LessonSlide slide;
  final JohnSchoolRoom? schoolRoom;

  const _CocktailBuilderSlide({required this.slide, this.schoolRoom});
  @override
  State<_CocktailBuilderSlide> createState() => _CocktailBuilderSlideState();
}

class _CocktailBuilderSlideState extends State<_CocktailBuilderSlide> {
  // Палитра комнаты урока: тренажёры раньше были на старой фиолетово-синей
  // теме `AppColors` и на дереве читались как экран из другой версии.
  JohnRoomStyle get _roomStyle =>
      JohnRoomStyle.forRoom(widget.schoolRoom ?? JohnSchoolRoom.flavorLab);
  Color get _ink => _roomStyle.onDark;
  Color get _inkMuted => _roomStyle.onDark.withAlpha(190);
  Color get _accent => _roomStyle.accent;
  int _currentStep = 0;
  bool _showResult = false;

  List<String> get _cocktailSteps {
    if (widget.slide.title.contains('Mojito')) {
      return [
        'Muddle mint + sugar',
        'Add rum',
        'Fill with ice',
        'Top with soda',
        'Garnish mint'
      ];
    } else if (widget.slide.title.contains('Daiquiri')) {
      return [
        'Ice in shaker',
        'Add rum + lime + syrup',
        'Shake 12 sec',
        'Double strain'
      ];
    } else if (widget.slide.title.contains('Negroni')) {
      return [
        'Ice in mixing glass',
        'Add gin',
        'Add Campari',
        'Add vermouth',
        'Stir 30 sec',
        'Strain to rocks',
        'Garnish orange'
      ];
    } else if (widget.slide.title.contains('Практика') &&
        widget.slide.content.contains('3 коктейля')) {
      return ['Mojito: Build', 'Daiquiri: Shake', 'Negroni: Stir'];
    }
    return ['Step 1', 'Step 2'];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: JohnWoodPanel(
          room: widget.schoolRoom ?? JohnSchoolRoom.flavorLab,
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SlideTypeIcon(type: widget.slide.type),
              const SizedBox(height: 16),
              Text(widget.slide.title,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 8),
              Text('Собери коктейль пошагово!',
                  style:
                      TextStyle(fontSize: 14, color: _inkMuted, height: 1.5)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent),
                ),
                child: Column(
                  children: [
                    Text('🍸 Прогресс',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _accent)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_currentStep) / _cocktailSteps.length,
                      backgroundColor: _roomStyle.accent.withAlpha(60),
                      valueColor: AlwaysStoppedAnimation<Color>(_accent),
                    ),
                    const SizedBox(height: 4),
                    Text('Шаг ${_currentStep + 1} из ${_cocktailSteps.length}',
                        style: TextStyle(color: _inkMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Порядок сборки:',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 12),
              ...List.generate(_cocktailSteps.length, (index) {
                final step = _cocktailSteps[index];
                final isCompleted = index < _currentStep;
                final isCurrent = index == _currentStep;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withAlpha(30)
                        : (isCurrent
                            ? _accent.withAlpha(30)
                            : _roomStyle.surface),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted
                          ? Colors.green
                          : (isCurrent
                              ? _accent
                              : _roomStyle.accent.withAlpha(90)),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green
                              : (isCurrent ? _accent : Colors.grey),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.check, color: Colors.white, size: 18)
                              : Text('${index + 1}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(step,
                              style: TextStyle(
                                  color: _ink,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal))),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              if (!_showResult)
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (_currentStep < _cocktailSteps.length - 1) {
                          _currentStep++;
                        } else {
                          _showResult = true;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: Text(_currentStep < _cocktailSteps.length - 1
                        ? 'Следующий шаг →'
                        : 'Готово! 🎉'),
                  ),
                )
              else
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Коктейль собран!',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        const SizedBox(height: 8),
                        Text('Ты знаешь правильную последовательность!',
                            style: TextStyle(color: _inkMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _currentStep = 0;
                              _showResult = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ));
  }
}

/// Строка в итоговом блоке квеста: иконка и текст.
class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final JohnRoomStyle style;

  const _ResultRow({
    required this.icon,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: style.accent.withAlpha(200)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: style.onDark.withAlpha(205),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
