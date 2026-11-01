import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coin/core/models/ingredient_price.dart';
import 'package:coin/core/repositories/price_repository.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'moldova_catalog_sheet.dart';

/// Экран прайс-листа ингредиентов.
///
/// Позволяет вводить:
///   - Название ингредиента
///   - Цену бутылки
///   - Объём бутылки в мл
///
/// На основе этих данных рассчитывается себестоимость ингредиентов
/// в авторских рецептах.
class PriceBookScreen extends StatelessWidget {
  const PriceBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.priceBookTitle),
        actions: [
          // Moldova catalog shortcut — opens a pre-filled spirits list in MDL
          IconButton(
            icon: const Text('🇲🇩', style: TextStyle(fontSize: 22)),
            tooltip: 'Moldova Spirits Catalog',
            onPressed: () => MoldovaCatalogSheet.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openAddEdit(context, null),
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
      body: Consumer<PriceRepository>(
        builder: (_, repo, __) {
          final prices = repo.getAll();

          if (prices.isEmpty) {
            return _EmptyState(l10n: l10n);
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: prices.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) => _PriceTile(
              price: prices[i],
              onEdit: () => _openAddEdit(context, prices[i]),
              onDelete: () => repo.deleteByName(prices[i].name),
            ),
          );
        },
      ),
    );
  }

  /// Открывает диалог добавления или редактирования цены ингредиента
  void _openAddEdit(BuildContext context, IngredientPrice? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // разрешаем высоту по клавиатуре
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddEditSheet(existing: existing),
    );
  }
}

// ─── Строка ингредиента ───────────────────────────────────────────────────────

