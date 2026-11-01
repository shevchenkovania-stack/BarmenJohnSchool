import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';

/// Общие виджеты для экранов управления баром (стоп-лист и инвентарь).
/// Вынесены в отдельный файл чтобы не дублировать код.

// ─── Поле добавления ──────────────────────────────────────────────────────────

/// TextField + кнопка "Добавить" в одной строке
class BarAddField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String addLabel;
  final VoidCallback onAdd;

  const BarAddField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.addLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(hintText: hintText),
              onSubmitted: (_) => onAdd(),
              textCapitalization: TextCapitalization.words,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(onPressed: onAdd, child: Text(addLabel)),
        ],
      ),
    );
  }
}

// ─── Список с удалением ───────────────────────────────────────────────────────

/// Список элементов с иконкой удаления у каждой строки
class BarItemList<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T) getName;
  final void Function(T) onDelete;
  final Color accentColor;

  const BarItemList({
    super.key,
    required this.items,
    required this.getName,
    required this.onDelete,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = items[i];
        return ListTile(
          leading: Icon(Icons.circle, color: accentColor, size: 10),
          title: Text(
            getName(item),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.textSecondary),
            onPressed: () => onDelete(item),
          ),
        );
      },
    );
  }
}

// ─── Пустое состояние ─────────────────────────────────────────────────────────

/// Иконка + подпись + подсказка при отсутствии данных
class BarEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const BarEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 56),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
