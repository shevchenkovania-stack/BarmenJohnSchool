/// Недельный контракт Джона.
///
/// Ежедневные задания отвечают на вопрос «что сделать сегодня», но не дают
/// цели на дистанции. Контракт закрывает это: раз в неделю Джон «даёт
/// смену» — три урока, два коктейля, один квиз на 80%+. Награда — не
/// цифры, а история из его жизни: единственная валюта, которой он
/// действительно готов делиться.
///
/// Всё хранится локально в SharedPreferences, сброс — в понедельник.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Состояние одного пункта контракта.
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

/// История, открываемая за выполненный контракт.
class ContractStory {
  final String title;
  final String text;

  const ContractStory({required this.title, required this.text});
}

/// Пул историй: их меньше, чем недель в году, поэтому выдаём по кругу,
/// но по одной за контракт — так награда всегда ощущается событием.
const List<ContractStory> contractStories = [
  ContractStory(
    title: 'Салфетка, 1998',
    text: 'Первую неделю я не продавал коктейли — я запоминал, кто что '
        'заказывает. На седьмой день гость сел и сказал: «Обычное». Я понял, '
        'что это не про напиток. С тех пор у меня на стойке лежит салфетка, '
        'где я записываю не рецепты, а людей.',
  ),
  ContractStory(
    title: 'Тот вечер в Петербурге',
    text: 'Пётр зашёл через год после того, как я его однажды завалил '
        'разговором. Он ничего не сказал, просто сел. Я кивнул, поставил '
        'воду и отошёл. Через десять минут он заказал сам. Это был лучший '
        'комплимент за мою практику — и урок на всю жизнь: иногда работа '
        'бармена состоит в том, чтобы не мешать.',
  ),
  ContractStory(
    title: 'Про воду после полуночи',
    text: 'Я никогда не спрашиваю «вам ещё?» у человека, который третий час '
        'сидит один. Я ставлю воду. Без слов, без счёта. Половина гостей '
        'даже не замечает. Остальные — замечают всё.',
  ),
  ContractStory(
    title: 'Как я перестал бояться тишины',
    text: 'Молодой бармен считает, что тишина — это его ошибка. У меня '
        'уходили годы, чтобы понять: тишина — это гость думает. Твоя задача '
        'не заполнить её, а не испортить.',
  ),
  ContractStory(
    title: 'Правило седьмой попытки',
    text: 'Daiquiri у меня получился не с первого раза. И не с пятого. '
        'Я помню седьмой — он был идеальным, и я выпил его сам, у стойки, '
        'после закрытия. С тех пор я не верю людям, которые говорят, что '
        'у них всё получилось сразу.',
  ),
];

/// Сервис недельного контракта.
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

  /// Неделя считается с понедельника.
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
          title: 'Пройди 3 урока',
          emoji: '📖',
          target: lessonTarget,
          done: lessonsDone,
        ),
        ContractItem(
          title: 'Собери 2 коктейля в мастерской',
          emoji: '🍸',
          target: cocktailTarget,
          done: cocktailsDone,
        ),
        ContractItem(
          title: 'Сдай квиз на 80%+',
          emoji: '🎯',
          target: examTarget,
          done: examsDone,
        ),
      ];

  bool get isComplete => items.every((item) => item.isComplete);

  bool get isClaimed => _prefs.getBool(_claimedKey) ?? false;

  /// Индекс истории, которая ждёт следующего закрытого контракта.
  int get storyIndex =>
      (_prefs.getInt(_storyKey) ?? 0) % contractStories.length;

  /// История, которую Джон расскажет за этот контракт.
  ContractStory get story => contractStories[storyIndex];

  /// История, которую уже открыли на этой неделе (после получения).
  ///
  /// После [claim] индекс сдвинут вперёд, поэтому нужная запись — предыдущая.
  ContractStory? get claimedStory => isClaimed ? lastClaimedStory : null;

  /// Отмечает прогресс контракта. Возвращает true, если что-то изменилось.
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

  /// Забрать историю. Возвращает её или null, если контракт не закрыт.
  ///
  /// Индекс истории не сдвигаем: иначе «уже открытая» история на этой
  /// неделе стала бы другой. Следующая неделя просто покажет следующую
  /// запись, потому что счётчик растёт только при подведении итога.
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

  /// Запомненная история для показа после получения награды.
  ///
  /// Индекс уже сдвинут вперёд, поэтому берём предыдущую запись.
  ContractStory get lastClaimedStory => contractStories[
      (storyIndex - 1 + contractStories.length) % contractStories.length];
}
