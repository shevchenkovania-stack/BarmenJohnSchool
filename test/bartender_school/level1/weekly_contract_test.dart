import 'package:coin/features/bartender_school/data/weekly_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ╨Ü╨╛╨╜╤é╤Ç╨░╨║╤é ΓÇö ╨╡╨┤╨╕╨╜╤ü╤é╨▓╨╡╨╜╨╜╨░╤Å ╨╝╨╡╤à╨░╨╜╨╕╨║╨░, ╨║╨╛╤é╨╛╤Ç╨░╤Å ╨┤╨░╤æ╤é ╨║╨╛╨╜╤é╨╡╨╜╤é ╨▓ ╨╜╨░╨│╤Ç╨░╨┤╤â.
/// ╨ƒ╨╛╤ì╤é╨╛╨╝╤â ╨┐╤Ç╨╛╨▓╨╡╤Ç╤Å╨╡╨╝ ╨╕ ╨┐╨╛╨┤╤ü╤ç╤æ╤é, ╨╕ ╤é╨╛, ╤ç╤é╨╛ ╨╜╨░╨│╤Ç╨░╨┤╤â ╨╜╨╡╨╗╤î╨╖╤Å ╨┐╨╛╨╗╤â╤ç╨╕╤é╤î ╨┤╨▓╨░╨╢╨┤╤ï.
Future<WeeklyContractService> _service(
    [Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(values));
  final prefs = await SharedPreferences.getInstance();
  return WeeklyContractService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('╨¥╨╡╨┤╨╡╨╗╤î╨╜╤ï╨╣ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é', () {
    test('╨╜╨╡╨┤╨╡╨╗╤Å ╤ü╤ç╨╕╤é╨░╨╡╤é╤ü╤Å ╤ü ╨┐╨╛╨╜╨╡╨┤╨╡╨╗╤î╨╜╨╕╨║╨░', () {
      // ╨í╤â╨▒╨▒╨╛╤é╨░ 2026-11-07 ╨╕ ╨▓╨╛╤ü╨║╤Ç╨╡╤ü╨╡╨╜╤î╨╡ 2026-11-08 ΓÇö ╨╛╨┤╨╜╨░ ╨╜╨╡╨┤╨╡╨╗╤Å.
      expect(
        WeeklyContractService.weekStamp(DateTime(2026, 11, 7)),
        WeeklyContractService.weekStamp(DateTime(2026, 11, 8)),
      );
      // ╨ƒ╨╛╨╜╨╡╨┤╨╡╨╗╤î╨╜╨╕╨║ 2026-11-09 ΓÇö ╤â╨╢╨╡ ╤ü╨╗╨╡╨┤╤â╤Ä╤ë╨░╤Å.
      expect(
        WeeklyContractService.weekStamp(DateTime(2026, 11, 9)),
        isNot(WeeklyContractService.weekStamp(DateTime(2026, 11, 7))),
      );
    });

    test('╨╜╨╛╨▓╤ï╨╣ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é ╨┐╤â╤ü╤é╨╛╨╣ ╨╕ ╨╜╨╡ ╨╖╨░╨║╤Ç╤ï╤é',
        () async {
      final service = await _service();
      expect(service.lessonsDone, 0);
      expect(service.cocktailsDone, 0);
      expect(service.examsDone, 0);
      expect(service.isComplete, isFalse);
      expect(service.isClaimed, isFalse);
    });

    test(
        '╨┐╤Ç╨╛╨│╤Ç╨╡╤ü╤ü ╨╛╤ü╤é╨░╨╜╨░╨▓╨╗╨╕╨▓╨░╨╡╤é╤ü╤Å ╨╜╨░ ╤å╨╡╨╗╨╕, ╨░ ╨╜╨╡ ╤Ç╨░╤ü╤é╤æ╤é ╨▒╨╡╤ü╨║╨╛╨╜╨╡╤ç╨╜╨╛',
        () async {
      final service = await _service();

      for (var i = 0; i < 5; i++) {
        await service.registerLesson();
      }

      expect(service.lessonsDone, WeeklyContractService.lessonTarget);
    });

    test('╨║╨╛╨╜╤é╤Ç╨░╨║╤é ╨╖╨░╨║╤Ç╤ï╨▓╨░╨╡╤é╤ü╤Å ╤é╤Ç╨╡╨╝╤Å ╨┐╤â╨╜╨║╤é╨░╨╝╨╕',
        () async {
      final service = await _service();

      for (var i = 0; i < WeeklyContractService.lessonTarget; i++) {
        await service.registerLesson();
      }
      for (var i = 0; i < WeeklyContractService.cocktailTarget; i++) {
        await service.registerCocktail();
      }
      expect(service.isComplete, isFalse,
          reason: '╨▒╨╡╨╖ ╨║╨▓╨╕╨╖╨░ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é ╨╜╨╡ ╨╖╨░╨║╤Ç╤ï╤é');

      await service.registerExam();
      expect(service.isComplete, isTrue);
    });

    test('╨╕╤ü╤é╨╛╤Ç╨╕╤Ä ╨╜╨╡╨╗╤î╨╖╤Å ╨╖╨░╨▒╤Ç╨░╤é╤î ╨┤╨▓╨░╨╢╨┤╤ï', () async {
      final service = await _service();
      for (var i = 0; i < WeeklyContractService.lessonTarget; i++) {
        await service.registerLesson();
      }
      for (var i = 0; i < WeeklyContractService.cocktailTarget; i++) {
        await service.registerCocktail();
      }
      await service.registerExam();

      final first = await service.claim();
      final second = await service.claim();

      expect(first, isNotNull);
      expect(first!.text.trim(), isNotEmpty);
      expect(second, isNull,
          reason:
              '╨┐╨╛╨▓╤é╨╛╤Ç╨╜╨░╤Å ╨▓╤ï╨┤╨░╤ç╨░ ╨╕╤ü╤é╨╛╤Ç╨╕╨╕ ╨╜╨╡╨┤╨╛╨┐╤â╤ü╤é╨╕╨╝╨░');
      expect(service.isClaimed, isTrue);
    });

    test(
        '╨╜╨╡╨╖╨░╨║╤Ç╤ï╤é╤ï╨╣ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é ╨╕╤ü╤é╨╛╤Ç╨╕╤Ä ╨╜╨╡ ╨╛╤é╨┤╨░╤æ╤é',
        () async {
      final service = await _service();
      await service.registerLesson();
      expect(await service.claim(), isNull);
    });

    test(
        '╨┐╨╛╤ü╨╗╨╡ ╨┐╨╛╨╗╤â╤ç╨╡╨╜╨╕╤Å ╨║╨░╤Ç╤é╨╛╤ç╨║╨░ ╨┐╨╛╨║╨░╨╖╤ï╨▓╨░╨╡╤é ╤é╤â ╨╢╨╡ ╨╕╤ü╤é╨╛╤Ç╨╕╤Ä',
        () async {
      final service = await _service();
      for (var i = 0; i < WeeklyContractService.lessonTarget; i++) {
        await service.registerLesson();
      }
      for (var i = 0; i < WeeklyContractService.cocktailTarget; i++) {
        await service.registerCocktail();
      }
      await service.registerExam();

      final story = await service.claim();
      expect(service.claimedStory?.title, story!.title);
    });

    test('╨╕╤ü╤é╨╛╤Ç╨╕╨╕ ╨╜╨╡ ╨┐╨╛╨▓╤é╨╛╤Ç╤Å╤Ä╤é╤ü╤Å ╨┐╨╛╨┤╤Ç╤Å╨┤', () async {
      expect(contractStories.length, greaterThanOrEqualTo(3));
      final titles = contractStories.map((s) => s.title).toSet();
      expect(titles.length, contractStories.length);
    });
  });
}
