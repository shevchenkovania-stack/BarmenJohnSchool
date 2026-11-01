import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/favorites_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/features/menu_builder/service/menu_pdf_service.dart';
import 'package:coin/features/qr_menu/view/qr_menu_screen.dart';

/// Экран конструктора меню.
///
/// Пользователь:
///   1. Вводит название заведения
///   2. Выбирает коктейли из избранного (галочками)
///   3. Выбирает тему оформления (Классика / Модерн / Минимализм)
///   4. Нажимает "Предпросмотр PDF" — открывается диалог с PDF
///   5. Нажимает "Печать" — отправляет на принтер или сохраняет PDF
class MenuBuilderScreen extends StatefulWidget {
  const MenuBuilderScreen({super.key});

  @override
  State<MenuBuilderScreen> createState() => _MenuBuilderScreenState();
}

class _MenuBuilderScreenState extends State<MenuBuilderScreen> {
  // ─── Состояние ────────────────────────────────────────────────────────────

  /// Название заведения которое попадёт в шапку меню
  final _venueController = TextEditingController();

  /// IDs of cocktails included in the menu
  final Set<String> _selectedIds = {};

  /// Per-cocktail menu price controllers (key = idDrink)
  final Map<String, TextEditingController> _priceControllers = {};

  /// Currently selected PDF theme
  String _theme = 'classic';

  /// Returns (or creates) the price TextEditingController for a cocktail
  TextEditingController _priceCtrlFor(String id) =>
      _priceControllers.putIfAbsent(id, () => TextEditingController());

  @override
  void dispose() {
    _venueController.dispose();
    for (final ctrl in _priceControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ─── Построение UI ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.menuBuilderTitle),
      ),
      // Bottom bar: PDF button only (QR moved to Kiosk)
      bottomNavigationBar: _BottomBar(
        selectedCount: _selectedIds.length,
        onPreview: _selectedIds.isEmpty ? null : _onPreview,
        l10n: l10n,
      ),
      body: Consumer<FavoritesService>(
        builder: (_, fav, __) {
          final cocktails = fav.favorites;

          // Нет избранных — подсказка добавить
          if (cocktails.isEmpty) {
            return _EmptyState(l10n: l10n);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Поле: название заведения
              _VenueField(controller: _venueController, l10n: l10n),
              const SizedBox(height: 20),

              // Выбор темы PDF
              _ThemeSelector(
                selected: _theme,
                onChanged: (t) => setState(() => _theme = t),
                l10n: l10n,
              ),
              const SizedBox(height: 20),

              // Счётчик выбранных + кнопки "все / снять"
              _SelectionHeader(
                total: cocktails.length,
                selectedCount: _selectedIds.length,
                onSelectAll: () => setState(() {
                  _selectedIds.addAll(cocktails.map((c) => c.idDrink));
                }),
                onDeselectAll: () => setState(() => _selectedIds.clear()),
                l10n: l10n,
              ),
              const SizedBox(height: 8),

              // Cocktail list with checkboxes and price input
              ...cocktails.map((c) => _CocktailCheckTile(
                    cocktail: c,
                    isSelected: _selectedIds.contains(c.idDrink),
                    priceCtrl: _priceCtrlFor(c.idDrink),
                    onToggle: () => setState(() {
                      _selectedIds.contains(c.idDrink)
                          ? _selectedIds.remove(c.idDrink)
                          : _selectedIds.add(c.idDrink);
                    }),
                  )),
            ],
          );
        },
      ),
    );
  }

  // ─── Действия ─────────────────────────────────────────────────────────────

  /// Collects prices from controllers into a clean map
  Map<String, double> _collectPrices() {
    final prices = <String, double>{};
    for (final entry in _priceControllers.entries) {
      final val = double.tryParse(entry.value.text.trim());
      if (val != null && val > 0) prices[entry.key] = val;
    }
    return prices;
  }

  /// Opens PDF preview with selected cocktails and their prices
  Future<void> _onPreview() async {
    final fav = context.read<FavoritesService>();

    // Collect only selected cocktails in display order
    final selected =
        fav.favorites.where((c) => _selectedIds.contains(c.idDrink)).toList();

    await MenuPdfService.previewAndPrint(
      context: context,
      venueName: _venueController.text.trim(),
      cocktails: selected,
      theme: _theme,
      prices: _collectPrices(),
    );
  }
}

// ─── Поле названия заведения ──────────────────────────────────────────────────

class _VenueField extends StatelessWidget {
  final TextEditingController controller;
  final AppLocalizations l10n;

  const _VenueField({required this.controller, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: l10n.menuBuilderVenueHint,
        prefixIcon: const Icon(Icons.storefront_rounded),
      ),
    );
  }
}

// ─── Выбор темы оформления ────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final AppLocalizations l10n;

  const _ThemeSelector({
    required this.selected,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    // Три темы: ключ → подпись
    final themes = {
      'classic': l10n.menuBuilderThemeClassic,
      'modern': l10n.menuBuilderThemeModern,
      'minimal': l10n.menuBuilderThemeMinimal,
    };

    return Row(
      children: themes.entries.map((e) {
        final isSelected = e.key == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                e.value,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Шапка с кнопками выделения ───────────────────────────────────────────────

class _SelectionHeader extends StatelessWidget {
  final int total;
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final AppLocalizations l10n;

  const _SelectionHeader({
    required this.total,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Счётчик выбранных
        Text(
          l10n.menuBuilderSelected(selectedCount),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        // Выбрать всё
        TextButton(
          onPressed: onSelectAll,
          child: Text(l10n.menuBuilderSelectAll,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        // Снять всё
        TextButton(
          onPressed: onDeselectAll,
          child: Text(l10n.menuBuilderDeselectAll,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}

// ─── Cocktail row with checkbox and optional price input ──────────────────────

class _CocktailCheckTile extends StatelessWidget {
  final Cocktail cocktail;
  final bool isSelected;
  final VoidCallback onToggle;
  final TextEditingController priceCtrl;

  const _CocktailCheckTile({
    required this.cocktail,
    required this.isSelected,
    required this.onToggle,
    required this.priceCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Cocktail thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: cocktail.strDrinkThumb,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.divider,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.divider,
                  child: const Icon(Icons.local_bar_rounded,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Cocktail name
            Expanded(
              child: Text(
                cocktail.strDrink,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),

            // Price input — visible only when selected
            if (isSelected) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                height: 36,
                child: TextField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$',
                    hintText: '0',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppColors.primary.withAlpha(100)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(width: 8),

            // Checkbox icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      key: ValueKey(true), color: AppColors.primary)
                  : const Icon(Icons.radio_button_unchecked_rounded,
                      key: ValueKey(false), color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Нижняя кнопка ────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onPreview;
  final AppLocalizations l10n;

  const _BottomBar({
    required this.selectedCount,
    required this.onPreview,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPreview,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text(l10n.menuBuilderPreview),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Пустое состояние ─────────────────────────────────────────────────────────

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
            const Icon(Icons.menu_book_rounded,
                color: AppColors.textSecondary, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.menuBuilderEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.menuBuilderEmptyHint,
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
