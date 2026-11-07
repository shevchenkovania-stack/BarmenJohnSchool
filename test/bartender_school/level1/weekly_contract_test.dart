import 'package:coin/features/bartender_school/data/weekly_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Контракт — единственная механика, которая даёт контент в награду.
/// Поэтому проверяем и подсчёт, и то, что награду нельзя получить дважды.
Future<WeeklyContractService> _service([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(Map<String, Object>.from(values));
  final prefs = await SharedPreferences.getInstance();
  return WeeklyContractService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Недельный контракт', () {
    test('неделя считается с понедельника', () {
      // Суббота 2026-11-07 и воскресенье 2026-11-08 — одна неделя.
      expect(
        WeeklyContractService.weekStamp(DateTime(2026, 11, 7)),
        WeeklyContractService.weekStamp(DateTime(2026, 11, 8)),
      );
      // Понедельник 2026-11-09 — уже следующая.
      expect(
        WeeklyContractService.weekStamp(DateTime(2026, 11, 9)),
        isNot(WeeklyContractService.weekStamp(DateTime(2026, 11, 7))),
      );
    });

    test('новый контракт пустой и не закрыт', () async {
      final service = await _service();
      expect(service.lessonsDone, 0);
      expect(service.cocktailsDone, 0);
      expect(service.examsDone, 0);
      expect(service.isComplete, isFalse);
      expect(service.isClaimed, isFalse);
    });

    test('прогресс останавливается на цели, а не растёт бесконечно', () async {
      final service = await _service();

      for (var i = 0; i < 5; i++) {
        await service.registerLesson();
      }

      expect(service.lessonsDone, WeeklyContractService.lessonTarget);
    });

    test('контракт закрывается тремя пунктами', () async {
      final service = await _service();

      for (var i = 0; i < WeeklyContractService.lessonTarget; i++) {
        await service.registerLesson();
      }
      for (var i = 0; i < WeeklyContractService.cocktailTarget; i++) {
        await service.registerCocktail();
      }
      expect(service.isComplete, isFalse, reason: 'без квиза контракт не закрыт');

      await service.registerExam();
      expect(service.isComplete, isTrue);
    });

    test('историю нельзя забрать дважды', () async {
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
      expect(second, isNull, reason: 'повторная выдача истории недопустима');
      expect(service.isClaimed, isTrue);
    });

    test('незакрытый контракт историю не отдаёт', () async {
      final service = await _service();
      await service.registerLesson();
      expect(await service.claim(), isNull);
    });

    test('после получения карточка показывает ту же историю', () async {
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

    test('истории не повторяются подряд', () async {
      expect(contractStories.length, greaterThanOrEqualTo(3));
      final titles = contractStories.map((s) => s.title).toSet();
      expect(titles.length, contractStories.length);
    });
  });
}
