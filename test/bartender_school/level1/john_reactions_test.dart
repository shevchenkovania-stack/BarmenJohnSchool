import 'package:coin/features/bartender_school/data/john_reactions.dart';
import 'package:flutter_test/flutter_test.dart';

/// ╨á╨╡╨┐╨╗╨╕╨║╨╕ ╨ö╨╢╨╛╨╜╨░ ΓÇö ╤ç╨░╤ü╤é╤î ╨┐╤Ç╨╛╨┤╤â╨║╤é╨░, ╨░ ╨╖╨╜╨░╤ç╨╕╤é ╨╕╤à ╨╜╨░╨┤╨╛ ╨┐╤Ç╨╛╨▓╨╡╤Ç╤Å╤é╤î ╨║╨░╨║ ╨║╨╛╨╜╤é╨╡╨╜╤é:
/// ╨╜╨╕ ╨╛╨┤╨╜╨░ ╤ä╤Ç╨░╨╖╨░ ╨╜╨╡ ╨┤╨╛╨╗╨╢╨╜╨░ ╨▒╤ï╤é╤î ╨┐╤â╤ü╤é╨╛╨╣, ╨┐╨╛╨▓╤é╨╛╤Ç╤Å╤é╤î╤ü╤Å ╨┤╨╛╤ü╨╗╨╛╨▓╨╜╨╛ ╤â ╤Ç╨░╨╖╨╜╤ï╤à
/// ╤ü╨╛╨▒╤ï╤é╨╕╨╣ ╨╕ ╨╜╨╡ ╨┤╨╛╨╗╨╢╨╜╨░ ╤ü╤é╤ï╨┤╨╕╤é╤î ╨╖╨░ ╨┐╤Ç╨╛╨▓╨░╨╗.
void main() {
  group('╨á╨╡╨┐╨╗╨╕╨║╨╕ ╨ö╨╢╨╛╨╜╨░', () {
    test('╨║╨░╨╢╨┤╨╛╨╡ ╤ü╨╛╨▒╤ï╤é╨╕╨╡ ╨┤╨░╤æ╤é ╨╜╨╡╨┐╤â╤ü╤é╤â╤Ä ╤ä╤Ç╨░╨╖╤â',
        () {
      for (final moment in JohnMoment.values) {
        for (final variant in [0, 1, 2, 3]) {
          final line =
              johnReaction(moment, const JohnContext(), variant: variant);
          expect(line.trim(), isNotEmpty,
              reason: '$moment, ╨▓╨░╤Ç╨╕╨░╨╜╤é $variant');
        }
      }
    });

    test(
        '╨┤╨╗╨╕╨╜╨░ ╤ä╤Ç╨░╨╖╤ï ╨┐╨╛╨┤╤à╨╛╨┤╨╕╤é ╨┤╨╗╤Å ╨║╨░╤Ç╤é╨╛╤ç╨║╨╕ ╨╜╨░ ╨│╨╗╨░╨▓╨╜╨╛╨╣',
        () {
      for (final moment in JohnMoment.values) {
        for (final variant in [0, 1]) {
          final line =
              johnReaction(moment, const JohnContext(), variant: variant);
          // ╨Ü╨░╤Ç╤é╨╛╤ç╨║╨░ ╨ö╨╢╨╛╨╜╨░ ΓÇö ╤é╤Ç╨╕ ╤ü╤é╤Ç╨╛╨║╨╕ ╨╜╨░ ╤â╨╖╨║╨╛╨╝ ╤ì╨║╤Ç╨░╨╜╨╡; ╨┤╨╗╨╕╨╜╨╜╨╡╨╡ ╨╜╨╡ ╨▓╨╗╨╡╨╖╨░╨╡╤é
          // ╨▒╨╡╨╖ ╨╛╨▒╤Ç╨╡╨╖╨║╨╕, ╨░ ╨╛╨▒╤Ç╨╡╨╖╨░╨╜╨╜╨░╤Å ╤ä╤Ç╨░╨╖╨░ ╤ç╨╕╤é╨░╨╡╤é╤ü╤Å ╨║╨░╨║ ╨╛╤ê╨╕╨▒╨║╨░.
          expect(line.length, lessThanOrEqualTo(140),
              reason: '$moment: ┬½$line┬╗');
        }
      }
    });

    test(
        '╨▓╤ï╨▒╨╛╤Ç ╨┤╨╡╤é╨╡╤Ç╨╝╨╕╨╜╨╕╤Ç╨╛╨▓╨░╨╜ ╨┐╤Ç╨╕ ╨╛╨┤╨╕╨╜╨░╨║╨╛╨▓╨╛╨╝ ╤ü╨╛╤ü╤é╨╛╤Å╨╜╨╕╨╕',
        () {
      const context = JohnContext(streak: 4);
      expect(
        johnReaction(JohnMoment.streak, context, variant: 2),
        johnReaction(JohnMoment.streak, context, variant: 2),
      );
    });

    test(
        '╨┐╨░╤â╨╖╨░ ╨╝╨╡╨╜╤Å╨╡╤é ╤é╨╛╨╜ ╨▓ ╨╖╨░╨▓╨╕╤ü╨╕╨╝╨╛╤ü╤é╨╕ ╨╛╤é ╨╡╤æ ╨┤╨╗╨╕╨╜╤ï',
        () {
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

    test('╨╜╨░ ╨┐╨╛╨▓╤é╨╛╤Ç╨╜╤ï╨╣ ╨┐╤Ç╨╛╨▓╨░╨╗ ╨ö╨╢╨╛╨╜ ╨╜╨╡ ╤ü╤é╤ï╨┤╨╕╤é', () {
      const context = JohnContext(failedAttemptsBefore: 3);
      // ╨í╨╗╨╛╨▓╨░, ╨║╨╛╤é╨╛╤Ç╤ï╨╡ ╨╜╨╡ ╨┤╨╛╨╗╨╢╨╜╤ï ╨┐╨╛╤Å╨▓╨╗╤Å╤é╤î╤ü╤Å ╨▓ ╤Ç╨░╨╖╨│╨╛╨▓╨╛╤Ç╨╡ ╨╛ ╨┐╤Ç╨╛╨▓╨░╨╗╨╡: ╤ì╤é╨╛
      // ╤ê╨║╨╛╨╗╨░, ╨░ ╨╜╨╡ ╤ì╨║╨╖╨░╨╝╨╡╨╜ ╨╜╨░ ╨▓╤ï╨╢╨╕╨▓╨░╨╜╨╕╨╡.
      const forbidden = [
        '╨┐╨╛╨╖╨╛╤Ç',
        '╤ü╤é╤ï╨┤╨╜╨╛',
        '╤ü╨╗╨░╨▒╨╛',
        '╨┐╤Ç╨╛╨▓╨░╨╗╨╕╨╗ ╨╛╨║╨╛╨╜╤ç╨░╤é╨╡╨╗╤î╨╜╨╛'
      ];

      for (final variant in [0, 1]) {
        final line = johnReaction(
          JohnMoment.quizFailedAgain,
          context,
          variant: variant,
        ).toLowerCase();
        for (final word in forbidden) {
          expect(line.contains(word), isFalse,
              reason: '┬½$line┬╗ ╤ü╨╛╨┤╨╡╤Ç╨╢╨╕╤é ┬½$word┬╗');
        }
      }
    });

    test(
        '╨╖╨▓╤æ╨╖╨┤╤ï ╨▓ ╨╝╨░╤ü╤é╨╡╤Ç╤ü╨║╨╛╨╣ ╨┤╨░╤Ä╤é ╤Ç╨░╨╖╨╜╤ï╨╣ ╤Ç╨░╨╖╨▒╨╛╤Ç',
        () {
      String lineFor(int stars) => johnReaction(
            JohnMoment.cocktailBuilt,
            JohnContext(stars: stars),
          );

      expect(lineFor(3), isNot(lineFor(0)));
      expect(lineFor(3), isNot(lineFor(2)));
    });

    test(
        'daysSince ╤ü╤ç╨╕╤é╨░╨╡╤é ╨║╨░╨╗╨╡╨╜╨┤╨░╤Ç╨╜╤ï╨╡ ╨┤╨╜╨╕, ╨░ ╨╜╨╡ ╤ç╨░╤ü╤ï',
        () {
      final now = DateTime(2026, 11, 7, 9);
      expect(daysSince(null, now), isNull);
      expect(daysSince(DateTime(2026, 11, 7, 23), now), 0);
      expect(daysSince(DateTime(2026, 11, 6, 1), now), 1);
      expect(daysSince(DateTime(2026, 10, 30, 12), now), 8);
    });

    test(
        '╨┐╨╛╨┤╤ü╨║╨░╨╖╨║╨░ ╨▓ ╨╝╨░╤ü╤é╨╡╤Ç╤ü╨║╨╛╨╣ ╤Ç╨╡╨░╨│╨╕╤Ç╤â╨╡╤é ╨╜╨░ ╤ç╨╕╤ü╨╗╨╛ ╨▓╤ï╨▒╤Ç╨░╨╜╨╜╨╛╨│╨╛',
        () {
      final empty = johnPracticeHint(JohnPracticeMoment.ingredients);
      final tooMany = johnPracticeHint(
        JohnPracticeMoment.ingredients,
        selectedCount: 5,
        expectedCount: 3,
      );
      final exact = johnPracticeHint(
        JohnPracticeMoment.ingredients,
        selectedCount: 3,
        expectedCount: 3,
      );

      expect(empty, isNot(tooMany));
      expect(tooMany, isNot(exact));
      expect(exact, isNot(empty));
    });

    test(
        '╨┐╨╛╨┤╤ü╨║╨░╨╖╨║╨░ ╨╜╨╡ ╨╜╨░╨╖╤ï╨▓╨░╨╡╤é ╨┐╤Ç╨░╨▓╨╕╨╗╤î╨╜╤ï╨╣ ╨╛╤é╨▓╨╡╤é',
        () {
      // ╨ƒ╤Ç╨╛╤ü╤é╨╛╨╣ ╨╖╨░╨┐╤Ç╨╡╤é: ╨┐╨╛╨┤╤ü╨║╨░╨╖╨║╨░ ╨╜╨╡ ╨┤╨╛╨╗╨╢╨╜╨░ ╨┐╨╡╤Ç╨╡╤ç╨╕╤ü╨╗╤Å╤é╤î ╨╕╨╜╨│╤Ç╨╡╨┤╨╕╨╡╨╜╤é╤ï ΓÇö
      // ╨╕╨╜╨░╤ç╨╡ ╨╖╨░╨┤╨░╨╜╨╕╨╡ ╨┐╤Ç╨╡╨▓╤Ç╨░╤ë╨░╨╡╤é╤ü╤Å ╨▓ ┬½╤ü╨┐╨╕╤ê╨╕ ╤ü╨╛ ╤ü╤é╨╡╨╜╤ï┬╗.
      const ingredientWords = [
        '╤Ç╨╛╨╝',
        '╨┤╨╢╨╕╨╜',
        '╨▓╨╛╨┤╨║╨░',
        '╨║╨░╨╝╨┐╨░╤Ç╨╕',
        '╨▓╨╡╤Ç╨╝╤â╤é'
      ];

      final hints = [
        johnPracticeHint(JohnPracticeMoment.ingredients),
        johnPracticeHint(
          JohnPracticeMoment.ingredients,
          selectedCount: 1,
          expectedCount: 3,
        ),
        johnPracticeHint(
          JohnPracticeMoment.ingredients,
          selectedCount: 4,
          expectedCount: 3,
        ),
        johnPracticeHint(
          JohnPracticeMoment.ingredients,
          selectedCount: 3,
          expectedCount: 3,
        ),
        johnPracticeHint(JohnPracticeMoment.method),
      ];

      for (final hint in hints) {
        final lower = hint.toLowerCase();
        for (final word in ingredientWords) {
          expect(lower.contains(word), isFalse,
              reason:
                  '╨┐╨╛╨┤╤ü╨║╨░╨╖╨║╨░ ┬½$hint┬╗ ╨╜╨░╨╖╤ï╨▓╨░╨╡╤é ╨╕╨╜╨│╤Ç╨╡╨┤╨╕╨╡╨╜╤é ┬½$word┬╗');
        }
      }
    });
  });
}
