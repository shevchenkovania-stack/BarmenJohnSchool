/// Бейджи Мастерской.
///
/// Каждый бейдж — достижение, которое разблокируется при выполнении условия.
/// Проверяется через [WorkshopBadge.check] после каждого задания.
library;

import 'package:coin/features/bartender_school/data/practice_challenges.dart';

class WorkshopBadge {
  final String id;
  final String title;
  final String emoji;
  final String description;

  /// [check] принимает: звёзды по заданиям, streak, есть ли time bonus.
  final bool Function(BadgeContext ctx) check;

  const WorkshopBadge({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.check,
  });
}

/// Контекст для проверки бейджей.
class BadgeContext {
  final Map<String, int> challengeStars; // challengeId → best stars (0-3)
  final int streak; // текущая серия дней
  final bool hasTimeBonus; // был ли хоть один time bonus

  const BadgeContext({
    required this.challengeStars,
    required this.streak,
    this.hasTimeBonus = false,
  });

  int get totalCompleted => challengeStars.values.where((s) => s > 0).length;

  bool hasBlockComplete(String blockId, {int minStars = 1}) {
    final blockChallenges =
        allPracticeChallenges.where((c) => c.blockId == blockId);
    if (blockChallenges.isEmpty) return false;
    return blockChallenges
        .every((c) => (challengeStars[c.id] ?? 0) >= minStars);
  }
}

// ── Список всех бейджей ─────────────────────────────────────────────────────

final List<WorkshopBadge> workshopBadges = [
  WorkshopBadge(
    id: 'first_cocktail',
    title: 'Первый коктейль',
    emoji: '🎉',
    description: 'Заверши любое задание',
    check: (ctx) => ctx.totalCompleted >= 1,
  ),
  WorkshopBadge(
    id: 'perfectionist',
    title: 'Точность',
    emoji: '⭐',
    description: 'Получи 3 звезды на любом задании',
    check: (ctx) => ctx.challengeStars.values.any((s) => s >= 3),
  ),
  WorkshopBadge(
    id: 'speed_demon',
    title: 'Скорость',
    emoji: '⚡',
    description: 'Выполни задание с бонусом за время',
    check: (ctx) => ctx.hasTimeBonus,
  ),
  WorkshopBadge(
    id: 'streak_3',
    title: 'Серия 3',
    emoji: '🔥',
    description: '3 дня практики подряд',
    check: (ctx) => ctx.streak >= 3,
  ),
  WorkshopBadge(
    id: 'block_a',
    title: 'Основы вкуса',
    emoji: '🍋',
    description: 'Пройди все задания блока A',
    check: (ctx) => ctx.hasBlockComplete('A'),
  ),
  WorkshopBadge(
    id: 'block_b',
    title: 'Инструменты',
    emoji: '🔧',
    description: 'Пройди все задания блока B',
    check: (ctx) => ctx.hasBlockComplete('B'),
  ),
  WorkshopBadge(
    id: 'block_c',
    title: 'Классика',
    emoji: '🥃',
    description: 'Пройди все задания блока C',
    check: (ctx) => ctx.hasBlockComplete('C'),
  ),
  WorkshopBadge(
    id: 'master',
    title: 'Мастер',
    emoji: '🏆',
    description: 'Все 20 коктейлей с 2+ звёздами',
    check: (ctx) =>
        ctx.hasBlockComplete('A', minStars: 2) &&
        ctx.hasBlockComplete('B', minStars: 2) &&
        ctx.hasBlockComplete('C', minStars: 2),
  ),
];
