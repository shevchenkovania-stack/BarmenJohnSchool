import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/core/services/favorites_service.dart';
import 'package:coin/features/cocktail_builder/models/generated_cocktail.dart';
import 'package:coin/features/cocktail_builder/models/cocktail_types.dart';
import 'package:coin/features/cocktail_builder/view/widgets/result_elements.dart';
import 'package:coin/features/cocktail_builder/view/widgets/metrics.dart';
import 'package:coin/features/cocktail_builder/view/widgets/buttons.dart';

class ResultScreen extends StatelessWidget {
  final GeneratedCocktail cocktail;
  final VoidCallback onBack;

  const ResultScreen({
    required this.cocktail,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: onBack,
            child: Row(
              children: [
                Icon(Icons.arrow_back_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Новый коктейль',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        _HeroCardWithImage(
          name: cocktail.name,
          description: cocktail.description,
          imageUrl: cocktail.imageUrl,
          missingHint: cocktail.missingForClassic,
          primaryColor: AppColors.primary,
        ),
        const SizedBox(height: 16),
        if (_Level1PracticeReview.matches(cocktail) != null) ...[
          _Level1PracticeCard(
            review: _Level1PracticeReview.matches(cocktail)!,
            score: cocktail.matchScore,
          ),
          const SizedBox(height: 16),
        ],
        Column(
          children: [
            QuickInfoCard(
              emoji: cocktail.method.emoji,
              label: 'Метод',
              value: cocktail.method.label,
              reason: cocktail.method.reason,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 12),
            QuickInfoCard(
              emoji: cocktail.glass.emoji,
              label: 'Бокал',
              value: cocktail.glass.label,
              color: Colors.blueAccent,
            ),
          ],
        ),
        const SizedBox(height: 16),
        MetricsPanel(cocktail: cocktail),
        const SizedBox(height: 20),
        if (cocktail.hasAllergens)
          AllergenWarning(allergens: cocktail.allergens),
        const SizedBox(height: 20),
        SectionTitle(
            icon: Icons.inventory_2_rounded,
            title: 'Состав',
            color: Colors.greenAccent),
        const SizedBox(height: 12),
        ...cocktail.ingredients.map((ing) => IngredientRow(
              name: ing.name,
              amount: ing.amountMl > 0 ? '${ing.amountMl} мл' : 'по вкусу',
              color: AppColors.primary,
            )),
        const SizedBox(height: 24),
        SectionTitle(
            icon: Icons.menu_book_rounded,
            title: 'Приготовление',
            color: Colors.blueAccent),
        const SizedBox(height: 12),
        ...cocktail.steps.asMap().entries.map((e) => StepRow(
              number: e.key + 1,
              text: e.value,
            )),
        const SizedBox(height: 20),
        if (cocktail.wowEffect.isNotEmpty)
          InsightCard(
            emoji: '✨',
            title: 'ВАУ-деталь подачи',
            text: cocktail.wowEffect,
            color: Colors.amber,
            borderColor: Colors.amber.withOpacity(0.4),
          ),
        if (cocktail.whyItWorks.isNotEmpty)
          InsightCard(
            emoji: '🧠',
            title: 'Почему это работает',
            text: cocktail.whyItWorks,
            color: Colors.purple,
            borderColor: Colors.purple.withOpacity(0.3),
          ),
        if (cocktail.proTip != null)
          InsightCard(
            emoji: '💡',
            title: 'Совет профи',
            text: cocktail.proTip!,
            color: Colors.amber,
          ),
        if (cocktail.fact != null)
          InsightCard(
            emoji: '🧪',
            title: 'Факт',
            text: cocktail.fact!,
            color: Colors.blue,
          ),
        if (cocktail.secret != null)
          InsightCard(
            emoji: '🔮',
            title: 'Секрет бармена',
            text: cocktail.secret!,
            color: Colors.purple,
          ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1),
        const SizedBox(height: 24),
        ActionButton(
          icon: Icons.favorite_rounded,
          label: 'Сохранить в избранное',
          style: ActionButtonStyle.filled,
          color: AppColors.primary,
          onPressed: () {
            context.read<FavoritesService>().addAiCocktail(cocktail);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('✅ "${cocktail.name}" сохранено!')),
                ]),
                backgroundColor: Colors.green.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ActionButton(
          icon: Icons.share_rounded,
          label: 'Поделиться',
          style: ActionButtonStyle.outlined,
          color: AppColors.primary,
          onPressed: () => _shareCocktail(context, cocktail),
        ),
        const SizedBox(height: 12),
        ActionButton(
          icon: Icons.refresh_rounded,
          label: 'Создать другой',
          style: ActionButtonStyle.outlined,
          color: AppColors.textSecondary,
          onPressed: onBack,
        ),
      ],
    );
  }
}

