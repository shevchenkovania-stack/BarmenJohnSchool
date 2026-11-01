import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:coin/core/repositories/cocktail_repository.dart';
import 'package:coin/core/services/cocktail_cache_service.dart';
import 'package:coin/core/services/cocktail_curriculum_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/cocktail_list/cocktail_list_viewmodel.dart';
import 'package:coin/features/cocktail_list/widgets/cocktail_tile.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

class CocktailListScreen extends StatefulWidget {
  const CocktailListScreen({super.key});

  @override
  State<CocktailListScreen> createState() => _CocktailListScreenState();
}

class _CocktailListScreenState extends State<CocktailListScreen> {
  late final CocktailListViewModel _vm;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = CocktailListViewModel(
      context.read<CocktailRepository>(),
      Provider.of<CocktailCacheService>(context, listen: false),
      Provider.of<ProgressService>(context, listen: false),
    );
    _searchCtrl.addListener(() => _vm.setFilter(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const JohnThemedAppBar(
          room: JohnSchoolRoom.recipeArchive,
          title: 'Рецептурный архив',
          automaticallyImplyLeading: false,
        ),
        body: JohnRoomBackground(
          room: JohnSchoolRoom.recipeArchive,
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Color(0xFF2E2115)),
                  decoration: InputDecoration(
                    hintText: 'Найти коктейль...',
                    hintStyle: const TextStyle(color: Color(0xFF7A654A)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF795327)),
                    filled: true,
                    fillColor: const Color(0xEEF5DFAD),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF9B7133)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFD0A24C), width: 2),
                    ),
                  ),
                ),
              ),
              // Collection progress
              Consumer<CocktailListViewModel>(
                builder: (_, vm, __) {
                  if (vm.isLoading || vm.totalLoaded == 0)
                    return const SizedBox.shrink();
                  final unlocked = vm.unlockedCount;
                  final total = vm.totalLoaded;
                  final pct = total > 0 ? unlocked / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: JohnWoodPanel(
                      room: JohnSchoolRoom.recipeArchive,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Image.asset(
                            'images/ui_icon_book_theory.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Коллекция: $unlocked из $total',
                                  style: const TextStyle(
                                    color: Color(0xFFF5E7BF),
                                    fontFamily: 'serif',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 4,
                                    backgroundColor: Color(0xFF0F1E17),
                                    valueColor: const AlwaysStoppedAnimation(
                                        Color(0xFFD0A24C)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(pct * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFFD0A24C),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Section tabs + filters
              Consumer<CocktailListViewModel>(
                builder: (_, vm, __) => Column(
                  children: [
                    _SectionTabs(activeSection: vm.activeSection),
                    if (vm.activeSection == RecipeSection.byTechnique)
                      _TechniqueChips(
                        selected: vm.techniqueFilter,
                        techniques: vm.curriculum.allTechniques,
                      ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: Consumer<CocktailListViewModel>(
                  builder: (_, vm, __) {
                    if (vm.isLoading) return const _ShimmerList();

                    final cocktails = vm.cocktails;

                    if (cocktails.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                color: AppColors.textSecondary, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'Ничего не найдено',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        const _OfflineBanner(),
                        // Section header with count
                        _SectionHeader(
                          section: vm.activeSection,
                          count: cocktails.length,
                          techniqueFilter: vm.techniqueFilter,
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: cocktails.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final c = cocktails[i];
                              return CocktailTile(
                                cocktail: c,
                                isLocked: !vm.isCocktailUnlocked(c.strDrink),
                                catalogStyle: true,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Tabs ───────────────────────────────────────────────────────────

class _SectionTabs extends StatelessWidget {
  final RecipeSection activeSection;

  const _SectionTabs({required this.activeSection});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _SectionChip(
            label: 'Изучено',
            isSelected: activeSection == RecipeSection.myPath,
            onTap: () => context
                .read<CocktailListViewModel>()
                .setActiveSection(RecipeSection.myPath),
          ),
          const SizedBox(width: 8),
          _SectionChip(
            label: 'Классика',
            isSelected: activeSection == RecipeSection.classics,
            onTap: () => context
                .read<CocktailListViewModel>()
                .setActiveSection(RecipeSection.classics),
          ),
          const SizedBox(width: 8),
          _SectionChip(
            label: 'По технике',
            isSelected: activeSection == RecipeSection.byTechnique,
            onTap: () => context
                .read<CocktailListViewModel>()
                .setActiveSection(RecipeSection.byTechnique),
          ),
          const SizedBox(width: 8),
          _SectionChip(
            label: 'Все',
            isSelected: activeSection == RecipeSection.allRecipes,
            onTap: () => context
                .read<CocktailListViewModel>()
                .setActiveSection(RecipeSection.allRecipes),
          ),
        ],
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD0A24C) : const Color(0xEE183226),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFE7C77E) : const Color(0xFF7B6338),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0x66D0A24C),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                isSelected ? const Color(0xFF2E2115) : const Color(0xFFF5E7BF),
            fontFamily: 'serif',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Technique Chips ────────────────────────────────────────────────────────

class _TechniqueChips extends StatelessWidget {
  final String? selected;
  final List<String> techniques;

  const _TechniqueChips({
    required this.selected,
    required this.techniques,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _FilterChip(
            label: 'Все техники',
            isSelected: selected == null,
            onTap: () =>
                context.read<CocktailListViewModel>().setTechniqueFilter(null),
          ),
          const SizedBox(width: 8),
          for (final technique in techniques) ...[
            _FilterChip(
              label:
                  '${CocktailCurriculumService.techniqueIcons[technique] ?? ''} ${CocktailCurriculumService.techniqueLabels[technique] ?? technique}',
              isSelected: selected == technique,
              onTap: () => context
                  .read<CocktailListViewModel>()
                  .setTechniqueFilter(technique),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final RecipeSection section;
  final int count;
  final String? techniqueFilter;

  const _SectionHeader({
    required this.section,
    required this.count,
    this.techniqueFilter,
  });

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    switch (section) {
      case RecipeSection.myPath:
        final total = CocktailCurriculumService.entries.length;
        subtitle = 'Изучено $count из $total коктейлей';
        break;
      case RecipeSection.classics:
        subtitle = 'Mojito · Daiquiri · Negroni — сдай экзамен';
        break;
      case RecipeSection.byTechnique:
        subtitle = techniqueFilter != null
            ? 'Коктейли на технику ${CocktailCurriculumService.techniqueLabels[techniqueFilter]}'
            : 'Выбери технику — увидишь коктейли';
        break;
      case RecipeSection.allRecipes:
        subtitle = 'Полная база — $count коктейлей';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface.withAlpha(80),
      child: Row(
        children: [
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer ────────────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 12,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 100, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Offline Banner ─────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  Future<bool> _checkOffline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.none);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkOffline(),
      builder: (context, snapshot) {
        final isOffline = snapshot.data ?? false;
        if (!isOffline) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.orange.withOpacity(0.1),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded,
                  color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Офлайн — показаны кешированные данные',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
