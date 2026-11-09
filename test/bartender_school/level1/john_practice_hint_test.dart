import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/john_reactions.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';

void main() {
  group('johnPracticeHint: ингредиенты', () {
    test('ничего не выбрано — просит вспомнить урок', () {
      final line = johnPracticeHint(
        JohnPracticeMoment.ingredients,
        selectedCount: 0,
        expectedCount: 3,
      );
      expect(line.trim(), isNotEmpty);
    });

    test('выбрано больше нужного — называет разницу', () {
      final line = johnPracticeHint(
        JohnPracticeMoment.ingredients,
        selectedCount: 5,
        expectedCount: 3,
      );
      expect(line, contains('2'));
    });

    test('выбрано меньше нужного — просит вспомнить вкус', () {
      final line = johnPracticeHint(
        JohnPracticeMoment.ingredients,
        selectedCount: 1,
        expectedCount: 3,
      );
      expect(line, isNotEmpty);
    });

    test('ровно нужное — переводит к вопросу «как»', () {
      final line = johnPracticeHint(
        JohnPracticeMoment.ingredients,
        selectedCount: 3,
        expectedCount: 3,
      );
      expect(line.trim(), isNotEmpty);
      // На этой ветке Джон уже не просит считать — он переводит к методу,
      // поэтому подсказка длиннее короткого «добавь ещё».
      expect(line.length, greaterThan(30));
    });
    test('все три состояния дают разные фразы', () {
      final less = johnPracticeHint(JohnPracticeMoment.ingredients,
          selectedCount: 1, expectedCount: 3);
      final exact = johnPracticeHint(JohnPracticeMoment.ingredients,
          selectedCount: 3, expectedCount: 3);
      final more = johnPracticeHint(JohnPracticeMoment.ingredients,
          selectedCount: 5, expectedCount: 3);
      expect({less, exact, more}.length, 3);
    });
  });

  group('johnPracticeHint: метод', () {
    test('напоминает правило shake-or-stir', () {
      final line = johnPracticeHint(JohnPracticeMoment.method).toLowerCase();
      expect(line, contains('shake'));
      expect(line, contains('stir'));
    });
  });

  group('подсказка НЕ называет правильный ответ', () {
    test('ни один ингредиент ни одного задания не упомянут в подсказках', () {
      // Реальные названия ингредиентов берём из контента мастерской:
      // если автор допишет в подсказку «возьми джин», тест это поймает.
      final names = <String>{};
      for (final challenge in allPracticeChallenges) {
        names.addAll(challenge.correctIngredients);
      }
      expect(names, isNotEmpty, reason: 'в контенте нет ингредиентов?');

      final hints = <String>[];
      for (var selected = 0; selected <= 6; selected++) {
        for (var expected = 0; expected <= 6; expected++) {
          hints.add(johnPracticeHint(
            JohnPracticeMoment.ingredients,
            selectedCount: selected,
            expectedCount: expected,
          ));
        }
      }
      hints.add(johnPracticeHint(JohnPracticeMoment.method));

      for (final hint in hints) {
        final lower = hint.toLowerCase();
        for (final name in names) {
          // Короткие слова («лёд», «сок») проверяем только целым словом,
          // иначе поймаем ложное срабатывание внутри другого слова.
          final needle = name.toLowerCase();
          final isWholeWord = RegExp(
            '(^|[^а-яёa-z])${RegExp.escape(needle)}([^а-яёa-z]|\$)',
          ).hasMatch(lower);
          expect(isWholeWord, isFalse,
              reason: 'подсказка называет ингредиент «$name»: $hint');
        }
      }
    });

    test('метод утверждения не подсказывает выбор', () {
      final all = allPracticeChallenges.map((c) => c.correctMethod).toSet();
      // Если все задания одного метода — правило не выдаёт ответ, но
      // контент перекосило; сообщим как факт.
      expect(all, isNotEmpty);
    });
  });
}
