import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/repositories/stop_list_repository.dart';
import 'package:coin/core/models/stop_item.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/features/bar_manager/widgets/bar_manager_widgets.dart';

/// Экран стоп-листа — управление ингредиентами которых нет сегодня.
///
/// Логика простая:
///   — TextField + кнопка "Добавить" → добавляет в [StopListRepository]
///   — Список с кнопкой удаления у каждого элемента
///   — Кнопка "Очистить всё" в AppBar (начало новой смены)
class StopListScreen extends StatefulWidget {
  const StopListScreen({super.key});

  @override
  State<StopListScreen> createState() => _StopListScreenState();
}

class _StopListScreenState extends State<StopListScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(StopListRepository repo) {
    repo.add(_ctrl.text);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // context.watch перестраивает экран при каждом изменении репозитория
    final repo = context.watch<StopListRepository>();
    final items = repo.getAll();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.stopListTitle),
        actions: [
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showClearDialog(context, repo, l10n),
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: Text(l10n.stopListClearAll),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            ),
        ],
      ),
      body: Column(
        children: [
          BarAddField(
            controller: _ctrl,
            hintText: l10n.stopListAddHint,
            addLabel: l10n.actionAdd,
            onAdd: () => _add(repo),
          ),
          Expanded(
            child: items.isEmpty
                ? BarEmptyState(
                    icon: Icons.block_rounded,
                    message: l10n.stopListEmpty,
                    hint: l10n.stopListEmptyHint,
                  )
                : BarItemList<StopItem>(
                    items: items,
                    getName: (item) => item.name,
                    onDelete: (item) => repo.remove(item),
                    accentColor: Colors.redAccent,
                  ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(
    BuildContext context,
    StopListRepository repo,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.stopListClearAll,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(l10n.actionConfirmDelete,
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.actionCancel)),
          TextButton(
            onPressed: () {
              repo.clearAll();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
  }
}
