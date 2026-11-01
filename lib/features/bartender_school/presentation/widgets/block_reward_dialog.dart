/// Диалог награды за завершение блока.
///
/// Показывается после успешного завершения последнего урока блока.
/// Содержит:
/// - Новый ранг студента
/// - Персональное послание от Джона
/// - Бонусный XP
///
/// При закрытии награда автоматически "claim"-ится через [ProgressService].
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/features/bartender_school/data/block_rewards.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';

/// Показать диалог награды за блок.
/// Возвращает true если награда была получена.
Future<bool> showBlockRewardDialog(
  BuildContext context, {
  required BlockReward reward,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BlockRewardDialog(reward: reward),
  );
  return result ?? false;
}

/// Диалог награды за блок.
class _BlockRewardDialog extends StatelessWidget {
  final BlockReward reward;

  const _BlockRewardDialog({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1D1A2F),
              const Color(0xFF0F0D1A),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD4AF37).withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Верхняя часть: ранг ─────────────────────────────────────
            _buildRankHeader(),

            // ── Послание от Джона ───────────────────────────────────────
            _buildJohnMessage(),

            // ── Бонусный XP ─────────────────────────────────────────────
            _buildBonusXp(),

            // ── Кнопка получения ────────────────────────────────────────
            _buildClaimButton(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Заголовок с рангом и эмодзи.
  Widget _buildRankHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFD4AF37).withAlpha(25),
            Colors.transparent,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Большой эмодзи ранга
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4AF37).withAlpha(40),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                reward.rankEmoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Название ранга
          Text(
            'Ранг: ${reward.rankTitle}',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),

          // Название блока
          Text(
            reward.title,
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Послание от Джона.
  Widget _buildJohnMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Имя Джона
          const Row(
            children: [
              Text(
                '👨‍🍳 ',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'Джон:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Текст послания
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(12),
              ),
            ),
            child: Text(
              reward.johnMessage,
              style: TextStyle(
                color: Colors.white.withAlpha(220),
                fontSize: 13,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Бонусный XP.
  Widget _buildBonusXp() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4CAF50).withAlpha(20),
              const Color(0xFF4CAF50).withAlpha(5),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF4CAF50).withAlpha(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⭐ ', style: TextStyle(fontSize: 16)),
            Text(
              '+${reward.bonusXp} XP',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Кнопка "Получить".
  Widget _buildClaimButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Claim награду через ProgressService
            final progress = context.read<ProgressService>();
            progress.claimBlockReward(reward.blockId);
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Получить',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
