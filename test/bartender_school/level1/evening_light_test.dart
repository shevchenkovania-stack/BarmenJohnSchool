import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/room_mood.dart';

void main() {
  group('isEveningNow: 18:00–05:00', () {
    test('день — не вечер', () {
      for (final hour in [5, 8, 12, 14, 17]) {
        expect(
          isEveningNow(DateTime(2025, 6, 1, hour)),
          isFalse,
          reason: '$hour:00 должен быть днём',
        );
      }
    });

    test('вечер и ночь — вечер', () {
      for (final hour in [18, 19, 21, 23, 0, 3, 4]) {
        expect(
          isEveningNow(DateTime(2025, 6, 1, hour)),
          isTrue,
          reason: '$hour:00 должен быть вечером',
        );
      }
    });

    test('граница 17:59 / 18:00', () {
      expect(isEveningNow(DateTime(2025, 6, 1, 17, 59)), isFalse);
      expect(isEveningNow(DateTime(2025, 6, 1, 18, 0)), isTrue);
    });
  });

  group('eveningStrength', () {
    test('днём ноль', () {
      expect(eveningStrength(DateTime(2025, 6, 1, 12)), 0);
    });

    test('в 18:00 мягче, чем в 22:00', () {
      final early = eveningStrength(DateTime(2025, 6, 1, 18));
      final late = eveningStrength(DateTime(2025, 6, 1, 22));
      expect(early, greaterThan(0));
      expect(late, greaterThan(early));
    });

    test('после 23:00 — максимум и не растёт', () {
      expect(eveningStrength(DateTime(2025, 6, 1, 23)), 1.0);
      expect(eveningStrength(DateTime(2025, 6, 1, 2)), 1.0);
    });

    test('всегда в диапазоне 0..1', () {
      for (var hour = 0; hour < 24; hour++) {
        final s = eveningStrength(DateTime(2025, 6, 1, hour));
        expect(s, greaterThanOrEqualTo(0));
        expect(s, lessThanOrEqualTo(1));
      }
    });
  });

  group('roomStageFor', () {
    test('ничего не сдано — пустая комната', () {
      expect(
        roomStageFor(completedLessons: 0, totalLessons: 4),
        RoomStage.empty,
      );
    });

    test('начато, но не закончено — один бокал', () {
      expect(
        roomStageFor(completedLessons: 1, totalLessons: 4),
        RoomStage.working,
      );
      expect(
        roomStageFor(completedLessons: 3, totalLessons: 4),
        RoomStage.working,
      );
    });

    test('блок закрыт — верхний свет и медаль', () {
      expect(
        roomStageFor(completedLessons: 4, totalLessons: 4),
        RoomStage.finished,
      );
    });

    test('недогруженный каталог не выдаёт медаль', () {
      expect(
        roomStageFor(completedLessons: 0, totalLessons: 0),
        RoomStage.empty,
      );
    });
  });
}
