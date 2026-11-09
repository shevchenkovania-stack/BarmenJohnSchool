/// Квест-сцена первого урока.
///
/// Отличие от [SlideType.choice] из уроков Мудрости: там варианты — это
/// аккордеон, можно раскрыть все три и ничего не изменится. Здесь выбор
/// настоящий: вопрос задаётся один раз, гость отвечает только на то, о чём
/// его спросили, а финальное действие закрывает сцену.
///
/// Файл намеренно без Flutter: модель и правила проверяются тестами без
/// сборки экрана и не могут сломать UI.
library;

/// Реплика в сцене (титры, постановка, слова гостя).
class QuestBeat {
  /// Кто говорит. `null` — авторский текст (титры и постановка).
  final String? speaker;

  final String text;

  const QuestBeat({this.speaker, required this.text});
}

/// Вопрос, который ученик задаёт гостю.
///
/// [insight] — что игрок понял из ответа. Копится и показывается, чтобы
/// чувствовалось «я узнал больше», а не «я нажал три кнопки».
class QuestProbe {
  final String id;

  /// Как звучит вопрос ученика.
  final String label;

  /// Что ответил гость.
  final String response;

  /// Что из этого следует.
  final String insight;

  const QuestProbe({
    required this.id,
    required this.label,
    required this.response,
    required this.insight,
  });
}

/// Финальное действие (что налить).
class QuestOption {
  final String id;

  /// Что делает ученик.
  final String text;

  /// Единственный верный вариант. На прогресс не влияет: квест
  /// пропускает вперёд всегда, но правильный ответ звучит иначе.
  final bool isRight;

  /// Ответ гостя на действие.
  final String guestReaction;

  /// Вывод Джона после сцены.
  final String johnLesson;

  /// Что гость делает дальше — своя ветка для каждого выбора.
  ///
  /// Это и есть ветвление: не новый экран, а другой конец разговора.
  /// Один и тот же напиток можно подать так, что гость уйдёт, или так,
  /// что останется. Пустая строка — ветки нет, показываем [guestReaction].
  final String followUp;

  /// Продолжение для той же ветки, когда игрок успел всё выяснить.
  /// Пустая строка — общего продолжения хватает.
  final String followUpInformed;

  const QuestOption({
    required this.id,
    required this.text,
    required this.isRight,
    required this.guestReaction,
    required this.johnLesson,
    this.followUp = '',
    this.followUpInformed = '',
  });
}

/// Сцена целиком.
class QuestScene {
  final String id;

  /// Заголовок сцены («Дождь на Пятой авеню»).
  final String title;

  /// Титры: год и место.
  final String timeStamp;

  /// Реплики до первого вопроса.
  final List<QuestBeat> beats;

  /// Вопросы, которые можно задать (каждый — один раз).
  final List<QuestProbe> probes;

  /// Варианты финального действия.
  final List<QuestOption> answers;

  const QuestScene({
    required this.id,
    required this.title,
    required this.timeStamp,
    required this.beats,
    required this.probes,
    required this.answers,
  });

  /// Есть ли у сцены смысл: нужны реплики, вопросы и варианты.
  bool get isValid =>
      beats.isNotEmpty &&
      probes.isNotEmpty &&
      answers.isNotEmpty &&
      answers.where((a) => a.isRight).length == 1;

  /// Целевой (правильный) вариант. `null`, если данные битые.
  QuestOption? get rightAnswer {
    for (final answer in answers) {
      if (answer.isRight) return answer;
    }
    return null;
  }

  factory QuestScene.fromJson(Map<String, dynamic> json) {
    List<T> readList<T>(String key, T Function(Map<String, dynamic>) build) {
      final raw = json[key];
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map>()
          .map((e) => build(e.cast<String, dynamic>()))
          .toList();
    }

    return QuestScene(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      timeStamp: json['timeStamp'] as String? ?? '',
      beats: readList(
        'beats',
        (j) => QuestBeat(
          speaker: j['speaker'] as String?,
          text: j['text'] as String? ?? '',
        ),
      ),
      probes: readList(
        'probes',
        (j) => QuestProbe(
          id: j['id'] as String? ?? '',
          label: j['label'] as String? ?? '',
          response: j['response'] as String? ?? '',
          insight: j['insight'] as String? ?? '',
        ),
      ),
      answers: readList(
        'answers',
        (j) => QuestOption(
          id: j['id'] as String? ?? '',
          text: j['text'] as String? ?? '',
          isRight: j['isRight'] as bool? ?? false,
          guestReaction: j['guestReaction'] as String? ?? '',
          johnLesson: j['johnLesson'] as String? ?? '',
          followUp: j['followUp'] as String? ?? '',
          followUpInformed: j['followUpInformed'] as String? ?? '',
        ),
      ),
    );
  }
}

/// Состояние прохождения сцены.
///
/// Правила:
/// - вопрос задаётся ровно один раз (иначе это не вопрос, а подсказка);
/// - финальное действие доступно при любом числе вопросов;
/// - после выбора сцена закрыта и второй раз не выбирается.
class QuestSceneState {
  /// Гость на выбор, сделанный вслепую: ни одного вопроса не задано.
  static const String _guestLineForNothing =
      '…а тебе, собственно, какая разница?';

  /// Гость на выбор, сделанный до того, как картина сложилась.
  static const String _guestLineForPartial = 'Хм. Ты многого не спросил.';

  /// Джон про раннее решение: не стыдит, называет потерю.
  static const String _johnLineForNothing =
      'Ты не спросил ни слова. Налить можно и так, но это уже не разговор.';

  static const String _johnLineForPartial =
      'Гость ответил, но картина ещё не собралась. Одно решение — из того, '
      'что успел услышать.';

