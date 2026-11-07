import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';

/// Экран «О приложении».
///
/// Здесь то, что нужно человеку перед первой покупкой и в любой момент:
/// кто мы, что умеет приложение, где хранятся данные и как начать заново.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('О приложении')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(90)),
                ),
                child: Image.asset('images/logo.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Школа бармена Джона',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Версия $_version',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Практический курс барменского дела: вкус и баланс, инструменты, '
            'техника и три классических коктейля. Уроки, квизы и мастерская '
            'работают без интернета — интернет нужен только для справки о '
            'коктейлях.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('ЧТО ВАЖНО ЗНАТЬ'),
          const _InfoRow(
            icon: Icons.school_outlined,
            title: 'Диплом — учебный',
            text: 'Приложение не выдаёт лицензию на продажу алкоголя и не '
                'заменяет обучение на рабочем месте.',
          ),
          const _InfoRow(
            icon: Icons.phone_android,
            title: 'Данные остаются на телефоне',
            text: 'Прогресс хранится локально. При удалении приложения он '
                'пропадёт — перенос между устройствами в этой версии не '
                'поддерживается.',
          ),
          const _InfoRow(
            icon: Icons.local_bar_outlined,
            title: '18+',
            text: 'Курс рассказывает об алкогольных коктейлях. Мастерская — '
                'тренировка рецептов и пропорций, а не приглашение пить.',
          ),
          const SizedBox(height: 28),
          const _SectionTitle('ПРОГРЕСС'),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context),
            icon: const Icon(Icons.restart_alt, size: 18),
            label: const Text('Начать обучение заново'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD0824A),
              side: const BorderSide(color: Color(0xFFD0824A)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Сброс удалит XP, монеты, пройденные уроки и диплом. '
            'Это действие нельзя отменить.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'Сделано для тех, кто учится за стойкой и дома.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final progress = context.read<ProgressService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Начать заново?'),
        content: const Text(
          'XP, монеты, пройденные уроки и диплом будут удалены. '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Сбросить',
              style: TextStyle(color: Color(0xFFD0824A)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await progress.resetProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Прогресс сброшен. Можно начинать заново.')),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
