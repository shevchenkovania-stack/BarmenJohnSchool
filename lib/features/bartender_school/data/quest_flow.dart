/// Квест первого урока: расследование, подача и финал по правилам.
///
/// Отличие от [QuestScene] (сцена с вопросами) в том, что здесь есть
/// **факты**, **попытки** и **правила финала**. Файл без Flutter: правила
/// проверяются тестами без сборки экрана.
///
/// Данные приходят из поля `quest` урока. Поле необязательное: уроки без
/// него идут прежним путём.
library;

/// Один вопрос, который игрок задаёт гостю.
///
/// Ответ на вопрос открывает факт ([evidenceText]) — тот же ответ второй
/// раз фактов не добавляет.
class QuestEvidenceItem {
  final String id;

  /// Как звучит вопрос игрока.
  final String label;

  /// Что ответил гость.
  final String response;

  /// Что из ответа стало фактом.
  final String evidenceText;

  /// Учитывается ли факт в итоге. По спеке учитываются все три.
  final bool isKey;

  final List<String> tags;

  const QuestEvidenceItem({
    required this.id,
    required this.label,
    required this.response,
    required this.evidenceText,
    this.isKey = true,
    this.tags = const [],
  });

  factory QuestEvidenceItem.fromJson(Map<String, dynamic> json) {
    final tags = json['evidenceTags'];
    return QuestEvidenceItem(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      response: json['response'] as String? ?? '',
      evidenceText: json['evidenceText'] as String? ?? '',
      isKey: json['key'] as bool? ?? true,
      tags: tags is List ? tags.whereType<String>().toList() : const [],
    );
  }
}

/// Расследование: вопросы, факты и правила завершения.
class QuestInvestigation {
  final String instruction;
  final List<QuestEvidenceItem> items;

  /// Порог полного результата (сколько фактов нужно для `complete`).
  final int minimumForFullResult;

  /// Текст подсказки, если игрок лезет с выводами раньше времени.
  final String hintText;

  /// Порог, ниже которого показывается подсказка.
  final int hintBelow;

  const QuestInvestigation({
    required this.instruction,
    required this.items,
    this.minimumForFullResult = 3,
    this.hintText = '',
    this.hintBelow = 2,
  });

  factory QuestInvestigation.fromJson(Map<String, dynamic> json) {
    final evidence = json['evidence'];
    final items = evidence is Map && evidence['items'] is List
        ? (evidence['items'] as List)
            .whereType<Map>()
            .map((e) => QuestEvidenceItem.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <QuestEvidenceItem>[];

    final completion = json['completion'];
    final hint = completion is Map ? completion['hintThreshold'] : null;

    return QuestInvestigation(
      instruction: json['instruction'] as String? ?? '',
      items: items,
      minimumForFullResult:
          (json['minimumEvidenceForFullResult'] as num?)?.toInt() ?? 3,
      hintText: completion is Map
          ? (completion['hintText'] as String? ?? '')
          : '',
      hintBelow: hint is Map ? (hint['value'] as num?)?.toInt() ?? 2 : 2,
    );
  }
}

/// Один вариант подачи.
class QuestServeOption {
  final String id;
  final String text;
  final bool isCorrect;

  /// Что гость делает, когда видит этот вариант.
  final String guestReaction;

  /// Что Джон говорит после.
  final String johnComment;

  const QuestServeOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    required this.guestReaction,
    required this.johnComment,
  });

  factory QuestServeOption.fromJson(Map<String, dynamic> json) {
    return QuestServeOption(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isCorrect: json['correct'] as bool? ?? false,
      guestReaction: json['guestReaction'] as String? ?? '',
      johnComment: json['johnComment'] as String? ?? '',
    );
  }
}

