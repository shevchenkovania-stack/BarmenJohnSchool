/// ╨¥╨╡╨┤╨╡╨╗╤î╨╜╤ï╨╣ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é ╨ö╨╢╨╛╨╜╨░.
///
/// ╨ò╨╢╨╡╨┤╨╜╨╡╨▓╨╜╤ï╨╡ ╨╖╨░╨┤╨░╨╜╨╕╤Å ╨╛╤é╨▓╨╡╤ç╨░╤Ä╤é ╨╜╨░ ╨▓╨╛╨┐╤Ç╨╛╤ü ┬½╤ç╤é╨╛ ╤ü╨┤╨╡╨╗╨░╤é╤î ╤ü╨╡╨│╨╛╨┤╨╜╤Å┬╗, ╨╜╨╛ ╨╜╨╡ ╨┤╨░╤Ä╤é
/// ╤å╨╡╨╗╨╕ ╨╜╨░ ╨┤╨╕╤ü╤é╨░╨╜╤å╨╕╨╕. ╨Ü╨╛╨╜╤é╤Ç╨░╨║╤é ╨╖╨░╨║╤Ç╤ï╨▓╨░╨╡╤é ╤ì╤é╨╛: ╤Ç╨░╨╖ ╨▓ ╨╜╨╡╨┤╨╡╨╗╤Ä ╨ö╨╢╨╛╨╜ ┬½╨┤╨░╤æ╤é
/// ╤ü╨╝╨╡╨╜╤â┬╗ ΓÇö ╤é╤Ç╨╕ ╤â╤Ç╨╛╨║╨░, ╨┤╨▓╨░ ╨║╨╛╨║╤é╨╡╨╣╨╗╤Å, ╨╛╨┤╨╕╨╜ ╨║╨▓╨╕╨╖ ╨╜╨░ 80%+. ╨¥╨░╨│╤Ç╨░╨┤╨░ ΓÇö ╨╜╨╡
/// ╤å╨╕╤ä╤Ç╤ï, ╨░ ╨╕╤ü╤é╨╛╤Ç╨╕╤Å ╨╕╨╖ ╨╡╨│╨╛ ╨╢╨╕╨╖╨╜╨╕: ╨╡╨┤╨╕╨╜╤ü╤é╨▓╨╡╨╜╨╜╨░╤Å ╨▓╨░╨╗╤Ä╤é╨░, ╨║╨╛╤é╨╛╤Ç╨╛╨╣ ╨╛╨╜
/// ╨┤╨╡╨╣╤ü╤é╨▓╨╕╤é╨╡╨╗╤î╨╜╨╛ ╨│╨╛╤é╨╛╨▓ ╨┤╨╡╨╗╨╕╤é╤î╤ü╤Å.
///
/// ╨Æ╤ü╤æ ╤à╤Ç╨░╨╜╨╕╤é╤ü╤Å ╨╗╨╛╨║╨░╨╗╤î╨╜╨╛ ╨▓ SharedPreferences, ╤ü╨▒╤Ç╨╛╤ü ΓÇö ╨▓ ╨┐╨╛╨╜╨╡╨┤╨╡╨╗╤î╨╜╨╕╨║.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ╨í╨╛╤ü╤é╨╛╤Å╨╜╨╕╨╡ ╨╛╨┤╨╜╨╛╨│╨╛ ╨┐╤â╨╜╨║╤é╨░ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é╨░.
class ContractItem {
  final String title;
  final String emoji;
  final int target;
  final int done;

  const ContractItem({
    required this.title,
    required this.emoji,
    required this.target,
    required this.done,
  });

  bool get isComplete => done >= target;
  double get progress => (done / target).clamp(0.0, 1.0);

  ContractItem copyWith({int? done}) => ContractItem(
        title: title,
        emoji: emoji,
        target: target,
        done: done ?? this.done,
      );
}

/// ╨ÿ╤ü╤é╨╛╤Ç╨╕╤Å, ╨╛╤é╨║╤Ç╤ï╨▓╨░╨╡╨╝╨░╤Å ╨╖╨░ ╨▓╤ï╨┐╨╛╨╗╨╜╨╡╨╜╨╜╤ï╨╣ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é.
class ContractStory {
  final String title;
  final String text;

  const ContractStory({required this.title, required this.text});
}

