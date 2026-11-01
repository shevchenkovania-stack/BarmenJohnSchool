import 'package:flutter/material.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/core/theme/app_theme.dart';
// import 'package:coin/features/bar_manager/stop_list/view/stop_list_screen.dart';
import 'package:coin/features/bar_manager/inventory/view/inventory_screen.dart';
import 'package:coin/features/bar_manager/can_make/view/can_make_screen.dart';
import 'package:coin/features/bar_manager/custom_recipes/view/custom_recipes_screen.dart';
// import 'package:coin/features/bar_manager/price_book/view/price_book_screen.dart';
import 'package:coin/features/guest_mode/view/kiosk_setup_screen.dart';
import 'package:coin/features/cocktail_builder/view/cocktail_builder_screen.dart';
import 'package:coin/features/settings/view/settings_screen.dart';

/// Хаб "Управление баром" — главный экран раздела для барменов.
///
/// Показывает 4 карточки-кнопки, каждая открывает соответствующую функцию.
/// Навигация через Navigator.push — без вложенных табов.
class BarManagerScreen extends StatelessWidget {
  const BarManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.barTitle),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Настройки',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Инвентарь ────────────────────────────────────────────────────────
          _FeatureCard(
            icon: Icons.inventory_2_rounded,
            iconColor: Colors.greenAccent,
            title: l10n.inventoryTitle,
            subtitle: l10n.inventorySubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // ── Что могу приготовить ─────────────────────────────────────────────
          _FeatureCard(
            icon: Icons.local_bar_rounded,
            iconColor: AppColors.primary,
            title: l10n.canMakeTitle,
            subtitle: l10n.canMakeSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CanMakeScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // ── Мои рецепты ──────────────────────────────────────────────────────
          _FeatureCard(
            icon: Icons.menu_book_rounded,
            iconColor: Colors.purpleAccent,
            title: l10n.myRecipesTitle,
            subtitle: l10n.myRecipesSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomRecipesScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // ── Конструктор Коктейлей ─────────────────────────────────----------
          _FeatureCard(
            icon: Icons.auto_awesome_rounded,
            iconColor: AppColors.primary,
            title: 'Конструктор',
            subtitle: 'Создай идеальный коктейль из того что есть',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CocktailBuilderScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // ── Цифровое меню (Киоск) ─────────────────────────────────────────────
          _FeatureCard(
            icon: Icons.tablet_mac_rounded,
            iconColor: AppColors.primary,
            title: l10n.kioskTitle,
            subtitle: l10n.kioskSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KioskSetupScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Карточка функции ─────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            // Лёгкий фон цвета иконки — чтобы иконка выделялась
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
