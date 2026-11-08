import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/daily_quest_service.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// 5-шаговый флоу практического задания.
class PracticeFlowScreen extends StatefulWidget {
  final PracticeChallenge challenge;
  const PracticeFlowScreen({super.key, required this.challenge});

  @override
  State<PracticeFlowScreen> createState() => _PracticeFlowScreenState();
}

class _PracticeFlowScreenState extends State<PracticeFlowScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Состояние выбора пользователя
  final Set<String> _selectedIngredients = {};
  String? _selectedMethod;
  final Map<String, int> _proportions = {};

  // Результат
  PracticeResult? _result;
  int _xpEarned = 0;
  bool _timeBonusAwarded = false;

  // Таймер (60с на шаги 1-3)
  static const _timerTotal = 60;
  int _timerSeconds = _timerTotal;
  Timer? _timer;
  bool _timeBonusEarned = false;

  static const _totalSteps = 5;
  static const _stepLabels = [
    'Задание',
    'Ингредиенты',
    'Метод',
    'Пропорции',
    'Результат',
  ];

  @override
  void initState() {
    super.initState();
    for (final ing in widget.challenge.correctIngredients) {
      _proportions[ing] = 30;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      // Старт таймера на шаге 1 (ингредиенты)
      if (_currentStep == 1) _startTimer();
      // Стоп таймера на шаге 4 (результат)
      if (_currentStep == 4) _stopTimer();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _evaluate() {
    _stopTimer();
    _timeBonusEarned = _timerSeconds >= 20;
    final result = evaluateAttempt(
      widget.challenge,
      _selectedIngredients,
      _selectedMethod ?? '',
      _proportions,
    );
    final award = context.read<ProgressService>().recordPracticeAttempt(
          challenge: widget.challenge,
          stars: result.stars,
          timeBonusEarned: _timeBonusEarned,
        );

    // Ежедневное задание: коктейль в мастерской
    if (award.improvedStars > 0) {
      final qs = context.read<DailyQuestService>();
      final progress = context.read<ProgressService>();
      qs.completeQuest(DailyQuestType.practiceCocktail).then((reward) {
        if (reward > 0) progress.earnCoins(reward);
      });
    }
    setState(() {
      _result = result;
      _xpEarned = award.xpEarned;
      _timeBonusAwarded = award.timeBonusAwarded;
    });
    _nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: JohnThemedAppBar(
        room: JohnSchoolRoom.workshop,
        title: widget.challenge.cocktailName,
        // Таймер (виден на шагах 1-3)
        actions: [
          if (_currentStep >= 1 && _currentStep <= 3)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_timerSeconds}с',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _timerSeconds <= 10
                        ? Colors.redAccent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.workshop,
        child: Column(
          children: [
            // ── Step indicator ──────────────────────────────────────────────
            _StepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              labels: _stepLabels,
            ),
            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _IntroStep(challenge: widget.challenge, onNext: _nextStep),
                  _IngredientsStep(
                    challenge: widget.challenge,
                    selected: _selectedIngredients,
                    onToggle: (ing) {
                      setState(() {
                        if (_selectedIngredients.contains(ing)) {
                          _selectedIngredients.remove(ing);
                        } else {
                          _selectedIngredients.add(ing);
                        }
                      });
                    },
                    onNext: _nextStep,
                  ),
                  _MethodStep(
                    selected: _selectedMethod,
                    onSelect: (method) {
                      setState(() => _selectedMethod = method);
                    },
                    onNext: _nextStep,
                  ),
                  _ProportionsStep(
                    challenge: widget.challenge,
                    selectedIngredients: _selectedIngredients.toList(),
                    proportions: _proportions,
                    onChange: (ing, ml) {
                      setState(() => _proportions[ing] = ml);
                    },
                    onEvaluate: _evaluate,
                  ),
                  _ResultStep(
                    challenge: widget.challenge,
                    result: _result,
                    xpEarned: _xpEarned,
                    timeBonusEarned: _timeBonusAwarded,
                    onRetry: () {
                      _timerSeconds = _timerTotal;
                      _timeBonusEarned = false;
                      _timeBonusAwarded = false;
                      _xpEarned = 0;
                      setState(() {
                        _selectedIngredients.clear();
                        _selectedMethod = null;
                        for (final ing in widget.challenge.correctIngredients) {
                          _proportions[ing] = 30;
                        }
                        _result = null;
                        _currentStep = 0;
                      });
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    onBack: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step Indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xEE24160F),
        border: Border(bottom: BorderSide(color: Color(0x998F6A32))),
      ),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFFD0A24C)
                          : isActive
                              ? const Color(0x99D0A24C)
                              : const Color(0xFF4C3827),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? const Color(0xFFD0A24C)
                          : const Color(0xFFB8A58A),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 0: Intro ───────────────────────────────────────────────────────────

class _IntroStep extends StatelessWidget {
  final PracticeChallenge challenge;
  final VoidCallback onNext;

  const _IntroStep({required this.challenge, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Аватар Джона
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'images/barista_john_teach.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primary.withAlpha(30),
                child: const Icon(Icons.person,
                    size: 32, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Название коктейля
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/ui_icon_practice_motion.png',
                width: 34,
                height: 34,
              ),
              const SizedBox(width: 8),
              // «Espresso Martini» на 24pt не влезал в строку и давал
              // переполнение на 59 px — имя переносится по центру.
              Flexible(
                child: Text(
                  challenge.cocktailName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Текст Джона
          JohnWoodPanel(
            room: JohnSchoolRoom.workshop,
            padding: const EdgeInsets.all(16),
            child: Text(
              challenge.johnIntro,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFF7E7C0),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Кнопка
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B4A2D),
                foregroundColor: const Color(0xFFFFE9BE),
                side: const BorderSide(color: Color(0xFFD0A24C)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Начать',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Ingredients ─────────────────────────────────────────────────────

/// Заголовок шага на плашке.
///
/// Шаги практики живут поверх фото стойки: без подложки белый заголовок
/// терялся на светлых участках снимка (стаканы, лёд, бумага).
class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(200),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsStep extends StatelessWidget {
  final PracticeChallenge challenge;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const _IngredientsStep({
    required this.challenge,
    required this.selected,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final options = challenge.allOptions;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            title: 'Выбери ингредиенты',
            subtitle: 'Нажми на те, что нужны для ${challenge.cocktailName}',
          ),
          const SizedBox(height: 12),
          // Плашка под списком: чипы полупрозрачные, и на фото стойки
          // подписи теряли контраст. Фон под ними делает текст читаемым.
          // Flexible + InnerScroll: если вариантов много и экран низкий,
          // чипы скроллятся, а заголовок и кнопка остаются на месте.
          Flexible(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background.withAlpha(200),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider.withAlpha(60)),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: options.map((ing) {
                    final isSelected = selected.contains(ing);
                    return GestureDetector(
                      onTap: () => onToggle(ing),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(30)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.divider.withAlpha(100),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.check_circle,
                                    size: 16, color: AppColors.primary),
                              ),
                            Text(
                              ing,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Кнопка
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: selected.isEmpty ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.primary.withAlpha(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                selected.isEmpty
                    ? 'Выбери ингредиенты'
                    : 'Дальше (${selected.length} выбрано)',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Method ──────────────────────────────────────────────────────────

class _MethodStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  const _MethodStep({
    required this.selected,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            title: 'Выбери метод',
            subtitle: 'Как будешь готовить?',
          ),
          const SizedBox(height: 12),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: methodDescriptions.entries.map((entry) {
                final method = entry.key;
                final desc = entry.value;
                final isSelected = selected == method;

                return GestureDetector(
                  onTap: () => onSelect(method),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(25)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider.withAlpha(80),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(desc.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          desc.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Кнопка
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: selected == null ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.primary.withAlpha(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Дальше',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Proportions (Visual Jigger) ────────────────────────────────────

class _ProportionsStep extends StatelessWidget {
  final PracticeChallenge challenge;
  final List<String> selectedIngredients;
  final Map<String, int> proportions;
  final void Function(String ingredient, int ml) onChange;
  final VoidCallback onEvaluate;

  const _ProportionsStep({
    required this.challenge,
    required this.selectedIngredients,
    required this.proportions,
    required this.onChange,
    required this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    final ingredients = selectedIngredients.isNotEmpty
        ? selectedIngredients
        : challenge.correctIngredients;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            title: 'Настрой пропорции',
            subtitle:
                'Потяни слайсер — зелёная зона показывает правильный диапазон',
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.separated(
              itemCount: ingredients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final ing = ingredients[i];
                final ml = proportions[ing] ?? 30;
                final target = challenge.proportions[ing];
                final targetMl = target?.targetMl ?? 30;
                final tolerance = target?.toleranceMl ?? 10;
                final inRange = target?.isWithin(ml) ?? true;

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: inRange
                          ? Colors.green.withAlpha(100)
                          : AppColors.divider.withAlpha(80),
                      width: inRange ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ing,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          // Value badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: inRange
                                  ? Colors.green.withAlpha(25)
                                  : AppColors.primary.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$ml мл',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: inRange
                                    ? Colors.green.shade700
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Slider with target zone
                      _JiggerSlider(
                        value: ml,
                        targetMl: targetMl,
                        tolerance: tolerance,
                        onChanged: (v) => onChange(ing, v),
                      ),
                      // Target hint
                      const SizedBox(height: 4),
                      Text(
                        'Цель: ${targetMl}мл',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Кнопка
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onEvaluate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Проверить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider with a highlighted target zone.
class _JiggerSlider extends StatelessWidget {
  final int value;
  final int targetMl;
  final int tolerance;
  final ValueChanged<int> onChanged;

  const _JiggerSlider({
    required this.value,
    required this.targetMl,
    required this.tolerance,
    required this.onChanged,
  });

  /// Запас шкалы сверх максимума цели.
  ///
  /// Задания вроде Moscow Mule и Hot Toddy целятся в 120 мл с допуском
  /// ±15–20. При шкале ровно 120 зона упиралась в правый край, и половина
  /// допуска была недостижима — точную дозу нельзя было налить в принципе.
  /// Даём 30 мл запаса: цель всегда стоит внутри шкалы.
  static const double _headroomMl = 30;
  static const double _maxMl = 120 + _headroomMl;
  static const double _minMl = 0;

  /// Трек `Slider` врезан с обеих сторон на радиус оверлея (max(overlay,
  /// thumb)); зона должна считаться от трека, а не от ширины экрана.
  static const double _trackInset = 16;

  double _xOf(int ml, double width) =>
      _trackInset + (ml / _maxMl) * (width - 2 * _trackInset);

  @override
  Widget build(BuildContext context) {
    final rangeLow =
        (targetMl - tolerance).clamp(_minMl.toInt(), _maxMl.toInt());
    final rangeHigh =
        (targetMl + tolerance).clamp(_minMl.toInt(), _maxMl.toInt());

    return SizedBox(
      height: 32,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            // Target zone background
            Positioned(
              left: _xOf(rangeLow, width),
              right: width - _xOf(rangeHigh, width),
              top: 10,
              bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Slider
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: _trackInset),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.divider.withAlpha(60),
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                min: _minMl,
                max: _maxMl,
                // Шаг 1мл: при шаге 5мл допуска вроде «2мл ±1» физически
                // недостижимы и 3★ нельзя получить в принципе.
                divisions: _maxMl.toInt(),
                value: value.clamp(_minMl.toInt(), _maxMl.toInt()).toDouble(),
                label: '${value.clamp(_minMl.toInt(), _maxMl.toInt())} мл',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Step 4: Result ──────────────────────────────────────────────────────────

class _ResultStep extends StatelessWidget {
  final PracticeChallenge challenge;
  final PracticeResult? result;
  final int xpEarned;
  final bool timeBonusEarned;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ResultStep({
    required this.challenge,
    required this.result,
    required this.xpEarned,
    required this.timeBonusEarned,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();

    final stars = result!.stars;
    final statusColor = stars == 3
        ? Colors.green
        : stars == 2
            ? Colors.orange
            : Colors.redAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Звёзды
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Icon(
                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                size: 40,
                color: i < stars ? Colors.amber : AppColors.divider,
              );
            }),
          ),
          const SizedBox(height: 8),

          // XP бейдж
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$xpEarned XP',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          if (timeBonusEarned) ...[
            const SizedBox(height: 6),
            Text(
              '⚡ Бонус за скорость +10 XP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Статус
          Text(
            stars == 3
                ? 'Идеально!'
                : stars == 2
                    ? 'Почти!'
                    : stars == 1
                        ? 'Начало положено'
                        : 'Попробуй ещё раз',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 20),

          // Детали
          _ResultRow(
            label: 'Ингредиенты',
            correct: result!.ingredientsCorrect,
          ),
          _ResultRow(
            label: 'Метод',
            correct: result!.methodCorrect,
          ),
          _ResultRow(
            label: 'Пропорции',
            correct: result!.proportionsCorrect,
          ),
          const SizedBox(height: 12),

          // Разблокировка коктейля
          if (stars >= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍸', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${challenge.cocktailName} разблокирован в Рецептах!',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Фидбэк Джона
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withAlpha(60)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'images/barista_john_teach.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Container(
                      color: statusColor.withAlpha(30),
                      child: Icon(Icons.person, size: 18, color: statusColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result!.feedbackText,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Кнопки
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Повторить',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('В Мастерскую',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final bool correct;

  const _ResultRow({required this.label, required this.correct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: correct ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: correct ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
