/// Эхо гостя.
///
/// В уроке мудрости ученик выбирает ход в сцене (`SlideType.choice`). Сейчас
/// этот выбор никуда не уходит: выбрал, прочитал объяснение, пошёл дальше.
/// Здесь выбор запоминается и через несколько дней возвращается одной
/// фразой на главной: «Гость вернулся. Ты тогда выбрал тишину — он это
/// помнит».
///
/// Ничего не начисляем и не оцениваем: это память, а не рейтинг.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Один запомненный выбор.
class GuestEcho {
  /// Заголовок сцены, чтобы фраза читалась в контексте.
  final String sceneTitle;

  /// Текст выбранного варианта.
  final String choiceText;

  /// Был ли выбор верным. Не используется для оценки, только для тона.
  final bool wasRight;

  /// Когда выбор сделан.
  final DateTime pickedAt;

  const GuestEcho({
    required this.sceneTitle,
    required this.choiceText,
    required this.wasRight,
    required this.pickedAt,
  });
}

/// Хранит последний выбор сцены и решает, когда о нём напомнить.
class GuestEchoService {
  final SharedPreferences _prefs;

  GuestEchoService(this._prefs);

  static const String _sceneKey = 'guest_echo_scene';
  static const String _choiceKey = 'guest_echo_choice';
  static const String _rightKey = 'guest_echo_right';
  static const String _dateKey = 'guest_echo_date';
  static const String _shownKey = 'guest_echo_shown_date';

  /// Запоминает выбор. Предыдущий просто перезаписывается: важно не
  /// собирать досье, а держать в памяти последний разговор.
  Future<void> remember({
    required String sceneTitle,
    required String choiceText,
    required bool wasRight,
    DateTime? now,
  }) async {
    final stamp = (now ?? DateTime.now()).toIso8601String();
    await _prefs.setString(_sceneKey, sceneTitle);
    await _prefs.setString(_choiceKey, choiceText);
    await _prefs.setBool(_rightKey, wasRight);
    await _prefs.setString(_dateKey, stamp);
  }

  GuestEcho? get last {
    final scene = _prefs.getString(_sceneKey);
    final choice = _prefs.getString(_choiceKey);
    final date = DateTime.tryParse(_prefs.getString(_dateKey) ?? '');
    if (scene == null || choice == null || date == null) return null;
    return GuestEcho(
      sceneTitle: scene,
      choiceText: choice,
      wasRight: _prefs.getBool(_rightKey) ?? false,
      pickedAt: date,
    );
  }

  /// Возвращает фразу эха, если с выбора прошло не меньше трёх дней и
  /// сегодня её ещё не показывали.
  String? takeEcho([DateTime? now]) {
    final echo = last;
    if (echo == null) return null;

    final today = now ?? DateTime.now();
    final days = DateTime(today.year, today.month, today.day)
        .difference(DateTime(
          echo.pickedAt.year,
          echo.pickedAt.month,
          echo.pickedAt.day,
        ))
        .inDays;

    if (days < 3) return null;

    final todayStamp = _stamp(today);
    if (_prefs.getString(_shownKey) == todayStamp) return null;
    _prefs.setString(_shownKey, todayStamp);

    final lead = echo.wasRight
        ? 'Гость вернулся через несколько дней.'
        : 'Тот гость больше не пришёл. Бывает.';
    return '$lead Ты тогда в сцене «${echo.sceneTitle}»: '
        '«${_shorten(echo.choiceText)}». Я запомнил.';
  }

  static String _stamp(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _shorten(String text) {
    final flat = text.replaceAll('\n', ' ').trim();
    if (flat.length <= 70) return flat;
    final slice = flat.substring(0, 70);
    final space = slice.lastIndexOf(' ');
    return '${slice.substring(0, space > 30 ? space : 70)}…';
  }
}
