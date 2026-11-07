import 'package:coin/features/bartender_school/data/guest_echo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Эхо гостя — единственное место, где приложение «помнит» ученика между
/// уроками. Проверяем три вещи: эхо не появляется сразу, не повторяется
/// дважды за день и не врёт о тоне выбора.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GuestEchoService> service() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return GuestEchoService(prefs);
  }

  group('Эхо гостя', () {
    test('без выбора эха нет', () async {
      final echo = await service();
      expect(echo.last, isNull);
      expect(echo.takeEcho(DateTime(2026, 11, 7)), isNull);
    });

    test('эхо молчит первые дни после выбора', () async {
      final echo = await service();
      await echo.remember(
        sceneTitle: 'Пятничная запара',
        choiceText: 'Налить воду и отойти',
        wasRight: true,
        now: DateTime(2026, 11, 7, 10),
      );

      expect(echo.takeEcho(DateTime(2026, 11, 7, 22)), isNull);
      expect(echo.takeEcho(DateTime(2026, 11, 9, 9)), isNull);
    });

    test('через три дня эхо возвращает выбор в кавычках', () async {
      final echo = await service();
      await echo.remember(
        sceneTitle: 'Пятничная запара',
        choiceText: 'Налить воду и отойти',
        wasRight: true,
        now: DateTime(2026, 11, 7, 10),
      );

      final phrase = echo.takeEcho(DateTime(2026, 11, 10, 9));

      expect(phrase, isNotNull);
      expect(phrase, contains('Пятничная запара'));
      expect(phrase, contains('Налить воду и отойти'));
    });

    test('эхо не повторяется в тот же день, но вернётся позже', () async {
      final echo = await service();
      await echo.remember(
        sceneTitle: 'Сцена',
        choiceText: 'Промолчать',
        wasRight: false,
        now: DateTime(2026, 11, 1, 12),
      );

      expect(echo.takeEcho(DateTime(2026, 11, 5, 9)), isNotNull);
      expect(echo.takeEcho(DateTime(2026, 11, 5, 21)), isNull);
      expect(echo.takeEcho(DateTime(2026, 11, 6, 9)), isNotNull);
    });

    test('новый выбор перезаписывает старый', () async {
      final echo = await service();
      await echo.remember(
        sceneTitle: 'Первая',
        choiceText: 'Первый ход',
        wasRight: true,
        now: DateTime(2026, 11, 1),
      );
      await echo.remember(
        sceneTitle: 'Вторая',
        choiceText: 'Второй ход',
        wasRight: false,
        now: DateTime(2026, 11, 2),
      );

      expect(echo.last?.sceneTitle, 'Вторая');
      expect(echo.last?.choiceText, 'Второй ход');
      expect(echo.last?.wasRight, isFalse);
    });
  });
}