/// ╨ƒ╤â╨╗ ╨╕╤ü╤é╨╛╤Ç╨╕╨╣: ╨╕╤à ╨╝╨╡╨╜╤î╤ê╨╡, ╤ç╨╡╨╝ ╨╜╨╡╨┤╨╡╨╗╤î ╨▓ ╨│╨╛╨┤╤â, ╨┐╨╛╤ì╤é╨╛╨╝╤â ╨▓╤ï╨┤╨░╤æ╨╝ ╨┐╨╛ ╨║╤Ç╤â╨│╤â,
/// ╨╜╨╛ ╨┐╨╛ ╨╛╨┤╨╜╨╛╨╣ ╨╖╨░ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é ΓÇö ╤é╨░╨║ ╨╜╨░╨│╤Ç╨░╨┤╨░ ╨▓╤ü╨╡╨│╨┤╨░ ╨╛╤ë╤â╤ë╨░╨╡╤é╤ü╤Å ╤ü╨╛╨▒╤ï╤é╨╕╨╡╨╝.
const List<ContractStory> contractStories = [
  ContractStory(
    title: '╨í╨░╨╗╤ä╨╡╤é╨║╨░, 1998',
    text:
        '╨ƒ╨╡╤Ç╨▓╤â╤Ä ╨╜╨╡╨┤╨╡╨╗╤Ä ╤Å ╨╜╨╡ ╨┐╤Ç╨╛╨┤╨░╨▓╨░╨╗ ╨║╨╛╨║╤é╨╡╨╣╨╗╨╕ ΓÇö ╤Å ╨╖╨░╨┐╨╛╨╝╨╕╨╜╨░╨╗, ╨║╤é╨╛ ╤ç╤é╨╛ '
        '╨╖╨░╨║╨░╨╖╤ï╨▓╨░╨╡╤é. ╨¥╨░ ╤ü╨╡╨┤╤î╨╝╨╛╨╣ ╨┤╨╡╨╜╤î ╨│╨╛╤ü╤é╤î ╤ü╨╡╨╗ ╨╕ ╤ü╨║╨░╨╖╨░╨╗: ┬½╨₧╨▒╤ï╤ç╨╜╨╛╨╡┬╗. ╨» ╨┐╨╛╨╜╤Å╨╗, '
        '╤ç╤é╨╛ ╤ì╤é╨╛ ╨╜╨╡ ╨┐╤Ç╨╛ ╨╜╨░╨┐╨╕╤é╨╛╨║. ╨í ╤é╨╡╤à ╨┐╨╛╤Ç ╤â ╨╝╨╡╨╜╤Å ╨╜╨░ ╤ü╤é╨╛╨╣╨║╨╡ ╨╗╨╡╨╢╨╕╤é ╤ü╨░╨╗╤ä╨╡╤é╨║╨░, '
        '╨│╨┤╨╡ ╤Å ╨╖╨░╨┐╨╕╤ü╤ï╨▓╨░╤Ä ╨╜╨╡ ╤Ç╨╡╤å╨╡╨┐╤é╤ï, ╨░ ╨╗╤Ä╨┤╨╡╨╣.',
  ),
  ContractStory(
    title: '╨ó╨╛╤é ╨▓╨╡╤ç╨╡╤Ç ╨▓ ╨ƒ╨╡╤é╨╡╤Ç╨▒╤â╤Ç╨│╨╡',
    text:
        '╨ƒ╤æ╤é╤Ç ╨╖╨░╤ê╤æ╨╗ ╤ç╨╡╤Ç╨╡╨╖ ╨│╨╛╨┤ ╨┐╨╛╤ü╨╗╨╡ ╤é╨╛╨│╨╛, ╨║╨░╨║ ╤Å ╨╡╨│╨╛ ╨╛╨┤╨╜╨░╨╢╨┤╤ï ╨╖╨░╨▓╨░╨╗╨╕╨╗ '
        '╤Ç╨░╨╖╨│╨╛╨▓╨╛╤Ç╨╛╨╝. ╨₧╨╜ ╨╜╨╕╤ç╨╡╨│╨╛ ╨╜╨╡ ╤ü╨║╨░╨╖╨░╨╗, ╨┐╤Ç╨╛╤ü╤é╨╛ ╤ü╨╡╨╗. ╨» ╨║╨╕╨▓╨╜╤â╨╗, ╨┐╨╛╤ü╤é╨░╨▓╨╕╨╗ '
        '╨▓╨╛╨┤╤â ╨╕ ╨╛╤é╨╛╤ê╤æ╨╗. ╨º╨╡╤Ç╨╡╨╖ ╨┤╨╡╤ü╤Å╤é╤î ╨╝╨╕╨╜╤â╤é ╨╛╨╜ ╨╖╨░╨║╨░╨╖╨░╨╗ ╤ü╨░╨╝. ╨¡╤é╨╛ ╨▒╤ï╨╗ ╨╗╤â╤ç╤ê╨╕╨╣ '
        '╨║╨╛╨╝╨┐╨╗╨╕╨╝╨╡╨╜╤é ╨╖╨░ ╨╝╨╛╤Ä ╨┐╤Ç╨░╨║╤é╨╕╨║╤â ΓÇö ╨╕ ╤â╤Ç╨╛╨║ ╨╜╨░ ╨▓╤ü╤Ä ╨╢╨╕╨╖╨╜╤î: ╨╕╨╜╨╛╨│╨┤╨░ ╤Ç╨░╨▒╨╛╤é╨░ '
        '╨▒╨░╤Ç╨╝╨╡╨╜╨░ ╤ü╨╛╤ü╤é╨╛╨╕╤é ╨▓ ╤é╨╛╨╝, ╤ç╤é╨╛╨▒╤ï ╨╜╨╡ ╨╝╨╡╤ê╨░╤é╤î.',
  ),
  ContractStory(
    title: '╨ƒ╤Ç╨╛ ╨▓╨╛╨┤╤â ╨┐╨╛╤ü╨╗╨╡ ╨┐╨╛╨╗╤â╨╜╨╛╤ç╨╕',
    text:
        '╨» ╨╜╨╕╨║╨╛╨│╨┤╨░ ╨╜╨╡ ╤ü╨┐╤Ç╨░╤ê╨╕╨▓╨░╤Ä ┬½╨▓╨░╨╝ ╨╡╤ë╤æ?┬╗ ╤â ╤ç╨╡╨╗╨╛╨▓╨╡╨║╨░, ╨║╨╛╤é╨╛╤Ç╤ï╨╣ ╤é╤Ç╨╡╤é╨╕╨╣ ╤ç╨░╤ü '
        '╤ü╨╕╨┤╨╕╤é ╨╛╨┤╨╕╨╜. ╨» ╤ü╤é╨░╨▓╨╗╤Ä ╨▓╨╛╨┤╤â. ╨æ╨╡╨╖ ╤ü╨╗╨╛╨▓, ╨▒╨╡╨╖ ╤ü╤ç╤æ╤é╨░. ╨ƒ╨╛╨╗╨╛╨▓╨╕╨╜╨░ ╨│╨╛╤ü╤é╨╡╨╣ '
        '╨┤╨░╨╢╨╡ ╨╜╨╡ ╨╖╨░╨╝╨╡╤ç╨░╨╡╤é. ╨₧╤ü╤é╨░╨╗╤î╨╜╤ï╨╡ ΓÇö ╨╖╨░╨╝╨╡╤ç╨░╤Ä╤é ╨▓╤ü╤æ.',
  ),
  ContractStory(
    title: '╨Ü╨░╨║ ╤Å ╨┐╨╡╤Ç╨╡╤ü╤é╨░╨╗ ╨▒╨╛╤Å╤é╤î╤ü╤Å ╤é╨╕╤ê╨╕╨╜╤ï',
    text:
        '╨£╨╛╨╗╨╛╨┤╨╛╨╣ ╨▒╨░╤Ç╨╝╨╡╨╜ ╤ü╤ç╨╕╤é╨░╨╡╤é, ╤ç╤é╨╛ ╤é╨╕╤ê╨╕╨╜╨░ ΓÇö ╤ì╤é╨╛ ╨╡╨│╨╛ ╨╛╤ê╨╕╨▒╨║╨░. ╨ú ╨╝╨╡╨╜╤Å '
        '╤â╤à╨╛╨┤╨╕╨╗╨╕ ╨│╨╛╨┤╤ï, ╤ç╤é╨╛╨▒╤ï ╨┐╨╛╨╜╤Å╤é╤î: ╤é╨╕╤ê╨╕╨╜╨░ ΓÇö ╤ì╤é╨╛ ╨│╨╛╤ü╤é╤î ╨┤╤â╨╝╨░╨╡╤é. ╨ó╨▓╨╛╤Å ╨╖╨░╨┤╨░╤ç╨░ '
        '╨╜╨╡ ╨╖╨░╨┐╨╛╨╗╨╜╨╕╤é╤î ╨╡╤æ, ╨░ ╨╜╨╡ ╨╕╤ü╨┐╨╛╤Ç╤é╨╕╤é╤î.',
  ),
  ContractStory(
    title: '╨ƒ╤Ç╨░╨▓╨╕╨╗╨╛ ╤ü╨╡╨┤╤î╨╝╨╛╨╣ ╨┐╨╛╨┐╤ï╤é╨║╨╕',
    text:
        'Daiquiri ╤â ╨╝╨╡╨╜╤Å ╨┐╨╛╨╗╤â╤ç╨╕╨╗╤ü╤Å ╨╜╨╡ ╤ü ╨┐╨╡╤Ç╨▓╨╛╨│╨╛ ╤Ç╨░╨╖╨░. ╨ÿ ╨╜╨╡ ╤ü ╨┐╤Å╤é╨╛╨│╨╛. '
        '╨» ╨┐╨╛╨╝╨╜╤Ä ╤ü╨╡╨┤╤î╨╝╨╛╨╣ ΓÇö ╨╛╨╜ ╨▒╤ï╨╗ ╨╕╨┤╨╡╨░╨╗╤î╨╜╤ï╨╝, ╨╕ ╤Å ╨▓╤ï╨┐╨╕╨╗ ╨╡╨│╨╛ ╤ü╨░╨╝, ╤â ╤ü╤é╨╛╨╣╨║╨╕, '
        '╨┐╨╛╤ü╨╗╨╡ ╨╖╨░╨║╤Ç╤ï╤é╨╕╤Å. ╨í ╤é╨╡╤à ╨┐╨╛╤Ç ╤Å ╨╜╨╡ ╨▓╨╡╤Ç╤Ä ╨╗╤Ä╨┤╤Å╨╝, ╨║╨╛╤é╨╛╤Ç╤ï╨╡ ╨│╨╛╨▓╨╛╤Ç╤Å╤é, ╤ç╤é╨╛ '
        '╤â ╨╜╨╕╤à ╨▓╤ü╤æ ╨┐╨╛╨╗╤â╤ç╨╕╨╗╨╛╤ü╤î ╤ü╤Ç╨░╨╖╤â.',
  ),
];

