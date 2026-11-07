import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/school_config.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/quiz_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/block_rewards.dart';
import 'package:coin/features/bartender_school/data/daily_quest_service.dart';
import 'package:coin/features/bartender_school/data/john_reactions.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/domain/entities/quiz.dart';
import 'package:coin/features/bartender_school/domain/services/quiz_answer_evaluator.dart';
import 'package:coin/features/bartender_school/presentation/widgets/block_reward_dialog.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Quiz screen - shows 5 random questions from lesson pool.
class QuizScreen extends StatefulWidget {
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

  /// Награды за блоки, которые нужно показать после завершения квиза.
  List<BlockReward> _pendingBlockRewards = [];

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
      print('📝 QuizScreen: Loading questions for lesson ${widget.lessonId}');
      final quizRepo = Provider.of<QuizRepository>(context, listen: false);

      // Wait for quizzes to load if still loading
      if (quizRepo.isLoading) {
        print('   ⏳ Waiting for quizzes to load...');
        _isLoadingQuestions = false;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _loadQuestions();
        });
        return;
      }

      print('   quizRepo available lessons: ${quizRepo.availableLessonIds}');

      _questions = quizRepo.getQuestionsForLesson(widget.lessonId);
      _prepareCurrentInteractiveQuestion();
      print('✅ Loaded ${_questions.length} questions');

      if (_questions.isEmpty) {
        print('⚠️ No questions available for ${widget.lessonId}');
        print('   Available: ${quizRepo.availableLessonIds}');
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
    } catch (e, stackTrace) {
      print('❌ Error loading quiz questions: $e');
      print('Stack trace: $stackTrace');

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
    final percentage =
        _questions.isEmpty ? 100 : (_score / _questions.length * 100);

    // Порог берём из данных квиза (passingScore — число верных ответов),
    // а если его там нет — общий процент школы. Так один и тот же урок
    // не может «провалиться» из-за разного числа вопросов в попытке.
    final quiz = context.read<QuizRepository>().getQuiz(widget.lessonId);
    final requiredCorrect = quiz?.passingScore;
    final passed = requiredCorrect != null
        ? _score >= requiredCorrect
        : percentage >= BartenderSchoolConfig.quizPassingScore;

    // Сколько раз этот квиз уже проваливали до текущей попытки: от этого
    // зависит, что Джон скажет — «пойдём ещё раз» или «дело не в памяти».
    final failedBefore = progressService.quizFailedAttempts(widget.lessonId);
    if (!passed) progressService.registerQuizFailure(widget.lessonId);

    // Реплика Джона вместо безликого «Попробуй ещё»: он не оценивает
    // результат, а предлагает следующий шаг.
    final johnLine = johnReaction(
      passed
          ? JohnMoment.quizPassed
          : (failedBefore == 0
              ? JohnMoment.quizFailedFirstTime
              : JohnMoment.quizFailedAgain),
      JohnContext(failedAttemptsBefore: failedBefore, streak: progressService.streak),
    );
    final xpEarned = passed ? BartenderSchoolConfig.xpPerLesson : 0;

    // Coins earned based on performance (base + quiz bonus)
    final coinsEarned = passed
        ? BartenderSchoolConfig.coinsPerLesson +
            BartenderSchoolConfig.coinsQuizBonus(percentage.toInt())
        : 0;

    // Only a passed quiz completes the lesson. Failed attempts should not
    // unlock the next step or make the certificate meaningless.
    if (passed) {
      progressService.completeLesson(
        widget.lessonId,
        score: percentage.toInt(),
        xpEarned: xpEarned,
      );

      // Начисляем монеты за урок
      progressService.earnCoins(coinsEarned);

      // Ежедневные задания: урок пройден + квиз на 80%+
      final questService = context.read<DailyQuestService>();
      questService.completeQuest(DailyQuestType.completeLesson).then((reward) {
        if (reward > 0) progressService.earnCoins(reward);
      });
      if (percentage.toInt() >= 80) {
        questService.completeQuest(DailyQuestType.passQuiz).then((reward) {
          if (reward > 0) progressService.earnCoins(reward);
        });
      }

      // Проверяем, завершён ли какой-то блок (награды за блоки)
      _pendingBlockRewards = progressService.getNewlyCompletedBlockRewards();
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
    // Повторный проход не должен превращать уже засчитанный урок в
    // «проваленный»: статус и XP не откатываются.
    final alreadyCompleted =
        progressService.getLessonStatus(widget.lessonId) ==
            LessonStatus.completed;
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
                  passed ? 'УРОК ЗАСЧИТАН' : 'ПОПРОБУЙ ЕЩЁ!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                // Джон говорит по делу: не «молодец», а что делать дальше.
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(70)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'images/barista_john.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 28),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          johnLine,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
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
                      // Если урок уже был засчитан, провал попытки ничего
                      // не отменяет — говорим об этом прямо, чтобы ученик
                      // не думал, что потерял прогресс.
                      if (!passed && alreadyCompleted)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Урок уже засчитан — прогресс сохранён.\nЭту попытку можно считать тренировкой.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (passed && requiredCorrect != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Порог урока: $requiredCorrect из ${_questions.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // XP + Coins earned
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    // Coins badge (only if passed)
                    if (passed && coinsEarned > 0) ...[
                      const SizedBox(width: 12),
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
                  ],
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
                      color: AppColors.textSecondary,
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
                                fontSize: 14, color: AppColors.textSecondary),
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
                      // Бирюза/розовый были из другого (неонового) набора и
                      // спорили с золотом школы. Держим одну палитру: золото
                      // для успеха, янтарь для «попробуй ещё».
                      gradient: LinearGradient(
                        colors: passed
                            ? const [
                                Color(0xFFD9A54A),
                                Color(0xFFB8821A),
                              ]
                            : const [
                                Color(0xFFD0824A),
                                Color(0xFF9E5A2A),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (passed
                                  ? const Color(0xFFD9A54A)
                                  : const Color(0xFFD0824A))
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

    // Навигация назад
    if (passed) {
      for (var i = 0; i < 3 && navigator.canPop(); i++) {
        navigator.pop();
      }
    } else if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildMatchingQuestion(QuizQuestion question) {
    final style = _currentStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Выбери пару для каждой карточки:',
          style: TextStyle(
            color: style.onDark.withAlpha(185),
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
                  : style.surfaceLight.withAlpha(150),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _answered
                    ? (isPairCorrect ? Colors.green : Colors.red)
                    : style.accent.withAlpha(120),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  left,
                  style: TextStyle(
                    color: style.onDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Соответствие',
                    labelStyle: TextStyle(color: style.onDark.withAlpha(170)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: style.accent.withAlpha(120),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: style.accent),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRight,
                      isExpanded: true,
                      dropdownColor: style.surfaceLight,
                      style: TextStyle(color: style.onDark, fontSize: 15),
                      hint: Text(
                        'Выбери вариант',
                        style: TextStyle(color: style.onDark.withAlpha(140)),
                      ),
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
                    style: TextStyle(
                      color: style.ink.computeLuminance() > 0.5
                          ? const Color(0xFF9ED97B)
                          : const Color(0xFF2F7A3D),
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
              style: _buttonStyle(style),
            ),
          ),
      ],
    );
  }

  Widget _buildMultipleChoiceQuestion(QuizQuestion question) {
    final style = _currentStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Можно выбрать несколько ответов:',
          style: TextStyle(
            color: style.onDark.withAlpha(185),
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
              borderColor = style.onDark.withAlpha(60);
              backgroundColor = Colors.transparent;
            }
          } else {
            borderColor = isSelected
                ? style.accent
                : style.onDark.withAlpha(60);
            backgroundColor = isSelected
                ? style.accent.withAlpha(30)
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
                          style: TextStyle(
                            color: style.onDark,
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
              style: _buttonStyle(style),
            ),
          ),
      ],
    );
  }

  /// Цвета комнаты Джона для экрана квиза: тело экрана лежит на деревянной
  /// панели, поэтому дефолтные фиолетовые подписи темы здесь выпадают из
  /// палитры.
  JohnRoomStyle get _currentStyle {
    final lesson =
        context.read<LessonRepository>().getLesson(widget.lessonId);
    return JohnRoomStyle.forRoom(JohnRoomStyle.roomForBlock(lesson?.blockId));
  }

  ButtonStyle _buttonStyle(JohnRoomStyle style) => ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: style.accent,
        foregroundColor: style.ink,
        disabledBackgroundColor: style.accent.withAlpha(60),
        disabledForegroundColor: style.ink.withAlpha(140),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

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
    final style = _currentStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Расставь шаги в правильном порядке:',
          style: TextStyle(
            color: style.onDark.withAlpha(185),
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
                    : style.surfaceLight.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _answered
                      ? (isStepCorrect ? Colors.green : Colors.red)
                      : style.accent.withAlpha(120),
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
                          : style.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: style.ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: style.onDark,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (!_answered)
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.drag_handle,
                          color: style.onDark.withAlpha(150),
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
                    style: TextStyle(color: style.onDark.withAlpha(185)),
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
              style: _buttonStyle(style),
            ),
          ),
      ],
    );
  }

  Widget _buildSliderQuestion(QuizQuestion question) {
    final style = _currentStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Настройте баланс ползунками:',
          style: TextStyle(
            color: style.onDark.withAlpha(185),
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
                color: style.surfaceLight.withAlpha(120),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _answered
                      ? (inRange ? Colors.green : Colors.red).withAlpha(120)
                      : style.accent.withAlpha(110),
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
                          style: TextStyle(
                            color: style.onDark,
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
                          color: inRange
                              ? (style.ink.computeLuminance() > 0.5
                                  ? const Color(0xFF9ED97B)
                                  : const Color(0xFF2F7A3D))
                              : style.onDark.withAlpha(170),
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
              style: _buttonStyle(style),
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
        final question = _questions[_currentQuestionIndex];
        final progress = (_currentQuestionIndex + 1) / _questions.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: JohnThemedAppBar(
            room: schoolRoom,
            title:
                'Экзамен • ${_currentQuestionIndex + 1}/${_questions.length}',
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
                          else if (question.type == QuestionType.multipleChoice)
                            _buildMultipleChoiceQuestion(question)
                          else if (question.options != null &&
                              question.options!.isNotEmpty)
                            ...List.generate(question.options!.length, (index) {
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
                                  backgroundColor = Colors.green.withAlpha(30);
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
                                        borderRadius: BorderRadius.circular(12),
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
                                                String.fromCharCode(65 + index),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: schoolStyle,
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
  final JohnRoomStyle style;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _QuizBottomButton({
    required this.question,
    required this.answered,
    required this.isLastQuestion,
    required this.style,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isSliderQuestion = question.type == QuestionType.slider;
    final canPress = answered || isSliderQuestion;
    final isNext = answered;

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
        backgroundColor: style.accent,
        foregroundColor: style.ink,
        disabledBackgroundColor: style.accent.withAlpha(60),
        disabledForegroundColor: style.ink.withAlpha(140),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
