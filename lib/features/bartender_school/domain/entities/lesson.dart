/// Represents a single lesson in the bartender school.
import 'package:coin/features/bartender_school/data/quest_scene.dart';

class Lesson {
  final String id;
  final String blockId; // "A", "B", "C"
  final int lessonNumber; // 1-12
  final String title;
  final String emoji;
  final String shortDescription; // Front of flip card
  final List<String> keyPoints; // 3 thesis points for front
  final List<LessonSlide> slides; // Full lesson content
  final List<String> tools; // ["Jigger", "Shaker"]
  final List<String> terms; // ["Balance", "ABV"]
  final List<String> skills; // ["Acid balance", "Measurement"]
  final int estimatedMinutes;
  final String? unlockCondition; // null = always available, or "lesson_A_04"
  final String? diplomaCocktailId; // For lessons 9-11
  final LessonMentor? mentor;
  final String? historicalStory;
  final String? nextLessonHook;

  Lesson({
    required this.id,
    required this.blockId,
    required this.lessonNumber,
    required this.title,
    required this.emoji,
    required this.shortDescription,
    required this.keyPoints,
    required this.slides,
    this.tools = const [],
    this.terms = const [],
    this.skills = const [],
    this.estimatedMinutes = 5,
    this.unlockCondition,
    this.diplomaCocktailId,
    this.mentor,
    this.historicalStory,
    this.nextLessonHook,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      blockId: json['blockId'] as String,
      lessonNumber: json['lessonNumber'] as int,
      title: json['title'] as String,
      emoji: json['emoji'] as String,
      shortDescription: json['shortDescription'] as String,
      keyPoints: (json['keyPoints'] as List).cast<String>(),
      slides: (json['slides'] as List)
          .map((slide) => LessonSlide.fromJson(slide))
          .toList(),
      tools: (json['tools'] as List?)?.cast<String>() ?? [],
      terms: (json['terms'] as List?)?.cast<String>() ?? [],
      skills: (json['skills'] as List?)?.cast<String>() ?? [],
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 5,
      unlockCondition: json['unlockCondition'] as String?,
      diplomaCocktailId: json['diplomaCocktailId'] as String?,
      historicalStory: json['historicalStory'] as String?,
      nextLessonHook: json['nextLessonHook'] as String?,
      mentor: json['mentor'] == null
          ? null
          : LessonMentor.fromJson(
              Map<String, dynamic>.from(json['mentor'] as Map),
            ),
    );
  }
}

/// Voice of the bartender mentor that guides a lesson.
class LessonMentor {
  final String intro;
  final String whyItMatters;
  final String commonMistake;
  final String barReality;
  final String? examAdvice;

  const LessonMentor({
    required this.intro,
    required this.whyItMatters,
    required this.commonMistake,
    required this.barReality,
    this.examAdvice,
  });

  factory LessonMentor.fromJson(Map<String, dynamic> json) {
    return LessonMentor(
      intro: json['intro'] as String? ?? '',
      whyItMatters: json['whyItMatters'] as String? ?? '',
      commonMistake: json['commonMistake'] as String? ?? '',
      barReality: json['barReality'] as String? ?? '',
      examAdvice: json['examAdvice'] as String?,
    );
  }
}

/// Represents a single slide within a lesson.
class LessonSlide {
  final SlideType type;
  final String title;
  final String content;
  final String? imageUrl;
  final List<String>? bulletPoints;
  final String? mentorNote;
  final String? author;

  /// Варианты сценарного выбора (`choice`).
  ///
  /// У слайдов Мудрости это готовая сцена с тремя ходами и разбором
  /// каждого. Раньше поле не парсилось, и варианты молча терялись.
  final List<SlideChoice>? choices;

  /// Сцена-квест на слайде.
  ///
  /// Если задана — слайд рисуется как сцена (`QuestSceneView`), а не как
  /// обычная теория. Поле необязательное: уроки без сцены работают как
  /// раньше.
  final QuestScene? questScene;

  LessonSlide({
    required this.type,
    required this.title,
    required this.content,
    this.imageUrl,
    this.bulletPoints,
    this.mentorNote,
    this.author,
    this.choices,
    this.questScene,
  });

  factory LessonSlide.fromJson(Map<String, dynamic> json) {
    return LessonSlide(
      type: SlideType.values.firstWhere(
        (e) => e.toString() == 'SlideType.${json['type']}',
        orElse: () => SlideType.theory,
      ),
      title: json['title'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      bulletPoints: (json['bulletPoints'] as List?)?.cast<String>(),
      mentorNote: json['mentorNote'] as String?,
      author: json['author'] as String?,
      choices: (json['choices'] as List?)
          ?.whereType<Map>()
          .map((c) => SlideChoice.fromJson(c.cast<String, dynamic>()))
          .toList(),
      questScene: json['questScene'] is Map
          ? QuestScene.fromJson(
              (json['questScene'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

/// Один ход в сценарном слайде `choice`.
class SlideChoice {
  final String id;
  final String text;
  final bool isCorrect;
  final String explanation;

  const SlideChoice({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.explanation,
  });

  factory SlideChoice.fromJson(Map<String, dynamic> json) {
    return SlideChoice(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

/// Types of lesson slides.
enum SlideType {
  theory,
  toolVisual,
  termAnimation,
  practice,
  barTip, // Bar tip / lifehack from real practice
  balanceTrainer, // Interactive balance trainer with sliders
  checklist, // Pre-service checklist
  interactive, // Interactive calibration with sliders (acid dose)
  failure, // «Моя ошибка» — личная история-провал Джона
  quote, // «Золотое правило» — цитата с автором
  observation, // Наблюдение за гостем («барменский радар»)
  choice, // Сцена с выбором хода и разбором
  silence, // Пауза-вдох без задания
}
