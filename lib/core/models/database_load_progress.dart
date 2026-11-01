/// Модель прогресса загрузки базы коктейлей
///
/// **Зачем нужен:**
/// - Отслеживает прогресс загрузки 26 букв (A-Z)
/// - Показывает текущую букву
/// - Считает количество загруженных коктейлей
///
/// **Пример использования:**
/// ```dart
/// final progress = DatabaseLoadProgress(
///   currentLetter: 'M',
///   totalLetters: 26,
///   loadedCocktails: 342,
/// );
///
/// print('${progress.letterProgress} - ${progress.progressPercent}%');
/// // 'M - 50%'
/// ```
class DatabaseLoadProgress {
  /// Текущая загружаемая буква (A, B, C...)
  final String currentLetter;

  /// Общее количество букв (всегда 26)
  final int totalLetters;

  /// Количество уже загруженных коктейлей
  final int loadedCocktails;

  /// Индекс текущей буквы (0-25)
  final int currentLetterIndex;

  DatabaseLoadProgress({
    required this.currentLetter,
    required this.totalLetters,
    required this.loadedCocktails,
    required this.currentLetterIndex,
  });

  /// Процент загрузки (0-100)
  int get progressPercent =>
      ((currentLetterIndex + 1) / totalLetters * 100).round();

  /// Прогресс в виде "M/26"
  String get letterProgress => '$currentLetter/$totalLetters';

  /// Описание для UI
  String get statusMessage =>
      'Загружаю $currentLetter... (${loadedCocktails} коктейлей)';
}