/// Подача: варианты и правила попыток.
///
/// Правила лежат не в `correction`, а в `attempts`:
/// - `maxAttempts` — сколько всего попыток (обычно 2);
/// - `onFirstIncorrect` — что показать после ошибки (реплику Джона,
///   а не реакцию гостя) и разрешить ли повтор;
/// - `setCorrectionUsedWhen` — когда считаем, что исправление началось.
class QuestServe {
  final String instruction;
  final List<QuestServeOption> options;

  /// Всего попыток, включая первую. Минимум 1.
  final int maxAttempts;

  /// Что Джон говорит перед повторной попыткой.
  final String johnPrompt;

  /// Показывать ли реакцию гостя после первой ошибочной подачи.
  /// По спеке — нет: сначала объяснение, потом вторая попытка.
  final bool showReactionAfterFirstMiss;

  const QuestServe({
    required this.instruction,
    required this.options,
    this.maxAttempts = 2,
    this.johnPrompt = '',
    this.showReactionAfterFirstMiss = false,
  });

  /// Сколько повторных попыток разрешено.
  int get maxCorrections => (maxAttempts - 1).clamp(0, 10);

  factory QuestServe.fromJson(Map<String, dynamic> json) {
    final raw = json['options'];
    final attempts = json['attempts'];
    final firstMiss = attempts is Map ? attempts['onFirstIncorrect'] : null;

    return QuestServe(
      instruction: json['instruction'] as String? ?? '',
      options: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => QuestServeOption.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <QuestServeOption>[],
      maxAttempts: attempts is Map
          ? (attempts['maxAttempts'] as num?)?.toInt() ?? 2
          : 2,
      johnPrompt: firstMiss is Map
          ? (firstMiss['prompt'] as String? ?? '')
          : '',
      showReactionAfterFirstMiss: firstMiss is Map
          ? (firstMiss['showGuestReaction'] as bool? ?? false)
          : false,
    );
  }
}

/// Чем кончился квест. Порядок важен: правила проверяются сверху вниз.
enum QuestEnding { complete, partial, recovered, incomplete }

/// Правило выбора финала. Условия — простые сравнения метрик.
class QuestEndingRule {
  final QuestEnding ending;
  final int priority;
  final Map<String, Object> conditions;
  final bool isDefault;
  final String guestText;
  final String johnText;
  final String resultLabel;

  const QuestEndingRule({
    required this.ending,
    required this.priority,
    this.conditions = const {},
    this.isDefault = false,
    this.guestText = '',
    this.johnText = '',
    this.resultLabel = '',
  });
}

/// Награда за конкретный финал.
class QuestReward {
  final QuestEnding ending;
  final int xp;
  final String journalEntry;

  const QuestReward({
    required this.ending,
    required this.xp,
    this.journalEntry = '',
  });
}

/// Квест целиком: что спрашивать, что подавать и чем это кончается.
class QuestFlow {
  final String id;
  final String title;

  /// Задача игрока одной фразой. В данных бывает и строкой, и объектом
  /// с `text` — читаем оба вида.
  final String mission;

  /// Что здесь считается успехом (из того же объекта).
  final String successMeaning;

  final QuestInvestigation investigation;
  final QuestServe serve;
  final List<QuestEndingRule> rules;
  final List<QuestReward> rewards;

  const QuestFlow({
    required this.id,
    required this.title,
    required this.mission,
    required this.investigation,
    required this.serve,
    required this.rules,
    this.successMeaning = '',
    this.rewards = const [],
  });

  /// Есть ли у квеста смысл: вопросы, варианты и правила финала.
  bool get isValid =>
      investigation.items.isNotEmpty && serve.options.isNotEmpty && rules.isNotEmpty;

  QuestReward? rewardFor(QuestEnding ending) {
    for (final r in rewards) {
      if (r.ending == ending) return r;
    }
    return null;
  }

