import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/cocktail_curriculum_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';

// Импорт экрана деталей — нужен для навигации по тапу
import 'package:coin/features/cocktail_detail/view/cocktail_detail_screen.dart';

/// Строка списка коктейлей с учебным контекстом.
///
/// Показывает:
/// - Фото + название (как раньше)
/// - Бейдж урока (e.g. "C09 · Build") если коктейль в программе
/// - Иконку техники (🥃 Shake / 🥄 Stir / 🏗 Build)
/// - Тип (Alcoholic / Non alcoholic)
class CocktailTile extends StatelessWidget {
  final Cocktail cocktail;
  final VoidCallback? onTap;
  final bool isLocked;
  final bool catalogStyle;

  const CocktailTile({
    super.key,
    required this.cocktail,
    this.onTap,
    this.isLocked = false,
    this.catalogStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final curriculum = CocktailCurriculumService();
    final entry = curriculum.getEntry(cocktail.strDrink);

    return InkWell(
      onTap: isLocked
          ? null
          : (onTap ??
              () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CocktailDetailScreen(cocktail: cocktail),
                    ),
                  )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: catalogStyle ? const EdgeInsets.all(11) : EdgeInsets.zero,
          decoration: catalogStyle
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF5DFAD), Color(0xFFDAB874)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF9B7133)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                )
              : null,
          child: Row(
            children: [
              // Photo (or silhouette if locked)
              isLocked
                  ? const _LockedSilhouette()
                  : _CocktailImage(cocktail: cocktail),
              const SizedBox(width: 14),
              // Name + curriculum info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      isLocked ? '???' : cocktail.strDrink,
                      style: TextStyle(
                        color: isLocked
                            ? AppColors.textSecondary.withValues(alpha: 0.5)
                            : catalogStyle
                                ? const Color(0xFF2E2115)
                                : AppColors.textPrimary,
                        fontSize: 15,
                        fontFamily: catalogStyle ? 'serif' : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Curriculum badges row
                    Row(
                      children: [
                        if (isLocked)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  color: AppColors.textSecondary, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Не открыто',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        else if (entry != null) ...[
                          _LessonBadge(entry: entry),
                          const SizedBox(width: 6),
                          _TechniqueBadge(entry: entry),
                          if (entry.isDiploma) ...[
                            const SizedBox(width: 6),
                            const _DiplomaBadge(),
                          ],
                        ] else
                          Text(
                            cocktail.strAlcoholic,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Practice stars (if practiced in Workshop)
              _PracticeStars(cocktailName: cocktail.strDrink),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: catalogStyle
                    ? const Color(0xFF795327)
                    : AppColors.textSecondary,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cocktail Image ─────────────────────────────────────────────────────────

class _CocktailImage extends StatelessWidget {
  final Cocktail cocktail;
  const _CocktailImage({required this.cocktail});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: cocktail.strDrinkThumb,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        cacheManager: DefaultCacheManager(),
        placeholder: (_, __) => Container(
          width: 58,
          height: 58,
          color: AppColors.shimmerBase,
          child:
              const Icon(Icons.local_bar, color: AppColors.primary, size: 30),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 58,
          height: 58,
          color: AppColors.shimmerBase,
          child: Center(
            child: Text(
              cocktail.strDrink.isNotEmpty
                  ? cocktail.strDrink[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Lesson Badge ───────────────────────────────────────────────────────────

class _LessonBadge extends StatelessWidget {
  final CurriculumEntry entry;
  const _LessonBadge({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Text(
        entry.lessonLabel,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Technique Badge ────────────────────────────────────────────────────────

class _TechniqueBadge extends StatelessWidget {
  final CurriculumEntry entry;
  const _TechniqueBadge({required this.entry});

  @override
  Widget build(BuildContext context) {
    final icon =
        CocktailCurriculumService.techniqueIcons[entry.technique] ?? '';
    final label =
        CocktailCurriculumService.techniqueLabels[entry.technique] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$icon $label',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Diploma Badge ──────────────────────────────────────────────────────────

class _DiplomaBadge extends StatelessWidget {
  const _DiplomaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withAlpha(50)),
      ),
      child: const Text(
        '🏆',
        style: TextStyle(fontSize: 10),
      ),
    );
  }
}

// ─── Practice Stars ────────────────────────────────────────────────────────

class _PracticeStars extends StatelessWidget {
  final String cocktailName;
  const _PracticeStars({required this.cocktailName});

  @override
  Widget build(BuildContext context) {
    final stars = context
        .watch<ProgressService>()
        .getPracticeStarsByCocktail(cocktailName);
    if (stars == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Icon(
          i < stars ? Icons.star_rounded : Icons.star_border_rounded,
          size: 14,
          color: i < stars ? Colors.amber : AppColors.divider,
        ),
      ),
    );
  }
}

// ─── Locked Silhouette ──────────────────────────────────────────────────────

class _LockedSilhouette extends StatelessWidget {
  const _LockedSilhouette();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Icon(
          Icons.local_bar_rounded,
          color: AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}