class _Level1PracticeReview {
  final String cocktailName;
  final String lesson;
  final String methodFocus;
  final List<String> checklist;

  const _Level1PracticeReview({
    required this.cocktailName,
    required this.lesson,
    required this.methodFocus,
    required this.checklist,
  });

  static _Level1PracticeReview? matches(GeneratedCocktail cocktail) {
    final name = cocktail.name.toLowerCase();

    if (name.contains('mojito') || name.contains('мохито')) {
      return const _Level1PracticeReview(
        cocktailName: 'Mojito',
        lesson: 'Урок C09',
        methodFocus: 'Build: собрать в бокале, не убить мяту, держать баланс.',
        checklist: [
          'Мята мягко прижата, не порвана в кашу',
          'Лайм и сахар дают живой, не липкий баланс',
          'Сода добавлена в конце',
        ],
      );
    }

    if (name.contains('daiquiri') || name.contains('дайкири')) {
      return const _Level1PracticeReview(
        cocktailName: 'Daiquiri',
        lesson: 'Урок C10',
        methodFocus: 'Shake: точность джиггера, холод и чистый баланс.',
        checklist: [
          'Ром, лайм и сахар отмерены точно',
          'Shake достаточно холодный и энергичный',
          'Кислота и сладость не спорят между собой',
        ],
      );
    }

    if (name.contains('negroni') || name.contains('негрони')) {
      return const _Level1PracticeReview(
        cocktailName: 'Negroni',
        lesson: 'Урок C11',
        methodFocus: 'Stir: равные части, прозрачность и controlled dilution.',
        checklist: [
          'Джин, Campari и вермут идут равными частями',
          'Коктейль размешан, не встряхнут',
          'Горечь держит структуру, а не ломает напиток',
        ],
      );
    }

    return null;
  }
}

class _Level1PracticeCard extends StatelessWidget {
  final _Level1PracticeReview review;
  final double score;

  const _Level1PracticeCard({
    required this.review,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).round();
    final isGood = score >= 0.8;
    final isOk = score >= 0.5 && score < 0.8;
    final statusColor = isGood
        ? Colors.green
        : isOk
            ? Colors.orange
            : Colors.redAccent;
    final statusIcon = isGood
        ? Icons.check_circle_rounded
        : isOk
            ? Icons.info_rounded
            : Icons.cancel_rounded;
    final statusText = percent == 0
        ? 'тренировка'
        : isGood
            ? 'Сборка верная!'
            : isOk
                ? 'Почти! Попробуй ещё раз'
                : 'Попробуй ещё раз';
    final displayScore = percent == 0 ? '' : '$percent%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: lesson + cocktail name
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${review.lesson}: ${review.cocktailName}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (displayScore.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    displayScore,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Status message
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          // Method focus
          Text(
            review.methodFocus,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          // Checklist items
          ...review.checklist.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isGood
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isGood ? statusColor : AppColors.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: isGood
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _shareCocktail(BuildContext context, GeneratedCocktail cocktail) {
  final ingredients = cocktail.ingredients
      .map((i) => '- ${i.name} (${i.amountMl} ml)')
      .join('\n');

  final steps = cocktail.steps
      .asMap()
      .entries
      .map((e) => '${e.key + 1}. ${e.value}')
      .join('\n');

  final text = '''
${cocktail.name}

${cocktail.description}

Method: ${cocktail.method.label}
Glass: ${cocktail.glass.label}

Ingredients:
$ingredients

Instructions:
$steps

${cocktail.wowEffect.isNotEmpty ? '\n${cocktail.wowEffect}\n' : ''}
Recipe from Cocktail Mix app
''';

  Share.share(text, subject: cocktail.name);
}

/// Объединенный Hero Card с картинкой, названием и подсказкой
class _HeroCardWithImage extends StatelessWidget {
  final String name;
  final String description;
  final String? imageUrl;
  final String? missingHint;
  final Color primaryColor;

  const _HeroCardWithImage({
    required this.name,
    required this.description,
    this.imageUrl,
    this.missingHint,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.2),
            primaryColor.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🖼️ Картинка сверху (компактная)
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image,
                              size: 48, color: Colors.grey),
                        );
                      },
                    ),
                    // Бейдж "Классика"
                    if (imageUrl!.contains('thecocktaildb'))
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Классика',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            const SizedBox(height: 16),

          // 🍸 Иконка (если нет картинки)
          if (imageUrl == null || imageUrl!.isEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_bar_rounded,
                  color: AppColors.primary, size: 32),
            ),
          if (imageUrl == null || imageUrl!.isEmpty) const SizedBox(height: 16),

          // 📝 Название
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // 📝 Описание
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ⚠️ Подсказка чего не хватает
          if (missingHint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      missingHint!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
