import 'package:coin/features/bartender_school/data/guest_echo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ╨¡╤à╨╛ ╨│╨╛╤ü╤é╤Å ΓÇö ╨╡╨┤╨╕╨╜╤ü╤é╨▓╨╡╨╜╨╜╨╛╨╡ ╨╝╨╡╤ü╤é╨╛, ╨│╨┤╨╡ ╨┐╤Ç╨╕╨╗╨╛╨╢╨╡╨╜╨╕╨╡ ┬½╨┐╨╛╨╝╨╜╨╕╤é┬╗ ╤â╤ç╨╡╨╜╨╕╨║╨░ ╨╝╨╡╨╢╨┤╤â
/// ╤â╤Ç╨╛╨║╨░╨╝╨╕. ╨ƒ╤Ç╨╛╨▓╨╡╤Ç╤Å╨╡╨╝ ╤é╤Ç╨╕ ╨▓╨╡╤ë╨╕: ╤ì╤à╨╛ ╨╜╨╡ ╨┐╨╛╤Å╨▓╨╗╤Å╨╡╤é╤ü╤Å ╤ü╤Ç╨░╨╖╤â, ╨╜╨╡ ╨┐╨╛╨▓╤é╨╛╤Ç╤Å╨╡╤é╤ü╤Å
/// ╨┤╨▓╨░╨╢╨┤╤ï ╨╖╨░ ╨┤╨╡╨╜╤î ╨╕ ╨╜╨╡ ╨▓╤Ç╤æ╤é ╨╛ ╤é╨╛╨╜╨╡ ╨▓╤ï╨▒╨╛╤Ç╨░.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GuestEchoService> service() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return GuestEchoService(prefs);
  }

  group('╨¡╤à╨╛ ╨│╨╛╤ü╤é╤Å', () {
    test('╨▒╨╡╨╖ ╨▓╤ï╨▒╨╛╤Ç╨░ ╤ì╤à╨░ ╨╜╨╡╤é', () async {
      final echo = await service();
      expect(echo.last, isNull);
      expect(echo.takeEcho(DateTime(2026, 11, 7)), isNull);
    });

    test('╤ì╤à╨╛ ╨╝╨╛╨╗╤ç╨╕╤é ╨┐╨╡╤Ç╨▓╤ï╨╡ ╨┤╨╜╨╕ ╨┐╨╛╤ü╨╗╨╡ ╨▓╤ï╨▒╨╛╤Ç╨░',
        () async {
      final echo = await service();
      await echo.remember(
        sceneTitle: '╨ƒ╤Å╤é╨╜╨╕╤ç╨╜╨░╤Å ╨╖╨░╨┐╨░╤Ç╨░',
        choiceText: '╨¥╨░╨╗╨╕╤é╤î ╨▓╨╛╨┤╤â ╨╕ ╨╛╤é╨╛╨╣╤é╨╕',
        wasRight: true,
        now: DateTime(2026, 11, 7, 10),
      );

      expect(echo.takeEcho(DateTime(2026, 11, 7, 22)), isNull);
      expect(echo.takeEcho(DateTime(2026, 11, 9, 9)), isNull);
    });

    test(
        '╤ç╨╡╤Ç╨╡╨╖ ╤é╤Ç╨╕ ╨┤╨╜╤Å ╤ì╤à╨╛ ╨▓╨╛╨╖╨▓╤Ç╨░╤ë╨░╨╡╤é ╨▓╤ï╨▒╨╛╤Ç ╨▓ ╨║╨░╨▓╤ï╤ç╨║╨░╤à',
        () async {
      final echo = await service();
      await echo.remember(
        sceneTitle: '╨ƒ╤Å╤é╨╜╨╕╤ç╨╜╨░╤Å ╨╖╨░╨┐╨░╤Ç╨░',
        choiceText: '╨¥╨░╨╗╨╕╤é╤î ╨▓╨╛╨┤╤â ╨╕ ╨╛╤é╨╛╨╣╤é╨╕',
        wasRight: true,
        now: DateTime(2026, 11, 7, 10),
      );

      final phrase = echo.takeEcho(DateTime(2026, 11, 10, 9));

      expect(phrase, isNotNull);
      expect(phrase, contains('╨ƒ╤Å╤é╨╜╨╕╤ç╨╜╨░╤Å ╨╖╨░╨┐╨░╤Ç╨░'));
      expect(phrase, contains('╨¥╨░╨╗╨╕╤é╤î ╨▓╨╛╨┤╤â ╨╕ ╨╛╤é╨╛╨╣╤é╨╕'));
    });

    test(
        '╤ì╤à╨╛ ╨╜╨╡ ╨┐╨╛╨▓╤é╨╛╤Ç╤Å╨╡╤é╤ü╤Å ╨▓ ╤é╨╛╤é ╨╢╨╡ ╨┤╨╡╨╜╤î, ╨╜╨╛ ╨▓╨╡╤Ç╨╜╤æ╤é╤ü╤Å ╨┐╨╛╨╖╨╢╨╡',
        () async {
      final echo = await service();
      await echo.remember(
        sceneTitle: '╨í╤å╨╡╨╜╨░',
        choiceText: '╨ƒ╤Ç╨╛╨╝╨╛╨╗╤ç╨░╤é╤î',
        wasRight: false,
        now: DateTime(2026, 11, 1, 12),
      );

      expect(echo.takeEcho(DateTime(2026, 11, 5, 9)), isNotNull);
      expect(echo.takeEcho(DateTime(2026, 11, 5, 21)), isNull);
      expect(echo.takeEcho(DateTime(2026, 11, 6, 9)), isNotNull);
    });

    test('╨╜╨╛╨▓╤ï╨╣ ╨▓╤ï╨▒╨╛╤Ç ╨┐╨╡╤Ç╨╡╨╖╨░╨┐╨╕╤ü╤ï╨▓╨░╨╡╤é ╤ü╤é╨░╤Ç╤ï╨╣',
        () async {
      final echo = await service();
      await echo.remember(
        sceneTitle: '╨ƒ╨╡╤Ç╨▓╨░╤Å',
        choiceText: '╨ƒ╨╡╤Ç╨▓╤ï╨╣ ╤à╨╛╨┤',
        wasRight: true,
        now: DateTime(2026, 11, 1),
      );
      await echo.remember(
        sceneTitle: '╨Æ╤é╨╛╤Ç╨░╤Å',
        choiceText: '╨Æ╤é╨╛╤Ç╨╛╨╣ ╤à╨╛╨┤',
        wasRight: false,
        now: DateTime(2026, 11, 2),
      );

      expect(echo.last?.sceneTitle, '╨Æ╤é╨╛╤Ç╨░╤Å');
      expect(echo.last?.choiceText, '╨Æ╤é╨╛╤Ç╨╛╨╣ ╤à╨╛╨┤');
      expect(echo.last?.wasRight, isFalse);
    });
  });
}
