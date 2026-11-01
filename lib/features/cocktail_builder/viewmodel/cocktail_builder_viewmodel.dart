import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:coin/core/repositories/inventory_repository.dart';
import 'package:coin/core/services/api_key_service.dart';
import 'package:coin/features/cocktail_builder/models/generated_cocktail.dart';
import 'package:coin/features/cocktail_builder/models/style_preset.dart';
import 'package:coin/features/cocktail_builder/models/cocktail_types.dart';
import 'package:coin/features/cocktail_builder/services/cocktail_matcher_service.dart';
import 'package:coin/features/cocktail_builder/services/ai_enhancer_service.dart';
import 'package:coin/features/cocktail_builder/services/cocktail_safety_service.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';

// Ключи для SharedPreferences
const _kHasUsedAdvanced = 'cocktail_builder_has_used_advanced';
const _kIsAdvancedExpanded = 'cocktail_builder_is_advanced_expanded';

/// ViewModel для конструктора коктейлей.
///
/// Управляет состоянием экрана:
/// - выбор ингредиентов (только из инвентаря + свои)
/// - настройки вкуса
/// - генерация коктейля (Rule-based по умолчанию, AI опционально)
/// - отображение результата
/// Result of a workshop mission match after generation.
class WorkshopMissionResult {
  final String missionId;
  final String missionTitle;
  final double matchScore;
  final int xpEarned;

  const WorkshopMissionResult({
    required this.missionId,
    required this.missionTitle,
    required this.matchScore,
    required this.xpEarned,
  });
}

class CocktailBuilderViewModel extends ChangeNotifier {
  final CocktailMatcherService _matcher;
  final InventoryRepository _inventory;
  final ApiKeyService _apiKeyService;
  final ProgressService? _progressService;

  // Выбранные ингредиенты
  Set<String> _selectedIngredients = {};

  // Свои ингредиенты (вручную добавленные)
  List<String> _customIngredients = [];

  // ════════════════════════════════════════════════════════════════════════════
  //  🎨 НОВАЯ СИСТЕМА: Пресеты + Умные слайдеры
  // ════════════════════════════════════════════════════════════════════════════

  // Выбранный пресет стиля
  StylePreset? _selectedPreset;

  // Умные слайдеры
  int _balance = 5; // 0-10: Сухой ↔ Сладкий (влияет на sweetness/acidity)
  int _intensity = 5; // 0-10: Лёгкий ↔ Крепкий (влияет на strength)

  // Дополнительные параметры (для тонкой настройки)
  int _strength = 5;
  int _sweetness = 5;
  int _acidity = 5;
  int _bitterness = 2;
  bool _sparkling = false;

  // Контекст подачи
  String _aroma = 'Фруктовый';
  String _texture = 'Лёгкое';

  // Состояния
  bool _isGenerating = false;
  GeneratedCocktail? _generatedCocktail;
  List<MatchedCocktail> _matchedCocktails = []; // Все найденные коктейли
  String? _error;

  // ПАТЧ: Новые поля для вариантов коктейлей
  List<GeneratedCocktail> variants = [];
  GeneratedCocktail? selectedVariant;

  // Режим работы: Помощник (пресеты) / Ручной (свои настройки)
  bool _isHelperMode = true;
  bool get isHelperMode => _isHelperMode;

  void setHelperMode(bool value) {
    if (_isHelperMode != value) {
      _isHelperMode = value;
      if (value) {
        // При переходе в Помощник - сбрасываем пресет
        _selectedPreset = null;
      }
      notifyListeners();
    }
  }

  // 🤖 AI Mode toggle
  bool _isAiEnabled = false;
  bool get isAiEnabled => _isAiEnabled;