/// ╨í╨╡╤Ç╨▓╨╕╤ü ╨╜╨╡╨┤╨╡╨╗╤î╨╜╨╛╨│╨╛ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é╨░.
class WeeklyContractService extends ChangeNotifier {
  final SharedPreferences _prefs;

  WeeklyContractService(this._prefs) {
    _rollOverIfNeeded();
  }

  static const String _weekKey = 'weekly_contract_week';
  static const String _lessonsKey = 'weekly_contract_lessons';
  static const String _cocktailsKey = 'weekly_contract_cocktails';
  static const String _examsKey = 'weekly_contract_exams';
  static const String _storyKey = 'weekly_contract_story_index';
  static const String _claimedKey = 'weekly_contract_claimed';

  static const int lessonTarget = 3;
  static const int cocktailTarget = 2;
  static const int examTarget = 1;

  /// ╨¥╨╡╨┤╨╡╨╗╤Å ╤ü╤ç╨╕╤é╨░╨╡╤é╤ü╤Å ╤ü ╨┐╨╛╨╜╨╡╨┤╨╡╨╗╤î╨╜╨╕╨║╨░.
  static String weekStamp([DateTime? now]) {
    final date = now ?? DateTime.now();
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    return '${monday.year}-${_two(monday.month)}-${_two(monday.day)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  void _rollOverIfNeeded() {
    final current = weekStamp();
    if (_prefs.getString(_weekKey) == current) return;
    _prefs.setString(_weekKey, current);
    _prefs.setInt(_lessonsKey, 0);
    _prefs.setInt(_cocktailsKey, 0);
    _prefs.setInt(_examsKey, 0);
    _prefs.setBool(_claimedKey, false);
  }

