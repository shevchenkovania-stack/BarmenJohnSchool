import 'dart:async';

import 'package:flutter/material.dart';

import 'package:coin/core/services/bar_sound_service.dart';
import 'package:coin/core/theme/app_theme.dart';

/// Живая заставка перед уроком.
///
/// Задача — не развлечь, а дать сцене «вдохнуть»: фон едет медленнее
/// переднего плана, лампа покачивается, реплика Джона печатается. Всё
/// на обычных `AnimationController` и `Transform`, без игровых движков:
/// так заставка не ломает тесты и не тянет второй цикл рендера.
///
/// Правила, которые нельзя нарушать:
/// - при `MediaQuery.disableAnimations` (настройка «убрать анимации»)
///   показывается статичный кадр и кнопка «Дальше» сразу;
/// - ничего не блокирует: «Пропустить» доступна с первой секунды;
/// - на 4 секунды всего, потом сама отдаёт управление.
class LessonTeaser extends StatefulWidget {
  /// Заголовок сцены (например, «Школа бармена Джона»).
  final String title;

  /// Реплика, которая печатается по буквам.
  final String line;

  /// Что вызывать, когда заставка закончилась или её пропустили.
  final VoidCallback onFinished;

  /// Фон сцены.
  final String backgroundAsset;

  /// Портрет Джона.
  final String johnAsset;

  const LessonTeaser({
    super.key,
    required this.title,
    required this.line,
    required this.onFinished,
    this.backgroundAsset = 'images/john_room_school_hall.jpg',
    this.johnAsset = 'images/barista_john_teach.png',
  });

  @override
  State<LessonTeaser> createState() => _LessonTeaserState();
}

class _LessonTeaserState extends State<LessonTeaser>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 4200);
  static const Duration _typeDuration = Duration(milliseconds: 2200);

  late final AnimationController _controller;
  Timer? _finishTimer;
  int _visibleChars = 0;
  bool _finished = false;
  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _controller.addListener(_onTick);
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Уважаем системную настройку: без анимаций заставка не нужна.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _visibleChars = widget.line.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else if (!_controller.isAnimating && !_finished) {
      _controller.forward();
    }
  }

  void _onTick() {
    if (_finished) return;
    final typed = (_controller.value *
            _duration.inMilliseconds /
            _typeDuration.inMilliseconds *
            widget.line.length)
        .round()
        .clamp(0, widget.line.length);

    if (typed != _visibleChars) {
      setState(() => _visibleChars = typed);
    }

    // Стук бокала — один раз, когда сцена «проявилась».
    if (!_soundPlayed && _controller.value > 0.12) {
      _soundPlayed = true;
      BarSoundService.instance.glassTap();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _finishTimer?.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _controller
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(_controller.value);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1008),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Задний план: едет медленно и уходит в темноту ──
          Transform.scale(
            scale: 1.12 - 0.04 * t,
            child: Transform.translate(
              offset: Offset(0, -14 * t),
              child: Image.asset(
                widget.backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                opacity: const AlwaysStoppedAnimation(0.85),
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF2A1B0F)),
              ),
            ),
          ),

          // ── Тёплый свет лампы, пульсирует ──
          IgnorePointer(
            child: Opacity(
              opacity: 0.35 + 0.15 * t,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.45),
                    radius: 0.9,
                    colors: [Color(0x66FFB347), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),

          // ── Затемнение снизу под текст ──
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.35, 0.75, 1],
                colors: [
                  Color(0x00000000),
                  Color(0xCC1A1008),
                  Color(0xFF1A1008)
                ],
              ),
            ),
          ),

          // ── Передний план: Джон и текст ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0x99E8D6B1),
                      ),
                      child: const Text(
                        'Пропустить',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Джон въезжает слева и «дышит».
                  Transform.translate(
                    offset: Offset(-30 * (1 - t), 0),
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              widget.johnAsset,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, __, ___) => Container(
                                width: 76,
                                height: 76,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3A2515),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_bar_rounded,
                                  color: Color(0xFFE8A838),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                color: Color(0xFFE8A838),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Реплика печатается — как будто Джон говорит.
                  Text(
                    widget.line.substring(0, _visibleChars),
                    style: const TextStyle(
                      color: Color(0xFFF4E7CE),
                      fontSize: 17,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Тонкая линия прогресса внизу ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: _controller.value,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFE8A838)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Обёртка: показывает заставку один раз за сессию и потом открывает экран.
///
/// Отдельный виджет, чтобы не тащить показ внутрь урока: урок продолжает
/// работать как обычно, а сцена — необязательная шапка к нему.
class LessonTeaserGate extends StatefulWidget {
  /// Экран, который открывается после заставки.
  final Widget child;

  final String title;
  final String line;

  /// Ключ в SharedPreferences: если `true`, заставку больше не показываем.
  final String? seenKey;

  const LessonTeaserGate({
    super.key,
    required this.child,
    required this.title,
    required this.line,
    this.seenKey,
  });

  @override
  State<LessonTeaserGate> createState() => _LessonTeaserGateState();
}

class _LessonTeaserGateState extends State<LessonTeaserGate> {
  bool? _show;

  @override
  void initState() {
    super.initState();
    // Заставка не должна требовать хранилища: если ключ не задан —
    // показываем её всегда, решение об этом принимает вызывающий код.
    _show = widget.seenKey == null;
  }

  @override
  Widget build(BuildContext context) {
    if (_show == false) return widget.child;

    if (_show == null) {
      // Пока решаем — держим фон, чтобы не мигало белым.
      return const Scaffold(backgroundColor: AppColors.background);
    }

    return LessonTeaser(
      title: widget.title,
      line: widget.line,
      onFinished: () {
        if (!mounted) return;
        setState(() => _show = false);
      },
    );
  }
}
