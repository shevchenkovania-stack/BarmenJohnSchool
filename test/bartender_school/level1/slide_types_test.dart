import 'dart:convert';
import 'dart:io';

import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:flutter_test/flutter_test.dart';

/// Проверяем, что контент уроков мудрости не теряет свой вид.
///
/// Раньше `observation`, `choice` и `silence` молча схлопывались в
/// `theory`: тип не был объявлен в `SlideType`, а `orElse` подставлял
/// теорию. Внешне это выглядело как «страницы, где всё — сплошной текст».
void main() {
  group('Slide types from content', () {
    late List<Map<String, dynamic>> wisdomLessons;
    late List<Map<String, dynamic>> level1Lessons;

    setUpAll(() {
      wisdomLessons = (json.decode(
        File('data/content/lessons_wisdom.json').readAsStringSync(),
      ) as List)
          .cast<Map<String, dynamic>>();
      level1Lessons = [
        ...json.decode(
            File('data/content/lessons_level1_part1.json').readAsStringSync())
            as List,
        ...json.decode(
            File('data/content/lessons_level1_part2.json').readAsStringSync())
            as List,
      ].cast<Map<String, dynamic>>();
    });

    Iterable<Map<String, dynamic>> allSlides() sync* {
      for (final lesson in [...wisdomLessons, ...level1Lessons]) {
        for (final slide in (lesson['slides'] as List)) {
          yield Map<String, dynamic>.from(slide as Map);
        }
      }
    }

    test('every slide type in content is declared in SlideType', () {
      final declared = SlideType.values.map((type) => type.name).toSet();
      final used = allSlides().map((slide) => slide['type'] as String).toSet();

      expect(
        used.difference(declared),
        isEmpty,
        reason: 'В данных есть типы слайдов, которых нет в SlideType: '
            '${used.difference(declared)}',
      );
    });

    test('slide parser keeps the declared type instead of falling back', () {
      for (final raw in allSlides()) {
        final slide = LessonSlide.fromJson(raw);
        expect(
          slide.type.name,
          raw['type'],
          reason: 'слайд «${raw['title']}» потерял свой тип',
        );
      }
    });

    test('choice slides carry options with at least one right move', () {
      final choiceSlides =
          allSlides().where((slide) => slide['type'] == 'choice').toList();

      expect(choiceSlides, isNotEmpty, reason: 'в мудрости нет сцен-выборов');

      for (final raw in choiceSlides) {
        final slide = LessonSlide.fromJson(raw);
        final rightMoves = slide.choices.where((c) => c.isCorrect).length;

        expect(slide.choices.length, greaterThanOrEqualTo(2),
            reason: 'сцена «${slide.title}»: нужен хотя бы один неверный ход');
        // В части сцен верных ходов два (например, «сказать напарнику» и
        // «позвать менеджера») — это осознанная задумка: у сервиса бывает
        // больше одного правильного ответа.
        expect(rightMoves, greaterThanOrEqualTo(1),
            reason: 'в сцене «${slide.title}» нет верного хода');
        expect(rightMoves, lessThan(slide.choices.length),
            reason: 'в сцене «${slide.title}» все варианты верны — выбора нет');
        for (final choice in slide.choices) {
          expect(choice.explanation?.trim(), isNotEmpty,
              reason: 'у варианта «${choice.text}» нет объяснения');
        }
      }
    });

    test('observation and silence slides exist and stay readable', () {
      final observation = allSlides()
          .where((slide) => slide['type'] == 'observation')
          .map((raw) => LessonSlide.fromJson(raw))
          .toList();
      final silence = allSlides()
          .where((slide) => slide['type'] == 'silence')
          .map((raw) => LessonSlide.fromJson(raw))
          .toList();

      expect(observation, isNotEmpty);
      expect(silence, isNotEmpty);

      for (final slide in [...observation, ...silence]) {
        expect(slide.content.trim(), isNotEmpty,
            reason: 'слайд «${slide.title}» пустой');
      }
    });
  });
}