  Future<void> setAiEnabled(bool value) async {
    if (value) {
      // Проверяем интернет перед включением AI
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity.contains(ConnectivityResult.none);

      if (isOffline) {
        // Нет интернета - не включаем AI
        debugPrint('⚠️ AI toggle: offline, cannot enable');
        _isAiEnabled = false;

        // Показываем ошибку
        _error =
            '📴 AI режим требует интернет\nПодключитесь к сети и попробуйте снова';
        notifyListeners();
        return;
      }
    }

    _isAiEnabled = value;
    _error = null; // Убираем ошибку если успешно включили
    debugPrint('🤖 AI Mode: $_isAiEnabled');
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  📊 ПРОГРЕССИВНОЕ РАСКРЫТИЕ НАСТРОЕК
  // ════════════════════════════════════════════════════════════════════════════

  bool _isAdvancedExpanded = false;
  bool _hasUsedAdvanced = false;

  bool get isAdvancedExpanded => _isAdvancedExpanded;
  bool get hasUsedAdvanced => _hasUsedAdvanced;

  // Last mission result (for UI snackbar)
  WorkshopMissionResult? _lastMissionResult;
  WorkshopMissionResult? get lastMissionResult => _lastMissionResult;
  void clearMissionResult() => _lastMissionResult = null;

  /// Map cocktail name patterns to mission IDs.
  static const _missionPatterns = {
    'mojito': ('mojito', 'Mojito'),
    'мохито': ('mojito', 'Mojito'),
    'daiquiri': ('daiquiri', 'Daiquiri'),
    'дайкири': ('daiquiri', 'Daiquiri'),
    'negroni': ('negroni', 'Negroni'),
    'негрони': ('negroni', 'Negroni'),
  };

  /// Technique-based mission definitions: method requirement + ingredient categories.
  static const _techniqueMissionDefs = {
    'balance_drill': ('Any', ['citrus', 'sweetener', 'spirit']),
    'sour_fix': ('Any', ['sour', 'spirit']),
    'shake_master': ('Shake', ['spirit', 'juice']),
    'stir_master': ('Stir', ['spirit']),
  };

  /// Human-readable titles for technique missions.
  static const _techniqueMissionTitles = {
    'balance_drill': 'Balance Drill',
    'sour_fix': 'Sour Fix',
    'shake_master': 'Shake Master',
    'stir_master': 'Stir Master',
  };

  /// Maps mission IDs to their corresponding lesson IDs.
  /// When a mission is completed in the workshop, the lesson's practice is marked done.
  static const _missionToLesson = {
    // Block C — cocktail missions
    'mojito': 'lesson_C_09',
    'daiquiri': 'lesson_C_10',
    'negroni': 'lesson_C_11',
    // Blocks A & B — technique missions
    'balance_drill': 'lesson_A_02',
    'sour_fix': 'lesson_A_04',
    'shake_master': 'lesson_B_07',
    'stir_master': 'lesson_B_08',
  };

  CocktailBuilderViewModel({
    required CocktailMatcherService matcher,
    required InventoryRepository inventory,
    required ApiKeyService apiKeyService,
    ProgressService? progressService,
  })  : _matcher = matcher,
        _inventory = inventory,
        _apiKeyService = apiKeyService,
        _progressService = progressService {
    _loadAdvancedSettings();
  }

  /// Загрузить настройки расширенного режима из SharedPreferences
  Future<void> _loadAdvancedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasUsedAdvanced = prefs.getBool(_kHasUsedAdvanced) ?? false;
      _isAdvancedExpanded = prefs.getBool(_kIsAdvancedExpanded) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Ошибка загрузки настроек: $e');
    }
  }

  /// Сохранить настройки расширенного режима
  Future<void> _saveAdvancedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHasUsedAdvanced, _hasUsedAdvanced);
      await prefs.setBool(_kIsAdvancedExpanded, _isAdvancedExpanded);
    } catch (e) {
      debugPrint('⚠️ Ошибка сохранения настроек: $e');
    }
  }

  // ─── Геттеры ──────────────────────────────────────────────────────────────

  /// Только ингредиенты из инвентаря пользователя
  List<String> get availableIngredients {
    return _inventory.getAll().map((i) => i.name).toList()..sort();
  }

  /// Все ингредиенты (инвентарь + свои)
  List<String> get allIngredients {
    final all = {...availableIngredients, ..._customIngredients};
    return all.toList()..sort();
  }

  /// Выбранные ингредиенты
  Set<String> get selectedIngredients => _selectedIngredients;

  /// 🎨 НОВАЯ СИСТЕМА: Пресеты и умные слайдеры
  StylePreset? get selectedPreset => _selectedPreset;
  int get balance => _balance;
  int get intensity => _intensity;

  /// Дополнительные параметры (для тонкой настройки)
  int get strength => _strength;
  int get sweetness => _sweetness;
  int get acidity => _acidity;
  int get bitterness => _bitterness;
  bool get sparkling => _sparkling;

  /// Контекст подачи
  String get aroma => _aroma;
  String get texture => _texture;

  /// Состояния
  bool get isGenerating => _isGenerating;
  GeneratedCocktail? get generatedCocktail => _generatedCocktail;
  List<MatchedCocktail> get matchedCocktails =>
      _matchedCocktails; // Список найденных
  String? get error => _error;

  // ПАТЧ: Геттеры для вариантов
  List<GeneratedCocktail> get variantsList => List.unmodifiable(variants);
  GeneratedCocktail? get currentSelectedVariant => selectedVariant;

  // ─── Методы выбора ингредиентов ───────────────────────────────────────────

  /// Переключить ингредиент
  void toggleIngredient(String name) {
    if (_selectedIngredients.contains(name)) {
      _selectedIngredients.remove(name);
    } else {
      _selectedIngredients.add(name);
    }
    // ✅ Обновляем список найденных коктейлей
    _updateMatchedCocktails();
    notifyListeners();
  }

  /// Обновить список найденных коктейлей (для индикатора)
  void _updateMatchedCocktails() {
    if (_selectedIngredients.length >= 2) {
      _matchedCocktails = _matcher.match(_selectedIngredients.toList());
    } else {
      _matchedCocktails = [];
    }
  }

  /// Выбрать все ингредиенты
  void selectAll() {
    _selectedIngredients = availableIngredients.toSet();
    notifyListeners();
  }

  /// Сбросить все ингредиенты
  void clearIngredients() {
    _selectedIngredients.clear();
    notifyListeners();
  }

  /// Подготовить ингредиенты для учебной практики Level 1.
  ///
  /// Мастерская должна работать даже без заполненного Bar Manager, поэтому
  /// учебные наборы добавляются как custom ingredients и сразу выбираются.
  void prepareLevel1Practice(List<String> ingredients) {
    _selectedIngredients.clear();

    for (final ingredient in ingredients) {
      final trimmed = ingredient.trim();
      if (trimmed.isEmpty) continue;

      if (!_customIngredients.contains(trimmed) &&
          !availableIngredients.contains(trimmed)) {
        _customIngredients.add(trimmed);
      }
      _selectedIngredients.add(trimmed);
    }

    _updateMatchedCocktails();
    notifyListeners();
  }

  // ─── Методы настроек вкуса ────────────────────────────────────────────────

  void setStrength(int value) {
    _strength = value;
    notifyListeners();
  }

  void setSweetness(int value) {
    _sweetness = value;
    notifyListeners();
  }

  void setAcidity(int value) {
    _acidity = value;
    notifyListeners();
  }

  void setBitterness(int value) {
    _bitterness = value;
    notifyListeners();
  }

  void toggleSparkling() {
    _sparkling = !_sparkling;
    notifyListeners();
  }

  void setAroma(String value) {
    debugPrint('🍃 setAroma called: $value');
    _aroma = value;
    notifyListeners();
  }

  void setTexture(String value) {
    debugPrint('🧴 setTexture called: $value');
    _texture = value;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  🎨 НОВЫЕ МЕТОДЫ: Пресеты и умные слайдеры
  // ════════════════════════════════════════════════════════════════════════════

  /// Выбрать пресет стиля — автоматически устанавливает все параметры
  void selectPreset(StylePreset preset) {
    _selectedPreset = preset;
    // Устанавливаем базовые значения из пресета
    _strength = preset.baseStrength;
    _sweetness = preset.baseSweetness;
    _acidity = preset.baseAcidity;
    _bitterness = preset.baseBitterness;
    _sparkling = preset.baseSparkling;
    // Устанавливаем умные слайдеры
    _balance = 5; // баланс по умолчанию
    _intensity = preset.baseStrength; // интенсивность = крепость
    // Контекст подачи
    _aroma = preset.defaultAroma;
    _texture = preset.defaultTexture;
    notifyListeners();
  }

  /// Сбросить пресет (вернуться к ручной настройке)
  void clearPreset() {
    _selectedPreset = null;
    _aroma = 'Фруктовый';
    _texture = 'Лёгкое';
    notifyListeners();
  }

  /// Установить баланс (0-10: Сухой ↔ Сладкий)
  /// Связанные параметры: sweetness и acidity меняются инверсно
  void setBalance(int value) {
    _balance = value.clamp(0, 10);
    // Сладость растёт с балансом
    _sweetness = _balance;
    // Кислотность падает с ростом баланса (но не до нуля)
    _acidity = 10 - _balance;
    notifyListeners();
  }

  /// Установить интенсивность (0-10: Лёгкий ↔ Крепкий)
  /// Влияет на крепость
  void setIntensity(int value) {
    _intensity = value.clamp(0, 10);
    _strength = _intensity;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  📊 ПРОГРЕССИВНОЕ РАСКРЫТИЕ: Методы
  // ════════════════════════════════════════════════════════════════════════════

  /// Переключить видимость расширенных настроек
  Future<void> toggleAdvanced() async {
    _isAdvancedExpanded = !_isAdvancedExpanded;
    if (_isAdvancedExpanded) {
      _hasUsedAdvanced = true;
      // TODO: Log analytics event 'advanced_toggled'
    }
    notifyListeners();
    await _saveAdvancedSettings();
  }

  /// Принудительно установить состояние расширенных настроек (для восстановления)
  Future<void> setAdvancedExpanded(bool value) async {
    _isAdvancedExpanded = value;
    notifyListeners();
    await _saveAdvancedSettings();
  }

  /// Установить флаг использования расширенных настроек (при загрузке из кэша)
  Future<void> setHasUsedAdvanced(bool value) async {
    _hasUsedAdvanced = value;
    notifyListeners();
    await _saveAdvancedSettings();
  }

  // ─── Свои ингредиенты ────────────────────────────────────────────────────

  /// Добавить свой ингредиент
  void addCustomIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // Проверяем нет ли уже такого
    if (!_customIngredients.contains(trimmed)) {
      _customIngredients.add(trimmed);
      // ✅ Обновляем список найденных коктейлей
      _updateMatchedCocktails();
      notifyListeners();
    }
  }

  /// Удалить свой ингредиент
  void removeCustomIngredient(String name) {
    _customIngredients.remove(name);
    // Также убираем из выбранных если был
    _selectedIngredients.remove(name);
    // ✅ Обновляем список найденных коктейлей
    _updateMatchedCocktails();
    notifyListeners();
  }

  /// Список своих ингредиентов
  List<String> get customIngredients => List.unmodifiable(_customIngredients);

  bool get isDatabaseLoaded => _matcher.isDatabaseLoaded;

  // ─── Генерация коктейля ───────────────────────────────────────────────────

  /// Сгенерировать коктейль (Rule-based + AI Enhancer опционально)
  Future<void> generateCocktail() async {
    if (_selectedIngredients.length < 2) {
      _error = '👆 Выберите хотя бы 2 ингредиента';
      notifyListeners();
      return;
    }

    if (!_matcher.isDatabaseLoaded) {
      // Диагностика: почему база не загружена?
      print('⚠️ CocktailBuilder: database NOT loaded!');
      print('   - selectedIngredients: ${_selectedIngredients.length}');
      print('   - isDatabaseLoaded: ${_matcher.isDatabaseLoaded}');

      _error =
          '💡 База коктейлей загружается... Попробуйте через несколько секунд';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🎨 Запуск генерации коктейля (Rule-based)...');

      // Получаем ВСЕ найденные коктейли
      final matchedList = _matcher.match(_selectedIngredients.toList());

      if (matchedList.isEmpty) {
        _error =
            '🍸 Не нашли коктейлей с такими ингредиентами. Попробуйте другие!';
        _isGenerating = false;
        notifyListeners();
        return;
      }

      var cocktail = _matcher.generateSingle(_selectedIngredients.toList());

      // AI Enhancer: улучшаем рецепт если AI mode включен
      if (_isAiEnabled) {
        // 🔧 TEST MODE: используем тестовый ключ если пользователь не ввёл свой
        final userKey = _apiKeyService.apiKey;
        final testKey =
            'sk-test-key-for-debugging'; // ЗАМЕНИТЬ на реальный ключ для теста

        final apiKey = (userKey != null && userKey.isNotEmpty)
            ? userKey
            : testKey; // Fallback на тестовый ключ

        if (apiKey.isNotEmpty && apiKey != 'sk-test-key-for-debugging') {
          debugPrint('🤖 AI Enhancer активен - улучшаем рецепт...');
          final enhancer = AiEnhancerService(apiKey);
          // Передаём настройки слайдеров в AI промпт!
          cocktail = await enhancer.enhance(cocktail,
              balance: _balance, intensity: _intensity);
          debugPrint(
              '✅ AI улучшение применено (balance=$_balance, intensity=$_intensity)');
        } else if (apiKey == 'sk-test-key-for-debugging') {
          debugPrint('⚠️ AI Enhancer: TEST MODE - нужен реальный API ключ');
        } else {
          debugPrint('ℹ️ AI Enhancer не активен - нет API ключа');
        }
      }

      // Сохраняем список и лучший коктейль
      _matchedCocktails = matchedList;
      _generatedCocktail = cocktail;
      _isGenerating = false;
      notifyListeners();

      debugPrint(
          '✅ Найдено ${matchedCocktails.length} коктейлей, показываем список');
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      debugPrint('❌ Ошибка генерации: $e');
    }
  }

  /// Сбросить результат и создать заново
  void createNew() {
    _generatedCocktail = null;
    variants = [];
    selectedVariant = null;
    _error = null;
    notifyListeners();
  }

  // ПАТЧ: Методы выбора варианта
  void selectVariant(GeneratedCocktail cocktail) {
    selectedVariant = cocktail;
    notifyListeners();
  }

  void clearSelectedVariant() {
    selectedVariant = null;
    notifyListeners();
  }

  /// Сохранить в избранное (будет реализовано позже)
  Future<void> addToFavorites() async {
    if (_generatedCocktail == null) return;
    // TODO: Добавить в FavoritesService
    debugPrint('❤️ Сохранено в избранное: ${_generatedCocktail!.name}');
  }

  // ─── Safety Service ─────────────────────────────────────────────────────
  final _safetyService = CocktailSafetyService();

  // Результат последней валидации
  IngredientValidationResult? _lastValidation;
  CombinationValidationResult? _lastCombinationCheck;

  /// Проверить ингредиенты на безопасность (публичный метод)
  IngredientValidationResult validateIngredients() {
    _lastValidation =
        _safetyService.validateIngredients(_selectedIngredients.toList());
    return _lastValidation!;
  }

  /// Проверить сочетания ингредиентов
  CombinationValidationResult validateCombinations() {
    _lastCombinationCheck =
        _safetyService.validateCombination(_selectedIngredients.toList());
    return _lastCombinationCheck!;
  }

  /// Получить предупреждения для начинающих
  List<String> getBeginnerWarnings() {
    return _safetyService.getBeginnerWarnings(
      _selectedIngredients.toList(),
      _strength,
    );
  }

  /// Обнаружить аллергены
  List<String> detectAllergens() {
    return _safetyService.detectAllergens(_selectedIngredients.toList());
  }

  /// Сгенерировать варианты коктейлей (Rule-based + AI Enhancer опционально)
  Future<void> generateVariants({bool useAllIngredients = false}) async {
    if (_selectedIngredients.length < 2) {
      _error = '👆 Выберите хотя бы 2 ингредиента';
      notifyListeners();
      return;
    }

    if (!_matcher.isDatabaseLoaded) {
      // Диагностика: почему база не загружена?
      print('⚠️ CocktailBuilder: database NOT loaded!');
      print('   - selectedIngredients: ${_selectedIngredients.length}');
      print('   - isDatabaseLoaded: ${_matcher.isDatabaseLoaded}');

      _error =
          '💡 База коктейлей загружается... Попробуйте через несколько секунд';
      notifyListeners();
      return;
    }

    final validation =
        _safetyService.validateIngredients(_selectedIngredients.toList());
    final combinationCheck =
        _safetyService.validateCombination(_selectedIngredients.toList());

    if (!validation.isSafe) {
      _error = validation.errors.join('\n');
      notifyListeners();
      return;
    }

    if (!combinationCheck.isSafe &&
        combinationCheck.riskLevel == RiskLevel.critical) {
      _error =
          '🚫 ${combinationCheck.warning}\n${combinationCheck.alternative}';
      notifyListeners();
      return;
    }

    _isGenerating = true;
    _error = null;
    variants = [];
    selectedVariant = null;
    notifyListeners();

    try {
      debugPrint('🎨 Поиск вариантов по базе коктейлей...');

      var cocktails = _matcher.generateVariants(_selectedIngredients.toList());

      // AI Enhancer для вариантов (если включен AI mode)
      if (_isAiEnabled && cocktails.isNotEmpty) {
        final userKey = _apiKeyService.apiKey;
        final testKey =
            'sk-test-key-for-debugging'; // ЗАМЕНИТЬ на реальный ключ

        final apiKey =
            (userKey != null && userKey.isNotEmpty) ? userKey : testKey;

        if (apiKey.isNotEmpty && apiKey != 'sk-test-key-for-debugging') {
          debugPrint(
              '🤖 AI Enhancer активен (${cocktails.length} вариантов)...');
          final enhancer = AiEnhancerService(apiKey);
          final enhanced = <GeneratedCocktail>[];
          for (final c in cocktails) {
            enhanced.add(await enhancer.enhance(c,
                balance: _balance, intensity: _intensity));
          }
          cocktails = enhanced;
          debugPrint(
              '✅ AI улучшение применено (balance=$_balance, intensity=$_intensity)');
        } else if (apiKey == 'sk-test-key-for-debugging') {
          debugPrint('⚠️ AI Enhancer: TEST MODE - нужен реальный API ключ');
        }
      }

      variants = cocktails;
      _isGenerating = false;

      if (cocktails.isEmpty) {
        _error = '🔍 Совпадений не нашли. Попробуйте другие ингредиенты!';
      } else {
        // Check if any variant matches a workshop mission
        _checkMissionMatch(cocktails);
      }

      notifyListeners();

      debugPrint('✅ Найдено вариантов: ${cocktails.length}');
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      debugPrint('❌ Ошибка поиска: $e');
    }
  }

  /// Check if any generated cocktail matches a workshop mission.
  /// When matched, marks the corresponding lesson's practice as complete.
  void _checkMissionMatch(List<GeneratedCocktail> cocktails) {
    if (_progressService == null) return;

    // 1. Name-based matching (Block C: Mojito, Daiquiri, Negroni)
    for (final cocktail in cocktails) {
      if (cocktail.matchScore < 0.5) continue;

      final name = cocktail.name.toLowerCase();
      for (final entry in _missionPatterns.entries) {
        if (name.contains(entry.key)) {
          final (missionId, missionTitle) = entry.value;
          _progressService.incrementWorkshopMission(missionId);
          _progressService.addWorkshopXp(10);
          // Mark lesson practice as complete (Theory → Practice cycle)
          final lessonId = _missionToLesson[missionId];
          if (lessonId != null) {
            _progressService.completeLessonPractice(lessonId);
          }
          _lastMissionResult = WorkshopMissionResult(
            missionId: missionId,
            missionTitle: missionTitle,
            matchScore: cocktail.matchScore,
            xpEarned: 10,
          );
          debugPrint(
              '🎯 Mission matched: $missionTitle (${(cocktail.matchScore * 100).round()}%) → practice done for $lessonId');
          return;
        }
      }
    }

    // 2. Technique-based matching (Blocks A & B)
    for (final cocktail in cocktails) {
      if (cocktail.matchScore < 0.4) continue;

      for (final entry in _techniqueMissionDefs.entries) {
        final missionId = entry.key;
        final (methodReq, categories) = entry.value;

        // Check method
        if (methodReq != 'Any') {
          final methodMatch = (methodReq == 'Shake' &&
                  cocktail.method == CocktailMethod.shake) ||
              (methodReq == 'Stir' && cocktail.method == CocktailMethod.stir);
          if (!methodMatch) continue;
        }

        // Check ingredient categories
        final ingredientNames =
            cocktail.ingredients.map((i) => i.name.toLowerCase()).toList();
        final allCategoriesMet = categories.every(
            (cat) => ingredientNames.any((ing) => _categoryContains(ing, cat)));
        if (!allCategoriesMet) continue;

        // Match found!
        _progressService.incrementWorkshopMission(missionId);
        _progressService.addWorkshopXp(10);
        // Mark lesson practice as complete (Theory → Practice cycle)
        final lessonId = _missionToLesson[missionId];
        if (lessonId != null) {
          _progressService.completeLessonPractice(lessonId);
        }
        final title = _techniqueMissionTitles[missionId] ?? missionId;
        _lastMissionResult = WorkshopMissionResult(
          missionId: missionId,
          missionTitle: title,
          matchScore: cocktail.matchScore,
          xpEarned: 10,
        );
        debugPrint(
            '🎯 Technique mission matched: $title (${(cocktail.matchScore * 100).round()}%) → practice done for $lessonId');
        return;
      }
    }
  }

  /// Check if an ingredient name belongs to a category.
  static bool _categoryContains(String ingredient, String category) {
    const cats = {
      'citrus': ['lime', 'lemon', 'orange', 'grapefruit'],
      'juice': [
        'lime',
        'lemon',
        'orange',
        'grapefruit',
        'cranberry',
        'pineapple',
        'apple',
        'tomato'
      ],
      'spirit': [
        'vodka',
        'gin',
        'rum',
        'tequila',
        'whiskey',
        'bourbon',
        'brandy',
        'light rum',
        'dark rum',
        'white rum'
      ],
      'sweetener': [
        'sugar',
        'powdered sugar',
        'simple syrup',
        'honey',
        'grenadine',
        'syrup'
      ],
      'sour': ['lemon', 'lime', 'citric acid', 'grapefruit'],
    };
    final items = cats[category] ?? [];
    return items.any((item) => ingredient.contains(item));
  }
}