  int get lessonsDone => _prefs.getInt(_lessonsKey) ?? 0;
  int get cocktailsDone => _prefs.getInt(_cocktailsKey) ?? 0;
  int get examsDone => _prefs.getInt(_examsKey) ?? 0;

  List<ContractItem> get items => [
        ContractItem(
          title: '╨ƒ╤Ç╨╛╨╣╨┤╨╕ 3 ╤â╤Ç╨╛╨║╨░',
          emoji: '≡ƒôû',
          target: lessonTarget,
          done: lessonsDone,
        ),
        ContractItem(
          title: '╨í╨╛╨▒╨╡╤Ç╨╕ 2 ╨║╨╛╨║╤é╨╡╨╣╨╗╤Å ╨▓ ╨╝╨░╤ü╤é╨╡╤Ç╤ü╨║╨╛╨╣',
          emoji: '≡ƒì╕',
          target: cocktailTarget,
          done: cocktailsDone,
        ),
        ContractItem(
          title: '╨í╨┤╨░╨╣ ╨║╨▓╨╕╨╖ ╨╜╨░ 80%+',
          emoji: '≡ƒÄ»',
          target: examTarget,
          done: examsDone,
        ),
      ];

  bool get isComplete => items.every((item) => item.isComplete);

  bool get isClaimed => _prefs.getBool(_claimedKey) ?? false;

