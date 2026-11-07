import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/home/home_viewmodel.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/features/bartender_school/data/john_reactions.dart';
import 'package:coin/features/bartender_school/data/blind_tasting.dart';
import 'package:coin/features/bartender_school/data/guest_echo.dart';
import 'package:coin/features/bartender_school/presentation/screens/blind_tasting_screen.dart';
import 'package:coin/features/bartender_school/data/weekly_contract.dart';
import 'package:coin/core/services/bar_sound_service.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/presentation/screens/level1_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/glossary_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/certificates_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/student_name_dialog.dart';
import 'package:coin/features/settings/view/settings_screen.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:coin/features/cocktail_list/view/cocktail_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final dailyChallenge = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<HomeViewModel>(
        builder: (_, vm, __) {
          if (!vm.hasCache) return const _NoCacheChallengeHint();
          if (vm.isLoading) return const _Skeleton();
          if (vm.hasError) return _ErrorCard(onRetry: vm.loadRandom);
          if (vm.cocktail != null) {
            return _DailyChallengeCard(
              cocktail: vm.cocktail!,
              onRefresh: vm.loadRandom,
            );
          }
          return const _Skeleton();
        },
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: JohnRoomBackground(
        room: JohnSchoolRoom.foyer,
        evening: isEveningNow(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Порог поднят с 560: карточка Джона добавила строку, и на
            // экранах 640 px высотой фиксированная колонка упиралась в низ.
            final isCompactHeight = constraints.maxHeight < 640;
            // Слот карточки дня масштабируется от высоты экрана: фиксированные
            // 205 px обрезали плашку «Загрузите рецепты» вместе с кнопкой на
            // телефонах 640-700 px, и её было видно только в альбомной
            // ориентации.
            final challengeSlot =
                (constraints.maxHeight * 0.34).clamp(200.0, 320.0).toDouble();
            final children = <Widget>[
              _SchoolHeroHeader(topPad: topPad),
              const _JohnSays(),
              const SizedBox(height: 12),
              if (isCompactHeight)
                SizedBox(height: challengeSlot, child: dailyChallenge)
              else
                Expanded(child: dailyChallenge),
              const SizedBox(height: 12),
              const _WeeklyContractCard(),
              const SizedBox(height: 12),
              const _LevelCardsRow(),
              const SizedBox(height: 12),
              const _QuickActionsRow(),
              const SizedBox(height: 12),
            ];

            if (isCompactHeight) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          },
        ),
      ),
    );
  }
}

// ── School Hero Header ────────────────────────────────────────────────────────

