/// Слепая дегустация — одна игра в день.
///
/// Берём терм из уже изученных уроков и даём три подсказки: категория,
/// первая половина определения и пример употребления. Нужно угадать сам
/// терм среди четырёх вариантов. Ничего нового не заводим — учимся на тех
/// же данных, что и уроки.
///
/// Игра добровольная и без наказаний: один раунд в день, ошибка просто
/// показывает правильный ответ.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coin/features/bartender_school/data/term_service.dart';

/// Один раунд игры.
class BlindTastingRound {
  /// Терм, который нужно угадать.
  final TermData answer;

  /// Четыре варианта, включая правильный.
  final List<TermData> options;

  const BlindTastingRound({required this.answer, required this.options});

  /// Подсказки выдаются по одной: 3 → 2 → 1.
  List<String> get hints => [
        'Категория: ${answer.category}',
        _cut(answer.definition, 90),
        _cut(answer.example, 80),
      ];

  static String _cut(String text, int limit) {
    final flat = text.replaceAll('\n', ' ').trim();
    if (flat.length <= limit) return flat;
    final slice = flat.substring(0, limit);
    final space = slice.lastIndexOf(' ');
    return '${slice.substring(0, space > 40 ? space : limit)}…';
  }
}

/// Собирает раунд из термов, которые ученик уже проходил.
///
/// [learntTermNames] — русские названия термов из завершённых уроков.
/// Если изученных мало (меньше четырёх), берём ближайшие из будущих
/// уроков: пустая игра хуже, чем игра на опережение.
BlindTastingRound? buildBlindTastingRound({
  required Set<String> learntTermNames,
  Random? random,
}) {
  final learnt = TermService.allTerms
      .where((term) => learntTermNames.contains(term.russianName))
      .toList();

  final pool = learnt.length >= 4
      ? learnt
      : TermService.allTerms.where((t) => t.definition.length > 40).toList();

  if (pool.length < 4) return null;

  final rng = random ?? Random();

  // Детерминированный выбор берём только если Random не передан: в тестах
  // Random(seed) даёт предсказуемый раунд.
  final answer = pool[rng.nextInt(pool.length)];

  final distractors = <TermData>[];
  var guard = 0;
  while (distractors.length < 3 && guard < 200) {
    guard++;
    final candidate = pool[rng.nextInt(pool.length)];
    if (candidate.russianName == answer.russianName) continue;
    if (distractors.any((d) => d.russianName == candidate.russianName)) {
      continue;
    }
    distractors.add(candidate);
  }
  if (distractors.length < 3) return null;

  final options = [answer, ...distractors]..shuffle(rng);
  return BlindTastingRound(answer: answer, options: options);
}

/// Хранит, играл ли человек сегодня, и сколько раундов угадано.
class BlindTastingService extends ChangeNotifier {
  final SharedPreferences _prefs;

  BlindTastingService(this._prefs);

  static const String _lastPlayedKey = 'blind_tasting_last_day';
  static const String _correctKey = 'blind_tasting_correct';
  static const String _playedKey = 'blind_tasting_played';

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool get playedToday => _prefs.getString(_lastPlayedKey) == _today();

  /// Всего угаданных раундов — используется как знак на главной.
  int get correctCount => _prefs.getInt(_correctKey) ?? 0;

  int get playedCount => _prefs.getInt(_playedKey) ?? 0;

  /// Отмечает раунд. Повторный вызов в тот же день ничего не меняет.
  Future<void> registerRound({required bool correct}) async {
    if (playedToday) return;
    await _prefs.setString(_lastPlayedKey, _today());
    await _prefs.setInt(_playedKey, playedCount + 1);
    if (correct) {
      await _prefs.setInt(_correctKey, correctCount + 1);
    }
    notifyListeners();
  }
}
