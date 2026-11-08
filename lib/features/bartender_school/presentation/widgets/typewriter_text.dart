import 'dart:async';

import 'package:flutter/material.dart';

/// Текст, который печатается посимвольно.
///
/// Тап по тексту дописывает всё сразу: ждать до конца не обязательно.
/// Если в системе отключены анимации (доступность), текст появляется
/// мгновенно — иначе экран оказался бы пустым для тех, кто просил
/// убрать движение.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  /// Миллисекунды на символ.
  final int speedMs;

  /// Задержка перед началом печати.
  final Duration delay;

  /// Вызывается, когда текст дописан целиком.
  final VoidCallback? onDone;

  const TypewriterText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.speedMs = 22,
    this.delay = Duration.zero,
    this.onDone,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  int _shown = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // MediaQuery доступен только после вставки в дерево, поэтому решение
    // «печатать или показать сразу» принимаем в первом кадре.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleStart();
    });
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      setState(() {
        _shown = 0;
        _done = false;
      });
      _scheduleStart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _animationsDisabled {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations ?? false;
  }

  void _scheduleStart() {
    if (_animationsDisabled) {
      // Никакой асинхронности: сразу весь текст, чтобы не заставлять
      // ждать тех, кто отключил движение.
      setState(() {
        _shown = widget.text.length;
        _done = true;
      });
      widget.onDone?.call();
      return;
    }

    if (widget.delay > Duration.zero) {
      _timer = Timer(widget.delay, _tick);
    } else {
      _tick();
    }
  }

  void _tick() {
    if (!mounted) return;
    if (_shown >= widget.text.length) {
      _finish();
      return;
    }
    setState(() => _shown++);
    _timer = Timer(Duration(milliseconds: widget.speedMs), _tick);
  }

  void _finish() {
    _timer?.cancel();
    if (_done) return;
    setState(() {
      _shown = widget.text.length;
      _done = true;
    });
    widget.onDone?.call();
  }

  /// Дописать всё сразу — по тапу.
  void skipToEnd() => _finish();

  @override
  Widget build(BuildContext context) {
    final visible =
        widget.text.substring(0, _shown.clamp(0, widget.text.length));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Text(
        visible,
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}
