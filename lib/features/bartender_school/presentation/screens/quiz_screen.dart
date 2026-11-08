import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/school_config.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/quiz_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/block_rewards.dart';
import 'package:coin/features/bartender_school/data/daily_quest_service.dart';
import 'package:coin/features/bartender_school/data/term_service.dart';
import 'package:coin/features/bartender_school/data/john_reactions.dart';
import 'package:coin/features/bartender_school/data/weekly_contract.dart';
import 'package:coin/features/bartender_school/domain/entities/quiz.dart';
import 'package:coin/features/bartender_school/domain/services/quiz_answer_evaluator.dart';
import 'package:coin/features/bartender_school/presentation/widgets/block_reward_dialog.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Квиз: сначала вопросы по терминам урока, потом вопросы урока.
///
/// Раньше это были два отдельных экрана подряд: сначала `TermQuizScreen`
/// («Термины: …»), сразу за ним обычный квиз. Студент видел «второй квиз
/// с начала». Теперь один экран, один прогресс, один результат: термины идут
/// первым блоком той же сессии.
class QuizScreen extends StatefulWidget {
  /// Имя маршрута квиза. Нужно, чтобы при выходе снять ровно этот экран
  /// с навигатора (`popUntil`), а не гадать «сколько раз pop». Прежний
  /// цикл из трёх `pop()` подряд уводил ученика далеко назад — сразу к списку
  /// уроков, минуя саму теорию, и казалось, что из квиза нет выхода.
  static const String routeName = '/quiz';

  final String lessonId;

  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  Set<int>? _selectedIndices; // For multiple choice
  Map<int, double> _sliderValues = {}; // For slider questions
  Map<String, String> _matchingSelections = {};
  List<String> _matchingOptions = [];
  List<String> _sequenceOrder = [];
  bool? _isCurrentAnswerCorrect;
  bool _answered = false;
  bool _isLoadingQuestions = false;

  // ── Блок терминов ────────────────────────────────────────────────────────
  // Вопросы по терминам идут первыми и не входят в процент квиза:
  // процент считается только по вопросам урока, иначе провал терминов
  // топил бы результат по самому уроку.
  List<TermQuizQuestion> _termQuestions = [];
  int _termIndex = 0;
  final Set<String> _termsLearnedNow = {};
  String? _termSelectedAnswer;
  bool _termAnswered = false;

  /// Сколько вопросов всего в сессии: термины + урок.
  int get _totalSteps => _termQuestions.length + _questions.length;

  /// На каком шаге мы сейчас (для одного общего прогресса).
  ///
  /// Пока идёт блок терминов, шаг — это его собственный индекс, а не
  /// «все термины + текущий вопрос урока»: иначе заголовок показывал 5/11
  /// на первом термине.
  int get _currentStep {
    if (_termIndex < _termQuestions.length) return _termIndex;
    return _termQuestions.length + _currentQuestionIndex;
  }

  /// Награды за блоки, которые нужно показать после завершения квиза.
  List<BlockReward> _pendingBlockRewards = [];

