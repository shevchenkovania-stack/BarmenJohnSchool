import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/search/search_viewmodel.dart';
import 'package:coin/features/cocktail_list/widgets/cocktail_tile.dart';
import 'package:coin/l10n/app_localizations.dart';

/// Экран поиска коктейлей по названию.
///
/// Использует API эндпоинт /search.php?s=name
/// Debounce 500 мс — запрос идёт только после паузы в наборе текста.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('🔍 SearchScreen: creating SearchViewModel');
    // Создаём ViewModel прямо здесь — она живёт пока жив этот экран (таб)
    return ChangeNotifierProvider(
      create: (ctx) {
        final vm = SearchViewModel(ctx.read<CocktailRepository>());
        print('🔍 SearchScreen: SearchViewModel created');
        return vm;
      },
      child: const _SearchView(),
    );
  }
}

// ─── View (отдельный StatefulWidget для TextEditingController) ────────────────

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SearchViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppBar(title: Text(AppLocalizations.of(context).searchAppBarTitle)),
      body: Column(
        children: [
          // ── Поле ввода ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              style: const TextStyle(color: AppColors.textPrimary),
              // При каждом символе — передаём в ViewModel (с debounce)
              onChanged: vm.search,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchInputHint,
                prefixIcon: const Icon(Icons.search_rounded),
                // Кнопка очистки поля
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textSecondary),
                        onPressed: () {
                          _ctrl.clear();
                          vm.search('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ── Результаты ────────────────────────────────────────────────────

          Expanded(
            child: Consumer<SearchViewModel>(
              builder: (_, vm, __) {
                // Идёт запрос к API
                if (vm.isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                // Поле пустое — подсказка
                if (!vm.hasSearched) {
                  return const _Placeholder();
                }

                // Ничего не нашли
                if (vm.filteredResults.isEmpty && vm.results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded,
                            size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        const Text(
                          'Ничего не найдено',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                // Список результатов
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: vm.filteredResults.isNotEmpty
                      ? vm.filteredResults.length
                      : vm.results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final results = vm.filteredResults.isNotEmpty
                        ? vm.filteredResults
                        : vm.results;
                    return CocktailTile(cocktail: results[i]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Заглушка "начните вводить" ───────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_bar_rounded,
              color: AppColors.textSecondary, size: 56),
          const SizedBox(height: 16),
          Text(
            l10n.searchPlaceholderText,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.searchPlaceholderHint,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
