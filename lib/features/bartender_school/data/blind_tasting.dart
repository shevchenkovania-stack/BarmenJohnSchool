/// ╨í╨╗╨╡╨┐╨░╤Å ╨┤╨╡╨│╤â╤ü╤é╨░╤å╨╕╤Å ΓÇö ╨╛╨┤╨╜╨░ ╨╕╨│╤Ç╨░ ╨▓ ╨┤╨╡╨╜╤î.
///
/// ╨æ╨╡╤Ç╤æ╨╝ ╤é╨╡╤Ç╨╝ ╨╕╨╖ ╤â╨╢╨╡ ╨╕╨╖╤â╤ç╨╡╨╜╨╜╤ï╤à ╤â╤Ç╨╛╨║╨╛╨▓ ╨╕ ╨┤╨░╤æ╨╝ ╤é╤Ç╨╕ ╨┐╨╛╨┤╤ü╨║╨░╨╖╨║╨╕: ╨║╨░╤é╨╡╨│╨╛╤Ç╨╕╤Å,
/// ╨┐╨╡╤Ç╨▓╨░╤Å ╨┐╨╛╨╗╨╛╨▓╨╕╨╜╨░ ╨╛╨┐╤Ç╨╡╨┤╨╡╨╗╨╡╨╜╨╕╤Å ╨╕ ╨┐╤Ç╨╕╨╝╨╡╤Ç ╤â╨┐╨╛╤é╤Ç╨╡╨▒╨╗╨╡╨╜╨╕╤Å. ╨¥╤â╨╢╨╜╨╛ ╤â╨│╨░╨┤╨░╤é╤î ╤ü╨░╨╝
/// ╤é╨╡╤Ç╨╝ ╤ü╤Ç╨╡╨┤╨╕ ╤ç╨╡╤é╤ï╤Ç╤æ╤à ╨▓╨░╤Ç╨╕╨░╨╜╤é╨╛╨▓. ╨¥╨╕╤ç╨╡╨│╨╛ ╨╜╨╛╨▓╨╛╨│╨╛ ╨╜╨╡ ╨╖╨░╨▓╨╛╨┤╨╕╨╝ ΓÇö ╤â╤ç╨╕╨╝╤ü╤Å ╨╜╨░ ╤é╨╡╤à
/// ╨╢╨╡ ╨┤╨░╨╜╨╜╤ï╤à, ╤ç╤é╨╛ ╨╕ ╤â╤Ç╨╛╨║╨╕.
///
/// ╨ÿ╨│╤Ç╨░ ╨┤╨╛╨▒╤Ç╨╛╨▓╨╛╨╗╤î╨╜╨░╤Å ╨╕ ╨▒╨╡╨╖ ╨╜╨░╨║╨░╨╖╨░╨╜╨╕╨╣: ╨╛╨┤╨╕╨╜ ╤Ç╨░╤â╨╜╨┤ ╨▓ ╨┤╨╡╨╜╤î, ╨╛╤ê╨╕╨▒╨║╨░ ╨┐╤Ç╨╛╤ü╤é╨╛
/// ╨┐╨╛╨║╨░╨╖╤ï╨▓╨░╨╡╤é ╨┐╤Ç╨░╨▓╨╕╨╗╤î╨╜╤ï╨╣ ╨╛╤é╨▓╨╡╤é.
library;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:coin/features/bartender_school/data/term_service.dart';

/// ╨₧╨┤╨╕╨╜ ╤Ç╨░╤â╨╜╨┤ ╨╕╨│╤Ç╤ï.
class BlindTastingRound {
  /// ╨ó╨╡╤Ç╨╝, ╨║╨╛╤é╨╛╤Ç╤ï╨╣ ╨╜╤â╨╢╨╜╨╛ ╤â╨│╨░╨┤╨░╤é╤î.
  final TermData answer;

  /// ╨º╨╡╤é╤ï╤Ç╨╡ ╨▓╨░╤Ç╨╕╨░╨╜╤é╨░, ╨▓╨║╨╗╤Ä╤ç╨░╤Å ╨┐╤Ç╨░╨▓╨╕╨╗╤î╨╜╤ï╨╣.
  final List<TermData> options;

  const BlindTastingRound({required this.answer, required this.options});

  /// ╨ƒ╨╛╨┤╤ü╨║╨░╨╖╨║╨╕ ╨▓╤ï╨┤╨░╤Ä╤é╤ü╤Å ╨┐╨╛ ╨╛╨┤╨╜╨╛╨╣: 3 ΓåÆ 2 ΓåÆ 1.
  List<String> get hints => [
        '╨Ü╨░╤é╨╡╨│╨╛╤Ç╨╕╤Å: ${answer.category}',
        _cut(answer.definition, 90),
        _cut(answer.example, 80),
      ];

