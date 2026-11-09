import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/john_reactions.dart';

void main() {
  group('johnHomeMoment: что Джон скажет на главной', () {
    test('первый вход без прогресса — freshStart', () {
      expect(
        johnHomeMoment(
            streak: 0, daysSinceLastVisit: null, hasAnyProgress: false),
        JohnMoment.freshStart,
      );
    });

    test('прогресс есть, но дата неизвестна — freshStart', () {
      expect(
        johnHomeMoment(
            streak: 0, daysSinceLastVisit: null, hasAnyProgress: true),
        JohnMoment.freshStart,
      );
    });

    test('заходил сегодня, серии нет — returningToday', () {
      expect(
        johnHomeMoment(streak: 0, daysSinceLastVisit: 0, hasAnyProgress: true),
        JohnMoment.returningToday,
      );
    });

    test('заходил сегодня, серия 3 — streak', () {
      expect(
        johnHomeMoment(streak: 3, daysSinceLastVisit: 0, hasAnyProgress: true),
        JohnMoment.streak,
      );
    });

    test('пауза 2+ дня — returningAfterBreak', () {
      for (final days in [2, 3, 7, 30]) {
        expect(
          johnHomeMoment(
            streak: 5,
            daysSinceLastVisit: days,
            hasAnyProgress: true,
          ),
          JohnMoment.returningAfterBreak,
          reason: 'пауза $days дн. должна перебивать серию',
        );
      }
    });
  });

  group('johnVariantForDay', () {
    test('стабилен внутри одного дня и меняется по дням недели', () {
      // Понедельник 6 января 2025.
      final monday = DateTime(2025, 1, 6, 9);
      final mondayEvening = DateTime(2025, 1, 6, 21);
      expect(johnVariantForDay(monday), johnVariantForDay(mondayEvening));

      final variants = <int>{};
      for (var d = 0; d < 7; d++) {
        variants.add(johnVariantForDay(monday.add(Duration(days: d))));
      }
      expect(variants.length, 7);
    });
  });

  group('двойной провал не повторяет ту же фразу', () {
    // Ровно то, что просил план: после второго провала Джон меняет угол
    // подачи, а не повторяет первую фразу.
    test('первый провал и второй провал — разные наборы реплик', () {
      const first = JohnContext(failedAttemptsBefore: 0);
      const second = JohnContext(failedAttemptsBefore: 1);
      const third = JohnContext(failedAttemptsBefore: 2);

      final firstLines = <String>{};
      for (var v = 0; v < 6; v++) {
        firstLines.add(
            johnReaction(JohnMoment.quizFailedFirstTime, first, variant: v));
      }
      final secondLines = <String>{};
      for (var v = 0; v < 6; v++) {
        secondLines
            .add(johnReaction(JohnMoment.quizFailedAgain, second, variant: v));
      }
      final thirdLines = <String>{};
      for (var v = 0; v < 6; v++) {
        thirdLines
            .add(johnReaction(JohnMoment.quizFailedAgain, third, variant: v));
      }

      expect(firstLines.intersection(secondLines), isEmpty);
      expect(secondLines.intersection(thirdLines), isEmpty);
      expect(firstLines, isNotEmpty);
      expect(secondLines, isNotEmpty);
      expect(thirdLines, isNotEmpty);
    });
  });

  group('тон Джона: наблюдает, а не оценивает', () {
    const shame = [
      'позор',
      'стыд',
      'глупо',
      'тупость',
      'бездар',
      'ноль без',
      'неудачник',
      'никчём',
    ];

    test('ни в одной реплике нет слов стыда', () {
      final contexts = <JohnContext>[
        const JohnContext(),
        const JohnContext(streak: 2),
        const JohnContext(streak: 3),
        const JohnContext(streak: 7),
        const JohnContext(daysSinceLastVisit: 1),
        const JohnContext(daysSinceLastVisit: 3),
        const JohnContext(daysSinceLastVisit: 7),
        const JohnContext(failedAttemptsBefore: 1),
        const JohnContext(failedAttemptsBefore: 2),
        const JohnContext(stars: 1),
        const JohnContext(stars: 2),
        const JohnContext(stars: 3),
      ];
      for (final moment in JohnMoment.values) {
        for (final ctx in contexts) {
          for (var v = 0; v < 4; v++) {
            final line = johnReaction(moment, ctx, variant: v).toLowerCase();
            for (final word in shame) {
              expect(line.contains(word), isFalse,
                  reason: '$moment / $word → $line');
            }
          }
        }
      }
    });

    test('каждая реплика не пустая и без двойных пробелов', () {
      const ctx = JohnContext(streak: 3, daysSinceLastVisit: 3, stars: 2);
      for (final moment in JohnMoment.values) {
        final line = johnReaction(moment, ctx);
        expect(line.trim(), isNotEmpty, reason: '$moment пустая');
        expect(line.contains('  '), isFalse, reason: '$moment: $line');
      }
    });
  });
}
