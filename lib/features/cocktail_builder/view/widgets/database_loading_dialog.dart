import 'package:flutter/material.dart';
import 'package:coin/core/models/database_load_progress.dart';

/// Диалог загрузки базы коктейлей
///
/// **Зачем нужен:**
/// - Показывает прогресс загрузки при первом запуске
/// - Профессиональный, стильный дизайн
/// - Можно закрыть (загрузка продолжится в фоне)
///
/// **Дизайн:**
/// - Тёмный фон с градиентом
/// - Анимированная иконка коктейля
/// - Progress bar с процентами
/// - Текущая буква (A-Z)
/// - Количество загруженных коктейлей
///
/// **Пример использования:**
/// ```dart
/// showDatabaseLoadingDialog(
///   context: context,
///   repository: cocktailRepo,
/// );
/// ```
class DatabaseLoadingDialog extends StatelessWidget {
  final Stream<DatabaseLoadProgress> progressStream;
  final VoidCallback? onClose;

  const DatabaseLoadingDialog({
    super.key,
    required this.progressStream,
    this.onClose,
  });

  /// Показать диалог загрузки
  static void show({
    required BuildContext context,
    required Stream<DatabaseLoadProgress> progressStream,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true, // Можно закрыть
      builder: (context) => DatabaseLoadingDialog(
        progressStream: progressStream,
        onClose: onClose,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE8B84B).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Анимированная иконка коктейля
            _AnimatedCocktailIcon(),

            const SizedBox(height: 20),

            // Заголовок
            const Text(
              'Загрузка базы рецептов',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Подзаголовок
            Text(
              'Скачиваем 600+ коктейлей для offline работы',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Progress stream builder
            StreamBuilder<DatabaseLoadProgress>(
              stream: progressStream,
              builder: (context, snapshot) {
                final progress = snapshot.data;

                if (progress == null) {
                  return const _LoadingPlaceholder();
                }

                return _ProgressContent(progress: progress);
              },
            ),

            const SizedBox(height: 20),

            // Кнопка закрыть
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onClose?.call();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Продолжить в фоне',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFE8B84B).withOpacity(0.8),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Анимированная иконка коктейля
class _AnimatedCocktailIcon extends StatefulWidget {
  const _AnimatedCocktailIcon();

  @override
  State<_AnimatedCocktailIcon> createState() => _AnimatedCocktailIconState();
}

class _AnimatedCocktailIconState extends State<_AnimatedCocktailIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8B84B),
                  Color(0xFFFFD700),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8B84B).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_bar,
              size: 36,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder пока нет данных
class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Индикатор загрузки
        const SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE8B84B)),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Подготовка...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// Контент с прогрессом
class _ProgressContent extends StatelessWidget {
  final DatabaseLoadProgress progress;

  const _ProgressContent({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        SizedBox(
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.progressPercent / 100,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFE8B84B)),
              minHeight: 6,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Процент
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Текущая буква
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8B84B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFE8B84B).withOpacity(0.3),
                ),
              ),
              child: Text(
                'Буква: ${progress.currentLetter}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE8B84B),
                ),
              ),
            ),

            // Процент
            Text(
              '${progress.progressPercent}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Количество коктейлей
        Text(
          '${progress.loadedCocktails} коктейлей загружено',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