  /// ╨ÿ╨╜╨┤╨╡╨║╤ü ╨╕╤ü╤é╨╛╤Ç╨╕╨╕, ╨║╨╛╤é╨╛╤Ç╨░╤Å ╨╢╨┤╤æ╤é ╤ü╨╗╨╡╨┤╤â╤Ä╤ë╨╡╨│╨╛ ╨╖╨░╨║╤Ç╤ï╤é╨╛╨│╨╛ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é╨░.
  int get storyIndex =>
      (_prefs.getInt(_storyKey) ?? 0) % contractStories.length;

  /// ╨ÿ╤ü╤é╨╛╤Ç╨╕╤Å, ╨║╨╛╤é╨╛╤Ç╤â╤Ä ╨ö╨╢╨╛╨╜ ╤Ç╨░╤ü╤ü╨║╨░╨╢╨╡╤é ╨╖╨░ ╤ì╤é╨╛╤é ╨║╨╛╨╜╤é╤Ç╨░╨║╤é.
  ContractStory get story => contractStories[storyIndex];

  /// ╨ÿ╤ü╤é╨╛╤Ç╨╕╤Å, ╨║╨╛╤é╨╛╤Ç╤â╤Ä ╤â╨╢╨╡ ╨╛╤é╨║╤Ç╤ï╨╗╨╕ ╨╜╨░ ╤ì╤é╨╛╨╣ ╨╜╨╡╨┤╨╡╨╗╨╡ (╨┐╨╛╤ü╨╗╨╡ ╨┐╨╛╨╗╤â╤ç╨╡╨╜╨╕╤Å).
  ///
  /// ╨ƒ╨╛╤ü╨╗╨╡ [claim] ╨╕╨╜╨┤╨╡╨║╤ü ╤ü╨┤╨▓╨╕╨╜╤â╤é ╨▓╨┐╨╡╤Ç╤æ╨┤, ╨┐╨╛╤ì╤é╨╛╨╝╤â ╨╜╤â╨╢╨╜╨░╤Å ╨╖╨░╨┐╨╕╤ü╤î ΓÇö ╨┐╤Ç╨╡╨┤╤ï╨┤╤â╤ë╨░╤Å.
  ContractStory? get claimedStory => isClaimed ? lastClaimedStory : null;

  /// ╨₧╤é╨╝╨╡╤ç╨░╨╡╤é ╨┐╤Ç╨╛╨│╤Ç╨╡╤ü╤ü ╨║╨╛╨╜╤é╤Ç╨░╨║╤é╨░. ╨Æ╨╛╨╖╨▓╤Ç╨░╤ë╨░╨╡╤é true, ╨╡╤ü╨╗╨╕ ╤ç╤é╨╛-╤é╨╛ ╨╕╨╖╨╝╨╡╨╜╨╕╨╗╨╛╤ü╤î.
  Future<bool> registerLesson() => _bump(_lessonsKey, lessonTarget);
  Future<bool> registerCocktail() => _bump(_cocktailsKey, cocktailTarget);
  Future<bool> registerExam() => _bump(_examsKey, examTarget);

