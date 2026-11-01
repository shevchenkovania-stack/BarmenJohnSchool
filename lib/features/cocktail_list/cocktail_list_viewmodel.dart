import 'package:flutter/material.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/services/cocktail_cache_service.dart';
import 'package:coin/core/services/cocktail_curriculum_service.dart';
import 'package:coin/core/services/virgin_cocktail_service.dart';
import 'package:coin/core/services/virgin_analysis.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';

/// Section types for the curriculum-aware recipe list.
enum RecipeSection {
  myPath, // "Мой путь" — cocktails linked to current progress
  classics, // "Классика Level 1" — diploma cocktails
  byTechnique, // "По технике" — grouped by shake/stir/build
  allRecipes, // "Все" — full 426 cocktail database
}

/// ViewModel экрана "Рецептурник".
///
/// Загружает коктейли из Hive-кэша (offline-first).
/// Показывает в 4 секциях: Мой путь / Классика / По технике / Все.
class CocktailListViewModel extends ChangeNotifier {
  final CocktailRepository _repo;
  final CocktailCacheService _cache;
  final ProgressService _progress;
  final VirginCocktailService _virginService = VirginCocktailService();
  final CocktailCurriculumService _curriculum = CocktailCurriculumService();

  final List<Cocktail> _allCocktails = [];
  String _filter = '';
  bool _virginMode = false;
  String? _techniqueFilter; // null = all techniques
  RecipeSection _activeSection = RecipeSection.myPath;
  bool isLoading = true;
  int totalLoaded = 0;

  /// IDs of cocktails the user has unlocked via lesson completion.
  final Set<String> _unlockedCocktailIds = {};

  CocktailListViewModel(this._repo, this._cache, this._progress) {
    _loadAll();
  }

  // ─── Getters ────────────────────────────────────────────────────────────

  bool get virginMode => _virginMode;
  RecipeSection get activeSection => _activeSection;
  String? get techniqueFilter => _techniqueFilter;
  CocktailCurriculumService get curriculum => _curriculum;

  /// The filtered list for the current section + filters.
  List<Cocktail> get cocktails {
    var list = _allCocktails;

    // Virgin mode
    if (_virginMode) {
      final virginList = <Cocktail>[];
      for (final cocktail in list) {
        final virginCocktail =
            _virginService.createVirginFromCocktail(cocktail);
        if (virginCocktail != null) {
          virginList.add(virginCocktail);
        }
      }
      list = virginList;
    }

    // Text filter
    if (_filter.isNotEmpty) {
      final q = _filter.toLowerCase();
      list = list.where((c) => c.strDrink.toLowerCase().contains(q)).toList();
    }

    // Section-specific filtering
    switch (_activeSection) {
      case RecipeSection.myPath:
        // Show only cocktails that user has practiced (stars > 0)
        list = list
            .where((c) => _progress.getPracticeStarsByCocktail(c.strDrink) > 0)
            .toList();
        break;
      case RecipeSection.classics:
        // Diploma cocktails only
        final diplomaNames = _curriculum.diplomaCocktails
            .map((e) => e.cocktailName.toLowerCase())
            .toSet();
        list = list
            .where((c) => diplomaNames.contains(c.strDrink.toLowerCase()))
            .toList();
        break;
      case RecipeSection.byTechnique:
        // Filter by technique if selected
        if (_techniqueFilter != null) {
          final techniqueNames = _curriculum
              .entriesForTechnique(_techniqueFilter!)
              .map((e) => e.cocktailName.toLowerCase())
              .toSet();
          list = list
              .where((c) => techniqueNames.contains(c.strDrink.toLowerCase()))
              .toList();
        } else {
          // Show all curriculum cocktails
          list = list
              .where((c) => _curriculum.isCurriculumCocktail(c.strDrink))
              .toList();
        }
        break;
      case RecipeSection.allRecipes:
        break; // no filtering
    }

    return List.unmodifiable(list);
  }

  /// Get curriculum cocktails sorted by block for "My Path" section.
  List<Cocktail> get myPathCocktails {
    final curriculumNames = CocktailCurriculumService.entries
        .map((e) => e.cocktailName.toLowerCase())
        .toSet();

    var list = _allCocktails
        .where((c) => curriculumNames.contains(c.strDrink.toLowerCase()))
        .toList();

    if (_filter.isNotEmpty) {
      final q = _filter.toLowerCase();
      list = list.where((c) => c.strDrink.toLowerCase().contains(q)).toList();
    }

    // Sort by block → difficulty → name
    list.sort((a, b) {
      final entryA = _curriculum.getEntry(a.strDrink);
      final entryB = _curriculum.getEntry(b.strDrink);
      if (entryA == null || entryB == null) return 0;
      final blockCmp = entryA.blockId.compareTo(entryB.blockId);
      if (blockCmp != 0) return blockCmp;
      final diffCmp = entryA.difficulty.compareTo(entryB.difficulty);
      if (diffCmp != 0) return diffCmp;
      return a.strDrink.compareTo(b.strDrink);
    });

    return List.unmodifiable(list);
  }

  // ─── Public methods ─────────────────────────────────────────────────────

  void setFilter(String query) {
    _filter = query;
    notifyListeners();
  }

  void setVirginMode(bool value) {
    _virginMode = value;
    notifyListeners();
  }

  void setActiveSection(RecipeSection section) {
    _activeSection = section;
    _techniqueFilter = null; // reset technique when switching sections
    notifyListeners();
  }

  void setTechniqueFilter(String? technique) {
    _techniqueFilter = technique;
    notifyListeners();
  }

  /// Mark cocktail IDs as unlocked (from ProgressService).
  void setUnlockedCocktails(List<String> ids) {
    _unlockedCocktailIds.clear();
    _unlockedCocktailIds.addAll(ids);
    notifyListeners();
  }

  /// Check if a cocktail is unlocked via lesson/practice progress.
  bool isCocktailUnlocked(String cocktailName) {
    // Practice stars = permanently unlocked
    if (_progress.getPracticeStarsByCocktail(cocktailName) > 0) return true;
    // Unlocked via lesson completion or manual mark
    if (_progress.unlockedCocktails.contains(cocktailName)) return true;
    // Non-curriculum cocktails are always accessible
    final entry = _curriculum.getEntry(cocktailName);
    if (entry == null) return true;
    return false;
  }

  /// Count of unlocked cocktails (for collection progress).
  int get unlockedCount {
    return _allCocktails.where((c) => isCocktailUnlocked(c.strDrink)).length;
  }

  // ─── Private methods ────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    // Try Hive cache first (offline-first)
    final cachedCocktails = _cache.loadAll();
    if (cachedCocktails.isNotEmpty) {
      _allCocktails.addAll(cachedCocktails);
      totalLoaded = _allCocktails.length;
      isLoading = false;
      notifyListeners();
      return;
    }

    // Memory cache fallback
    final memoryCocktails = _repo.getAllCached();
    if (memoryCocktails.isNotEmpty) {
      _allCocktails.addAll(memoryCocktails);
      totalLoaded = _allCocktails.length;
      isLoading = false;
      notifyListeners();
      return;
    }

    // API fallback — load by letter
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (final letter in alphabet.split('')) {
      final batch = await _repo.getCocktailsByLetter(letter);
      _allCocktails.addAll(batch);
      totalLoaded = _allCocktails.length;
      if (isLoading && _allCocktails.isNotEmpty) {
        isLoading = false;
      }
      notifyListeners();
    }

    isLoading = false;
    notifyListeners();
    analyzeVirginCapability(_allCocktails);
  }
}