  factory QuestFlow.fromJson(Map<String, dynamic> json) {
    final outcomes = json['outcomes'];
    final rules = <QuestEndingRule>[];
    if (outcomes is Map) {
      final selection = outcomes['endingSelection'];
      final raw = selection is Map ? selection['rules'] : null;
      if (raw is List) {
        for (final r in raw.whereType<Map>()) {
          final m = r.cast<String, dynamic>();
          final id = m['id'] as String? ?? '';
          final conditions = <String, Object>{};
          final all = m['all'];
          if (all is List) {
            for (final c in all.whereType<Map>()) {
              final cond = c.cast<String, dynamic>();
              final metric = cond['metric'] as String?;
              final value = cond['value'];
              if (metric != null && value is Object) {
                // Храним как key:metric → operator, value — в одной паре,
                // чтобы правило оставалось данными, а не кодом.
                conditions['$metric.${cond['operator']}'] = value;
              }
            }
          }
          rules.add(QuestEndingRule(
            ending: _endingFromId(id),
            priority: (m['priority'] as num?)?.toInt() ?? 99,
            conditions: conditions,
            isDefault: m['default'] == true,
            guestText: m['guestText'] as String? ?? '',
            johnText: m['johnText'] as String? ?? '',
            resultLabel: m['resultLabel'] as String? ?? '',
          ));
        }
        rules.sort((a, b) => a.priority.compareTo(b.priority));
      }
    }

    final progression = json['progression'];
    final rewards = <QuestReward>[];
    if (progression is Map && progression['rewards'] is Map) {
      (progression['rewards'] as Map).forEach((key, value) {
        if (value is Map) {
          rewards.add(QuestReward(
            ending: _endingFromId(key as String? ?? ''),
            xp: (value['xp'] as num?)?.toInt() ?? 0,
            journalEntry: value['journalEntry'] as String? ?? '',
          ));
        }
      });
    }

    final mission = json['mission'];

    return QuestFlow(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      mission: mission is Map
          ? (mission['text'] as String? ?? '')
          : mission as String? ?? '',
      successMeaning: mission is Map
          ? (mission['successMeaning'] as String? ?? '')
          : '',
      investigation: QuestInvestigation.fromJson(
        json['investigation'] is Map
            ? (json['investigation'] as Map).cast<String, dynamic>()
            : const {},
      ),
      serve: QuestServe.fromJson(
        json['serve'] is Map
            ? (json['serve'] as Map).cast<String, dynamic>()
            : const {},
      ),
      rules: rules,
      rewards: rewards,
    );
  }

  static QuestEnding _endingFromId(String id) {
    for (final e in QuestEnding.values) {
      if (e.name == id) return e;
    }
    return QuestEnding.incomplete;
  }
}

/// Прохождение квеста: что спрошено, что подано и чем кончилось.
///
/// Правила по спеке:
/// - каждый вопрос открывает факт один раз, повтор не считается;
/// - первая подача запоминается навсегда ([firstServeCorrect]);
/// - исправление доступно один раз и только после ошибки;
/// - финал выбирается первым подходящим правилом сверху вниз.
class QuestFlowState {
  final QuestFlow flow;

  final Set<String> _askedIds = <String>{};
  final List<String> _attempts = <String>[];

  /// Правильность **первой** подачи. `null` — ещё не подавали.
  bool? firstServeCorrect;

  QuestFlowState(this.flow);

  /// Сколько уникальных фактов собрано.
  int get evidenceCount => _askedIds.length;

  /// Заданные вопросы в порядке данных, а не нажатий: лента читается ровно.
  List<QuestEvidenceItem> get askedItems => flow.investigation.items
      .where((i) => _askedIds.contains(i.id))
      .toList();

  /// Вопрос, который ещё не задан. `null` — спрошено всё.
  QuestEvidenceItem? get nextItem {
    for (final i in flow.investigation.items) {
      if (!_askedIds.contains(i.id)) return i;
    }
    return null;
  }

  bool get isInvestigationComplete => nextItem == null;

  /// Можно ли сейчас выбрать подачу. По спеке — всегда, даже без вопросов:
  /// цена раннего решения в том, что финал окажется `incomplete`.
  bool get canServe => flow.serve.options.isNotEmpty;