class _SchoolHeroHeader extends StatelessWidget {
  final double topPad;
  const _SchoolHeroHeader({required this.topPad});

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(JohnSchoolRoom.foyer);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF13B2619),
            Color(0xF01D120D),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: style.accent.withAlpha(155), width: 1),
        ),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 16, offset: Offset(0, 7)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF1D8A0),
              shape: BoxShape.circle,
              border: Border.all(color: style.accent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: style.accent.withAlpha(95),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(
                'images/barista_john_logo.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ШКОЛА БАРМЕНА ДЖОНА',
                  style: TextStyle(
                    color: Color(0xFFF8E8BD),
                    fontFamily: 'serif',
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Level 1: основы, практика и честный экзамен',
                  style: TextStyle(
                    color: style.onDark.withAlpha(190),
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.accent.withAlpha(22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: style.accent.withAlpha(95)),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: style.onDark,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Джон говорит ─────────────────────────────────────────────────────────────

/// Короткая реплика Джона под шапкой.
///
/// Это первый слой «живого приложения»: текст зависит от того, когда человек
/// заходил в последний раз и какая у него серия. Никакой случайности — при
/// одном и том же состоянии фраза одна и та же, поэтому её можно проверить.
class _JohnSays extends StatefulWidget {
  const _JohnSays();

  @override
  State<_JohnSays> createState() => _JohnSaysState();
}

class _JohnSaysState extends State<_JohnSays> {
  static const _lastVisitKey = 'john_last_visit_day';

  String _text = '';
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickLine());
    // Фоновый джаз бара — только на главной.
    BarSoundService.instance.playBg();
  }

  @override
  void dispose() {
    BarSoundService.instance.stopBg();
    super.dispose();
  }

  Future<void> _pickLine() async {
    if (!mounted) return;
    final progress = context.read<ProgressService>();
    final prefs = context.read<SharedPreferences>();
    final now = DateTime.now();

    final lastRaw = prefs.getString(_lastVisitKey);
    final lastVisit = lastRaw == null ? null : DateTime.tryParse(lastRaw);
    final gap = daysSince(lastVisit, now);

    final JohnMoment moment;
    if (progress.completedRegularLessons == 0 && (gap == null || gap > 0)) {
      moment = JohnMoment.freshStart;
    } else if (gap == null) {
      moment = JohnMoment.freshStart;
    } else if (gap == 0) {
      moment = JohnMoment.returningToday;
    } else if (gap >= 2) {
      moment = JohnMoment.returningAfterBreak;
    } else {
      moment = JohnMoment.streak;
    }

    // Запоминаем сегодняшний день уже после выбора фразы, иначе повторный
    // заход сегодня выглядел бы как «вернулся после паузы».
    await prefs.setString(
      _lastVisitKey,
      DateTime(now.year, now.month, now.day).toIso8601String(),
    );

    // Эхо гостя: если прошлый выбор в сцене был давно, Джон сначала
    // говорит о нём, а не о погоде. Приоритет у памяти, не у расписания.
    final echo = context.read<GuestEchoService>().takeEcho();
    if (!mounted) return;
    if (echo != null) {
      setState(() {
        _text = echo;
        _ready = true;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _text = johnReaction(
        moment,
        JohnContext(streak: progress.streak, daysSinceLastVisit: gap),
      );
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(JohnSchoolRoom.foyer);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: style.surface.withAlpha(190),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.accent.withAlpha(90)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Image.asset(
                'images/barista_john.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox(width: 32),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ДЖОН',
                    style: TextStyle(
                      color: style.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _ready ? _text : 'Джон протирает стойку…',
                    style: TextStyle(
                      color: style.onDark,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Недельный контракт Джона ──────────────────────────────────────────────────

/// Карточка «Договор на неделю»: три пункта и история в награду.
///
/// Цифры здесь второстепенны: главное — что человек получает историю,
/// а не ещё одну строку XP. Поэтому когда контракт закрыт, карточка
/// превращается в кнопку «Слушать историю».
class _WeeklyContractCard extends StatelessWidget {
  const _WeeklyContractCard();

  @override
  Widget build(BuildContext context) {
    final contract = context.watch<WeeklyContractService>();
    final style = JohnRoomStyle.forRoom(JohnSchoolRoom.foyer);
    final claimed = contract.isClaimed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: style.surface.withAlpha(205),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                contract.isComplete ? style.accent : style.accent.withAlpha(70),
            width: contract.isComplete ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    claimed ? 'ДОГОВОР ЗАКРЫТ' : 'ДОГОВОР НА НЕДЕЛЮ',
                    style: TextStyle(
                      color: style.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                if (!claimed)
                  Text(
                    '${contract.items.where((i) => i.isComplete).length}/${contract.items.length}',
                    style: TextStyle(
                      color: style.onDark.withAlpha(170),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (claimed)
              Text(
                'История от Джона уже у тебя. В понедельник — новый договор.',
                style:
                    TextStyle(color: style.onDark, fontSize: 13, height: 1.35),
              )
            else ...[
              for (final item in contract.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(item.emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: item.isComplete
                                ? style.accent
                                : style.onDark.withAlpha(200),
                            fontSize: 13,
                            height: 1.3,
                            decoration: item.isComplete
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        '${item.done}/${item.target}',
                        style: TextStyle(
                          color: style.onDark.withAlpha(150),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: contract.isComplete
                      ? () => _claimStory(context, contract)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: style.accent,
                    foregroundColor: style.ink,
                    disabledBackgroundColor: style.accent.withAlpha(45),
                    disabledForegroundColor: style.onDark.withAlpha(140),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    contract.isComplete
                        ? 'Забрать историю'
                        : 'Джон ждёт до понедельника',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _claimStory(
    BuildContext context,
    WeeklyContractService contract,
  ) async {
    final story = await contract.claim();
    if (story == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(story.title),
        content: SingleChildScrollView(child: Text(story.text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Спасибо, Джон'),
          ),
        ],
      ),
    );
  }
}

// ── Level Cards Row (горизонтальная линия) ────────────────────────────────────
class _LevelCardsRow extends StatelessWidget {
  const _LevelCardsRow();

  Future<void> _navigateToSchool(BuildContext context) async {
    final progress = context.read<ProgressService>();
    // If name not entered, show dialog first
    if (!progress.hasEnteredName) {
      final saved = await StudentNameDialog.show(context);
      if (!saved) return; // User cancelled
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Level1Screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _CompactLevelCard(
        room: JohnSchoolRoom.flavorLab,
        iconAsset: 'images/ui_icon_book_theory.png',
        title: 'Level 1: Базовый курс',
        onTap: () => _navigateToSchool(context),
      ),
    );
  }
}

class _CompactLevelCard extends StatelessWidget {
  final JohnSchoolRoom room;
  final String iconAsset;
  final String title;
  final VoidCallback onTap;

  const _CompactLevelCard({
    required this.room,
    required this.iconAsset,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return GestureDetector(
      onTap: onTap,
      child: JohnWoodPanel(
        room: room,
        highlighted: true,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    style.accent.withAlpha(55),
                    style.accentSoft.withAlpha(30),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: style.accent.withAlpha(110)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(iconAsset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: style.onDark,
                  fontFamily: 'serif',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 22,
              color: style.accent,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Row ─────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickAction(
              label: 'Словарь',
              assetPath: 'images/ui_icon_book_theory.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlossaryScreen()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              label: 'Дегустация',
              assetPath: 'images/ui_icon_tip_citrus.png',
              // Маленькая точка, если раунд дня ещё не сыгран: приглашение
              // без текста, которое не давит.
              badge:
                  context.watch<BlindTastingService>().playedToday ? null : '1',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlindTastingScreen()),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _QuickAction(
              label: 'Диплом',
              assetPath: 'images/ui_icon_checklist.png',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CertificatesScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final String assetPath;
  final VoidCallback onTap;

  /// Метка справа сверху (например, «1» — доступен раунд дня).
  final String? badge;

  const _QuickAction({
    required this.label,
    required this.assetPath,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          JohnWoodPanel(
            room: JohnSchoolRoom.foyer,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(assetPath, width: 21, height: 21),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFFE8D6B1),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF1D120D), width: 1.5),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── No-Cache Challenge Hint ───────────────────────────────────────────────────

class _NoCacheChallengeHint extends StatelessWidget {
  const _NoCacheChallengeHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceLight, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(40), width: 1),
      ),
      // Карточка стоит в слоте ограниченной высоты, поэтому сама умеет
      // прокручиваться: раньше при высоте 205 px кнопка «Загрузить»
      // обрезалась, и на маленьком экране плашку было видно только в
      // горизонтальной ориентации.
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8A838), Color(0xFFB8821A)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.download_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'Загрузите рецепты',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Вызов дня берётся из базы рецептов — один раз скачать, '
                  'дальше работает без интернета',
                  style: TextStyle(
                    color: Color(0xC0FFFFFF),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Consumer<HomeViewModel>(
                  builder: (context, vm, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: vm.isLoading
                                  ? null
                                  : () => _openRecipes(context, vm),
                              icon: vm.isLoading
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.library_books_rounded,
                                      size: 16),
                              label: Text(
                                vm.isLoading ? 'Загрузка...' : 'Скачать базу',
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE8A838),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Второй путь: одним запросом взять случайный
                          // рецепт, если человеку нужен только вызов дня.
                          IconButton(
                            tooltip: 'Один случайный рецепт',
                            onPressed:
                                vm.isLoading ? null : () => vm.loadRandom(),
                            icon: const Icon(Icons.casino_rounded, size: 20),
                            color: Colors.white,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withAlpha(30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Ошибка сети больше не теряется: раньше кнопка просто
                      // ничего не делала, и это выглядело как поломка.
                      if (vm.hasError && vm.errorReason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          vm.errorReason!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFFFC9A3),
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Открываем список рецептов — именно там скачивается вся база.
  void _openRecipes(BuildContext context, HomeViewModel vm) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CocktailListScreen()),
    ).then((_) => vm.reloadAfterBrowse());
  }
}

// ── Daily Challenge Card (большая карточка) ───────────────────────────────────

class _DailyChallengeCard extends StatelessWidget {
  final Cocktail cocktail;
  final VoidCallback onRefresh;

  const _DailyChallengeCard({required this.cocktail, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cocktailName = cocktail.strDrink;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF24160F),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xB0D0A24C), width: 1.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Full-bleed image ──
            CachedNetworkImage(
              imageUrl: cocktail.strDrinkThumb,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              placeholder: (_, __) => Container(
                color: AppColors.shimmerBase,
                child: const Center(
                  child:
                      Icon(Icons.local_bar, color: Color(0xFFE8A838), size: 48),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.shimmerBase,
                child: const Icon(Icons.local_bar,
                    color: Color(0xFFE8A838), size: 64),
              ),
            ),

            // ── Bottom gradient (for text legibility) ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(160),
                    ],
                  ),
                ),
              ),
            ),

            // ── Badge: "СЕГОДНЯ НАУЧИСЬ" ──
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB88935), Color(0xFF6D441C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 11),
                    SizedBox(width: 4),
                    Text(
                      'СЕГОДНЯ НАУЧИСЬ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Refresh button ──
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: onRefresh,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(100),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(Icons.shuffle_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ),

            // ── Chips + cocktail name overlaid at bottom ──
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Chip(label: cocktail.strCategory, isAccent: true),
                      const SizedBox(width: 6),
                      _Chip(label: cocktail.strAlcoholic),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cocktailName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool isAccent;
  const _Chip({required this.label, this.isAccent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAccent
            ? const Color(0xFFE8A838).withAlpha(230)
            : AppColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(50),
        border: isAccent
            ? null
            : Border.all(color: AppColors.primary.withAlpha(60), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isAccent ? Colors.black : AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              color: AppColors.textSecondary.withAlpha(120), size: 44),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).homeLoadError,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded,
                size: 16, color: AppColors.primary),
            label: Text(
              AppLocalizations.of(context).actionRetry,
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