class _PriceTile extends StatelessWidget {
  final IngredientPrice price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PriceTile({
    required this.price,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Показываем: название | цена бутылки | цена за 1 ml
    final perMl = price.pricePerMl;
    final perMlStr = '${price.currency}${perMl.toStringAsFixed(4)}/ml';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.liquor_rounded, color: AppColors.primary),
      ),
      title: Text(
        price.name,
        style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        // "25$ / 700ml · 0.0357$/ml"
        '${price.currency}${price.bottlePrice.toStringAsFixed(2)} / '
        '${price.bottleSizeMl.toStringAsFixed(0)} ml  ·  $perMlStr',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Диалог добавления / редактирования ──────────────────────────────────────

class _AddEditSheet extends StatefulWidget {
  final IngredientPrice? existing;
  const _AddEditSheet({this.existing});

  @override
  State<_AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<_AddEditSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();

  /// Selected currency from dropdown
  String _selectedCurrency = '\$';

  /// Available currencies
  static const _currencies = ['\$', '€', 'MDL', '₽', '₴', 'BYN', '£'];

  /// Список всех ингредиентов из базы коктейлей
  List<String> _allIngredients = [];

  /// Отфильтрованные подсказки — показываем прямо в форме (без Overlay)
  List<String> _suggestions = [];

  /// Миниатюра выбранного ингредиента
  String? _thumbnailName;

  @override
  void initState() {
    super.initState();
    // При редактировании — заполняем поля существующими значениями
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text = e.name;
      _priceCtrl.text = e.bottlePrice.toString();
      _sizeCtrl.text = e.bottleSizeMl.toString();
      _selectedCurrency = e.currency;
      _thumbnailName = e.name;
    } else {
      _sizeCtrl.text = '700';
      _selectedCurrency = '\$';
    }

    // Слушаем изменения текста в поле названия — фильтруем подсказки
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allIngredients =
        context.read<CocktailRepository>().getAllIngredientNames();
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _sizeCtrl.dispose();
    super.dispose();
  }

  /// Фильтруем список по введённому тексту.
  /// Если текст пуст — список пустой.
  void _onNameChanged() {
    final q = _nameCtrl.text.trim().toLowerCase();
    setState(() {
      _thumbnailName = null; // сбрасываем миниатюру при ручном вводе
      _suggestions = q.isEmpty
          ? []
          : _allIngredients
              .where((n) => n.toLowerCase().contains(q))
              .take(8)
              .toList();
    });
  }

  /// Пользователь выбрал ингредиент из списка.
  void _selectSuggestion(String name) {
    // Сначала снимаем слушатель — иначе сеттер изменит текст и снова откроет список
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.text = name;
    _nameCtrl.addListener(_onNameChanged);
    setState(() {
      _suggestions = [];
      _thumbnailName = name;
    });
    // Убираем фокус с поля — закрывает клавиатуру
    FocusScope.of(context).unfocus();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final size = double.tryParse(_sizeCtrl.text.trim()) ?? 700;

    if (name.isEmpty || price <= 0 || size <= 0) return;

    final entry = IngredientPrice(
      name: name,
      bottlePrice: price,
      bottleSizeMl: size,
      currency: _selectedCurrency,
    );

    await context.read<PriceRepository>().save(entry);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNew = widget.existing == null;

    return SingleChildScrollView(
      // Поднимаем форму над клавиатурой на мобильных устройствах
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            isNew ? l10n.priceBookAddTitle : l10n.priceBookEditTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // ── Название + миниатюра
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Миниатюра — появляется после выбора из списка
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _thumbnailName != null
                    ? ClipRRect(
                        key: ValueKey(_thumbnailName),
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://www.thecocktaildb.com/images/ingredients/'
                              '${Uri.encodeComponent(_thumbnailName!)}-Small.png',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _IngredientIcon(filled: true),
                        ),
                      )
                    : _IngredientIcon(filled: false),
              ),
              const SizedBox(width: 12),

              // Поле ввода названия
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: l10n.priceBookIngredientHint,
                    suffixIcon: _nameCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _nameCtrl.clear();
                              setState(() {
                                _suggestions = [];
                                _thumbnailName = null;
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),

          // ── Список подсказок — появляется прямо под полем, без Overlay
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggestions.map((name) {
                  final thumbUrl =
                      'https://www.thecocktaildb.com/images/ingredients/'
                      '${Uri.encodeComponent(name)}-Small.png';
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    // Тап срабатывает надёжно внутри обычного дерева виджетов
                    onTap: () => _selectSuggestion(name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: thumbUrl,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                  Icons.liquor_rounded,
                                  size: 24,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            name,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 12),

          // ── Цена, объём, валюта
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _LabeledField(
                  label: l10n.priceBookBottlePriceLabel,
                  controller: _priceCtrl,
                  hint: '25.00',
                  numeric: true,
                  icon: Icons.attach_money_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _LabeledField(
                  label: l10n.priceBookBottleSizeLabel,
                  controller: _sizeCtrl,
                  hint: '700',
                  numeric: true,
                  icon: Icons.local_drink_rounded,
                ),
              ),
              const SizedBox(width: 8),
              // Currency dropdown
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.priceBookCurrencyLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          items: _currencies
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null)
                              setState(() => _selectedCurrency = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Кнопка Сохранить
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: Text(l10n.actionSave),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Вспомогательный TextField ────────────────────────────────────────────────

// ─── Иконка ингредиента ────────────────────────────────────────────────────────────────────────────

/// 52x52 плейсхолдер для миниатюры ингредиента.
class _IngredientIcon extends StatelessWidget {
  final bool filled; // true = выбран ингредиент (акцентный цвет)
  const _IngredientIcon({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(filled),
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.liquor_rounded,
        color: filled ? AppColors.primary : AppColors.textSecondary,
        size: 28,
      ),
    );
  }
}

// ─── Поле с подписью

/// Текстовая подпись над полем ввода.
/// Используется в форме прайс-листа чтобы было понятно что вводить.
class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final IconData? icon;

  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.numeric = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Подпись над полем
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
              : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.textSecondary, size: 18)
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ─── Пустое состояние ────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.price_change_rounded,
                color: AppColors.textSecondary, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.priceBookEmpty,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.priceBookEmptyHint,
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
