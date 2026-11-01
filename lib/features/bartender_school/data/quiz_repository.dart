import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:coin/features/bartender_school/domain/entities/quiz.dart';

/// Repository for loading and managing quiz data.
class QuizRepository extends ChangeNotifier {
  final Map<String, Quiz> _quizzes = {};
  final Map<String, Set<String>> _usedQuestionIds = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  
  /// Gets all lesson IDs that have quizzes loaded.
  List<String> get availableLessonIds => _quizzes.keys.toList();

  /// Loads all Level 1 quizzes from JSON files.
  Future<void> loadQuizzes() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📝 Loading quizzes...');
      
      // Load part 1
      final part1String = await rootBundle.loadString(
        'data/content/quizzes_level1_part1.json',
      );
      print('✅ Quiz part 1 loaded: ${part1String.length} bytes');
      final part1List = json.decode(part1String) as List;
      for (final item in part1List) {
        final quiz = Quiz.fromJson(item as Map<String, dynamic>);
        _quizzes[quiz.lessonId] = quiz;
        _usedQuestionIds[quiz.lessonId] = {};
        print('   ✅ Quiz loaded: ${quiz.lessonId} (${quiz.questionPool.length} questions)');
      }

      // Load part 2
      final part2String = await rootBundle.loadString(
        'data/content/quizzes_level1_part2.json',
      );
      print('✅ Quiz part 2 loaded: ${part2String.length} bytes');
      final part2List = json.decode(part2String) as List;
      for (final item in part2List) {
        final quiz = Quiz.fromJson(item as Map<String, dynamic>);
        _quizzes[quiz.lessonId] = quiz;
        _usedQuestionIds[quiz.lessonId] = {};
        print('   ✅ Quiz loaded: ${quiz.lessonId} (${quiz.questionPool.length} questions)');
      }

      // Load Level 2 quizzes
      final level2String = await rootBundle.loadString(
        'data/content/quizzes_level2.json',
      );
      print('✅ Level 2 quizzes loaded: ${level2String.length} bytes');
      final level2List = json.decode(level2String) as List;
      for (final item in level2List) {
        final quiz = Quiz.fromJson(item as Map<String, dynamic>);
        _quizzes[quiz.lessonId] = quiz;
        _usedQuestionIds[quiz.lessonId] = {};
        print('   ✅ Quiz loaded: ${quiz.lessonId} (${quiz.questionPool.length} questions)');
      }

      // Level 3 (legacy lessons_level3.json / quizzes_level3.json) в рантайм
      // не подключается: его уроки не загружаются (loadLevel3 не вызывается),
      // а старые slider-вопросы в формате «options: {…}» роняли всю загрузку
      // квизов. Файлы остаются как черновой материал до миграции на G/H/I.

      print('🎉 Total quizzes loaded: ${_quizzes.length}');
    } catch (e, stackTrace) {
      print('❌ Error loading quizzes: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets 5 random questions for a lesson, excluding previously used ones.
  List<QuizQuestion> getQuestionsForLesson(String lessonId) {
    final quiz = _quizzes[lessonId];
    if (quiz == null) return [];

    final usedIds = _usedQuestionIds[lessonId] ?? {};
    final availableQuestions = quiz.questionPool
        .where((q) => !usedIds.contains(q.id))
        .toList();

    // If we've used all questions, reset the used pool
    if (availableQuestions.length < quiz.questionsPerAttempt) {
      _usedQuestionIds[lessonId] = {};
      availableQuestions.clear();
      availableQuestions.addAll(quiz.questionPool);
    }

    // Shuffle and take questionsPerAttempt
    availableQuestions.shuffle(Random());
    final selected = availableQuestions.take(quiz.questionsPerAttempt).toList();

    // Mark these questions as used
    markQuestionsUsed(lessonId, selected.map((q) => q.id).toList());

    return selected;
  }

  /// Marks questions as used to avoid repetition.
  void markQuestionsUsed(String lessonId, List<String> questionIds) {
    _usedQuestionIds.putIfAbsent(lessonId, () => {});
    _usedQuestionIds[lessonId]!.addAll(questionIds);
  }

  /// Gets the full quiz for a lesson (for checking total questions).
  Quiz? getQuiz(String lessonId) {
    return _quizzes[lessonId];
  }

  /// Resets used questions for a lesson (e.g., for retry).
  void resetUsedQuestions(String lessonId) {
    _usedQuestionIds[lessonId] = {};
  }
}
