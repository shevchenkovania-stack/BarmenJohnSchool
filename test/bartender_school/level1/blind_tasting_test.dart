import 'dart:math';

import 'package:coin/features/bartender_school/data/blind_tasting.dart';
import 'package:coin/features/bartender_school/data/term_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ╨í╨╗╨╡╨┐╨░╤Å ╨┤╨╡╨│╤â╤ü╤é╨░╤å╨╕╤Å ΓÇö ╨╕╨│╤Ç╨░ ╨╜╨░ ╤é╨╡╤à ╨╢╨╡ ╨┤╨░╨╜╨╜╤ï╤à, ╤ç╤é╨╛ ╨╕ ╤â╤Ç╨╛╨║╨╕. ╨ƒ╤Ç╨╛╨▓╨╡╤Ç╤Å╨╡╨╝,
/// ╤ç╤é╨╛ ╤Ç╨░╤â╨╜╨┤ ╨▓╤ü╨╡╨│╨┤╨░ ╨╕╨│╤Ç╨░╨▒╨╡╨╗╨╡╨╜: ╤ç╨╡╤é╤ï╤Ç╨╡ ╤Ç╨░╨╖╨╜╤ï╤à ╨▓╨░╤Ç╨╕╨░╨╜╤é╨░, ╨╛╨┤╨╕╨╜ ╨┐╤Ç╨░╨▓╨╕╨╗╤î╨╜╤ï╨╣,
/// ╤é╤Ç╨╕ ╨┐╨╛╨┤╤ü╨║╨░╨╖╨║╨╕, ╨╕ ╨╜╨╕╨║╨░╨║╨╕╤à ╨┐╨╛╨▓╤é╨╛╤Ç╨╛╨▓ ╨▓ ╨╛╨┤╨╕╨╜ ╨┤╨╡╨╜╤î.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('╨í╨╗╨╡╨┐╨░╤Å ╨┤╨╡╨│╤â╤ü╤é╨░╤å╨╕╤Å', () {
    test('╤Ç╨░╤â╨╜╨┤ ╤ü╨╛╨▒╨╕╤Ç╨░╨╡╤é╤ü╤Å ╨╕╨╖ ╨╕╨╖╤â╤ç╨╡╨╜╨╜╤ï╤à ╤é╨╡╤Ç╨╝╨╛╨▓',
        () {
      final learnt =
          TermService.allTerms.take(6).map((term) => term.russianName).toSet();

      final round = buildBlindTastingRound(
        learntTermNames: learnt,
        random: Random(7),
      );

      expect(round, isNotNull);
      expect(round!.options, hasLength(4));
      expect(
        round.options.map((o) => o.russianName).toSet().length,
        4,
        reason: '╨▓╨░╤Ç╨╕╨░╨╜╤é╤ï ╨╜╨╡ ╨┤╨╛╨╗╨╢╨╜╤ï ╨┐╨╛╨▓╤é╨╛╤Ç╤Å╤é╤î╤ü╤Å',
      );
      expect(
        round.options.any((o) => o.russianName == round.answer.russianName),
        isTrue,
        reason:
            '╨┐╤Ç╨░╨▓╨╕╨╗╤î╨╜╤ï╨╣ ╨╛╤é╨▓╨╡╤é ╨╛╨▒╤Å╨╖╨░╨╜ ╨▒╤ï╤é╤î ╤ü╤Ç╨╡╨┤╨╕ ╨▓╨░╤Ç╨╕╨░╨╜╤é╨╛╨▓',
      );
      expect(learnt.contains(round.answer.russianName), isTrue);
    });

    test('╨┤╨╛ ╨┐╨╡╤Ç╨▓╨╛╨│╨╛ ╤â╤Ç╨╛╨║╨░ ╤Ç╨░╤â╨╜╨┤ ╨▓╤ü╤æ ╤Ç╨░╨▓╨╜╨╛ ╨╡╤ü╤é╤î',
        () {
      // ╨ÿ╨│╤Ç╨░ ╨╜╨╡ ╨┤╨╛╨╗╨╢╨╜╨░ ╨▒╤ï╤é╤î ╨┐╤â╤ü╤é╨╛╨╣ ╨╜╨░ ╤ü╤é╨░╤Ç╤é╨╡: ╨▒╨╡╤Ç╤æ╨╝ ╤é╨╡╤Ç╨╝╤ï ╨╕╨╖ ╨▒╤â╨┤╤â╤ë╨╕╤à ╤â╤Ç╨╛╨║╨╛╨▓.
      final round = buildBlindTastingRound(
        learntTermNames: const {},
        random: Random(1),
      );
      expect(round, isNotNull);
      expect(round!.options, hasLength(4));
    });

    test(
        '╨┐╨╛╨┤╤ü╨║╨░╨╖╨║╨╕ ╨╛╤é╨║╤Ç╤ï╨▓╨░╤Ä╤é╤ü╤Å ╨┐╨╛ ╨╛╨┤╨╜╨╛╨╣ ╨╕ ╨╜╨╡ ╨┐╤â╤ü╤é╤ï╨╡',
        () {
      final round = buildBlindTastingRound(
        learntTermNames:
            TermService.allTerms.take(8).map((t) => t.russianName).toSet(),
        random: Random(3),
      )!;

      expect(round.hints, hasLength(3));
      for (final hint in round.hints) {
        expect(hint.trim(), isNotEmpty);
      }
      // ╨ƒ╨╡╤Ç╨▓╨░╤Å ╨┐╨╛╨┤╤ü╨║╨░╨╖╨║╨░ ΓÇö ╨║╨░╤é╨╡╨│╨╛╤Ç╨╕╤Å, ╤é╨╛ ╨╡╤ü╤é╤î ╤ü╨░╨╝╨╛╨╡ ╨╛╨▒╤ë╨╡╨╡.
      expect(round.hints.first, contains('╨Ü╨░╤é╨╡╨│╨╛╤Ç╨╕╤Å'));
    });

    test(
        '╨▓ ╨╛╨┤╨╕╨╜ ╨┤╨╡╨╜╤î ╤Ç╨░╤â╨╜╨┤ ╨╖╨░╤ü╤ç╨╕╤é╤ï╨▓╨░╨╡╤é╤ü╤Å ╨╛╨┤╨╕╨╜ ╤Ç╨░╨╖',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = BlindTastingService(prefs);

      expect(service.playedToday, isFalse);
      await service.registerRound(correct: true);
      await service.registerRound(correct: true);

      expect(service.playedToday, isTrue);
      expect(service.playedCount, 1,
          reason: '╨┐╨╛╨▓╤é╨╛╤Ç╨╜╤ï╨╣ ╨▓╤ï╨╖╨╛╨▓ ╨╜╨╡ ╤ü╤ç╨╕╤é╨░╨╡╤é╤ü╤Å');
      expect(service.correctCount, 1);
    });

    test(
        '╨╛╤ê╨╕╨▒╨║╨░ ╨╖╨░╤ü╤ç╨╕╤é╤ï╨▓╨░╨╡╤é╤ü╤Å ╨║╨░╨║ ╤ü╤ï╨│╤Ç╨░╨╜╨╜╤ï╨╣ ╤Ç╨░╤â╨╜╨┤, ╨╜╨╛ ╨╜╨╡ ╨║╨░╨║ ╨▓╨╡╤Ç╨╜╤ï╨╣',
        () async {
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