  final QuestScene scene;

  final Set<String> _askedProbeIds = <String>{};
  QuestOption? _picked;

  /// Вопросы открываются по одному: сначала один, после ответа — следующий.
  /// Так ученик не видит сразу весь список и не «скачивает подсказки».
  int _nextProbeIndex = 0;

  QuestSceneState(this.scene);

  /// Уже заданные вопросы (в том числе их ответы показываются в ленте).
  List<QuestProbe> get askedProbes =>
      scene.probes.where((p) => _askedProbeIds.contains(p.id)).toList();

  /// Вопрос, который можно задать сейчас. `null` — вопросы кончились.
  QuestProbe? get availableProbe {
    for (var i = _nextProbeIndex; i < scene.probes.length; i++) {
      final probe = scene.probes[i];
      if (!_askedProbeIds.contains(probe.id)) return probe;
    }
    return null;
  }

  bool get hasQuestionsLeft => availableProbe != null;

  /// Финальное действие доступно всегда.
  ///
  /// Нельзя блокировать финал: сцена не проходится иначе, а игроку
  /// нужна честная обратная связь за раннее решение. Цена выбора — не
  /// запрет, а другой ответ гостя и другой урок Джона (см. [choose]).
  bool get canAnswer => _picked == null;

  /// Успел ли игрок всё выяснить.
  bool get isFullyInformed =>
      scene.probes.isNotEmpty && askedProbes.length == scene.probes.length;

  /// Выбранный вариант (после финала).
  QuestOption? get picked => _picked;

  bool get isFinished => _picked != null;

  /// Насколько сцена раскрыта: 0..1.
  double get insightProgress {
    if (scene.probes.isEmpty) return 1;
    return (askedProbes.length / scene.probes.length).clamp(0.0, 1.0);
  }

  /// Что игрок уже понял — накопительно.
  List<String> get insights =>
      askedProbes.map((p) => p.insight).where((s) => s.isNotEmpty).toList();

  /// Задать вопрос. Возвращает `false`, если вопрос уже задан или сцена
  /// закрыта — повторного нажатия не происходит.
  bool ask(String probeId) {
    if (isFinished) return false;
    if (_askedProbeIds.contains(probeId)) return false;
    final probe = scene.probes.where((p) => p.id == probeId).firstOrNull;
    if (probe == null) return false;
    _askedProbeIds.add(probeId);
    _nextProbeIndex = 0; // пересчитаем с начала; доступность решает set
    return true;
  }

  /// Выбрать финальное действие. Возвращает выбранный вариант или `null`,
  /// если сцена уже закрыта.
  ///
  /// Сам вариант не меняется: [QuestOption.isRight] — это про то, угадал
  /// ли игрок. А вот что услышит игрок в ответ, зависит от того, сколько
  /// он успел спросить.
  QuestOption? choose(String optionId) {
    if (!canAnswer) return null;
    final option = scene.answers.where((a) => a.id == optionId).firstOrNull;
    if (option == null) return null;
    _picked = option;
    return option;
  }

  /// Что гость говорит на выбор.
  ///
  /// Здесь начинается ветвление: один и тот же напиток можно подать так,
  /// что гость уйдёт, или так, что останется. Решает не «угадал или
  /// нет», а совпало ли действие с тем, что игрок услышал.
  ///
  /// Пустой выбор — гость спрашивает сам, какая разница.
  String get guestReaction {
    final pickedOption = _picked;
    if (pickedOption == null) return '';
    if (askedProbes.isEmpty) return _guestLineForNothing;
    final branch = _branch(pickedOption);
    if (branch.isNotEmpty) return branch;
    if (!isFullyInformed) return _guestLineForPartial;
    return pickedOption.guestReaction;
  }

  /// Куда ушла ветка после выбора.
  ///
  /// `null` — сцена не закончена. Остальное — один из трёх исходов:
  /// гость попросил ещё, поблагодарил или ушёл.
  QuestOutcome? get outcome {
    final pickedOption = _picked;
    if (pickedOption == null) return null;
    if (askedProbes.isEmpty) return QuestOutcome.blind;
    if (_branch(pickedOption).isNotEmpty) {
      return pickedOption.isRight ? QuestOutcome.stayed : QuestOutcome.left;
    }
    return isFullyInformed ? QuestOutcome.stayed : QuestOutcome.partial;
  }

  /// Ветка варианта с учётом того, всё ли выяснено.
  String _branch(QuestOption option) {
    if (isFullyInformed && option.followUpInformed.isNotEmpty) {
      return option.followUpInformed;
    }
    return option.followUp;
  }

  /// Вывод Джона: на раннее решение он говорит о том, чего игрок лишил себя,
  /// а не только о том, верно ли выбран напиток.
  String get johnLesson {
    final pickedOption = _picked;
    if (pickedOption == null) return '';
    if (askedProbes.isEmpty) return _johnLineForNothing;
    if (!isFullyInformed) return _johnLineForPartial;
    return pickedOption.johnLesson;
  }

  /// Был ли выбор верным (`null` — ещё не выбирали).
  bool? get wasRight => _picked?.isRight;
}

/// Чем кончился разговор — ветка сцены.
enum QuestOutcome {
  /// Выбрал, ни о чём не спросив. Гость отвечает вопросом.
  blind('без вопросов'),

  /// Спросил часть и решил. Гость ушёл недовольным.
  partial('недосказано'),

  /// Всё выяснил и пошёл не туда. Гость ушёл, но без стыда.
  left('гость ушёл'),

  /// Всё выяснил и попал в то, что человек просил.
  stayed('гость остался');

  final String label;

  const QuestOutcome(this.label);
}
