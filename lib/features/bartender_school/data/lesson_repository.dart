import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';

/// Repository for loading and managing lesson data.
class LessonRepository extends ChangeNotifier {
  List<Lesson> _lessons = [];
  List<Lesson> _level1Lessons = [];
  List<Lesson> _level2Lessons = [];
  List<Lesson> _level3Lessons = [];
  List<Lesson> _wisdomLessons = [];
  bool _isLoading = false;

  List<Lesson> get lessons => List.unmodifiable(_lessons);
  bool get isLoading => _isLoading;

  /// Loads the active curriculum shown in the main application.
  Future<void> loadCoreCurriculum() async {
    await loadLevel1();
    await loadLevel2();
  }

  /// Combines all loaded level lessons into the main list.
  void _combineLessons() {
    _lessons = [..._level1Lessons, ..._level2Lessons, ..._level3Lessons, ..._wisdomLessons];
    print('🎉 Total lessons combined: ${_lessons.length}');
  }

  /// Loads all Level 1 lessons from JSON files.
  Future<void> loadLevel1() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📚 Loading lessons part 1...');

      // Load part 1 (lessons 1-8)
      String part1String;
      try {
        part1String = await rootBundle
            .loadString('data/content/lessons_level1_part1.json');
        print('✅ Part 1 loaded: ${part1String.length} bytes');
      } catch (e) {
        print('❌ Failed to load part 1: $e');
        rethrow;
      }

      final part1List = json.decode(part1String) as List;
      final part1Lessons =
          part1List.map((json) => Lesson.fromJson(json)).toList();
      print('✅ Part 1 parsed: ${part1Lessons.length} lessons');

      print('📚 Loading lessons part 2...');

      // Load part 2 (lessons 9-12)
      String part2String;
      try {
        part2String = await rootBundle
            .loadString('data/content/lessons_level1_part2.json');
        print('✅ Part 2 loaded: ${part2String.length} bytes');
      } catch (e) {
        print('❌ Failed to load part 2: $e');
        rethrow;
      }

      final part2List = json.decode(part2String) as List;
      final part2Lessons =
          part2List.map((json) => Lesson.fromJson(json)).toList();
      print('✅ Part 2 parsed: ${part2Lessons.length} lessons');

      _level1Lessons = [...part1Lessons, ...part2Lessons];
      print('🎉 Level 1 lessons loaded: ${_level1Lessons.length}');
      _combineLessons();
    } catch (e, stackTrace) {
      print('❌ Error loading Level 1 lessons: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads Level 2 lessons from JSON file.
  Future<void> loadLevel2() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📚 Loading Level 2 lessons...');

      String level2String;
      try {
        level2String =
            await rootBundle.loadString('data/content/lessons_level2.json');
        print('✅ Level 2 loaded: ${level2String.length} bytes');
      } catch (e) {
        print('❌ Failed to load Level 2: $e');
        rethrow;
      }

      final level2List = json.decode(level2String) as List;
      final level2Lessons =
          level2List.map((json) => Lesson.fromJson(json)).toList();
      print('✅ Level 2 parsed: ${level2Lessons.length} lessons');

      _level2Lessons = level2Lessons;
      print('🎉 Level 2 lessons loaded: ${_level2Lessons.length}');
      _combineLessons();
    } catch (e, stackTrace) {
      print('❌ Error loading Level 2 lessons: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads Level 3 lessons from JSON file.
  Future<void> loadLevel3() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📚 Loading Level 3 lessons...');

      String level3String;
      try {
        level3String =
            await rootBundle.loadString('data/content/lessons_level3.json');
        print('✅ Level 3 loaded: ${level3String.length} bytes');
      } catch (e) {
        print('❌ Failed to load Level 3: $e');
        rethrow;
      }

      final level3List = json.decode(level3String) as List;
      final level3Lessons =
          level3List.map((json) => Lesson.fromJson(json)).toList();
      print('✅ Level 3 parsed: ${level3Lessons.length} lessons');

      _level3Lessons = level3Lessons;
      print('🎉 Level 3 lessons loaded: ${_level3Lessons.length}');
      _combineLessons();
    } catch (e, stackTrace) {
      print('❌ Error loading Level 3 lessons: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads Wisdom lessons from JSON file.
  Future<void> loadWisdom() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('📚 Loading Wisdom lessons...');

      String wisdomString;
      try {
        wisdomString = await rootBundle.loadString(
          'data/content/lessons_wisdom.json',
        );
        print('✅ Wisdom loaded: ${wisdomString.length} bytes');
      } catch (e) {
        print('❌ Failed to load Wisdom: $e');
        rethrow;
      }

      final wisdomList = json.decode(wisdomString) as List;
      final wisdomLessons = wisdomList
          .map((json) => Lesson.fromJson(json))
          .toList()
        ..sort((a, b) => a.lessonNumber.compareTo(b.lessonNumber));

      _wisdomLessons = wisdomLessons;
      _combineLessons();
      print('🎉 Wisdom lessons loaded: ${_wisdomLessons.length}');
    } catch (e, stackTrace) {
      print('❌ Error loading Wisdom lessons: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets all wisdom lessons.
  List<Lesson> getWisdomLessons() => List.unmodifiable(_wisdomLessons);

  /// Gets all lessons for a specific block.
  List<Lesson> getLessonsForBlock(String blockId) {
    return _lessons.where((lesson) => lesson.blockId == blockId).toList();
  }

  /// Gets a specific lesson by ID.
  Lesson? getLesson(String lessonId) {
    try {
      return _lessons.firstWhere((lesson) => lesson.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  /// Gets the next lesson after the given lesson ID.
  Lesson? getNextLesson(String currentLessonId) {
    final currentIndex = _lessons.indexWhere((l) => l.id == currentLessonId);
    if (currentIndex == -1 || currentIndex >= _lessons.length - 1) {
      return null;
    }
    return _lessons[currentIndex + 1];
  }

  /// Gets all blocks available in loaded lessons.
  List<String> getAvailableBlocks() {
    final blocks = _lessons.map((l) => l.blockId).toSet().toList();
    blocks.sort();
    return blocks;
  }
}



