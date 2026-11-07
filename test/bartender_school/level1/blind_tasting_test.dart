import 'dart:math';

import 'package:coin/features/bartender_school/data/blind_tasting.dart';
import 'package:coin/features/bartender_school/data/term_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Слепая дегустация — игра на тех же данных, что и уроки. Проверяем,
/// что раунд всегда играбелен: четыре разных варианта, один правильный,
/// три подсказки, и никаких повторов в один день.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Слепая дегустация', () {
    test('раунд собирается из изученных термов', () {
      final learnt = TermService.allTerms
          .take(6)
          .map((term) => term.russianName)
          .toSet();

      final round = buildBlindTastingRound(
        learntTermNames: learnt,
        random: Random(7),
      );

      expect(round, isNotNull);
      expect(round!.options, hasLength(4));
      expect(
        round.options.map((o) => o.russianName).toSet().length,
        4,
        reason: 'варианты не должны повторяться',
      );
      expect(
        round.options.any((o) => o.russianName == round.answer.russianName),
        isTrue,
        reason: 'правильный ответ обязан быть среди вариантов',
      );
      expect(learnt.contains(round.answer.russianName), isTrue);
    });

    test('до первого урока раунд всё равно есть', () {
      // Игра не должна быть пустой на старте: берём термы из будущих уроков.
      final round = buildBlindTastingRound(
        learntTermNames: const {},
        random: Random(1),
      );
      expect(round, isNotNull);
      expect(round!.options, hasLength(4));
    });

    test('подсказки открываются по одной и не пустые', () {
      final round = buildBlindTastingRound(
        learntTermNames: TermService.allTerms
            .take(8)
            .map((t) => t.russianName)
            .toSet(),
        random: Random(3),
      )!;

      expect(round.hints, hasLength(3));
      for (final hint in round.hints) {
        expect(hint.trim(), isNotEmpty);
      }
      // Первая подсказка — категория, то есть самое общее.
      expect(round.hints.first, contains('Категория'));
    });

    test('в один день раунд засчитывается один раз', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = BlindTastingService(prefs);

      expect(service.playedToday, isFalse);
      await service.registerRound(correct: true);
      await service.registerRound(correct: true);

      expect(service.playedToday, isTrue);
      expect(service.playedCount, 1, reason: 'повторный вызов не считается');
      expect(service.correctCount, 1);
    });

    test('ошибка засчитывается как сыгранный раунд, но не как верный', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = BlindTastingService(prefs);

      await service.registerRound(correct: false);

      expect(service.playedToday, isTrue);
      expect(service.playedCount, 1);
      expect(service.correctCount, 0);
    });
  });
}