  static String _cut(String text, int limit) {
    final flat = text.replaceAll('\n', ' ').trim();
    if (flat.length <= limit) return flat;
    final slice = flat.substring(0, limit);
    final space = slice.lastIndexOf(' ');
    return '${slice.substring(0, space > 40 ? space : limit)}ΓÇª';
  }
}

/// ╨í╨╛╨▒╨╕╤Ç╨░╨╡╤é ╤Ç╨░╤â╨╜╨┤ ╨╕╨╖ ╤é╨╡╤Ç╨╝╨╛╨▓, ╨║╨╛╤é╨╛╤Ç╤ï╨╡ ╤â╤ç╨╡╨╜╨╕╨║ ╤â╨╢╨╡ ╨┐╤Ç╨╛╤à╨╛╨┤╨╕╨╗.
///
/// [learntTermNames] ΓÇö ╤Ç╤â╤ü╤ü╨║╨╕╨╡ ╨╜╨░╨╖╨▓╨░╨╜╨╕╤Å ╤é╨╡╤Ç╨╝╨╛╨▓ ╨╕╨╖ ╨╖╨░╨▓╨╡╤Ç╤ê╤æ╨╜╨╜╤ï╤à ╤â╤Ç╨╛╨║╨╛╨▓.
/// ╨ò╤ü╨╗╨╕ ╨╕╨╖╤â╤ç╨╡╨╜╨╜╤ï╤à ╨╝╨░╨╗╨╛ (╨╝╨╡╨╜╤î╤ê╨╡ ╤ç╨╡╤é╤ï╤Ç╤æ╤à), ╨▒╨╡╤Ç╤æ╨╝ ╨▒╨╗╨╕╨╢╨░╨╣╤ê╨╕╨╡ ╨╕╨╖ ╨▒╤â╨┤╤â╤ë╨╕╤à
/// ╤â╤Ç╨╛╨║╨╛╨▓: ╨┐╤â╤ü╤é╨░╤Å ╨╕╨│╤Ç╨░ ╤à╤â╨╢╨╡, ╤ç╨╡╨╝ ╨╕╨│╤Ç╨░ ╨╜╨░ ╨╛╨┐╨╡╤Ç╨╡╨╢╨╡╨╜╨╕╨╡.
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

  // ╨ö╨╡╤é╨╡╤Ç╨╝╨╕╨╜╨╕╤Ç╨╛╨▓╨░╨╜╨╜╤ï╨╣ ╨▓╤ï╨▒╨╛╤Ç ╨▒╨╡╤Ç╤æ╨╝ ╤é╨╛╨╗╤î╨║╨╛ ╨╡╤ü╨╗╨╕ Random ╨╜╨╡ ╨┐╨╡╤Ç╨╡╨┤╨░╨╜: ╨▓ ╤é╨╡╤ü╤é╨░╤à
  // Random(seed) ╨┤╨░╤æ╤é ╨┐╤Ç╨╡╨┤╤ü╨║╨░╨╖╤â╨╡╨╝╤ï╨╣ ╤Ç╨░╤â╨╜╨┤.
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

/// ╨Ñ╤Ç╨░╨╜╨╕╤é, ╨╕╨│╤Ç╨░╨╗ ╨╗╨╕ ╤ç╨╡╨╗╨╛╨▓╨╡╨║ ╤ü╨╡╨│╨╛╨┤╨╜╤Å, ╨╕ ╤ü╨║╨╛╨╗╤î╨║╨╛ ╤Ç╨░╤â╨╜╨┤╨╛╨▓ ╤â╨│╨░╨┤╨░╨╜╨╛.
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

  /// ╨Æ╤ü╨╡╨│╨╛ ╤â╨│╨░╨┤╨░╨╜╨╜╤ï╤à ╤Ç╨░╤â╨╜╨┤╨╛╨▓ ΓÇö ╨╕╤ü╨┐╨╛╨╗╤î╨╖╤â╨╡╤é╤ü╤Å ╨║╨░╨║ ╨╖╨╜╨░╨║ ╨╜╨░ ╨│╨╗╨░╨▓╨╜╨╛╨╣.
  int get correctCount => _prefs.getInt(_correctKey) ?? 0;

  int get playedCount => _prefs.getInt(_playedKey) ?? 0;

  /// ╨₧╤é╨╝╨╡╤ç╨░╨╡╤é ╤Ç╨░╤â╨╜╨┤. ╨ƒ╨╛╨▓╤é╨╛╤Ç╨╜╤ï╨╣ ╨▓╤ï╨╖╨╛╨▓ ╨▓ ╤é╨╛╤é ╨╢╨╡ ╨┤╨╡╨╜╤î ╨╜╨╕╤ç╨╡╨│╨╛ ╨╜╨╡ ╨╝╨╡╨╜╤Å╨╡╤é.
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
