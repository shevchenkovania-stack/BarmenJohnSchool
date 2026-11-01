/// Represents a quiz for a lesson.
class Quiz {
  final String lessonId;
  final List<QuizQuestion> questionPool;
  final int questionsPerAttempt;

  Quiz({
    required this.lessonId,
    required this.questionPool,
    this.questionsPerAttempt = 5,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      lessonId: json['lessonId'] as String,
      questionPool: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      questionsPerAttempt: json['questionsPerAttempt'] as int? ?? 5,
    );
  }
}

/// Represents a single quiz question.
class QuizQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final List<String>? options;
  final int? correctAnswerIndex; // For single choice
  final List<int>? correctAnswerIndices; // For multiple choice
  final String? imageUrl;
  final String explanation;
  
  // For matching type
  final List<Map<String, String>>? pairs;
  
  // For sequence type
  final List<String>? sequence;
  
  // For slider type
  final List<Map<String, dynamic>>? sliders;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options,
    this.correctAnswerIndex,
    this.correctAnswerIndices,
    this.imageUrl,
    required this.explanation,
    this.pairs,
    this.sequence,
    this.sliders,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == 'QuestionType.${json['type']}',
        orElse: () => QuestionType.singleChoice,
      ),
      question: json['question'] as String,
      options: (json['options'] as List?)?.cast<String>(),
      correctAnswerIndex: json['correctAnswerIndex'] as int?,
      correctAnswerIndices: (json['correctAnswerIndices'] as List?)
          ?.cast<int>(),
      imageUrl: json['imageUrl'] as String?,
      explanation: json['explanation'] as String,
      pairs: (json['pairs'] as List?)
          ?.map((p) => Map<String, String>.from(p))
          .toList(),
      sequence: (json['sequence'] as List?)?.cast<String>(),
      sliders: (json['sliders'] as List?)
          ?.map((s) => Map<String, dynamic>.from(s))
          .toList(),
    );
  }
}

/// Types of quiz questions.
enum QuestionType {
  singleChoice,
  multipleChoice, // Multiple correct answers
  trueFalse,
  imageMatch,
  dragOrder,
  matching, // Drag & Drop matching (e.g., citrus to cocktail)
  slider, // Interactive slider for balance
  sequence, // Order of actions
}
