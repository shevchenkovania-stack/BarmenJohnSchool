import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

/// Вечерний свет — правило времени, а не случайность: от него зависит
/// читаемость интерфейса, поэтому границы проверяются явно.
void main() {
  group('Вечерний свет комнат', () {
    test('днём свет обычный', () {
      expect(isEveningNow(DateTime(2026, 11, 7, 12)), isFalse);
      expect(isEveningNow(DateTime(2026, 11, 7, 17, 59)), isFalse);
    });

    test('с 18:00 включается тёплый свет', () {
      expect(isEveningNow(DateTime(2026, 11, 7, 18)), isTrue);
      expect(isEveningNow(DateTime(2026, 11, 7, 22, 30)), isTrue);
    });

    test('ночью до 5 утра свет ещё тёплый', () {
      expect(isEveningNow(DateTime(2026, 11, 8, 0, 30)), isTrue);
      expect(isEveningNow(DateTime(2026, 11, 8, 4, 59)), isTrue);
      expect(isEveningNow(DateTime(2026, 11, 8, 5)), isFalse);
    });
  });
}
