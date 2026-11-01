import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/repositories/inventory_repository.dart';
import 'package:coin/core/repositories/stop_list_repository.dart';
import 'package:coin/core/services/cocktail_cache_service.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/features/cocktail_list/widgets/cocktail_tile.dart';
import 'package:coin/features/bar_manager/can_make/models/cocktail_with_availability.dart';
import 'package:coin/features/bar_manager/can_make/widgets/cocktail_with_ingredients_tile.dart';
import 'package:coin/features/cocktail_detail/view/cocktail_detail_screen.dart';

/// Экран "Что могу приготовить сейчас".
///
/// Consumer2 слушает сразу два репозитория — обновляется при изменении любого.
class CanMakeScreen extends StatefulWidget {
  const CanMakeScreen({super.key});

  @override
  State<CanMakeScreen> createState() => _CanMakeScreenState();
}

class _CanMakeScreenState extends State<CanMakeScreen> {
  String _searchQuery = '';
  // Фильтры скрыты - можно добавить позже при необходимости
  // String? _selectedCategory;
  // String? _selectedAlcoholic;
  // String? _selectedGlass;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.canMakeTitle),
      ),
      body: Column(
        children: [
          // Поиск во всю ширину
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск коктейля...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: Consumer2<InventoryRepository, StopListRepository>(
              builder: (context, inventory, stopList, _) {
                // Получаем множества для быстрой проверки (O(1) вместо O(n))
                final available =
                    inventory.getAll().map((i) => i.name.toLowerCase()).toSet();
                final stopped =
                    stopList.getAll().map((s) => s.name.toLowerCase()).toSet();

                // Если инвентарь пуст — нечего фильтровать
                if (available.isEmpty) {
                  return _CanMakeEmpty(
                    icon: Icons.inventory_2_rounded,
                    message: l10n.canMakeEmpty,
                    hint: l10n.canMakeEmptyHint,
                  );
                }

                final cocktailRepo = context.read<CocktailRepository>();
                var allCached = cocktailRepo.getAllCached();

                // 🔥 Если memory cache пуст, пробуем загрузить из Hive (offline)
                if (allCached.isEmpty) {
                  print('📦 CanMake: memory cache empty, trying Hive...');
                  final cacheService = context.read<CocktailCacheService>();
                  allCached = cacheService.loadAll();
                  print('📦 CanMake: loaded ${allCached.length} from Hive');
                }

                // Кэш ещё пустой — идёт фоновая загрузка
                if (allCached.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                            color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          l10n.canMakeLoading,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                // Фильтруем коктейли - создаём список с доступностью
                final allWithAvailability = _createCocktailListWithAvailability(
                    allCached, available, stopped);

                // Применяем фильтрацию
                var filteredWithAvailability = allWithAvailability;

                // Поиск по названию
                if (_searchQuery.isNotEmpty) {
                  filteredWithAvailability =
                      filteredWithAvailability.where((cwa) {
                    return cwa.cocktail.strDrink
                        .toLowerCase()
                        .contains(_searchQuery);
                  }).toList();
                }

                // Фильтры скрыты - можно раскомментировать позже
                // if (_selectedCategory != null) { ... }
                // if (_selectedAlcoholic != null) { ... }
                // if (_selectedGlass != null) { ... }

                // Разделяем на 2 группы
                final canMakeNow = filteredWithAvailability
                    .where((c) => c.canMakeNow)
                    .toList();
                final missingSome = filteredWithAvailability
                    .where((c) => !c.canMakeNow && c.missingCount <= 2)
                    .toList();

                if (allWithAvailability.isEmpty) {
                  return _CanMakeEmpty(
                    icon: Icons.local_bar_rounded,
                    message: l10n.canMakeEmpty,
                    hint: l10n.canMakeEmptyHint,
                  );
                }

                return ListView(
                  children: [
                    // Группа 1: Можно сделать сейчас
                    if (canMakeNow.isNotEmpty) ...[
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '✅ Можно сделать сейчас',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      ...canMakeNow.map((cwa) => CocktailTile(
                            cocktail: cwa.cocktail,
                            onTap: () => _openCocktail(context, cwa.cocktail),
                          )),
                    ],

                    // Группа 2: Не хватает 1-2 ингредиента
                    if (missingSome.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          '⚠️ Не хватает 1-2 ингредиента',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      ...missingSome.map((cwa) => CocktailWithIngredientsTile(
                            cocktailWithAvailability: cwa,
                            onTap: () => _openCocktail(context, cwa.cocktail),
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Возвращает только те коктейли которые можно приготовить.
  ///
  /// Коктейль доступен если:
  ///   — все его ингредиенты есть в [available] (инвентарь)
  ///   — ни один ингредиент не находится в [stopped] (стоп-лист)
  List<Cocktail> _filterCocktails(
    List<Cocktail> cocktails,
    Set<String> available,
    Set<String> stopped,
  ) {
    return cocktails.where((cocktail) {
      if (cocktail.ingredients.isEmpty) return false;

      return cocktail.ingredients.every((ingredient) {
        final lower = ingredient.toLowerCase();
        return available.contains(lower) && !stopped.contains(lower);
      });
    }).toList();
  }

  /// Создаёт список коктейлей с доступностью.
  List<CocktailWithAvailability> _createCocktailListWithAvailability(
    List<Cocktail> cocktails,
    Set<String> available,
    Set<String> stopped,
  ) {
    return cocktails.map((cocktail) {
      return CocktailWithAvailability.check(
        cocktail,
        available,
        stopped,
      );
    }).toList();
  }

  void _openCocktail(BuildContext context, Cocktail cocktail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CocktailDetailScreen(cocktail: cocktail),
      ),
    );
  }
}

// ─── Пустое состояние ─────────────────────────────────────────────────────────

class _CanMakeEmpty extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const _CanMakeEmpty({
    required this.icon,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Шапка секции ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.surfaceLight,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
