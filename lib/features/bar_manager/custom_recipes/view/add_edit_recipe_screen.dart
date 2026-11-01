import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/repositories/custom_recipe_repository.dart';
import 'package:coin/core/repositories/price_repository.dart';
import 'package:coin/core/models/custom_recipe.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/core/utils/unit_converter.dart';
import 'package:coin/l10n/app_localizations.dart';

/// Экран добавления / редактирования авторского рецепта.
///
/// Принимает [recipe]:
///   - null   → создаём новый (заголовок "Новый рецепт")
///   - object → редактируем существующий (заголовок "Редактировать рецепт")
///
/// При сохранении вызывает [CustomRecipeRepository.save()] который сам решает
/// создать новый или обновить существующий по ID.
class AddEditRecipeScreen extends StatefulWidget {
  final CustomRecipe? recipe; // null = новый рецепт

  const AddEditRecipeScreen({super.key, required this.recipe});

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _nameCtrl = TextEditingController();
  final _glassCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();

  // Ингредиенты хранятся как список пар контроллеров [ингредиент, мера]
  final List<List<TextEditingController>> _ingredientRows = [];

  @override
  void initState() {
    super.initState();

    if (widget.recipe != null) {
      // Редактирование: заполняем поля из существующего рецепта
      final r = widget.recipe!;
      _nameCtrl.text = r.name;
      _glassCtrl.text = r.glass;
      _instructionsCtrl.text = r.instructions;
      if (r.sellingPrice > 0) {
        _sellingPriceCtrl.text = r.sellingPrice.toString();
      }

      for (int i = 0; i < r.ingredients.length; i++) {
        _addIngredientRow(
          ingredient: r.ingredients[i],
          measure: i < r.measures.length ? r.measures[i] : '',
        );
      }
    }

    // Добавляем хотя бы одну пустую строку ингредиента
    if (_ingredientRows.isEmpty) {
      _addIngredientRow();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _glassCtrl.dispose();
    _instructionsCtrl.dispose();
    _sellingPriceCtrl.dispose();
    for (final row in _ingredientRows) {
      row[0].dispose();
      row[1].dispose();
    }
    super.dispose();
  }

  void _addIngredientRow({String ingredient = '', String measure = ''}) {
    setState(() {
      _ingredientRows.add([
        TextEditingController(text: ingredient),
        TextEditingController(text: measure),
      ]);
    });
  }

  void _removeIngredientRow(int index) {
    if (_ingredientRows.length <= 1) return; // минимум одна строка
    setState(() {
      _ingredientRows[index][0].dispose();
      _ingredientRows[index][1].dispose();
      _ingredientRows.removeAt(index);
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return; // название обязательно

    // Собираем непустые ингредиенты
    final ingredients = <String>[];
    final measures = <String>[];
    for (final row in _ingredientRows) {
      final ing = row[0].text.trim();
      if (ing.isNotEmpty) {
        ingredients.add(ing);
        measures.add(row[1].text.trim());
      }
    }

    final recipe = CustomRecipe(
      // Если редактируем — сохраняем тот же ID; иначе генерируем новый
      id: widget.recipe?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      ingredients: ingredients,
      measures: measures,
      instructions: _instructionsCtrl.text.trim(),
      glass: _glassCtrl.text.trim(),
      createdAt: widget.recipe?.createdAt ?? DateTime.now(),
      sellingPrice: double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0,
    );

    await context.read<CustomRecipeRepository>().save(recipe);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.recipe == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? l10n.addRecipeTitle : l10n.editRecipeTitle),
        actions: [
          // Кнопка сохранения в AppBar
          TextButton(
            onPressed: _save,
            child: Text(
              l10n.actionSave,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Название ──────────────────────────────────────────────────────
            _buildTextField(
              controller: _nameCtrl,
              hint: l10n.recipeNameHint,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 12),

            // ── Стакан ────────────────────────────────────────────────────────
            _buildTextField(
              controller: _glassCtrl,
              hint: l10n.recipeGlassHint,
              icon: Icons.local_bar_rounded,
            ),
            const SizedBox(height: 20),

            // ── Ингредиенты ───────────────────────────────────────────────────
            Text(
              l10n.recipeIngredientsSection,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // Динамический список строк ингредиентов
            ...List.generate(_ingredientRows.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Поле ингредиента
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _ingredientRows[i][0],
                        hint: l10n.recipeIngredientHint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Поле количества (только цифры)
                    Expanded(
                      child: TextField(
                        controller: _ingredientRows[i][1],
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.recipeMeasureHint,
                          isDense: true,
                        ),
                      ),
                    ),
                    // Кнопка удаления строки
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: AppColors.textSecondary),
                      onPressed: () => _removeIngredientRow(i),
                    ),
                  ],
                ),
              );
            }),

