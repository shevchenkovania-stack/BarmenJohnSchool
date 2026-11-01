import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/school_config.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';

class WisdomChestScreen extends StatefulWidget {
  const WisdomChestScreen({super.key});

  @override
  State<WisdomChestScreen> createState() => _WisdomChestScreenState();
}

class _WisdomChestScreenState extends State<WisdomChestScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _gold = Color(0xFFD4AF37);
  static const _ink = Color(0xFF3C2718);
  static const _night = Color(0xFFF6E8C9);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonRepo = context.watch<LessonRepository>();
    final progress = context.watch<ProgressService>();
    final wisdomLessons = lessonRepo.getWisdomLessons();

    final purchasedCount = wisdomLessons
        .where((lesson) => progress.isWisdomPurchased(lesson.lessonNumber))
        .length;

    return Scaffold(
      backgroundColor: _night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _ink,
        title: const Text(
          'Мудрость старого бармена',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: _ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _TreasureChip(
                label: '${progress.coins}',
                icon: '🪙',
                color: _gold,
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final pulse = 0.5 + 0.5 * math.sin(_controller.value * math.pi * 2);
          return Stack(
            children: [
              const Positioned.fill(child: _WisdomBackground()),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.08 + pulse * 0.04,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topCenter,
                          radius: 1.15,
                          colors: [
                            Color(0x33B07A31),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WisdomHeader(
                      total: progress.wisdomTotal,
                      purchasedCount: purchasedCount,
                      coins: progress.coins,
                      pulse: pulse,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Это не обычная библиотека. Это тайник Джона: старые заметки, '
                        'редкие подсказки и маленькие ключи к мастерству. Каждый '
                        'фрагмент открывается как находка на старой карте.',
                        style: TextStyle(
                          color: _ink.withAlpha(190),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (wisdomLessons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _AncientPanel(
                          borderColor: _gold.withAlpha(30),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF4E0B8), Color(0xFFE2C98E)],
                          ),
                          child: const Text(
                            'Мудрость пока не загружена. Пройди первый урок.',
                            style: TextStyle(color: _ink),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: wisdomLessons.asMap().entries.map((entry) {
                            final index = entry.key;
                            final lesson = entry.value;
                            final isPurchased =
                                progress.isWisdomPurchased(lesson.lessonNumber);
                            final isAvailable =
                                progress.isWisdomAvailable(lesson.lessonNumber);
                            final canAfford =
                                progress.canAffordWisdom(lesson.lessonNumber);
                            final price =
                                progress.getWisdomPrice(lesson.lessonNumber);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  math.sin((_controller.value * 2 * math.pi) +
                                          (index * 0.4)) *
                                      2.0,
                                ),
                                child: _WisdomCard(
                                  lesson: lesson,
                                  isPurchased: isPurchased,
                                  isAvailable: isAvailable,
                                  canAfford: canAfford,
                                  price: price,
                                  isFeatured: index == 0,
                                  onTap: () {
                                    if (isPurchased) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              LessonScreen(lesson: lesson),
                                        ),
                                      );
                                    } else if (isAvailable && canAfford) {
                                      _showPurchaseConfirm(
                                        context,
                                        lesson: lesson,
                                        price: price,
                                        progress: progress,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPurchaseConfirm(
    BuildContext context, {
    required Lesson lesson,
    required int price,
    required ProgressService progress,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: _AncientPanel(
          borderColor: _gold.withAlpha(45),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B2016), Color(0xFF17110F)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(lesson.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Открыть фрагмент?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                lesson.title,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lesson.shortDescription,
                style: TextStyle(
                  color: Colors.white.withAlpha(185),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('🪙 ', style: TextStyle(fontSize: 18)),
                  Text(
                    '$price монет',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Баланс: ${progress.coins}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(145),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: Colors.white.withAlpha(150)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final success = progress.purchaseWisdom(lesson.lessonNumber);
                      if (!success) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Text(lesson.emoji,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              const Expanded(child: Text('Фрагмент открыт!')),
                            ],
                          ),
                          backgroundColor: const Color(0xFF2B1B4B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: _ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Открыть'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WisdomBackground extends StatelessWidget {
  const _WisdomBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8EAC8), Color(0xFFF2DEB0), Color(0xFFE7D099)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            left: -30,
            child: _DustCloud(color: Color(0x33B07A31), size: 180),
          ),
          Positioned(
            top: 120,
            right: -50,
            child: _DustCloud(color: Color(0x229A7036), size: 220),
          ),
          Positioned(
            bottom: 120,
            left: -40,
            child: _DustCloud(color: Color(0x1A8E5E2C), size: 240),
          ),
          Positioned(
            top: 32,
            left: 18,
            child: Opacity(
              opacity: 0.18,
              child: CustomPaint(
                size: Size(220, 220),
                painter: _MapLinesPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DustCloud extends StatelessWidget {
  final Color color;
  final double size;

  const _DustCloud({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8E5E2C).withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(0, size.height * 0.22)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.18,
        size.width * 0.42,
        size.height * 0.42,
        size.width * 0.68,
        size.height * 0.34,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.30,
        size.width * 0.88,
        size.height * 0.54,
        size.width,
        size.height * 0.50,
      );
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = const Color(0xFF8E5E2C).withAlpha(90)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.23, size.height * 0.20), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.68, size.height * 0.34), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.90, size.height * 0.50), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WisdomHeader extends StatelessWidget {
  final int total;
  final int purchasedCount;
  final int coins;
  final double pulse;

  const _WisdomHeader({
    required this.total,
    required this.purchasedCount,
    required this.coins,
    required this.pulse,
  });

  static const _gold = Color(0xFFD4AF37);
  static const _ink = Color(0xFF3C2718);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7E5BC), Color(0xFFE8CF92), Color(0xFFDDBF76)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF9B6A2C).withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Transform.translate(
            offset: Offset(0, math.sin(pulse * math.pi * 2) * 4),
            child: Container(
                width: 94,
                height: 94,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0x33B07A31), Color(0x00F5E3B8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF9B6A2C).withAlpha(40)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD4AF37).withAlpha(12 + (pulse * 20).round()),
                      ),
                    ),
                  Image.asset(
                    'images/wisdom_chest.jpg',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('📜', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Записная книжка Джона',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Старые заметки, редкие подсказки и честные детали о баре.',
                  style: TextStyle(
                    color: _ink.withAlpha(180),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TreasureChip(
                      label: '$purchasedCount / $total',
                      icon: '📖',
                      color: _gold,
                    ),
                    _TreasureChip(
                      label: '$coins',
                      icon: '🪙',
                      color: _gold,
                    ),
                    const _TreasureChip(
                      label: 'артефакт',
                      icon: '✨',
                      color: Color(0xFF9B6A2C),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreasureChip extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;

  const _TreasureChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(55)),
      ),
      child: Text(
        '$icon $label',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AncientPanel extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final Color borderColor;

  const _AncientPanel({
    required this.child,
    required this.gradient,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(75),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WisdomCard extends StatelessWidget {
  final Lesson lesson;
  final bool isPurchased;
  final bool isAvailable;
  final bool canAfford;
  final int price;
  final bool isFeatured;
  final VoidCallback onTap;

  const _WisdomCard({
    required this.lesson,
    required this.isPurchased,
    required this.isAvailable,
    required this.canAfford,
    required this.price,
    required this.isFeatured,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !isPurchased && !isAvailable;
    final isActive = isPurchased || (isAvailable && canAfford);

    final gradient = isPurchased
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5E3B8), Color(0xFFE8CF92), Color(0xFFDDBF76)],
          )
        : isAvailable
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7E6C2), Color(0xFFEAD8A3), Color(0xFFDABB79)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0E0BB), Color(0xFFE8D19A), Color(0xFFD8BF82)],
              );

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: isLocked ? 0.56 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPurchased
                  ? const Color(0xFF9B6A2C).withAlpha(58)
                  : isAvailable
                      ? const Color(0xFF9B6A2C).withAlpha(36)
                      : const Color(0xFF9B6A2C).withAlpha(42),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isFeatured)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B6A2C).withAlpha(18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFF9B6A2C).withAlpha(45)),
                    ),
                    child: const Text(
                      'Начни здесь',
                      style: TextStyle(
                        color: Color(0xFF9B6A2C),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPurchased
                        ? const Color(0xFF9B6A2C).withAlpha(10)
                        : isAvailable
                            ? const Color(0xFF9B6A2C).withAlpha(10)
                            : Colors.white.withAlpha(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isPurchased
                          ? const Color(0xFF9B6A2C).withAlpha(24)
                          : Colors.white.withAlpha(8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isPurchased
                            ? const Color(0xFF9B6A2C).withAlpha(35)
                            : Colors.white.withAlpha(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        lesson.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9B6A2C).withAlpha(18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Фрагмент ${lesson.lessonNumber}',
                                style: const TextStyle(
                                  color: Color(0xFF9B6A2C),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lesson.title,
                          style: TextStyle(
                            color: const Color(0xFF3C2718),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.shortDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF5A3C27).withAlpha(
                              isPurchased ? 210 : 180,
                            ),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildRightSide(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (isPurchased) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF9B6A2C).withAlpha(18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Открыто',
          style: TextStyle(
            color: Color(0xFF9B6A2C),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (isAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF9B6A2C).withAlpha(18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '🪙 $price',
          style: const TextStyle(
            color: Color(0xFF9B6A2C),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    final requiredLessons =
        BartenderSchoolConfig.wisdomLessonRequirements[lesson.lessonNumber] ??
            0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Урок $requiredLessons',
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildRightSide() {
    if (isPurchased) {
      return const Text(
        '›',
        style: TextStyle(
          color: Color(0xFF9B6A2C),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (isAvailable && canAfford) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF9B6A2C).withAlpha(22),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF9B6A2C).withAlpha(52)),
        ),
        child: const Text(
          'Купить',
          style: TextStyle(
            color: Color(0xFF9B6A2C),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    return const Text(
      '🔒',
      style: TextStyle(fontSize: 18),
    );
  }
}
