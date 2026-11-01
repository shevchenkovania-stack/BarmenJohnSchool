import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/repositories/inventory_repository.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';

/// Экран инвентаря — визуальный каталог ингредиентов.
///
/// Бармен видит сетку ингредиентов с картинками.
/// Тап = добавить/убрать из инвентаря (зелёный = есть в баре).
/// Вкладка "Каталог" — ингредиенты из базы TheCocktailDB.
/// Вкладка "Свои" — вручную добавленные позиции.
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchCtrl = TextEditingController();
  final _customCtrl = TextEditingController();
  String _query = '';
  bool _showOnlyInStock = false; // Фильтр "только в наличии"
  Set<String>? _frozenFilterSet; // Зафиксированный список выбранных при фильтре

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(
        () => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inventory = context.watch<InventoryRepository>();
    final cocktailRepo = context.read<CocktailRepository>();
    final allIngredients = cocktailRepo.getAllIngredientNames();
    final inStockCount = inventory.getAll().length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.inventoryTitle),
        actions: [
          // Кнопка-фильтр "In Stock"
          if (inStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showOnlyInStock = !_showOnlyInStock;
                    // При включении фильтра — сохраняем текущий выбранных
                    // При выключении — очищаем
                    if (_showOnlyInStock) {
                      _frozenFilterSet = inventory
                          .getAll()
                          .map((i) => i.name.toLowerCase())
                          .toSet();
                    } else {
                      _frozenFilterSet = null;
                    }
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showOnlyInStock
                        ? Colors.greenAccent.withOpacity(0.3)
                        : Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.greenAccent,
                      width: _showOnlyInStock ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    l10n.inventorySelected(inStockCount),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.inventoryTabCatalog),
            Tab(text: l10n.inventoryTabCustom),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Вкладка 1: Каталог из базы ───────────────────────────────────
          _CatalogTab(
            allIngredients: allIngredients,
            query: _query,
            searchCtrl: _searchCtrl,
            inventory: inventory,
            showOnlyInStock: _showOnlyInStock,
            frozenFilterSet: _frozenFilterSet,
          ),
          // ── Вкладка 2: Свои ингредиенты ──────────────────────────────────
          _CustomTab(
            inventory: inventory,
            allCatalogNames: allIngredients.map((n) => n.toLowerCase()).toSet(),
            customCtrl: _customCtrl,
            showOnlyInStock: _showOnlyInStock,
          ),
        ],
      ),
    );
  }
}

// ─── Вкладка 1: каталог с картинками ─────────────────────────────────────────

class _CatalogTab extends StatelessWidget {
  final List<String> allIngredients;
  final String query;
  final TextEditingController searchCtrl;
  final InventoryRepository inventory;
  final bool showOnlyInStock;
  final Set<String>? frozenFilterSet;

  const _CatalogTab({
    required this.allIngredients,
    required this.query,
    required this.searchCtrl,
    required this.inventory,
    required this.showOnlyInStock,
    this.frozenFilterSet,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Фильтрация: поиск + наличие
    var filtered = query.isEmpty
        ? allIngredients
        : allIngredients.where((n) => n.toLowerCase().contains(query)).toList();

    // Если фильтр In Stock активен, показываем только из сохранённого набора
    // Элементы остаются видимыми даже после анчека — чтобы пользователь видел что делает
    if (showOnlyInStock && frozenFilterSet != null) {
      filtered = filtered
          .where((n) => frozenFilterSet!.contains(n.toLowerCase()))
          .toList();
    }

    if (allIngredients.isEmpty) {
      return Column(
        children: [
          _SearchBar(controller: searchCtrl, hint: l10n.inventorySearchHint),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty_rounded,
                      color: AppColors.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text(l10n.inventoryNoCatalog,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(l10n.inventoryNoCatalogHint,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _SearchBar(controller: searchCtrl, hint: l10n.inventorySearchHint),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final name = filtered[i];
              final inStock = inventory.has(name);
              return _IngredientCard(
                name: name,
                inStock: inStock,
                onTap: () => inStock
                    ? inventory.removeByName(name)
                    : inventory.add(name),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Вкладка 2: свои ингредиенты ─────────────────────────────────────────────

class _CustomTab extends StatelessWidget {
  final InventoryRepository inventory;
  final Set<String> allCatalogNames;
  final TextEditingController customCtrl;
  final bool showOnlyInStock;

  const _CustomTab({
    required this.inventory,
    required this.allCatalogNames,
    required this.customCtrl,
    required this.showOnlyInStock,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Только кастомные — те которых нет в базе каталога
    var customItems = inventory
        .getAll()
        .where((item) => !allCatalogNames.contains(item.name.toLowerCase()))
        .toList();

    // Если включен фильтр "только в наличии" - показываем все элементы (они уже в инвентаре)
    // Но для кастомной вкладки это не имеет смысла - все они уже в наличии
    if (showOnlyInStock) {
      // Все customItems уже в инвентаре, так что просто оставляем их
      // Можно добавить дополнительную фильтрацию если нужно
    }

    return Column(
      children: [
        // Поле добавления
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.inventoryAddHint,
                    prefixIcon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                  onSubmitted: (_) => _add(inventory),
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _add(inventory),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: Text(l10n.actionAdd,
                    style: const TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: customItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_box_rounded,
                          color: AppColors.textSecondary, size: 48),
                      const SizedBox(height: 12),
                      Text(l10n.inventoryAddCustom,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: customItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = customItems[i];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.surfaceLight,
                        child: Icon(Icons.local_bar_outlined,
                            color: AppColors.primary, size: 18),
                      ),
                      title: Text(item.name,
                          style: const TextStyle(color: AppColors.textPrimary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textSecondary, size: 20),
                        onPressed: () => inventory.remove(item),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _add(InventoryRepository inventory) {
    final text = customCtrl.text.trim();
    if (text.isEmpty) return;
    inventory.add(text);
    customCtrl.clear();
  }
}

// ─── Карточка ингредиента (сетка) ─────────────────────────────────────────────

class _IngredientCard extends StatelessWidget {
  final String name;
  final bool inStock;
  final VoidCallback onTap;

  const _IngredientCard({
    required this.name,
    required this.inStock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: inStock
              ? Colors.greenAccent.withOpacity(0.08)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inStock ? Colors.greenAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Картинка ингредиента
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                    child: CachedNetworkImage(
                      imageUrl: Cocktail.ingredientThumbUrl(name),
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Icon(
                        Icons.local_bar_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.local_bar_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                // Название
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: inStock
                          ? Colors.greenAccent
                          : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: inStock ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            // Галочка в углу если выбрано
            if (inStock)
              const Positioned(
                top: 6,
                right: 6,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.greenAccent,
                  child:
                      Icon(Icons.check_rounded, size: 12, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Строка поиска ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SearchBar({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: controller.clear,
                )
              : null,
        ),
      ),
    );
  }
}
