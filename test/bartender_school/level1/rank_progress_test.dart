import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/presentation/widgets/rank_progress_card.dart';

void main() {
  group('rankInfoFor', () {
    test('без закрытых блоков — новичок', () {
      final info = rankInfoFor(rank: null, totalXP: 0);
      expect(info.title, 'Новичок');
      expect(info.levelInRank, 1);
      expect(info.xpInRank, 0);
      expect(info.xpToNext, 250);
      expect(info.progress, 0);
    });

    test('звание берётся из прогресса, а не из XP', () {
      // 1500 XP, но C ещё не закрыт — значит не «Миксолог».
      final info = rankInfoFor(rank: null, totalXP: 1500);
      expect(info.title, 'Новичок');
    });

    test('XP двигает уровень внутри звания', () {
      final at0 = rankInfoFor(rank: null, totalXP: 0);
      final at250 = rankInfoFor(rank: null, totalXP: 250);
      final at600 = rankInfoFor(rank: null, totalXP: 600);

      expect(at0.levelInRank, 1);
      expect(at250.levelInRank, 2);
      expect(at600.levelInRank, 3);
    });

    test('полоса заполняется внутри шага, а не нарастает бесконечно', () {
      final mid = rankInfoFor(rank: null, totalXP: 375); // между 250 и 600
      expect(mid.levelInRank, 2);
      expect(mid.xpInRank, 125);
      expect(mid.xpToNext, 350);
      expect(mid.progress, closeTo(125 / 350, 1e-9));
    });

    test('на максимуме полоса полная и нет обещания следующего', () {
      final maxed = rankInfoFor(rank: null, totalXP: 99999);
      expect(maxed.isMaxed, isTrue);
      expect(maxed.xpToNext, 0);
      expect(maxed.progress, 1.0);
    });

    test('прогресс никогда не выходит за 0..1', () {
      for (final xp in [
        0,
        1,
        249,
        250,
        599,
        600,
        999,
        1000,
        1499,
        1500,
        5000
      ]) {
        final info = rankInfoFor(rank: null, totalXP: xp);
        expect(info.progress, greaterThanOrEqualTo(0));
        expect(info.progress, lessThanOrEqualTo(1));
        expect(info.levelInRank, greaterThanOrEqualTo(1));
      }
    });

    test('эмодзи звания из прогресса попадает в карточку', () {
      final info = rankInfoFor(
        rank: (title: 'Миксолог', emoji: '🎓'),
        totalXP: 600,
      );
      expect(info.title, 'Миксолог');
      expect(info.emoji, '🎓');
    });
  });
}
