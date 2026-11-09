/// ╨¡╤à╨╛ ╨│╨╛╤ü╤é╤Å.
///
/// ╨Æ ╤â╤Ç╨╛╨║╨╡ ╨╝╤â╨┤╤Ç╨╛╤ü╤é╨╕ ╤â╤ç╨╡╨╜╨╕╨║ ╨▓╤ï╨▒╨╕╤Ç╨░╨╡╤é ╤à╨╛╨┤ ╨▓ ╤ü╤å╨╡╨╜╨╡ (`SlideType.choice`). ╨í╨╡╨╣╤ç╨░╤ü
/// ╤ì╤é╨╛╤é ╨▓╤ï╨▒╨╛╤Ç ╨╜╨╕╨║╤â╨┤╨░ ╨╜╨╡ ╤â╤à╨╛╨┤╨╕╤é: ╨▓╤ï╨▒╤Ç╨░╨╗, ╨┐╤Ç╨╛╤ç╨╕╤é╨░╨╗ ╨╛╨▒╤è╤Å╤ü╨╜╨╡╨╜╨╕╨╡, ╨┐╨╛╤ê╤æ╨╗ ╨┤╨░╨╗╤î╤ê╨╡.
/// ╨ù╨┤╨╡╤ü╤î ╨▓╤ï╨▒╨╛╤Ç ╨╖╨░╨┐╨╛╨╝╨╕╨╜╨░╨╡╤é╤ü╤Å ╨╕ ╤ç╨╡╤Ç╨╡╨╖ ╨╜╨╡╤ü╨║╨╛╨╗╤î╨║╨╛ ╨┤╨╜╨╡╨╣ ╨▓╨╛╨╖╨▓╤Ç╨░╤ë╨░╨╡╤é╤ü╤Å ╨╛╨┤╨╜╨╛╨╣
/// ╤ä╤Ç╨░╨╖╨╛╨╣ ╨╜╨░ ╨│╨╗╨░╨▓╨╜╨╛╨╣: ┬½╨ô╨╛╤ü╤é╤î ╨▓╨╡╤Ç╨╜╤â╨╗╤ü╤Å. ╨ó╤ï ╤é╨╛╨│╨┤╨░ ╨▓╤ï╨▒╤Ç╨░╨╗ ╤é╨╕╤ê╨╕╨╜╤â ΓÇö ╨╛╨╜ ╤ì╤é╨╛
/// ╨┐╨╛╨╝╨╜╨╕╤é┬╗.
///
/// ╨¥╨╕╤ç╨╡╨│╨╛ ╨╜╨╡ ╨╜╨░╤ç╨╕╤ü╨╗╤Å╨╡╨╝ ╨╕ ╨╜╨╡ ╨╛╤å╨╡╨╜╨╕╨▓╨░╨╡╨╝: ╤ì╤é╨╛ ╨┐╨░╨╝╤Å╤é╤î, ╨░ ╨╜╨╡ ╤Ç╨╡╨╣╤é╨╕╨╜╨│.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// ╨₧╨┤╨╕╨╜ ╨╖╨░╨┐╨╛╨╝╨╜╨╡╨╜╨╜╤ï╨╣ ╨▓╤ï╨▒╨╛╤Ç.
class GuestEcho {
  /// ╨ù╨░╨│╨╛╨╗╨╛╨▓╨╛╨║ ╤ü╤å╨╡╨╜╤ï, ╤ç╤é╨╛╨▒╤ï ╤ä╤Ç╨░╨╖╨░ ╤ç╨╕╤é╨░╨╗╨░╤ü╤î ╨▓ ╨║╨╛╨╜╤é╨╡╨║╤ü╤é╨╡.
  final String sceneTitle;

  /// ╨ó╨╡╨║╤ü╤é ╨▓╤ï╨▒╤Ç╨░╨╜╨╜╨╛╨│╨╛ ╨▓╨░╤Ç╨╕╨░╨╜╤é╨░.
  final String choiceText;

  /// ╨æ╤ï╨╗ ╨╗╨╕ ╨▓╤ï╨▒╨╛╤Ç ╨▓╨╡╤Ç╨╜╤ï╨╝. ╨¥╨╡ ╨╕╤ü╨┐╨╛╨╗╤î╨╖╤â╨╡╤é╤ü╤Å ╨┤╨╗╤Å ╨╛╤å╨╡╨╜╨║╨╕, ╤é╨╛╨╗╤î╨║╨╛ ╨┤╨╗╤Å ╤é╨╛╨╜╨░.
  final bool wasRight;

