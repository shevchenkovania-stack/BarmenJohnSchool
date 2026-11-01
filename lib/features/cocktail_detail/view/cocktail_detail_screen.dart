import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/cocktail_curriculum_service.dart';
import 'package:coin/core/services/favorites_service.dart';
import 'package:coin/core/services/share_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/cocktail_detail/widgets/ingredient_row.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Экран детального просмотра коктейля.
///
/// Принимает [cocktail] через конструктор — никакой маршрутизации с аргументами,
/// всё явно и типобезопасно.
///
/// Структура экрана:
///   1. SliverAppBar с картинкой (Hero-анимация, кнопка избранного)
///   2. Название + теги (категория, алкогольность, стакан)
///   3. Счётчик порций + горизонтальная строка ингредиентов
///   4. Блок инструкции
class CocktailDetailScreen extends StatefulWidget {
  final Cocktail cocktail;

  const CocktailDetailScreen({super.key, required this.cocktail});

  @override
  State<CocktailDetailScreen> createState() => _CocktailDetailScreenState();
}

class _CocktailDetailScreenState extends State<CocktailDetailScreen> {
  int _servings = 1;

  @override
  Widget build(BuildContext context) {
    final cocktail = widget.cocktail;
    return Scaffold(
        backgroundColor: AppColors.background,
        body: JohnRoomBackground(
          room: JohnSchoolRoom.recipeArchive,
          child: CustomScrollView(
            slivers: [
              // ── Шапка с картинкой ───────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true, // AppBar остаётся видимым при скролле
                backgroundColor: const Color(0xFF13271E),
                iconTheme: const IconThemeData(color: Colors.white),

                // Кнопка "В избранное" справа
                actions: [
                  IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    onPressed: () => _shareCocktail(context),
                  ),
                  Consumer<FavoritesService>(
                    builder: (_, fav, __) {
                      final isFav = fav.isFavorite(cocktail.idDrink);
                      return IconButton(
                        tooltip: isFav
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav ? Colors.redAccent : Colors.white,
                        ),
                        onPressed: () => fav.toggle(cocktail),
                      );
                    },
                  ),
                ],

                flexibleSpace: FlexibleSpaceBar(
                  // Растягиваемая часть — картинка коктейля
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero: картинка "летит" с плитки списка
                      Hero(
                        tag: 'cocktail-img-${cocktail.idDrink}',
                        child: CachedNetworkImage(
                          imageUrl: cocktail.strDrinkThumb,
                          fit: BoxFit.cover,
                          cacheManager:
                              DefaultCacheManager(), // Тот же кэш что и preloader
                          placeholder: (_, __) =>
                              const ColoredBox(color: AppColors.shimmerBase),
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: AppColors.shimmerBase,
                            child: Icon(Icons.local_bar,
                                color: AppColors.primary, size: 60),
                          ),
                        ),
                      ),
                      // Градиент снизу — чтобы AppBar не сливался с картинкой
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC1A1825)],
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Контент ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                  child: JohnWoodPanel(
                    room: JohnSchoolRoom.recipeArchive,
                    highlighted: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Название
                        Text(
                          cocktail.strDrink,
                          style: const TextStyle(
                            color: Color(0xFFF5E7BF),
                            fontFamily: 'serif',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Теги: категория, тип, стакан
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _InfoTag(cocktail.strCategory),
                            _InfoTag(cocktail.strAlcoholic),
                            _InfoTag(cocktail.strGlass,
                                icon: Icons.local_bar_rounded),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Curriculum context card
                        _CurriculumCard(cocktailName: cocktail.strDrink),
                        const SizedBox(height: 28),

                        // Секция ингредиентов
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context).detailIngredients,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            // Счётчик порций
                            _ServingsCounter(
                              servings: _servings,
                              onDecrement: _servings > 1
                                  ? () => setState(() => _servings--)
                                  : null,
                              onIncrement: _servings < 50
                                  ? () => setState(() => _servings++)
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        IngredientRow(cocktail: cocktail, servings: _servings),
                        const SizedBox(height: 28),

                        // Original recipe from API
                        if (cocktail.strInstructions.isNotEmpty)
                          _OriginalApiRecipe(
                              instructions: cocktail.strInstructions),
                        const SizedBox(height: 20),

                        // "I made this" + Rating
                        _MadeThisSection(cocktailName: cocktail.strDrink),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  // Share cocktail as text
  Future<void> _shareCocktail(BuildContext ctx) async {
    final c = widget.cocktail;
    final ingredients = <String>[];
    for (var i = 0; i < c.ingredients.length; i++) {
      final measure = i < c.measures.length && c.measures[i].isNotEmpty
          ? c.measures[i]
          : '';
      ingredients
          .add('- ${c.ingredients[i]}${measure.isNotEmpty ? ' $measure' : ''}');
    }

    final text = '''
${c.strDrink}

Ingredients:
${ingredients.join('\n')}

Instructions:
${c.strInstructions}

Recipe from Cocktail Mix app
''';

    await ShareService.shareWithImage(
      imageUrl: c.strDrinkThumb,
      text: text,
      subject: c.strDrink,
    );
  }
}

// ─── Тег-чипс (категория, тип, стакан) ───────────────────────────────────────

class _InfoTag extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _InfoTag(this.label, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.primary, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Счётчик порций ───────────────────────────────────────────────────────────

class _ServingsCounter extends StatelessWidget {
  final int servings;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _ServingsCounter({
    required this.servings,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterButton(icon: Icons.remove, onPressed: onDecrement),
        const SizedBox(width: 6),
        Text(
          '$servings',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        _CounterButton(icon: Icons.add, onPressed: onIncrement),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CounterButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onPressed != null ? AppColors.primary : AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

// ─── Оригинальный рецепт из API ───────────────────────────────────────────────

class _OriginalApiRecipe extends StatelessWidget {
  final String instructions;

  const _OriginalApiRecipe({required this.instructions});

  @override
  Widget build(BuildContext context) {
    // Разбиваем инструкцию на предложения
    final sentences = instructions
        .replaceAll('.', '.\n')
        .replaceAll('!', '!\n')
        .split('\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(15),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Инструкция',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Список предложений с маркерами
          ...sentences.map((sentence) {
            final trimmed = sentence.trim();
            if (trimmed.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Маркер-точка
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Текст
                  Expanded(
                    child: Text(
                      trimmed,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Curriculum Context Card ─────────────────────────────────────────────────

class _CurriculumCard extends StatelessWidget {
  final String cocktailName;
  const _CurriculumCard({required this.cocktailName});

  @override
  Widget build(BuildContext context) {
    final curriculum = CocktailCurriculumService();
    final entry = curriculum.getEntry(cocktailName);
    if (entry == null) return const SizedBox.shrink();

    final techniqueIcon =
        CocktailCurriculumService.techniqueIcons[entry.technique] ?? '';
    final techniqueLabel =
        CocktailCurriculumService.techniqueLabels[entry.technique] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(15),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.school_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Учебная программа',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (entry.isDiploma)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withAlpha(50)),
                  ),
                  child: const Text(
                    '🏆 Дипломный',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Info row
          Row(
            children: [
              _MiniBadge(
                label: entry.lessonLabel,
                icon: Icons.menu_book_rounded,
              ),
              const SizedBox(width: 8),
              _MiniBadge(
                label: '$techniqueIcon $techniqueLabel',
                icon: null,
              ),
              const SizedBox(width: 8),
              _MiniBadge(
                label: 'Блок ${entry.blockId}',
                icon: Icons.category_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _MiniBadge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.textSecondary, size: 12),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── "I Made This" Section ───────────────────────────────────────────────────

class _MadeThisSection extends StatelessWidget {
  final String cocktailName;
  const _MadeThisSection({required this.cocktailName});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressService>(
      builder: (context, progress, _) {
        final isMade = progress.isCocktailMade(cocktailName);
        final rating = progress.getCocktailRating(cocktailName);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "I made this" button
              Row(
                children: [
                  GestureDetector(
                    onTap: () => progress.markCocktailMade(cocktailName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMade
                            ? Colors.green.withAlpha(20)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMade
                              ? Colors.green.withAlpha(50)
                              : AppColors.divider,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMade
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color:
                                isMade ? Colors.green : AppColors.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isMade ? 'Приготовлено ✓' : 'Я приготовил',
                            style: TextStyle(
                              color: isMade
                                  ? Colors.green
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMade) ...[
                    const SizedBox(width: 8),
                    Text(
                      '+10 XP',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Star rating
              Row(
                children: [
                  const Text(
                    'Оценка:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(5, (i) {
                    final starIndex = i + 1;
                    return GestureDetector(
                      onTap: () =>
                          progress.setCocktailRating(cocktailName, starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          starIndex <= rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
