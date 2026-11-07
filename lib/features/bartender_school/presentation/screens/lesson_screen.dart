import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/guest_echo.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/screens/quiz_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/term_quiz_screen.dart';
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

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isWisdomLesson => widget.lesson.blockId == 'W';

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
    final lessonTerms = widget.lesson.terms;
    final hasUnlearnedTerms =
        lessonTerms.isNotEmpty && !progress.areLessonTermsLearned(lessonTerms);

    if (hasUnlearnedTerms) {
      // First: term quiz (learn the vocabulary). Один проход гейта покрывает
      // максимум 5–6 вопросов, поэтому для урока с 8 терминами может
      // понадобиться второй заход. onComplete снова вызывает _goToQuiz():
      // когда все термины выучены — сработает ветка «main quiz»,
      // иначе — гейт откроется ещё раз для оставшихся терминов.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TermQuizScreen(
            lesson: widget.lesson,
            onComplete: () {
              Navigator.pop(context); // Pop term quiz
              _goToQuiz(); // Re-check gate, then open main quiz
            },
          ),
        ),
      );
    } else {
      // Terms already learned or no terms — go straight to quiz
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(lessonId: widget.lesson.id),
        ),
      );
    }
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
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
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
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
                          const Text(
                            'Словарик урока',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${glossaryTerms.length} терминов',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.divider, height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: glossaryTerms.length,
                  itemBuilder: (context, index) {
                    final term = glossaryTerms[index];
                    return _LessonTermCard(term: term);
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
                        lessonMentor: widget.lesson.mentor,
                        isFirstSlide: index == 0,
                        isWisdomLesson: isWisdomLesson,
                        schoolRoom: schoolRoom,
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
              Text(
                isWisdomLesson
                    ? 'СТРАНИЦА $currentSlide ИЗ $totalSlides'
                    : 'Слайд $currentSlide из $totalSlides',
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

  const _SlideWidget({
    required this.slide,
    this.lessonMentor,
    this.isFirstSlide = false,
    this.isWisdomLesson = false,
    this.schoolRoom,
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
      case SlideType.checklist:
        return 'images/barista_john_exam.png';
      case SlideType.theory:
      case SlideType.termAnimation:
      case SlideType.barTip:
      case SlideType.failure:
      case SlideType.quote:
      case SlideType.observation:
      case SlideType.choice:
      case SlideType.silence:
        return 'images/barista_john_teach.png';
    }
  }

  Widget _withMentor(Widget child) {
    final mentorText = _mentorText;
    if (mentorText == null) return child;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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

  /// Уровень 1 лежит поверх фотографии комнаты. Обычная теория печатается на
  /// деревянной панели, а тренажёры/tool visual/bar tip — нет: без панели их
  /// светлый текст и полупрозрачные плашки сливаются с фоном. Укрываем теми же
  /// досками и интерактивные слайды. Отступы подобраны так, чтобы ширина
  /// контента осталась прежней (8 + 16 = 24): иначе на экране 320px ряды
  /// внутри тренажёров начинают переполняться.
  Widget _onDesk(Widget child) {
    if (schoolRoom == null) return child;
    const radius = BorderRadius.all(Radius.circular(18));
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: JohnWoodPanel(
        room: schoolRoom!,
        highlighted: true,
        padding: EdgeInsets.zero,
        borderRadius: radius,
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isWisdomLesson) {
      return _buildWisdomSlide(context);
    }

    if (slide.type == SlideType.barTip) {
      return _onDesk(_withMentor(_buildBarTipSlide()));
    }

    if (slide.type == SlideType.balanceTrainer) {
      return _onDesk(_withMentor(_BalanceTrainerSlide(slide: slide)));
    }

    if (slide.type == SlideType.toolVisual) {
      return _onDesk(_withMentor(_ToolVisualSlide(slide: slide)));
    }

    if (slide.type == SlideType.interactive) {
      final Widget body;
      if (slide.title.contains('Кислот')) {
        body = _AcidCalibrationSlide(slide: slide);
      } else if (slide.title.contains('сладость') ||
          slide.title.contains('Сладость')) {
        body = _SweetnessCalibrationSlide(slide: slide);
      } else if (slide.title.contains('горечь') ||
          slide.title.contains('Горечь') ||
          slide.title.contains('биттер')) {
        body = _BitterCalibrationSlide(slide: slide);
      } else if (slide.title.contains('станцию') ||
          slide.title.contains('Собери')) {
        body = _StationBuilderSlide(slide: slide);
      } else if (slide.title.contains('джиггер') ||
          slide.title.contains('налей') ||
          (slide.title.contains('Практика') &&
              slide.content.contains('джиггер'))) {
        body = _JiggerMeasurementSlide(slide: slide);
      } else if (slide.title.contains('шейк') ||
          slide.title.contains('тайминг') ||
          slide.title.contains('встрях')) {
        body = _ShakeTimingSlide(slide: slide);
      } else if (slide.title.contains('dilution') ||
          slide.title.contains('Дильюш')) {
        body = _DilutionCalculatorSlide(slide: slide);
      } else if (slide.title.contains('Практика') &&
          slide.content.contains('Шаг')) {
        body = _CocktailBuilderSlide(slide: slide);
      } else {
        body = _AcidCalibrationSlide(slide: slide);
      }
      return _onDesk(_withMentor(body));
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

    // Панель должна занимать всю страницу, а не только высоту текста:
    // иначе под коротким слайдом просвечивает фотография комнаты и страница
    // выглядит «прозрачной». Скролл живёт внутри панели, как у тренажёров.
    return _onDesk(
      SingleChildScrollView(
        padding: schoolRoom == null
            ? const EdgeInsets.all(24)
            : const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
      SlideType.observation => 'images/ui_icon_book_theory.png',
      SlideType.choice => 'images/ui_icon_play_card.png',
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
                if (slide.type == SlideType.choice && slide.choices.isNotEmpty)
                  _WisdomChoiceList(
                    choices: slide.choices,
                    sceneTitle: slide.title,
                  ),
                if (slide.type == SlideType.silence)
                  const Padding(
                    padding: EdgeInsets.only(top: 22),
                    child: Center(
                      child: Text(
                        '◆ ◆ ◆',
                        style: TextStyle(
                          color: WisdomPalette.antiqueGold,
                          fontSize: 13,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ),
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
    // Слайд лежит поверх панели комнаты: общая тема (янтарь #E8A838 на
    // тёмном) спорит с золотом комнаты, поэтому берём её палитру.
    final style =
        schoolRoom == null ? null : JohnRoomStyle.forRoom(schoolRoom!);
    final accent = style?.accent ?? AppColors.primary;
    final ink = style?.ink ?? AppColors.textPrimary;
    final body = style?.onDark ?? AppColors.textPrimary;
    final surface = style?.surfaceLight ?? AppColors.surface;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar Tip header with icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withAlpha(40), accent.withAlpha(20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent.withAlpha(100),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent,
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
                      Text(
                        'БАРНЫЙ ЛАЙФХАК',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        slide.title,
                        style: TextStyle(
                          color: body,
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
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              slide.content,
              style: TextStyle(
                color: body,
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
                      Icon(Icons.star_rounded, size: 16, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          point,
                          style: TextStyle(
                            color: ink.computeLuminance() > 0.5
                                ? ink
                                : body.withAlpha(210),
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

  const _LessonTermCard({required this.term});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  term.term,
                  style: const TextStyle(
                    color: AppColors.accent,
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (term.example.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
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
                        color: AppColors.textSecondary.withAlpha(200),
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

/// Сцена из записной книжки: варианты хода и объяснение выбранного.
///
/// Ошибка здесь ничего не блокирует и не отнимает очки — это разговор с
/// Джоном, а не экзамен. Поэтому после выбора показываются все объяснения.
class _WisdomChoiceList extends StatefulWidget {
  final List<SlideChoice> choices;

  /// Заголовок сцены — по нему эхо на главной узнаваемо.
  final String sceneTitle;

  const _WisdomChoiceList({
    required this.choices,
    required this.sceneTitle,
  });

  @override
  State<_WisdomChoiceList> createState() => _WisdomChoiceListState();
}

class _WisdomChoiceListState extends State<_WisdomChoiceList> {
  String? _pickedId;

  /// В части сцен верных ходов несколько: у сервиса не всегда один
  /// правильный ответ. Говорим об этом заранее, чтобы выбор не выглядел
  /// ловушкой.
  String _rightMovesHint() {
    final right = widget.choices.where((choice) => choice.isCorrect).length;
    return right > 1
        ? 'Выбери свой ход. Верных решений здесь может быть больше одного.'
        : 'Выбери свой ход. Верное решение одно.';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'ТВОЙ ХОД',
          style: TextStyle(
            color: WisdomPalette.oldGold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _rightMovesHint(),
          style: const TextStyle(
            color: WisdomPalette.ink,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        ...widget.choices.map((choice) {
          final picked = _pickedId == choice.id;
          final revealed = _pickedId != null;
          final marksRight = revealed && choice.isCorrect;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: revealed
                  ? null
                  : () {
                      setState(() => _pickedId = choice.id);
                      // Запоминаем ход: через несколько дней Джон вернётся
                      // к нему на главной («гость вернулся...»).
                      context.read<GuestEchoService>().remember(
                            sceneTitle: widget.sceneTitle,
                            choiceText: choice.text,
                            wasRight: choice.isCorrect,
                          );
                    },
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: marksRight
                      ? WisdomPalette.antiqueGold.withAlpha(38)
                      : picked
                          ? WisdomPalette.wax.withAlpha(24)
                          : WisdomPalette.parchmentLight.withAlpha(90),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: marksRight
                        ? WisdomPalette.antiqueGold
                        : picked
                            ? WisdomPalette.wax
                            : WisdomPalette.parchmentDark,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            choice.text,
                            style: const TextStyle(
                              color: WisdomPalette.ink,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                        ),
                        if (marksRight)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check_circle,
                                size: 18, color: WisdomPalette.oldGold),
                          ),
                      ],
                    ),
                    if (revealed &&
                        choice.explanation != null &&
                        choice.explanation!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        choice.explanation!,
                        style: const TextStyle(
                          color: WisdomPalette.oldGold,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        if (_pickedId != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _pickedId = null),
                  child: const Text(
                    'Пройти сцену ещё раз',
                    style: TextStyle(
                      color: WisdomPalette.oldGold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
      case SlideType.failure:
        assetPath = 'images/ui_icon_book_theory.png';
        break;
      case SlideType.quote:
        assetPath = 'images/ui_icon_term_medal.png';
        break;
      case SlideType.observation:
        assetPath = 'images/ui_icon_book_theory.png';
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

  const _ToolVisualSlide({required this.slide});

  String _getToolEmoji() {
    final title = slide.title.toLowerCase();
    if (title.contains('джиггер') || title.contains('jigger')) {
      return '⚗️';
    }
    if (title.contains('шейкер') || title.contains('shaker')) {
      return '🥃';
    }
    if (title.contains('сок') || title.contains('пресс')) {
      return '🍋';
    }
    if (title.contains('лёд')) {
      return '🧊';
    }
    if (title.contains('станц')) {
      return '🔧';
    }
    return '🍸';
  }

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

  @override
  Widget build(BuildContext context) {
    final toolEmoji = _getToolEmoji();
    final parts = _getToolParts();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big tool visual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withAlpha(50),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  toolEmoji,
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 16),
                Text(
                  slide.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tool parts if available
          if (parts.isNotEmpty) ...[
            const Text(
              'Из чего состоит:',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...parts.entries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
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
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: entry.value,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
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

          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              slide.content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.6,
              ),
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
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
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
        ],
      ),
    );
  }
}

class _BalanceTrainerSlide extends StatefulWidget {
  final LessonSlide slide;

  const _BalanceTrainerSlide({required this.slide});

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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(
            widget.slide.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.slide.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
          _buildSliderWithHint(
              '🧂 Соль',
              _salt,
              (v) => setState(() => _salt = v),
              'Нет',
              'Щепотка',
              cocktail.salt),
          _buildSliderWithHint(
              '🍄 Умами',
              _umami,
              (v) => setState(() => _umami = v),
              'Лёгкое',
              'Глубокое',
              cocktail.umami),
        ],
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
            AppColors.primary.withAlpha(40),
            AppColors.primary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        cocktail.style,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
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
                      backgroundColor: AppColors.divider,
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
              color: AppColors.surface,
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
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
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Начать заново'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
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
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withAlpha(100)),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
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
                      : AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: isCorrect ? Colors.green : AppColors.primary,
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
              activeTrackColor: isCorrect ? Colors.green : AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: isCorrect ? Colors.green : AppColors.primary,
              overlayColor:
                  (isCorrect ? Colors.green : AppColors.primary).withAlpha(30),
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
              Text(minLabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
              if (_showRecipe)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'цель: ${target.toInt()}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Text(maxLabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCocktailIndex,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: _cocktails.asMap().entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Row(
                children: [
                  Text(entry.value.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          entry.value.style,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
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

  const _AcidCalibrationSlide({required this.slide});

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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(
            widget.slide.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.slide.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
      ),
    );
  }

  Widget _buildCocktailSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCocktailIndex,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
            AppColors.primary.withAlpha(40),
            AppColors.primary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Зона: ${cocktail.minGood.toInt()}-${cocktail.maxGood.toInt()} мл',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
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
                  border: Border.all(color: AppColors.divider, width: 3),
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
                Text(
                  _getDescription(),
                  style: TextStyle(
                    fontSize: 16,
                    color: _getColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(CocktailAcidTemplate cocktail) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🍋 Кислота (мл)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
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
                  color: AppColors.divider,
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
              const Text('10',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
              const Text('40',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
              const Text('Мягко',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const Text('Щепотка',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
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
                  Text(c.name, style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Подбери ${_cocktails[_selectedCocktailIndex].name}: ${_acidMl.toInt()} мл — оптимально ${_cocktails[_selectedCocktailIndex].optimal.toInt()} мл',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
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

  const _SweetnessCalibrationSlide({required this.slide});

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(
            widget.slide.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.slide.content,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
    );
  }

  Widget _buildCocktailSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCocktailIndex,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
            AppColors.primary.withAlpha(40),
            AppColors.primary.withAlpha(20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(80)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Сироп: ${cocktail.syrupType}, ${cocktail.minGood.toInt()}-${cocktail.maxGood.toInt()} мл',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
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
                  border: Border.all(color: AppColors.divider, width: 3),
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
                Text(
                  _getDescription(),
                  style: TextStyle(
                    fontSize: 16,
                    color: _getColor(),
                    fontWeight: FontWeight.bold,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🍯 Тип сиропа',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
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
                            ? (isCorrect ? Colors.green : AppColors.primary)
                            : (isCorrect
                                ? Colors.green.withAlpha(30)
                                : AppColors.divider),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? (isCorrect ? Colors.green : AppColors.primary)
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
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Expanded, иначе на 320px подпись с бейджем не влезают в ряд.
              const Expanded(
                child: Text(
                  '📏 Дозировка (мл)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
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
                  color: AppColors.divider,
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
              const Text('10',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
              const Text('30',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
              value: _dosageMl,
              min: 10,
              max: 30,
              divisions: 4,
              onChanged: (v) => setState(() => _dosageMl = v),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Мягко',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text('Плотно',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
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
                  Text(isOk ? '✅' : '❌', style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(c.name, style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Подбери ${_cocktails[_selectedCocktailIndex].name}: ${_selectedSyrup}, ${_dosageMl.toInt()} мл — оптимально ${_cocktails[_selectedCocktailIndex].optimal.toInt()} мл',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
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
  const _BitterCalibrationSlide({required this.slide});
  @override
  State<_BitterCalibrationSlide> createState() =>
      _BitterCalibrationSlideState();
}

class _BitterCalibrationSlideState extends State<_BitterCalibrationSlide> {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(widget.slide.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(widget.slide.content,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _idx,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: AppColors.primary),
                items: _cocktails
                    .asMap()
                    .entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Row(children: [
                            Text(e.value['emoji'] as String,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(e.value['name'] as String,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary))),
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
                gradient: LinearGradient(colors: [
                  AppColors.primary.withAlpha(40),
                  AppColors.primary.withAlpha(20)
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(80))),
            child: Column(children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text(c['emoji'] as String,
                        style: const TextStyle(fontSize: 28))),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(c['name'] as String,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                              '${c['bitter']}: ${c['min']}-${c['max']} дэша',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500))),
                    ])),
                Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        color: Color.lerp(const Color(0xFFE8D4B8),
                            const Color(0xFF8B4513), (_dashes - 0.5) / 2.5)!,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: AppColors.divider, width: 3)),
                    child: Center(
                        child: Text(_face(),
                            style: const TextStyle(fontSize: 40)))),
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
                        // Flexible: на 320px длинное описание влезает с переносом.
                        Flexible(
                            child: Text(_desc(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    color: _color(),
                                    fontWeight: FontWeight.bold))),
                      ])),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                // Expanded: без него на 320px подпись и счётчик дэшей не влезают.
                const Expanded(
                    child: Text('🌿 Дэши биттеров',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary))),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    inactiveTrackColor: AppColors.divider,
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
              const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Мягко',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    Text('Насыщенно',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ]),
            ]),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Сброс'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))))),
            const SizedBox(width: 12),
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: _check,
                    icon: const Icon(Icons.check_circle, size: 18),
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
                  const Icon(Icons.info, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Text(
                      'Текущий: ${_dashes.toStringAsFixed(1)} дэша — оптимально ${c['opt']} дэша',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                ]),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _cocktails.map((x) {
                      final ok = _dashes >= (x['min'] as double) &&
                          _dashes <= (x['max'] as double);
                      return Column(children: [
                        Text(ok ? '✅' : '❌',
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(x['name'] as String,
                            style: const TextStyle(fontSize: 12))
                      ]);
                    }).toList()),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _StationBuilderSlide extends StatefulWidget {
  final LessonSlide slide;
  const _StationBuilderSlide({required this.slide});
  @override
  State<_StationBuilderSlide> createState() => _StationBuilderSlideState();
}

class _StationBuilderSlideState extends State<_StationBuilderSlide> {
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

  static final _zones = <Map<String, dynamic>>[
    {'id': 'ice', 'name': '🧊 Лёд', 'color': 0xFF4FC3F7},
    {'id': 'bitter', 'name': '🌿 Биттеры', 'color': 0xFF8D6E63},
    {'id': 'syrup', 'name': '🍯 Сиропы', 'color': 0xFFFFB74D},
    {'id': 'citrus', 'name': '🍋 Цитрус', 'color': 0xFFFFEB3B},
    {'id': 'tools', 'name': '⚗️ Инструменты', 'color': 0xFF90A4AE},
    {'id': 'garnish', 'name': '🌸 Гарниры', 'color': 0xFF81C784},
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(widget.slide.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(widget.slide.content,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
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
                            color:
                                _score() >= 80 ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Элементы:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _elements.map((e) {
              final selected = _placements[e['name']!]!;
              final isCorrect = selected.isNotEmpty && selected == e['zone'];
              final isWrong = selected.isNotEmpty && selected != e['zone'];
              return GestureDetector(
                onTap: () => _showZoneSelector(e['name']!, e['zone']!),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withAlpha(30)
                        : (isWrong
                            ? Colors.red.withAlpha(30)
                            : AppColors.surface),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isCorrect
                            ? Colors.green
                            : (isWrong ? Colors.red : AppColors.divider),
                        width: 2),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(e['icon']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(e['name']!,
                        style: TextStyle(
                            color: AppColors.textPrimary,
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
          const Text('Зоны станции:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
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
                      const Text('Пусто',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12))
                    else
                      Wrap(
                          spacing: 6,
                          children: items
                              .map((e) => Chip(
                                    label: Text('${e['icon']} ${e['name']}',
                                        style: const TextStyle(fontSize: 11)),
                                    backgroundColor: AppColors.surface,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList()),
                  ]),
            );
          }),
        ],
      ),
    );
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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
  const _JiggerMeasurementSlide({required this.slide});
  @override
  State<_JiggerMeasurementSlide> createState() =>
      _JiggerMeasurementSlideState();
}

class _JiggerMeasurementSlideState extends State<_JiggerMeasurementSlide> {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(widget.slide.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(widget.slide.content.split('Цель:')[0],
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 3),
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
                              : const Color(0xFF42A5F5).withAlpha(180),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$_current мл',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _fillLevel > 0.5
                                ? Colors.white
                                : AppColors.textPrimary,
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
                    const Text('0',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 8),
                    const Text('🧪 60 мл',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Потяни, чтобы налить:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Slider(
                  value: _fillLevel,
                  min: 0,
                  max: 1,
                  divisions: 60,
                  activeColor: _checked
                      ? (_correct ? Colors.green : Colors.red)
                      : const Color(0xFF42A5F5),
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
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _check,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _checked
                        ? (_correct ? Colors.green : Colors.red)
                        : AppColors.primary,
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
                      style:
                          const TextStyle(fontSize: 13, color: Colors.orange),
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
    );
  }
}

class _ShakeTimingSlide extends StatefulWidget {
  final LessonSlide slide;
  const _ShakeTimingSlide({required this.slide});
  @override
  State<_ShakeTimingSlide> createState() => _ShakeTimingSlideState();
}

class _ShakeTimingSlideState extends State<_ShakeTimingSlide>
    with SingleTickerProviderStateMixin {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(widget.slide.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            widget.slide.content
                .split('Попробуй')[0]
                .replaceAll('Тренируй ритм!', ''),
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
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
                      color: _isShaking
                          ? const Color(0xFF42A5F5)
                          : AppColors.surface,
                      border: Border.all(
                        color: _isShaking
                            ? const Color(0xFF42A5F5)
                            : AppColors.divider,
                        width: 4,
                      ),
                      boxShadow: _isShaking
                          ? [
                              BoxShadow(
                                color: const Color(0xFF42A5F5).withAlpha(100),
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
                              color: _isShaking
                                  ? Colors.white
                                  : AppColors.textPrimary,
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
                const Text(
                  'Нажимай на шейкер, имитируя движения\n10-15 раз — идеальный shake!',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isShaking)
                      ElevatedButton.icon(
                        onPressed: _startShake,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Начать shake'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _stopShake,
                        icon: const Icon(Icons.stop),
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
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text('Формула идеального shake:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 4),
                      Text('12-15 движений за 10-15 секунд',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text('≈ движение каждые 0.8-1 секунда',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
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

class _DilutionCalculatorSlide extends StatefulWidget {
  final LessonSlide slide;
  const _DilutionCalculatorSlide({required this.slide});
  @override
  State<_DilutionCalculatorSlide> createState() =>
      _DilutionCalculatorSlideState();
}

class _DilutionCalculatorSlideState extends State<_DilutionCalculatorSlide> {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(widget.slide.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            widget.slide.content.split('Цель:')[0],
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text('Выбери метод приготовления:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MethodButton(
                      label: 'Shake',
                      icon: '🥤',
                      selected: _selectedMethod == 'shake',
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
                      onTap: () => setState(() {
                        _selectedMethod = 'build';
                        _dilutionMap['build'] = 0;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Количество льда:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Slider(
                  value: _selectedIce.toDouble(),
                  min: 10,
                  max: 50,
                  divisions: 8,
                  label: '$_selectedIce кусков',
                  onChanged: (v) => setState(() => _selectedIce = v.round()),
                ),
                Text('$_selectedIce кусков льда',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF42A5F5)),
                  ),
                  child: Column(
                    children: [
                      const Text('💧 Dilution',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF42A5F5))),
                      const SizedBox(height: 8),
                      Text(
                        '${_calculateDilution()} мл',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF42A5F5)),
                      ),
                      const Text('талой воды',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      _DilutionIndicator(dilution: _calculateDilution()),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      const Text('Справка:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                          'Shake (10-15 сек): ~30 мл | Stir (30-40 об.): ~25 мл | Build: 0 мл',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const Text('Цель: 20-25% dilution от объёма коктейля',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  const _MethodButton(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF42A5F5) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? const Color(0xFF42A5F5) : AppColors.divider),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
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
  const _CocktailBuilderSlide({required this.slide});
  @override
  State<_CocktailBuilderSlide> createState() => _CocktailBuilderSlideState();
}

class _CocktailBuilderSlideState extends State<_CocktailBuilderSlide> {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlideTypeIcon(type: widget.slide.type),
          const SizedBox(height: 16),
          Text(widget.slide.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Собери коктейль пошагово!',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF42A5F5).withAlpha(30),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF42A5F5)),
            ),
            child: Column(
              children: [
                const Text('🍸 Прогресс',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF42A5F5))),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentStep) / _cocktailSteps.length,
                  backgroundColor: Colors.grey.withAlpha(50),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
                ),
                const SizedBox(height: 4),
                Text('Шаг ${_currentStep + 1} из ${_cocktailSteps.length}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Порядок сборки:',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
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
                        ? const Color(0xFF42A5F5).withAlpha(30)
                        : AppColors.surface),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                      ? Colors.green
                      : (isCurrent
                          ? const Color(0xFF42A5F5)
                          : AppColors.divider),
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
                          : (isCurrent ? const Color(0xFF42A5F5) : Colors.grey),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : Text('${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(step,
                          style: TextStyle(
                              color: AppColors.textPrimary,
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
                  backgroundColor: const Color(0xFF42A5F5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                        style: TextStyle(color: AppColors.textSecondary)),
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
    );
  }
}