  /// ╨Ü╨╛╨│╨┤╨░ ╨▓╤ï╨▒╨╛╤Ç ╤ü╨┤╨╡╨╗╨░╨╜.
  final DateTime pickedAt;

  const GuestEcho({
    required this.sceneTitle,
    required this.choiceText,
    required this.wasRight,
    required this.pickedAt,
  });
}

/// ╨Ñ╤Ç╨░╨╜╨╕╤é ╨┐╨╛╤ü╨╗╨╡╨┤╨╜╨╕╨╣ ╨▓╤ï╨▒╨╛╤Ç ╤ü╤å╨╡╨╜╤ï ╨╕ ╤Ç╨╡╤ê╨░╨╡╤é, ╨║╨╛╨│╨┤╨░ ╨╛ ╨╜╤æ╨╝ ╨╜╨░╨┐╨╛╨╝╨╜╨╕╤é╤î.
class GuestEchoService {
  final SharedPreferences _prefs;

  GuestEchoService(this._prefs);

  static const String _sceneKey = 'guest_echo_scene';
  static const String _choiceKey = 'guest_echo_choice';
  static const String _rightKey = 'guest_echo_right';
  static const String _dateKey = 'guest_echo_date';
  static const String _shownKey = 'guest_echo_shown_date';

  /// ╨ù╨░╨┐╨╛╨╝╨╕╨╜╨░╨╡╤é ╨▓╤ï╨▒╨╛╤Ç. ╨ƒ╤Ç╨╡╨┤╤ï╨┤╤â╤ë╨╕╨╣ ╨┐╤Ç╨╛╤ü╤é╨╛ ╨┐╨╡╤Ç╨╡╨╖╨░╨┐╨╕╤ü╤ï╨▓╨░╨╡╤é╤ü╤Å: ╨▓╨░╨╢╨╜╨╛ ╨╜╨╡
  /// ╤ü╨╛╨▒╨╕╤Ç╨░╤é╤î ╨┤╨╛╤ü╤î╨╡, ╨░ ╨┤╨╡╤Ç╨╢╨░╤é╤î ╨▓ ╨┐╨░╨╝╤Å╤é╨╕ ╨┐╨╛╤ü╨╗╨╡╨┤╨╜╨╕╨╣ ╤Ç╨░╨╖╨│╨╛╨▓╨╛╤Ç.
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

  /// ╨Æ╨╛╨╖╨▓╤Ç╨░╤ë╨░╨╡╤é ╤ä╤Ç╨░╨╖╤â ╤ì╤à╨░, ╨╡╤ü╨╗╨╕ ╤ü ╨▓╤ï╨▒╨╛╤Ç╨░ ╨┐╤Ç╨╛╤ê╨╗╨╛ ╨╜╨╡ ╨╝╨╡╨╜╤î╤ê╨╡ ╤é╤Ç╤æ╤à ╨┤╨╜╨╡╨╣ ╨╕
  /// ╤ü╨╡╨│╨╛╨┤╨╜╤Å ╨╡╤æ ╨╡╤ë╤æ ╨╜╨╡ ╨┐╨╛╨║╨░╨╖╤ï╨▓╨░╨╗╨╕.
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
        ? '╨ô╨╛╤ü╤é╤î ╨▓╨╡╤Ç╨╜╤â╨╗╤ü╤Å ╤ç╨╡╤Ç╨╡╨╖ ╨╜╨╡╤ü╨║╨╛╨╗╤î╨║╨╛ ╨┤╨╜╨╡╨╣.'
        : '╨ó╨╛╤é ╨│╨╛╤ü╤é╤î ╨▒╨╛╨╗╤î╤ê╨╡ ╨╜╨╡ ╨┐╤Ç╨╕╤ê╤æ╨╗. ╨æ╤ï╨▓╨░╨╡╤é.';
    return '$lead ╨ó╤ï ╤é╨╛╨│╨┤╨░ ╨▓ ╤ü╤å╨╡╨╜╨╡ ┬½${echo.sceneTitle}┬╗: '
        '┬½${_shorten(echo.choiceText)}┬╗. ╨» ╨╖╨░╨┐╨╛╨╝╨╜╨╕╨╗.';
  }

  static String _stamp(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _shorten(String text) {
    final flat = text.replaceAll('\n', ' ').trim();
    if (flat.length <= 70) return flat;
    final slice = flat.substring(0, 70);
    final space = slice.lastIndexOf(' ');
    return '${slice.substring(0, space > 30 ? space : 70)}ΓÇª';
  }
}