            // Кнопка "Добавить ингредиент"
            TextButton.icon(
              onPressed: _addIngredientRow,
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              label: Text(
                l10n.addIngredientRow,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            // ── Инструкция ────────────────────────────────────────────────────
            Text(
              l10n.detailInstructions,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instructionsCtrl,
              maxLines: 6,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14, height: 1.6),
              decoration: InputDecoration(
                hintText: l10n.recipeInstructionsHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // ── Кнопка сохранить ──────────────────────────────────────────────
            // ── Себестоимость
            _CostCalculatorSection(
              ingredientRows: _ingredientRows,
              sellingPriceCtrl: _sellingPriceCtrl,
            ),
            const SizedBox(height: 24),

            // ── Кнопка сохранить
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Хелпер: стилизованный TextField для форм
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize,
          fontWeight: fontWeight),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            icon != null ? Icon(icon, color: AppColors.textSecondary) : null,
      ),
    );
  }
}

// ─── Калькулятор себестоимости ─────────────────────────────────────────────────────────────────────────────────

/// Блок расчёта себестоимости на экране редактирования рецепта.
///
/// Реальное время: пересчитывается при каждом изменении через [ListenableBuilder].
///
/// Логика:
///   1. Берём названия ингредиентов + мерки из текущих полей
///   2. Ищем цену каждого в PriceRepository по названию (без учёта регистра)
///   3. Парсим мерку в мл через UnitConverter
///   4. Суммируем стоимость всех ингредиентов
class _CostCalculatorSection extends StatefulWidget {
  final List<List<TextEditingController>> ingredientRows;
  final TextEditingController sellingPriceCtrl;

  const _CostCalculatorSection({
    required this.ingredientRows,
    required this.sellingPriceCtrl,
  });

  @override
  State<_CostCalculatorSection> createState() => _CostCalculatorSectionState();
}

class _CostCalculatorSectionState extends State<_CostCalculatorSection> {
  @override
  void initState() {
    super.initState();
    // Пересчитываем когда меняется цена продажи
    widget.sellingPriceCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<PriceRepository>();

    // Считаем себестоимость: проходимся по каждому ингредиенту
    final rows = <Map<String, dynamic>>[];
    double totalCost = 0;
    bool anyPriceFound = false;

    for (final row in widget.ingredientRows) {
      final name = row[0].text.trim();
      final measure = row[1].text.trim();
      if (name.isEmpty) continue;

      final priceEntry = repo.findByName(name);
      final ml = UnitConverter.parseMeasureToMl(measure);

      double? lineCost;
      if (priceEntry != null && ml != null) {
        lineCost = priceEntry.costFor(ml);
        totalCost += lineCost;
        anyPriceFound = true;
      }

      rows.add({
        'name': name,
        'measure': measure,
        'cost': lineCost,
        'currency': priceEntry?.currency ?? '',
      });
    }

    // Если ни для одного ингредиента нет цены — показываем подсказку
    if (!anyPriceFound) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.recipeCostNotAvailable,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Цена продажи и маржа
    final sellingPrice = double.tryParse(widget.sellingPriceCtrl.text) ?? 0;
    final currency = rows.firstWhere(
      (r) => r['currency'] != '',
      orElse: () => {'currency': r'$'},
    )['currency'] as String;

    double? margin;
    if (sellingPrice > 0 && totalCost > 0) {
      margin = (sellingPrice - totalCost) / sellingPrice * 100;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок блока
          Text(
            l10n.recipeCostSection,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),

          // Строчки по каждому ингредиенту
          ...rows.map((r) {
            final cost = r['cost'] as double?;
            final cur = r['currency'] as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r['name'] as String,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                  Text(
                    r['measure'] as String,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cost != null ? '$cur${cost.toStringAsFixed(2)}' : '—',
                    style: TextStyle(
                      color: cost != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 16),

          // Итого — себестоимость
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.recipeCostTotal,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              Text(
                '$currency${totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Поле цены продажи
          TextField(
            controller: widget.sellingPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.recipeCostSellingHint,
              labelText: l10n.recipeCostSelling,
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              prefixText: currency,
              prefixStyle: const TextStyle(color: AppColors.textPrimary),
            ),
          ),

          // Маржа — показываем только если задана цена продажи
          if (margin != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.recipeCostMargin,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${margin.toStringAsFixed(1)}%',
                  style: TextStyle(
                    // Зелёный если маржа > 60%, жёлтый если > 40%, иначе красный
                    color: margin > 60
                        ? Colors.greenAccent
                        : margin > 40
                            ? Colors.orangeAccent
                            : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
