import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/term_service.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Mini-quiz for testing term knowledge after a lesson.
/// Shown BEFORE the main lesson quiz — terms must be learned first.
class TermQuizScreen extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback onComplete;

  const TermQuizScreen({
    super.key,
    required this.lesson,
    required this.onComplete,
  });

  @override
  State<TermQuizScreen> createState() => _TermQuizScreenState();
}

class _TermQuizScreenState extends State<TermQuizScreen>
    with SingleTickerProviderStateMixin {
  final TermService _termService = TermService();
  late List<TermQuizQuestion> _questions;
  int _currentIndex = 0;
  int _correctCount = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  final Set<String> _learnedInThisSession = {};

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    final progress = context.read<ProgressService>();
    // Гейт спрашивает только то, что ещё не выучено. Раньше вопросы
    // перемешивались и брались первые N, поэтому урок с 8 терминами
    // требовал 3–4 случайных проходов подряд.
    final learnedTerms = <String>{};
    var unlearned = 0;
    for (final name in widget.lesson.terms) {
      final term = _termService.getTerm(name);
      if (term == null) continue;
      if (progress.isTermLearned(term.russianName)) {
        learnedTerms.add(term.russianName);
      } else {
        unlearned++;
      }
    }
    _questions = _termService.generateQuiz(
      widget.lesson.terms,
      maxQuestions: unlearned == 0 ? 3 : unlearned.clamp(3, 6),
      skipLearned: learnedTerms,
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onAnswerSelected(String answer) {
    if (_showResult) return;
    setState(() {
      _selectedAnswer = answer;
      _showResult = true;
      _isCorrect = answer == _questions[_currentIndex].correctAnswer;
      if (_isCorrect) {
        _correctCount++;
        _learnedInThisSession.add(_questions[_currentIndex].termName);
      }
    });

    if (!_isCorrect) {
      _shakeController.forward(from: 0);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showResult = false;
        _isCorrect = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final progress = context.read<ProgressService>();
    // Mark correctly answered terms as learned
    for (final termName in _learnedInThisSession) {
      progress.markTermLearned(termName);
    }

    // Check if ALL terms across the entire school have been learned
    final allTermNames =
        TermService.allTerms.map((t) => t.russianName).toList();
    if (allTermNames.isNotEmpty &&
        allTermNames.every((name) => progress.isTermLearned(name))) {
      progress.unlockAchievement('all_terms');
    }

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      // No terms to quiz — skip
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
      return const SizedBox.shrink();
    }

    final question = _questions[_currentIndex];
    final progress = context.watch<ProgressService>();
    final totalTerms = widget.lesson.terms.length;
    final learnedBefore = progress.getLearnedTermCount(widget.lesson.terms);
    final room = JohnRoomStyle.roomForBlock(widget.lesson.blockId);
    final style = JohnRoomStyle.forRoom(room);
    final panelTextColor = style.onDark;

    return Scaffold(
      backgroundColor: const Color(0xFF120B08),
      appBar: JohnThemedAppBar(
        room: room,
        title: 'Термины: ${widget.lesson.title}',
        leading: IconButton(
          icon: Icon(Icons.close, color: style.onDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: JohnRoomBackground(
        room: room,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress indicator
                JohnWoodPanel(
                  room: room,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: style.accent.withAlpha(28),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: style.accent.withAlpha(100),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'images/ui_icon_book_theory.png',
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$learnedBefore/$totalTerms выучено',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: panelTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_currentIndex + 1} / ${_questions.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: panelTextColor.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _questions.length,
                          backgroundColor: Colors.black.withAlpha(45),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(style.accent),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Question card
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final shake = _shakeController.isAnimating
                        ? _shakeAnimation.value * 8
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFCEAB9), Color(0xFFE7C681)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _showResult
                            ? (_isCorrect
                                ? Colors.green.shade700
                                : Colors.red.shade700)
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
                        Image.asset('images/ui_icon_book_theory.png',
                            width: 32, height: 32),
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
                ),
                const SizedBox(height: 22),

                // Answer options
                ...question.options.map((option) {
                  final isSelected = option == _selectedAnswer;
                  final isCorrectAnswer = option == question.correctAnswer;

                  Color bgColor;
                  Color borderColor;
                  Color textColor;

                  if (!_showResult) {
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
                        onTap: () => _onAnswerSelected(option),
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
                              if (_showResult && isCorrectAnswer)
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 22),
                              if (_showResult && isSelected && !isCorrectAnswer)
                                const Icon(Icons.cancel,
                                    color: Colors.red, size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const Spacer(),

                // Feedback + Next button
                if (_showResult) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? const Color(0xE7224A2C)
                          : const Color(0xE76A351E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _isCorrect ? Colors.green.shade400 : style.accent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          _isCorrect
                              ? 'images/ui_icon_checklist.png'
                              : 'images/ui_icon_book_theory.png',
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isCorrect
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: style.accent,
                        foregroundColor: style.ink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentIndex < _questions.length - 1
                            ? 'Дальше →'
                            : 'Завершить ($_correctCount/${_questions.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
