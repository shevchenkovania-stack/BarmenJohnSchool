/// Maps cocktails to the Bartender School curriculum.
///
/// Each entry connects a cocktail to:
/// - [lessonId]   — the lesson that teaches it (nullable for free-exploration)
/// - [technique]  — primary method: shake / stir / build / muddle
/// - [blockId]    — school block: A (taste), B (tools), C (classics)
/// - [difficulty] — 1 (easy) / 2 (medium) / 3 (hard)
class CocktailCurriculumService {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final CocktailCurriculumService _instance =
      CocktailCurriculumService._internal();
  factory CocktailCurriculumService() => _instance;
  CocktailCurriculumService._internal();

  // ── Technique labels ───────────────────────────────────────────────────

  static const techniqueLabels = {
    'shake': 'Shake',
    'stir': 'Stir',
    'build': 'Build',
    'muddle': 'Muddle',
    'blend': 'Blend',
    'layered': 'Layered',
  };

  static const techniqueIcons = {
    'shake': '🥃',
    'stir': '🥄',
    'build': '🏗',
    'muddle': '🌿',
    'blend': '🌀',
    'layered': '📐',
  };

  // ── Curriculum entries ─────────────────────────────────────────────────

  static final List<CurriculumEntry> entries = [
    // ── Block C: Classic cocktails (diploma cocktails) ───────────────────
    CurriculumEntry(
      cocktailName: 'Mojito',
      lessonId: 'lesson_C_09',
      technique: 'build',
      blockId: 'C',
      difficulty: 1,
      isDiploma: true,
    ),
    CurriculumEntry(
      cocktailName: 'Daiquiri',
      lessonId: 'lesson_C_10',
      technique: 'shake',
      blockId: 'C',
      difficulty: 1,
      isDiploma: true,
    ),
    CurriculumEntry(
      cocktailName: 'Negroni',
      lessonId: 'lesson_C_11',
      technique: 'stir',
      blockId: 'C',
      difficulty: 2,
      isDiploma: true,
    ),

    // ── Block A: Taste & Balance (technique examples) ────────────────────
    CurriculumEntry(
      cocktailName: 'Margarita',
      lessonId: 'lesson_A_02',
      technique: 'shake',
      blockId: 'A',
      difficulty: 1,
    ),
    CurriculumEntry(
      cocktailName: 'Whiskey Sour',
      lessonId: 'lesson_A_02',
      technique: 'shake',
      blockId: 'A',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Tom Collins',
      lessonId: 'lesson_A_02',
      technique: 'shake',
      blockId: 'A',
      difficulty: 1,
    ),
    CurriculumEntry(
      cocktailName: 'Cosmopolitan',
      lessonId: 'lesson_A_03',
      technique: 'shake',
      blockId: 'A',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Old Fashioned',
      lessonId: 'lesson_A_04',
      technique: 'stir',
      blockId: 'A',
      difficulty: 2,
    ),

    // ── Block B: Tools & Technique ───────────────────────────────────────
    CurriculumEntry(
      cocktailName: 'Moscow Mule',
      lessonId: 'lesson_B_07',
      technique: 'build',
      blockId: 'B',
      difficulty: 1,
    ),
    CurriculumEntry(
      cocktailName: 'Espresso Martini',
      lessonId: 'lesson_B_07',
      technique: 'shake',
      blockId: 'B',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Manhattan',
      lessonId: 'lesson_B_06',
      technique: 'stir',
      blockId: 'B',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Piña Colada',
      lessonId: 'lesson_B_07',
      technique: 'blend',
      blockId: 'B',
      difficulty: 1,
    ),
    CurriculumEntry(
      cocktailName: 'Bloody Mary',
      lessonId: 'lesson_B_05',
      technique: 'build',
      blockId: 'B',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Gin Fizz',
      lessonId: 'lesson_B_07',
      technique: 'shake',
      blockId: 'B',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Aperol Spritz',
      lessonId: 'lesson_B_05',
      technique: 'build',
      blockId: 'B',
      difficulty: 1,
    ),
    CurriculumEntry(
      cocktailName: 'Sidecar',
      lessonId: 'lesson_B_06',
      technique: 'shake',
      blockId: 'B',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Penicillin',
      lessonId: 'lesson_A_04',
      technique: 'shake',
      blockId: 'A',
      difficulty: 3,
    ),
    CurriculumEntry(
      cocktailName: 'Last Word',
      lessonId: 'lesson_A_04',
      technique: 'shake',
      blockId: 'A',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Boulevardier',
      lessonId: 'lesson_C_11',
      technique: 'stir',
      blockId: 'C',
      difficulty: 2,
    ),
    CurriculumEntry(
      cocktailName: 'Pisco Sour',
      lessonId: 'lesson_B_07',
      technique: 'shake',
      blockId: 'B',
      difficulty: 3,
    ),
  ];

  // ── Lookup helpers ─────────────────────────────────────────────────────

  /// Fast name → entry lookup (case-insensitive).
  final Map<String, CurriculumEntry> _byName = {
    for (final e in entries) e.cocktailName.toLowerCase(): e,
  };

  /// Get curriculum entry for a cocktail by name. Returns null if unmapped.
  CurriculumEntry? getEntry(String cocktailName) =>
      _byName[cocktailName.toLowerCase().trim()];

  /// Whether this cocktail is part of the curriculum.
  bool isCurriculumCocktail(String cocktailName) =>
      getEntry(cocktailName) != null;

  /// Get all entries for a specific lesson.
  List<CurriculumEntry> entriesForLesson(String lessonId) =>
      entries.where((e) => e.lessonId == lessonId).toList();

  /// Get all entries for a specific block.
  List<CurriculumEntry> entriesForBlock(String blockId) =>
      entries.where((e) => e.blockId == blockId).toList();

  /// Get all entries for a specific technique.
  List<CurriculumEntry> entriesForTechnique(String technique) =>
      entries.where((e) => e.technique == technique).toList();

  /// All diploma cocktails (linked to lesson completion).
  List<CurriculumEntry> get diplomaCocktails =>
      entries.where((e) => e.isDiploma).toList();

  /// All unique techniques used in curriculum.
  List<String> get allTechniques =>
      entries.map((e) => e.technique).toSet().toList()..sort();
}

/// A single mapping between a cocktail and its curriculum context.
class CurriculumEntry {
  final String cocktailName;
  final String? lessonId;
  final String technique; // shake / stir / build / muddle / blend / layered
  final String blockId; // A / B / C
  final int difficulty; // 1-3
  final bool isDiploma;

  const CurriculumEntry({
    required this.cocktailName,
    this.lessonId,
    required this.technique,
    required this.blockId,
    required this.difficulty,
    this.isDiploma = false,
  });

  /// Human-readable lesson label (e.g. "Урок C09").
  String get lessonLabel {
    if (lessonId == null) return '';
    // lesson_C_09 → C09, lesson_A_02 → A02
    final parts = lessonId!.split('_');
    if (parts.length >= 3) return '${parts[1]}${parts[2]}';
    return lessonId!;
  }
}