  /// Сколько раз этот квиз был провален до текущей попытки.
  int _failedAttemptsBefore = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuestions();
    });
  }

  void _loadQuestions() {
    if (!mounted) return;
    if (_isLoadingQuestions || _questions.isNotEmpty) return;
    _isLoadingQuestions = true;

    try {
      final quizRepo = Provider.of<QuizRepository>(context, listen: false);

      // Wait for quizzes to load if still loading
      if (quizRepo.isLoading) {
        _isLoadingQuestions = false;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _loadQuestions();
        });
        return;
      }

      _questions = quizRepo.getQuestionsForLesson(widget.lessonId);
      _failedAttemptsBefore =
          context.read<ProgressService>().getQuizFailures(widget.lessonId);
      _loadTermQuestions();
      _prepareCurrentInteractiveQuestion();

      if (_questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Вопросы для урока ${widget.lessonId} не найдены. Доступные: ${quizRepo.availableLessonIds.length}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки вопросов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoadingQuestions = false;
    }
  }

  /// Собирает вопросы блока терминов: только ещё не выученные.
  ///
  /// Один проход покрывает до 6 вопросов, а у урока бывает 8 терминов,
  /// поэтому остаток естественно переезжает в следующий подход к квизу
  /// (выученные пропускаются).
  void _loadTermQuestions() {
    final lesson =
        Provider.of<LessonRepository>(context, listen: false).getLesson(
      widget.lessonId,
    );
    if (lesson == null || lesson.terms.isEmpty) return;

    final termService = TermService();
    final progress = Provider.of<ProgressService>(context, listen: false);
    final learned = <String>{};
    var unlearned = 0;
    for (final name in lesson.terms) {
      final term = termService.getTerm(name);
      if (term == null) continue;
      if (progress.isTermLearned(term.russianName)) {
        learned.add(term.russianName);
      } else {
        unlearned++;
      }
    }
    _termQuestions = termService.generateQuiz(
      lesson.terms,
      maxQuestions: unlearned == 0 ? 3 : unlearned.clamp(3, 6),
      skipLearned: learned,
      // Seed из id урока: набор вопросов и порядок вариантов стабильны
      // между перерисовками и повторами — иначе выученный термин снова
      // не узнавался на следующей попытке.
      seed: widget.lessonId.hashCode,
    );
  }

  void _selectTermAnswer(String answer) {
    if (_termAnswered) return;
    final question = _termQuestions[_termIndex];
    final isCorrect = answer == question.correctAnswer;
    setState(() {
      _termSelectedAnswer = answer;
      _termAnswered = true;
      if (isCorrect) {
        _termsLearnedNow.add(question.termName);
      }
    });
  }

  void _nextTermQuestion() {
    // Термины закончились — записываем выученное и переходим к вопросам урока.
    // Индекс обязательно переводим за границу списка: именно по нему
    // `inTermBlock` понимает, что блок терминов закрыт. Без этого экран
    // застревал на последнем термине — дальше пройти было нельзя.
    if (_termIndex >= _termQuestions.length - 1) {
      _commitLearnedTerms();
      setState(() {
        _termIndex = _termQuestions.length;
        _termSelectedAnswer = null;
        _termAnswered = false;
        _prepareCurrentInteractiveQuestion();
      });
      return;
    }
    setState(() {
      _termIndex++;
      _termSelectedAnswer = null;
      _termAnswered = false;
    });
  }

  /// Досрочный выход из блока терминов («Пропустить»): выученное всё равно
  /// засчитывается, но квиз по уроку не блокируется терминами.
  void _skipTerms() {
    _commitLearnedTerms();
    setState(() {
      // Переводим индекс за границу, а не обнуляем список: иначе общий
      // прогресс и нумерация шагов считались бы по другому знаменателю.
      _termIndex = _termQuestions.length;
      _termSelectedAnswer = null;
      _termAnswered = false;
      _prepareCurrentInteractiveQuestion();
    });
  }

  void _commitLearnedTerms() {
    if (_termsLearnedNow.isEmpty) return;
    final progress = Provider.of<ProgressService>(context, listen: false);
    for (final termName in _termsLearnedNow) {
      progress.markTermLearned(termName);
    }
    _termsLearnedNow.clear();

    // Достижение «весь словарь выучен» живёт здесь же: раньше оно
    // разблокировалось в удалённом экране терминов.
    final allTermNames =
        TermService.allTerms.map((t) => t.russianName).toList();
    if (allTermNames.isNotEmpty && allTermNames.every(progress.isTermLearned)) {
      progress.unlockAchievement('all_terms');
    }
  }

  void _selectAnswer(int index) {
    if (_answered) return;

    setState(() {
      _selectedIndex = index;
      _answered = true;

      _isCurrentAnswerCorrect = QuizAnswerEvaluator.isSingleChoiceCorrect(
        _questions[_currentQuestionIndex],
        index,
      );
      if (_isCurrentAnswerCorrect!) {
        _score++;
      }
    });
  }

  void _toggleMultipleChoice(int index) {
    if (_answered) return;

    setState(() {
      _selectedIndices ??= {};
      if (_selectedIndices!.contains(index)) {
        _selectedIndices!.remove(index);
      } else {
        _selectedIndices!.add(index);
      }
    });
  }

  void _submitMultipleChoice() {
    if (_answered) return;

    final question = _questions[_currentQuestionIndex];
    final isCorrect = QuizAnswerEvaluator.isMultipleChoiceCorrect(
      question,
      _selectedIndices,
    );

    setState(() {
      _answered = true;
      _isCurrentAnswerCorrect = isCorrect;
      if (isCorrect) {
        _score++;
      }
      _selectedIndices = null;
    });
  }

  void _submitSliderAnswer() {
    if (_answered) return;

    final question = _questions[_currentQuestionIndex];
    final isCorrect = QuizAnswerEvaluator.isSliderAnswerCorrect(
      question,
      _sliderValues,
    );

    setState(() {
      _answered = true;
      _isCurrentAnswerCorrect = isCorrect;
      if (isCorrect) {
        _score++;
      }
    });
  }

  void _submitCurrentInteractiveAnswer() {
    final question = _questions[_currentQuestionIndex];
    if (question.type == QuestionType.slider) {
      _submitSliderAnswer();
      return;
    }
    if (question.type == QuestionType.matching) {
      _submitMatchingAnswer();
      return;
    }
    if (question.type == QuestionType.sequence) {
      _submitSequenceAnswer();
      return;
    }

    _selectAnswer(0);
  }

  void _prepareCurrentInteractiveQuestion() {
    if (_questions.isEmpty) return;

    final question = _questions[_currentQuestionIndex];
    _matchingSelections = {};
    _matchingOptions = question.pairs
            ?.map((pair) => pair['right'])
            .whereType<String>()
            .toSet()
            .toList() ??
        [];
    _matchingOptions.sort();

    final correctSequence = question.sequence ?? const <String>[];
    _sequenceOrder = List<String>.of(correctSequence);
    if (_sequenceOrder.length > 1) {
      final shift = 1 +
          question.id.codeUnits.fold<int>(0, (sum, value) => sum + value) %
              (_sequenceOrder.length - 1);
      _sequenceOrder = [
        ..._sequenceOrder.skip(shift),
        ..._sequenceOrder.take(shift),
      ];
    }
  }

  void _submitMatchingAnswer() {
    if (_answered) return;

    final question = _questions[_currentQuestionIndex];
    final isCorrect = QuizAnswerEvaluator.isMatchingAnswerCorrect(
      question,
      _matchingSelections,
    );

    setState(() {
      _answered = true;
      _isCurrentAnswerCorrect = isCorrect;
      if (isCorrect) _score++;
    });
  }

  void _submitSequenceAnswer() {
    if (_answered) return;

    final question = _questions[_currentQuestionIndex];
    final isCorrect = QuizAnswerEvaluator.isSequenceAnswerCorrect(
      question,
      _sequenceOrder,
    );

    setState(() {
      _answered = true;
      _isCurrentAnswerCorrect = isCorrect;
      if (isCorrect) _score++;
    });
  }

  void _nextQuestion() {
    // For multiple choice, submit first
    if (_questions[_currentQuestionIndex].type == QuestionType.multipleChoice &&
        !_answered) {
      _submitMultipleChoice();
      return;
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedIndex = null;
        _selectedIndices = null;
        _sliderValues = {};
        _isCurrentAnswerCorrect = null;
        _answered = false;
        _prepareCurrentInteractiveQuestion();
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final progressService =
        Provider.of<ProgressService>(context, listen: false);
    // Сервисы берём по ссылке сейчас: после закрытия квиза этот State
    // будет удалён, и `context.read` в асинхронных коллбеках упал бы
    // (`InheritedWidget was defunct`) — задание не засчиталось бы.
    final questService = context.read<DailyQuestService>();
    final contract = context.read<WeeklyContractService>();
    final percentage =
        _questions.isEmpty ? 100 : (_score / _questions.length * 100);
    final passed = percentage >= BartenderSchoolConfig.quizPassingScore;
    final xpEarned = passed ? BartenderSchoolConfig.xpPerLesson : 0;

    // Coins earned based on performance (base + quiz bonus)
    final coinsEarned = passed
        ? BartenderSchoolConfig.coinsPerLesson +
            BartenderSchoolConfig.coinsQuizBonus(percentage.toInt())
        : 0;

    // Only a passed quiz completes the lesson. Failed attempts should not
    // unlock the next step or make the certificate meaningless.
    if (passed) {
      progressService.resetQuizFailures(widget.lessonId);
      progressService.completeLesson(
        widget.lessonId,
        score: percentage.toInt(),
        xpEarned: xpEarned,
      );

      // Начисляем монеты за урок
      progressService.earnCoins(coinsEarned);

      // Ежедневные задания: урок пройден + квиз на 80%+
      unawaited(questService.completeQuest(DailyQuestType.completeLesson).then((reward) {
        if (reward > 0) progressService.earnCoins(reward);
      }));
      if (percentage.toInt() >= 80) {
        unawaited(questService.completeQuest(DailyQuestType.passQuiz).then((reward) {
          if (reward > 0) progressService.earnCoins(reward);
        }));
      }

      // Проверяем, завершён ли какой-то блок (награды за блоки)
      _pendingBlockRewards = progressService.getNewlyCompletedBlockRewards();

      // Недельный договор: урок и сданный экзамен.
      contract.registerLesson();
      if (percentage.toInt() >= 80) contract.registerExam();
    } else {
      // Провал запоминаем: на второй и третий раз Джон скажет по-другому.
      progressService.registerQuizFailure(widget.lessonId);
    }

    // Auto-unlock achievements
    List<String> unlockedAchievements = [];

    // Perfect quiz achievement (100% score)
    if (percentage == 100) {
      // Плашка показывается один раз — при первом открытии, а не на каждом
      // идеальном квизе (раньше «Перфекционист» всплывал 9 раз за Level 1).
      if (progressService.unlockAchievement('perfect_quiz')) {
        unlockedAchievements.add('perfect_quiz');
      }
    }

    // Calculate trophies based on score
    final trophies = (percentage / 100 * 3).round();
    final lesson = Provider.of<LessonRepository>(
      context,
      listen: false,
    ).getLesson(widget.lessonId);
    final nextLessonHook = lesson?.nextLessonHook?.trim();

    // Show achievement notifications
    if (unlockedAchievements.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAchievementNotification(context, unlockedAchievements);
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Text(
                        passed ? '🏆' : '💪',
                        style: const TextStyle(fontSize: 80),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  passed ? 'УРОВЕНЬ ПРОЙДЕН!' : 'ПОПРОБУЙ ЕЩЁ!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                // Score display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: passed
                        ? Colors.green.withAlpha(30)
                        : Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: passed ? Colors.green : Colors.orange,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_score / ${_questions.length}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: passed ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        '${percentage.toInt()}%',
                        style: TextStyle(
                          fontSize: 18,
                          color: passed ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // XP + Coins earned. В диалоге всего ~340 px по ширине:
                // два бейджа рядом не влезали (50 px overflow), поэтому
                // Wrap переносит их на новую строку вместо обрезки.
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    // XP badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8A838).withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8A838)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            '+$xpEarned XP',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE8A838),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Coins badge (only if passed). Отступ даёт `spacing` Wrap.
                    if (passed && coinsEarned > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD4AF37)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(
                              '+$coinsEarned',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _JohnVerdict(
                  passed: passed,
                  failedBefore: _failedAttemptsBefore,
                ),
                const SizedBox(height: 20),
                // 🎉 Congratulations Section
                if (passed) ...[
                  // Big animated trophy
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE8A838),
                                Color(0xFFB8821A),
                                Color(0xFFB8821A)
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE8A838).withAlpha(100),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🏆', style: TextStyle(fontSize: 60)),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Congratulations text
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE8A838), Color(0xFFFFA500)],
                    ).createShader(bounds),
                    child: const Text(
                      'ПОЗДРАВЛЯЕМ!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Вы прошли урок!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB8A8D8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Mini trophies row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 500 + (index * 200)),
                        curve: Curves.bounceOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                index < trophies ? '🏆' : '🔒',
                                style: TextStyle(fontSize: 28 + (index * 2)),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ] else ...[
                  // Not passed - show encouragement
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withAlpha(100)),
                    ),
                    child: const Row(
                      children: [
                        Text('📚', style: TextStyle(fontSize: 24)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Не сдавайся! Попробуй ещё раз — повтори материал урока.',
                            style: TextStyle(
                                fontSize: 14, color: Color(0xFFB8A8D8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (passed &&
                    nextLessonHook != null &&
                    nextLessonHook.isNotEmpty) ...[
                  _NextLessonHookCard(text: nextLessonHook),
                  const SizedBox(height: 16),
                ],
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: passed
                          ? const LinearGradient(
                              colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (passed
                                  ? const Color(0xFF4ECDC4)
                                  : const Color(0xFFFF6B9D))
                              .withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        _closeCompletionDialog(passed: passed);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            passed ? '🎓' : '📖',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          // Длинный текст «Вернуться к уроку» в узком диалоге
                          // вылезал за кнопку на 65 px.
                          Flexible(
                            child: Text(
                              passed ? 'К урокам' : 'Вернуться к уроку',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _closeCompletionDialog({required bool passed}) async {
    final navigator = Navigator.of(context);
    navigator.pop(); // Закрываем диалог завершения

    // Если есть награды за блоки — показываем их по очереди
    if (passed && _pendingBlockRewards.isNotEmpty) {
      for (final reward in _pendingBlockRewards) {
        await showBlockRewardDialog(context, reward: reward);
      }
      _pendingBlockRewards = [];
    }

    // Снимаем только сам квиз: теория и список уроков остаются в стеке.
    // Раньше здесь было до трёх `pop()` подряд — они сносили и экран урока,
    // и ученик видел список уроков, так что «выхода из квиза» не было.
    // Маршрут опознаём по имени, но на случай запуска без имени (тесты, deep
    // link) не даём `popUntil` уйти глубже предыдущего экрана.
    final route = ModalRoute.of(context);
    navigator.popUntil((target) =>
        target != route &&
        target.settings.name != QuizScreen.routeName);
  }

  Widget _buildMatchingQuestion(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Выбери пару для каждой карточки:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(question.pairs!.length, (index) {
          final pair = question.pairs![index];
          final left = pair['left']!;
          final correctRight = pair['right']!;
          final selectedRight = _matchingSelections[left];
          final isPairCorrect = selectedRight == correctRight;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _answered
                  ? (isPairCorrect
                      ? Colors.green.withAlpha(30)
                      : Colors.red.withAlpha(30))
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _answered
                    ? (isPairCorrect ? Colors.green : Colors.red)
                    : AppColors.divider,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  left,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Соответствие',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRight,
                      isExpanded: true,
                      hint: const Text('Выбери вариант'),
                      items: _matchingOptions
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            ),
                          )
                          .toList(),
                      onChanged: _answered
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(
                                () => _matchingSelections[left] = value,
                              );
                            },
                    ),
                  ),
                ),
                if (_answered && !isPairCorrect) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Правильно: $correctRight',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        if (!_answered)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _matchingSelections.length == question.pairs!.length
                  ? _submitMatchingAnswer
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Проверить пары'),
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

  Widget _buildMultipleChoiceQuestion(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Можно выбрать несколько ответов:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(question.options!.length, (index) {
          final option = question.options![index];
          final isSelected = _selectedIndices?.contains(index) ?? false;
          final isCorrect =
              question.correctAnswerIndices?.contains(index) ?? false;
          final showResult = _answered;

          Color borderColor;
          Color backgroundColor;

          if (showResult) {
            if (isCorrect) {
              borderColor = Colors.green;
              backgroundColor = Colors.green.withAlpha(30);
            } else if (isSelected && !isCorrect) {
              borderColor = Colors.red;
              backgroundColor = Colors.red.withAlpha(30);
            } else {
              borderColor = AppColors.divider;
              backgroundColor = Colors.transparent;
            }
          } else {
            borderColor = isSelected ? AppColors.primary : AppColors.divider;
            backgroundColor = isSelected
                ? AppColors.primary.withAlpha(30)
                : Colors.transparent;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleMultipleChoice(index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: borderColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        if (!_answered)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _selectedIndices != null && _selectedIndices!.isNotEmpty
                      ? () => _checkMultipleChoice()
                      : null,
              icon: const Icon(Icons.check),
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

  void _checkMultipleChoice() {
    if (_answered) return;

    final question = _questions[_currentQuestionIndex];
    final correctIndices = question.correctAnswerIndices ?? [];

    int correctCount = 0;
    for (final index in _selectedIndices ?? {}) {
      if (correctIndices.contains(index)) {
        correctCount++;
      }
    }

    setState(() {
      _answered = true;
      // Начисляем очки только если все правильные выбраны и нет неправильных
      _isCurrentAnswerCorrect = correctCount == correctIndices.length &&
          correctCount == (_selectedIndices?.length ?? 0);
      if (_isCurrentAnswerCorrect!) {
        _score++;
      }
    });
  }

  Widget _buildSequenceQuestion(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расставь шаги в правильном порядке:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _sequenceOrder.length,
          onReorder: _answered
              ? (_, __) {}
              : (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final step = _sequenceOrder.removeAt(oldIndex);
                    _sequenceOrder.insert(newIndex, step);
                  });
                },
          itemBuilder: (context, index) {
            final step = _sequenceOrder[index];
            final isStepCorrect = question.sequence![index] == step;

            return Container(
              key: ValueKey(step),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _answered
                    ? (isStepCorrect
                        ? Colors.green.withAlpha(30)
                        : Colors.red.withAlpha(30))
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _answered
                      ? (isStepCorrect ? Colors.green : Colors.red)
                      : AppColors.divider,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _answered
                          ? (isStepCorrect ? Colors.green : Colors.red)
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (!_answered)
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.drag_handle,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (_answered && _isCurrentAnswerCorrect == false) ...[
          const SizedBox(height: 4),
          const Text(
            'Правильный порядок:',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...question.sequence!.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
        ],
        const SizedBox(height: 16),
        if (!_answered)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitSequenceAnswer,
              icon: const Icon(Icons.check),
              label: const Text('Проверить порядок'),
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

  Widget _buildSliderQuestion(QuizQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Настройте баланс ползунками:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(question.sliders!.length, (index) {
          final slider = question.sliders![index];
          final name = slider['name'] as String;
          final correctMin = (slider['correctMin'] as num).toDouble();
          final correctMax = (slider['correctMax'] as num).toDouble();
          final value = _sliderValues[index] ?? 0.5;
          final inRange = value >= correctMin && value <= correctMax;
          final pct = (value * 100).toInt();

          // Ползунок в своей карточке: подпись значения, сам трек и строка
          // «Правильно: …» относятся именно к нему, а не к следующему.
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withAlpha(60),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _answered
                      ? (inRange ? Colors.green : Colors.red).withAlpha(120)
                      : AppColors.divider.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Без подписи значения вопрос превращался в угадывание:
                      // три ползунка с шириной зоны 20% дают ~1% шанса.
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              inRange ? Colors.green : AppColors.textSecondary,
                        ),
                      ),
                      if (!_answered && inRange)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(Icons.check_circle,
                              size: 18, color: Colors.green),
                        ),
                    ],
                  ),
                  Slider(
                    value: value,
                    onChanged: _answered
                        ? null
                        : (v) => setState(() => _sliderValues[index] = v),
                    min: 0,
                    max: 1,
                    divisions: 20,
                    label: '$pct%',
                  ),
                  if (_answered)
                    Text(
                      'Правильно: ${(correctMin * 100).toInt()}–${(correctMax * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        if (!_answered)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitSliderAnswer,
              icon: const Icon(Icons.check),
              label: const Text('Готово'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<QuizRepository>(
      builder: (context, quizRepo, _) {
        final lesson =
            context.read<LessonRepository>().getLesson(widget.lessonId);
        final schoolRoom = JohnRoomStyle.roomForBlock(lesson?.blockId);
        final schoolStyle = JohnRoomStyle.forRoom(schoolRoom);
        // Show loading while quizzes are loading
        if (quizRepo.isLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Загрузка квиза...'),
              backgroundColor: AppColors.background,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Загружаю вопросы...',
                      style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
          );
        }

        // If questions are not loaded after loading completes, try loading now
        if (_questions.isEmpty) {
          _loadQuestions();
          if (_questions.isEmpty) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Квиз'),
                backgroundColor: AppColors.background,
              ),
              body: const Center(
                child: Text('Вопросы для этого урока пока недоступны',
                    style: TextStyle(color: AppColors.textPrimary)),
              ),
            );
          }
        }

        // Build the actual quiz UI
        final inTermBlock = _termIndex < _termQuestions.length;
        final question = _questions[_currentQuestionIndex];
        final totalSteps = _totalSteps;
        final progress =
            totalSteps == 0 ? 0.0 : (_currentStep + 1) / totalSteps;
        final stepLabel = _termQuestions.isEmpty
            ? ''
            : (inTermBlock ? 'Термины · ' : 'Вопросы · ');

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: JohnThemedAppBar(
            room: schoolRoom,
            title: 'Квиз • $stepLabel${_currentStep + 1}/$totalSteps',
          ),
          body: JohnRoomBackground(
            room: schoolRoom,
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: schoolStyle.ink,
                  valueColor: AlwaysStoppedAnimation<Color>(schoolStyle.accent),
                  minHeight: 6,
                ),
                if (inTermBlock)
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _TermQuestionView(
                            question: _termQuestions[_termIndex],
                            index: _termIndex,
                            total: _termQuestions.length,
                            selected: _termSelectedAnswer,
                            answered: _termAnswered,
                            room: schoolRoom,
                            style: schoolStyle,
                            onSelect: _selectTermAnswer,
                            onNext: _nextTermQuestion,
                            onSkip: _skipTerms,
                          ),
                        ),
                        // Постоянная нижняя панель: даже если пользователь не
                        // видит кнопку перехода (длинный вопрос, крупный
                        // системный шрифт), «Пропустить» всегда под рукой.
                        // Раньше на последнем термине без выбора варианта
                        // не оставалось ни одной работающей кнопки — отсюда
                        // и ощущение, что из квиза нельзя выйти.
                        _TermBlockFooter(
                          style: schoolStyle,
                          isLast: _termIndex == _termQuestions.length - 1,
                          onNext: _termAnswered ? _nextTermQuestion : null,
                          onSkip: _skipTerms,
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: JohnWoodPanel(
                        room: schoolRoom,
                        highlighted: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              question.question,
                              style: TextStyle(
                                color: schoolStyle.onDark,
                                fontFamily: 'serif',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 32),
                            if (question.type == QuestionType.matching)
                              _buildMatchingQuestion(question)
                            else if (question.type == QuestionType.sequence)
                              _buildSequenceQuestion(question)
                            else if (question.type == QuestionType.slider)
                              _buildSliderQuestion(question)
                            else if (question.type ==
                                QuestionType.multipleChoice)
                              _buildMultipleChoiceQuestion(question)
                            else if (question.options != null &&
                                question.options!.isNotEmpty)
                              ...List.generate(question.options!.length,
                                  (index) {
                                final option = question.options![index];
                                final isSelected = _selectedIndex == index;
                                final isCorrect =
                                    index == question.correctAnswerIndex;
                                final showResult = _answered;

                                Color borderColor;
                                Color backgroundColor;

                                if (showResult) {
                                  if (isCorrect) {
                                    borderColor = Colors.green;
                                    backgroundColor =
                                        Colors.green.withAlpha(30);
                                  } else if (isSelected && !isCorrect) {
                                    borderColor = Colors.red;
                                    backgroundColor = Colors.red.withAlpha(30);
                                  } else {
                                    borderColor = AppColors.divider;
                                    backgroundColor = Colors.transparent;
                                  }
                                } else {
                                  borderColor = isSelected
                                      ? schoolStyle.accent
                                      : AppColors.divider;
                                  backgroundColor = isSelected
                                      ? schoolStyle.accent.withAlpha(30)
                                      : Colors.transparent;
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Material(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _selectAnswer(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: borderColor,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: borderColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  String.fromCharCode(
                                                      65 + index),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  color: schoolStyle.onDark,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (showResult && isCorrect)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              ),
                                            if (showResult &&
                                                isSelected &&
                                                !isCorrect)
                                              const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            if (_answered && _isCurrentAnswerCorrect == false)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: schoolStyle.accent.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: schoolStyle.accent.withAlpha(80),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Пояснение Джона',
                                        style: TextStyle(
                                          color: schoolStyle.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        question.explanation,
                                        style: TextStyle(
                                          color:
                                              schoolStyle.onDark.withAlpha(190),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Interactive questions own their submit action. The persistent
                // footer appears only after evaluation and is then used for Next.
                if (_answered)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: schoolStyle.surface,
                      border: Border(
                        top: BorderSide(
                          color: schoolStyle.accent.withAlpha(100),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _QuizBottomButton(
                        question: question,
                        answered: _answered,
                        isLastQuestion:
                            _currentQuestionIndex == _questions.length - 1,
                        onNext: _nextQuestion,
                        onSubmit: _submitCurrentInteractiveAnswer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows notification when achievement is unlocked
  void _showAchievementNotification(
      BuildContext context, List<String> achievementIds) {
    for (final achievementId in achievementIds) {
      String title = '';
      String icon = '🏆';

      switch (achievementId) {
        case 'perfect_quiz':
          title = 'Перфекционист';
          icon = '💯';
          break;
        default:
          title = achievementId;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎉 Достижение разблокировано!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

/// Нижняя панель блока терминов.
///
/// Живёт вне прокрутки и показывается всегда, поэтому из термина можно
/// уйти в любой момент: «Пропустить» активна всегда, «Дальше» — после
/// выбранного ответа. До этого единственной кнопкой перехода была та, что
/// рисовалась внутри прокручиваемого списка: на последнем термине без
/// ответа квиз выглядел тупиком.
class _TermBlockFooter extends StatelessWidget {
  static const Key skipKey = Key('quiz_term_footer_skip');
  static const Key nextKey = Key('quiz_term_footer_next');

  final JohnRoomStyle style;
  final bool isLast;
  final VoidCallback? onNext;
  final VoidCallback onSkip;

  const _TermBlockFooter({
    required this.style,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final canGoNext = onNext != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: style.surface,
        border: Border(
          top: BorderSide(color: style.accent.withAlpha(100)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: skipKey,
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: style.onDark.withAlpha(210),
                  side: BorderSide(color: style.accent.withAlpha(130)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Пропустить'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                key: nextKey,
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      canGoNext ? style.accent : style.accent.withAlpha(70),
                  foregroundColor: style.ink,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLast ? 'К вопросам урока →' : 'Дальше →',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Один вопрос блока терминов внутри общего квиза.
///
/// Повторяет вид бывшего `TermQuizScreen` (пергаментная карточка,
/// зелёный/красный разбор), но живёт в общем потоке: один прогресс,
/// один результат. Кнопка «К вопросам урока» есть всегда — термины не должны
/// блокировать квиз по уроку.
class _TermQuestionView extends StatelessWidget {
  /// Ключ кнопки перехода: по нему идут тесты, чтобы не путать кнопку
  /// с вариантами ответа.
  static const Key nextKey = Key('quiz_term_next');

  final TermQuizQuestion question;
  final int index;
  final int total;
  final String? selected;
  final bool answered;
  final JohnSchoolRoom room;
  final JohnRoomStyle style;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TermQuestionView({
    required this.question,
    required this.index,
    required this.total,
    required this.selected,
    required this.answered,
    required this.room,
    required this.style,
    required this.onSelect,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = selected == question.correctAnswer;
    final isLast = index == total - 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок блока: сразу видно, что это часть того же квиза.
          Row(
            children: [
              Image.asset(
                'images/ui_icon_book_theory.png',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Термины урока · ${index + 1}/$total',
                  style: TextStyle(
                    color: style.onDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // На системном масштабе 2.0 кнопка не помещается рядом с
              // заголовком — ограничиваем её масштаб и даём сжиматься.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'К вопросам урока',
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: style.accent, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Карточка вопроса
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFCEAB9), Color(0xFFE7C681)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: answered
                    ? (isCorrect ? Colors.green.shade700 : Colors.red.shade700)
                    : style.accent.withAlpha(190),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(95),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                Image.asset(
                  'images/ui_icon_book_theory.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  question.question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    color: style.ink,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Варианты
          ...question.options.map((option) {
            final isSelected = option == selected;
            final isCorrectAnswer = option == question.correctAnswer;

            Color bgColor;
            Color borderColor;
            Color textColor;
            if (!answered) {
              bgColor = const Color(0xFFF4DFAC);
              borderColor = style.accent.withAlpha(190);
              textColor = style.ink;
            } else if (isCorrectAnswer) {
              bgColor = const Color(0xFFDCE8C3);
              borderColor = Colors.green.shade700;
              textColor = const Color(0xFF245229);
            } else if (isSelected) {
              bgColor = const Color(0xFFF1C9B8);
              borderColor = Colors.red.shade700;
              textColor = const Color(0xFF7A241E);
            } else {
              bgColor = const Color(0xFFE9D5A3);
              borderColor = style.accent.withAlpha(100);
              textColor = style.ink.withAlpha(155);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(option),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(55),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (answered && isCorrectAnswer)
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 22),
                        if (answered && isSelected && !isCorrectAnswer)
                          const Icon(Icons.cancel, color: Colors.red, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          if (answered) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? const Color(0xE7224A2C)
                    : const Color(0xE76A351E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrect ? Colors.green.shade400 : style.accent,
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    isCorrect
                        ? 'images/ui_icon_checklist.png'
                        : 'images/ui_icon_book_theory.png',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCorrect
                          ? 'Правильно! Термин запомнен ✓'
                          : 'Не совсем. Попробуй запомнить — ещё раз увидишь в повторении.',
                      style: TextStyle(
                        fontSize: 13,
                        color: style.onDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: nextKey,
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: style.accent,
                foregroundColor: style.ink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLast ? 'К вопросам урока →' : 'Дальше →',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Кнопка «дальше» для вопроса урока.
///
/// Отдельный виджет с `Key`: у `ElevatedButton.icon` внутри есть
/// Material/InkWell, и тесты по типу путали кнопку с вариантами ответа.
class _LessonQuestionNextButton extends StatelessWidget {
  static const Key buttonKey = Key('quiz_lesson_next');

  final bool isLast;
  final VoidCallback onNext;

  const _LessonQuestionNextButton({
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      key: buttonKey,
      onPressed: onNext,
      icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
      label: Text(isLast ? 'Завершить' : 'Далее'),
    );
  }
}

class _NextLessonHookCard extends StatelessWidget {
  final String text;

  const _NextLessonHookCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'images/barista_john_exam.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Дальше по пути',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.4,
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

class _QuizBottomButton extends StatelessWidget {
  final QuizQuestion question;
  final bool answered;
  final bool isLastQuestion;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _QuizBottomButton({
    required this.question,
    required this.answered,
    required this.isLastQuestion,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isSliderQuestion = question.type == QuestionType.slider;
    final canPress = answered || isSliderQuestion;
    final isNext = answered;

    if (isNext) {
      return _LessonQuestionNextButton(
        isLast: isLastQuestion,
        onNext: onNext,
      );
    }

    return ElevatedButton.icon(
      onPressed: canPress
          ? (isNext ? onNext : (isSliderQuestion ? onSubmit : null))
          : null,
      icon: Icon(
        isNext
            ? (isLastQuestion ? Icons.check : Icons.arrow_forward)
            : Icons.check_circle,
      ),
      label: Text(
        isNext
            ? (isLastQuestion ? 'Завершить' : 'Далее')
            : (isSliderQuestion ? 'Готово' : 'Проверить'),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Реплика Джона на экране результата квиза.
///
/// Джон наблюдает, а не оценивает: на провале он не стыдит, а меняет подход.
/// Текст берётся из `johnReactions`, чтобы тон проверялся тестом.
class _JohnVerdict extends StatelessWidget {
  final bool passed;
  final int failedBefore;

  const _JohnVerdict({required this.passed, required this.failedBefore});

  String get _line {
    final johnContext = JohnContext(failedAttemptsBefore: failedBefore);
    if (passed) {
      return johnReaction(JohnMoment.quizPassed, johnContext);
    }
    return failedBefore == 0
        ? johnReaction(JohnMoment.quizFailedFirstTime, johnContext)
        : johnReaction(JohnMoment.quizFailedAgain, johnContext);
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    if (line.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2114),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0A24C).withAlpha(140)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircleAvatar(
              backgroundColor: Color(0xFF4A3720),
              child: Text(
                'Д',
                style: TextStyle(
                  color: Color(0xFFD0A24C),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(
                color: Color(0xFFF3E7D0),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
