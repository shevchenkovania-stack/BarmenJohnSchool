/// Пролог Джона Бартоне — показывается при первом входе в школу.
///
/// Атмосфера: тёмный экран, свет лампы, портрет Джона.
/// Текст появляется строка за строкой с паузами — как будто Джон
/// не спеша рассказывает за пустым баром после смены.
///
/// После последней строки — кнопка "Начать обучение".
/// Показыватся только 1 раз (флаг [ProgressService.hasSeenLevel1Prologue]).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:coin/features/bartender_school/data/john_backstory.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';

/// Показывает атмосферный пролог Джона.
///
/// Возвращает [true], если пролог был показан и завершён пользователем.
/// Возвращает [false], если пользователь закрыл диалог до конца.
Future<bool> showJohnPrologue({
  required BuildContext context,
  required ProgressService progressService,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) => const _JohnPrologueDialog(),
  );

  if (result == true) {
    await progressService.markLevel1PrologueSeen();
    return true;
  }
  return false;
}

// ── Внутренний виджет ────────────────────────────────────────────────────────

class _JohnPrologueDialog extends StatefulWidget {
  const _JohnPrologueDialog();

  @override
  State<_JohnPrologueDialog> createState() => _JohnPrologueDialogState();
}

class _JohnPrologueDialogState extends State<_JohnPrologueDialog>
    with TickerProviderStateMixin {
  /// Индекс текущей показанной строки (0 = ни одной, prologueLines.length = все).
  int _visibleLineCount = 0;

  /// Все ли строки показаны.
  bool get _allLinesShown =>
      _visibleLineCount >= prologueLines.length;

  /// Таймер для последовательного появления строк.
  Timer? _lineTimer;

  @override
  void initState() {
    super.initState();
    _startRevealing();
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    super.dispose();
  }

  /// Запускает последовательное появление строк.
  void _startRevealing() {
    // Первая строка появляется через короткую паузу — атмосфера.
    _lineTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_allLinesShown) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleLineCount++;
      });
    });
  }

  /// Пропустить анимацию — показать всё сразу.
  void _skipAnimation() {
    _lineTimer?.cancel();
    if (mounted) {
      setState(() {
        _visibleLineCount = prologueLines.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GestureDetector(
        // Тап по пустому месту — пропустить анимацию (показать всё сразу).
        onTap: _allLinesShown ? null : _skipAnimation,
        child: Container(
          decoration: BoxDecoration(
            // Тёмный градиент — атмосфера ночного бара.
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D0D1A),
                Color(0xFF1A1028),
                Color(0xFF0D0D1A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFD4AF37).withAlpha(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),

              // ── Портрет Джона ──────────────────────────────────────────
              _buildJohnPortrait(),
              const SizedBox(height: 16),

              // ── Текст пролога (строки появляются по одной) ─────────────
              // На низком экране (360×640, 320×568) портрет + весь пролог +
              // кнопка не помещались и Column переполнялась на 38 px: текст
              // прокручивается внутри, портрет и кнопка всегда на виду.
              Flexible(
                child: SingleChildScrollView(
                  child: _buildPrologueText(),
                ),
              ),

              const SizedBox(height: 8),

              // ── Кнопка (появляется после всех строк) ───────────────────
              _buildStartButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Портрет Джона в круге с золотой рамкой и мягким свечением.
  Widget _buildJohnPortrait() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4AF37).withAlpha(120),
                width: 2,
              ),
              // Мягкое золотое свечение.
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withAlpha(25),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'images/barista_john_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFD4AF37).withAlpha(20),
                child: const Center(
                  child: Text('🍸', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            johnFullName,
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Текст пролога — строки появляются последовательно с анимацией fade.
  Widget _buildPrologueText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(prologueLines.length, (index) {
          final line = prologueLines[index];
          final isShown = index < _visibleLineCount;
          final isEmpty = line.isEmpty;

          // Пустая строка = разделитель (просто отступ).
          if (isEmpty) {
            return AnimatedOpacity(
              opacity: isShown ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: const SizedBox(height: 12),
            );
          }

          return AnimatedOpacity(
            opacity: isShown ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(
                  color: index < 3
                      ? Colors.white.withAlpha(230)
                      : Colors.white.withAlpha(180),
                  fontSize: index < 3 ? 16 : 14,
                  fontWeight:
                      index == 0 ? FontWeight.w700 : FontWeight.w400,
                  height: 1.5,
                  fontStyle: index >= 4 ? FontStyle.italic : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Кнопка "Начать обучение" — появляется после всех строк.
  Widget _buildStartButton() {
    return AnimatedOpacity(
      opacity: _allLinesShown ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _allLinesShown ? Offset.zero : const Offset(0, 0.3),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _allLinesShown
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0D0D1A),
                disabledBackgroundColor:
                    const Color(0xFFD4AF37).withAlpha(40),
                disabledForegroundColor:
                    const Color(0xFF0D0D1A).withAlpha(40),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                prologueStartButton,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
