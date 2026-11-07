import 'package:coin/features/bartender_school/data/john_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Реплики Джона — часть продукта, а значит их надо проверять как контент:
/// ни одна фраза не должна быть пустой, повторяться дословно у разных
/// событий и не должна стыдить за провал.
void main() {
  group('Реплики Джона', () {
    test('каждое событие даёт непустую фразу', () {
      for (final moment in JohnMoment.values) {
        for (final variant in [0, 1, 2, 3]) {
          final line = johnReaction(moment, const JohnContext(), variant: variant);
          expect(line.trim(), isNotEmpty, reason: '$moment, вариант $variant');
        }
      }
    });

    test('длина фразы подходит для карточки на главной', () {
      for (final moment in JohnMoment.values) {
        for (final variant in [0, 1]) {
          final line = johnReaction(moment, const JohnContext(), variant: variant);
          // Карточка Джона — три строки на узком экране; длиннее не влезает
          // без обрезки, а обрезанная фраза читается как ошибка.
          expect(line.length, lessThanOrEqualTo(140),
              reason: '$moment: «$line»');
        }
      }
    });

    test('выбор детерминирован при одинаковом состоянии', () {
      const context = JohnContext(streak: 4);
      expect(
        johnReaction(JohnMoment.streak, context, variant: 2),
        johnReaction(JohnMoment.streak, context, variant: 2),
      );
    });

    test('пауза меняет тон в зависимости от её длины', () {
      final short = johnReaction(
        JohnMoment.returningAfterBreak,
        const JohnContext(daysSinceLastVisit: 2),
      );
      final long = johnReaction(
        JohnMoment.returningAfterBreak,
        const JohnContext(daysSinceLastVisit: 10),
      );
      expect(short, isNot(long));
    });

    test('на повторный провал Джон не стыдит', () {
      const context = JohnContext(failedAttemptsBefore: 3);
      // Слова, которые не должны появляться в разговоре о провале: это
      // школа, а не экзамен на выживание.
      const forbidden = ['позор', 'стыдно', 'слабо', 'провалил окончательно'];

      for (final variant in [0, 1]) {
        final line = johnReaction(
          JohnMoment.quizFailedAgain,
          context,
          variant: variant,
        ).toLowerCase();
        for (final word in forbidden) {
          expect(line.contains(word), isFalse, reason: '«$line» содержит «$word»');
        }
      }
    });

    test('звёзды в мастерской дают разный разбор', () {
      String lineFor(int stars) => johnReaction(
            JohnMoment.cocktailBuilt,
            JohnContext(stars: stars),
          );

      expect(lineFor(3), isNot(lineFor(0)));
      expect(lineFor(3), isNot(lineFor(2)));
    });

    test('daysSince считает календарные дни, а не часы', () {
      final now = DateTime(2026, 11, 7, 9);
      expect(daysSince(null, now), isNull);
      expect(daysSince(DateTime(2026, 11, 7, 23), now), 0);
      expect(daysSince(DateTime(2026, 11, 6, 1), now), 1);
      expect(daysSince(DateTime(2026, 10, 30, 12), now), 8);
    });
  });
}