  /// Задать вопрос. `false`, если он уже был задан или его нет.
  bool ask(String itemId) {
    if (_askedIds.contains(itemId)) return false;
    if (!flow.investigation.items.any((i) => i.id == itemId)) return false;
    _askedIds.add(itemId);
    return true;
  }

  /// Попытки подачи по порядку.
  List<String> get attempts => List.unmodifiable(_attempts);

  /// Было ли исправление — то есть вторая попытка действительно началась.
  bool get correctionUsed => _attempts.length > 1;

  /// Сколько попыток осталось, включая ещё не сделанную.
  int get attemptsLeft {
    final allowed = flow.serve.maxAttempts;
    return (allowed - _attempts.length).clamp(0, allowed);
  }

  /// Можно ли исправить текущую (неверную) подачу.
  bool get canCorrect =>
      _attempts.isNotEmpty &&
      firstServeCorrect == false &&
      _attempts.length < flow.serve.maxAttempts;

  /// Последняя выбранная подача. `null` — ещё не выбирали.
  QuestServeOption? get lastOption {
    if (_attempts.isEmpty) return null;
    final id = _attempts.last;
    for (final o in flow.serve.options) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Правильность последней подачи. `null` — не выбирали.
  bool? get finalServeCorrect => lastOption?.isCorrect;

  /// Выбрать подачу. Возвращает вариант или `null`, если такой нет.
  QuestServeOption? serve(String optionId) {
    QuestServeOption? option;
    for (final o in flow.serve.options) {
      if (o.id == optionId) option = o;
    }
    if (option == null) return null;
    if (_attempts.length >= flow.serve.maxAttempts) return null;
    // Правильную подачу второй раз не берём: сцена закрыта.
    if (_attempts.isNotEmpty && firstServeCorrect == true) return null;
    if (_attempts.isNotEmpty && !canCorrect) return null;

    firstServeCorrect ??= option.isCorrect;
    _attempts.add(option.id);
    return option;
  }

  /// Текущий финал по правилам сверху вниз.
  ///
  /// `null` — квест ещё не кончён (нет ни одной попытки).
  QuestEnding? get ending {
    if (_attempts.isEmpty) return null;
    final metrics = <String, Object>{
      'evidenceCount': evidenceCount,
      'firstServeCorrect': firstServeCorrect ?? false,
      'finalServeCorrect': finalServeCorrect ?? false,
      'correctionUsed': correctionUsed,
    };
    for (final rule in flow.rules) {
      if (rule.isDefault) return rule.ending;
      if (_matches(rule, metrics)) return rule.ending;
    }
    return QuestEnding.incomplete;
  }

  /// Правило, которое сработало — для текстов гостя и Джона.
  QuestEndingRule? get endingRule {
    final e = ending;
    if (e == null) return null;
    for (final rule in flow.rules) {
      if (rule.ending == e) return rule;
    }
    return null;
  }

  bool _matches(QuestEndingRule rule, Map<String, Object> metrics) {
    for (final entry in rule.conditions.entries) {
      final dot = entry.key.lastIndexOf('.');
      if (dot < 0) return false;
      final metric = entry.key.substring(0, dot);
      final op = entry.key.substring(dot + 1);
      final actual = metrics[metric];
      if (actual == null) return false;
      final expected = entry.value;

      final bool ok;
      switch (op) {
        case 'equals':
          ok = actual == expected;
          break;
        case 'greater_than_or_equal':
          ok = actual is num && expected is num && actual >= expected;
          break;
        case 'greater_than':
          ok = actual is num && expected is num && actual > expected;
          break;
        case 'less_than':
          ok = actual is num && expected is num && actual < expected;
          break;
        case 'less_than_or_equal':
          ok = actual is num && expected is num && actual <= expected;
          break;
        default:
          ok = false;
      }
      if (!ok) return false;
    }
    return true;
  }
}
