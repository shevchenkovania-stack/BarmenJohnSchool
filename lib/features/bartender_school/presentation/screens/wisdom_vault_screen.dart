import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/presentation/screens/lesson_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/wisdom_visuals.dart';

/// Complete visual experience for the Old Bartender's Wisdom.
class WisdomVaultScreen extends StatefulWidget {
  const WisdomVaultScreen({super.key});

  @override
  State<WisdomVaultScreen> createState() => _WisdomVaultScreenState();
}

class _WisdomVaultScreenState extends State<WisdomVaultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = context.watch<LessonRepository>().getWisdomLessons();
    final progress = context.watch<ProgressService>();
    final opened = lessons
        .where((lesson) => progress.isWisdomPurchased(lesson.lessonNumber))
        .length;

    return Scaffold(
      backgroundColor: WisdomPalette.darkInk,
      appBar: AppBar(
        backgroundColor: WisdomPalette.wood,
        foregroundColor: WisdomPalette.parchmentLight,
        elevation: 8,
        shadowColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'Мудрость старого бармена',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: .3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(child: _CoinBadge(coins: progress.coins)),
          ),
        ],
      ),
      body: WisdomMapBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, _) => _ChestHero(
                  pulse: Curves.easeInOut.transform(_glowController.value),
                  opened: opened,
                  total: lessons.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 2, 22, 16),
                child: _ChapterHeading(),
              ),
            ),
            if (lessons.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: WisdomParchmentPanel(
                    child: Text(
                      'Записи Джона пока не найдены.',
                      style: TextStyle(color: WisdomPalette.ink),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 42),
                sliver: SliverList.separated(
                  itemCount: lessons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return _WisdomMapCard(
                      index: index,
                      lesson: lesson,
                      isPurchased:
                          progress.isWisdomPurchased(lesson.lessonNumber),
                      isAvailable:
                          progress.isWisdomAvailable(lesson.lessonNumber),
                      canAfford: progress.canAffordWisdom(lesson.lessonNumber),
                      price: progress.getWisdomPrice(lesson.lessonNumber),
                      requiredLessons:
                          progress.wisdomRequiredLessons(lesson.lessonNumber),
                      sequenceLocked: !progress
                          .isWisdomSequenceUnlocked(lesson.lessonNumber),
                      onTap: () => _openLesson(context, lesson, progress),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openLesson(
    BuildContext context,
    Lesson lesson,
    ProgressService progress,
  ) {
    if (progress.isWisdomPurchased(lesson.lessonNumber)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)),
      );
      return;
    }
    if (!progress.isWisdomAvailable(lesson.lessonNumber)) return;
    _showPurchaseDialog(
      context,
      lesson,
      progress.getWisdomPrice(lesson.lessonNumber),
      progress,
    );
  }

  void _showPurchaseDialog(
    BuildContext context,
    Lesson lesson,
    int price,
    ProgressService progress,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withAlpha(190),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            WisdomParchmentPanel(
              highlighted: true,
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lesson.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WisdomPalette.ink,
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const WisdomOrnamentDivider(),
                  const SizedBox(height: 12),
                  Text(
                    lesson.shortDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: WisdomPalette.ink,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '$price монет  •  у тебя ${progress.coins}',
                    style: const TextStyle(
                      color: WisdomPalette.oldGold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Не сейчас'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              progress.canAffordWisdom(lesson.lessonNumber)
                                  ? () {
                                      final bought = progress
                                          .purchaseWisdom(lesson.lessonNumber);
                                      Navigator.pop(dialogContext);
                                      if (bought && context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                LessonScreen(lesson: lesson),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WisdomPalette.wax,
                            foregroundColor: WisdomPalette.parchmentLight,
                          ),
                          child: const Text('Сломать печать'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              top: -25,
              right: 18,
              child: WisdomWaxSeal(size: 58),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChestHero extends StatelessWidget {
  final double pulse;
  final int opened;
  final int total;

  const _ChestHero({
    required this.pulse,
    required this.opened,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 305,
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: WisdomPalette.antiqueGold
                          .withAlpha(55 + (pulse * 75).round()),
                      blurRadius: 38 + pulse * 14,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(130),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset('images/wisdom_chest.jpg', fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xB3140A05)],
                            stops: [.5, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: -2,
                bottom: -10,
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WisdomPalette.parchmentLight,
                    border: Border.all(
                      color: WisdomPalette.antiqueGold,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(120),
                        blurRadius: 12,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'images/barista_john_teach.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              const Positioned(
                right: -3,
                bottom: -18,
                child: WisdomWaxSeal(size: 68),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'СУНДУК МУДРОСТИ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: WisdomPalette.darkInk,
              fontFamily: 'serif',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.7,
              shadows: [Shadow(color: Color(0x66FFF3D0), blurRadius: 2)],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Открыто $opened из $total записей Джона',
            style: const TextStyle(
              color: WisdomPalette.oldGold,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterHeading extends StatelessWidget {
  const _ChapterHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        WisdomOrnamentDivider(),
        SizedBox(height: 10),
        Text(
          'Следуй по карте. Каждая запись открывается после уроков Level 1.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: WisdomPalette.ink,
            fontFamily: 'serif',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _WisdomMapCard extends StatelessWidget {
  final int index;
  final Lesson lesson;
  final bool isPurchased;
  final bool isAvailable;
  final bool canAfford;
  final int price;
  final int requiredLessons;
  final bool sequenceLocked;
  final VoidCallback onTap;

  const _WisdomMapCard({
    required this.index,
    required this.lesson,
    required this.isPurchased,
    required this.isAvailable,
    required this.canAfford,
    required this.price,
    required this.requiredLessons,
    required this.sequenceLocked,
    required this.onTap,
  });

  static const _icons = [
    'images/ui_icon_book_theory.png',
    'images/ui_icon_tip_citrus.png',
    'images/ui_icon_balance_precision.png',
    'images/ui_icon_tool_station.png',
    'images/ui_icon_term_medal.png',
    'images/ui_icon_practice_motion.png',
    'images/ui_icon_checklist.png',
  ];

  @override
  Widget build(BuildContext context) {
    final locked = !isPurchased && !isAvailable;
    final featured = index == 0;
    return Opacity(
      opacity: locked ? .66 : 1,
      child: InkWell(
        onTap: (isPurchased || isAvailable) ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            WisdomParchmentPanel(
              highlighted: featured && !locked,
              padding: const EdgeInsets.fromLTRB(14, 15, 58, 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: WisdomPalette.oldGold.withAlpha(28),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: WisdomPalette.oldGold.withAlpha(100),
                      ),
                    ),
                    child: Image.asset(_icons[index % _icons.length]),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'ЗАПИСЬ ${index + 1}',
                              style: const TextStyle(
                                color: WisdomPalette.oldGold,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            if (featured) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: WisdomPalette.wax,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'НАЧНИ ЗДЕСЬ',
                                  style: TextStyle(
                                    color: WisdomPalette.parchmentLight,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            color: WisdomPalette.ink,
                            fontFamily: 'serif',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          lesson.shortDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF5A3A23),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          _statusText(locked),
                          style: TextStyle(
                            color: isPurchased
                                ? const Color(0xFF47672E)
                                : WisdomPalette.oldGold,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              top: 14,
              child: isPurchased
                  ? const WisdomWaxSeal(size: 43, mark: '✓')
                  : locked
                      ? const _LockMedallion()
                      : WisdomWaxSeal(
                          size: 43,
                          mark: canAfford ? '${index + 1}' : '!',
                        ),
            ),
            if (featured && !locked)
              Positioned(
                left: 16,
                bottom: -4,
                child: Container(
                  width: 110,
                  height: 3,
                  decoration: BoxDecoration(
                    color: WisdomPalette.antiqueGold,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: WisdomPalette.antiqueGold.withAlpha(180),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusText(bool locked) {
    if (isPurchased) return 'Печать снята • читать';
    if (locked) {
      if (sequenceLocked) {
        return 'Сначала завершите запись ${lesson.lessonNumber - 1}';
      }
      return 'Откроется после урока $requiredLessons';
    }
    if (!canAfford) return 'Нужно $price монет';
    return '$price монет • сломать печать';
  }
}

class _LockMedallion extends StatelessWidget {
  const _LockMedallion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: WisdomPalette.wood.withAlpha(210),
        border: Border.all(color: WisdomPalette.antiqueGold),
      ),
      child: const Icon(
        Icons.lock_rounded,
        color: WisdomPalette.parchment,
        size: 20,
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  final int coins;

  const _CoinBadge({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: WisdomPalette.antiqueGold.withAlpha(35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: WisdomPalette.antiqueGold.withAlpha(130)),
      ),
      child: Text(
        '● $coins',
        style: const TextStyle(
          color: WisdomPalette.parchmentLight,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