  Future<bool> _bump(String key, int target) async {
    _rollOverIfNeeded();
    final current = _prefs.getInt(key) ?? 0;
    if (current >= target) return false;
    await _prefs.setInt(key, current + 1);
    notifyListeners();
    return true;
  }

  /// ╨ù╨░╨▒╤Ç╨░╤é╤î ╨╕╤ü╤é╨╛╤Ç╨╕╤Ä. ╨Æ╨╛╨╖╨▓╤Ç╨░╤ë╨░╨╡╤é ╨╡╤æ ╨╕╨╗╨╕ null, ╨╡╤ü╨╗╨╕ ╨║╨╛╨╜╤é╤Ç╨░╨║╤é ╨╜╨╡ ╨╖╨░╨║╤Ç╤ï╤é.
  ///
  /// ╨ÿ╨╜╨┤╨╡╨║╤ü ╨╕╤ü╤é╨╛╤Ç╨╕╨╕ ╨╜╨╡ ╤ü╨┤╨▓╨╕╨│╨░╨╡╨╝: ╨╕╨╜╨░╤ç╨╡ ┬½╤â╨╢╨╡ ╨╛╤é╨║╤Ç╤ï╤é╨░╤Å┬╗ ╨╕╤ü╤é╨╛╤Ç╨╕╤Å ╨╜╨░ ╤ì╤é╨╛╨╣
  /// ╨╜╨╡╨┤╨╡╨╗╨╡ ╤ü╤é╨░╨╗╨░ ╨▒╤ï ╨┤╤Ç╤â╨│╨╛╨╣. ╨í╨╗╨╡╨┤╤â╤Ä╤ë╨░╤Å ╨╜╨╡╨┤╨╡╨╗╤Å ╨┐╤Ç╨╛╤ü╤é╨╛ ╨┐╨╛╨║╨░╨╢╨╡╤é ╤ü╨╗╨╡╨┤╤â╤Ä╤ë╤â╤Ä
  /// ╨╖╨░╨┐╨╕╤ü╤î, ╨┐╨╛╤é╨╛╨╝╤â ╤ç╤é╨╛ ╤ü╤ç╤æ╤é╤ç╨╕╨║ ╤Ç╨░╤ü╤é╤æ╤é ╤é╨╛╨╗╤î╨║╨╛ ╨┐╤Ç╨╕ ╨┐╨╛╨┤╨▓╨╡╨┤╨╡╨╜╨╕╨╕ ╨╕╤é╨╛╨│╨░.
  Future<ContractStory?> claim() async {
    if (!isComplete || isClaimed) return null;
    final story = this.story;
    await _prefs.setBool(_claimedKey, true);
    await _prefs.setInt(
      _storyKey,
      (storyIndex + 1) % contractStories.length,
    );
    notifyListeners();
    return story;
  }

  /// ╨ù╨░╨┐╨╛╨╝╨╜╨╡╨╜╨╜╨░╤Å ╨╕╤ü╤é╨╛╤Ç╨╕╤Å ╨┤╨╗╤Å ╨┐╨╛╨║╨░╨╖╨░ ╨┐╨╛╤ü╨╗╨╡ ╨┐╨╛╨╗╤â╤ç╨╡╨╜╨╕╤Å ╨╜╨░╨│╤Ç╨░╨┤╤ï.
  ///
  /// ╨ÿ╨╜╨┤╨╡╨║╤ü ╤â╨╢╨╡ ╤ü╨┤╨▓╨╕╨╜╤â╤é ╨▓╨┐╨╡╤Ç╤æ╨┤, ╨┐╨╛╤ì╤é╨╛╨╝╤â ╨▒╨╡╤Ç╤æ╨╝ ╨┐╤Ç╨╡╨┤╤ï╨┤╤â╤ë╤â╤Ä ╨╖╨░╨┐╨╕╤ü╤î.
  ContractStory get lastClaimedStory => contractStories[
      (storyIndex - 1 + contractStories.length) % contractStories.length];
}
