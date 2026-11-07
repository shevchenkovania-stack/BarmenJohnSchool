/// Реплики Джона вне уроков.
///
/// Здесь нет озвучки и нет AI: только правило «событие + состояние →
/// фраза». Джон остаётся персонажем, а не подписью под кнопкой, но каждая
/// фраза детерминирована и проверяема тестом.
///
/// Правило тона: Джон наблюдает, а не оценивает. Он не хвалит за нажатие
/// и не стыдит за провал.
library;

/// Событие, на которое реагирует Джон.
enum JohnMoment {
  /// Открыл приложение после долгой паузы.
  returningAfterBreak,

  /// Открыл приложение в тот же день повторно.
  returningToday,

  /// Серия дней подряд.
  streak,

  /// Квиз сдан.
  quizPassed,

  /// Квиз провален впервые.
  quizFailedFirstTime,

  /// Квиз провален повторно.
  quizFailedAgain,

  /// Коктейль собран в мастерской.
  cocktailBuilt,

  /// Ни одного урока ещё не начато.
  freshStart,
}

/// Контекст для выбора фразы.
class JohnContext {
  /// Серия дней подряд (streak в прогрессе).
  final int streak;

  /// Сколько дней прошло с последнего захода; null — первый заход.
  final int? daysSinceLastVisit;

  /// Сколько раз ученик уже проваливал этот квиз (0 — впервые).
  final int failedAttemptsBefore;

  /// Сколько звёзд получил коктейль (для [JohnMoment.cocktailBuilt]).
  final int stars;

  const JohnContext({
    this.streak = 0,
    this.daysSinceLastVisit,
    this.failedAttemptsBefore = 0,
    this.stars = 0,
  });
}

/// Выбирает фразу Джона для момента [moment].
///
/// [variant] позволяет показать разные фразы на разные случаи одного и того
/// же события (например, по номеру дня недели). Он не обязателен: выбор
/// детерминирован, чтобы тест и повторная сборка давали одинаковый текст.
String johnReaction(
  JohnMoment moment,
  JohnContext context, {
  int variant = 0,
}) {
  final lines = _linesFor(moment, context);
  if (lines.isEmpty) return '';
  return lines[variant.abs() % lines.length];
}

List<String> _linesFor(JohnMoment moment, JohnContext context) {
  switch (moment) {
    case JohnMoment.freshStart:
      return const [
        'Заходи. Бар открыт, но обучение начинается не с бутылок, а с вкуса.',
        'Первый день — самый честный. Ничего не умеешь и не притворяешься.',
      ];

    case JohnMoment.returningAfterBreak:
      final days = context.daysSinceLastVisit ?? 0;
      if (days >= 7) {
        return const [
          'Неделя прошла. Я не считаю, я просто протираю стойку — она всё ждала.',
          'Давно не виделись. Начнём с простого: один урок, без подвигов.',
        ];
      }
      if (days >= 3) {
        return const [
          'Три дня тишины. Бар без тебя не скучал — но бокалы стояли не так.',
          'Ты вернулся. Хорошая привычка важнее вдохновения.',
        ];
      }
      return const [
        'Вчера не доучил, сегодня продолжим. Здесь никто не теряет лицо.',
        'Пауза — часть работы. Продолжаем.',
      ];

    case JohnMoment.returningToday:
      return const [
        'Опять ты. Хорошо: повторение важнее первого раза.',
        'Ты сегодня уже был. Я запомнил, где ты остановился.',
      ];

    case JohnMoment.streak:
      if (context.streak >= 7) {
        return const [
          'Неделя подряд. Скажу честно: так учатся не все.',
        ];
      }
      if (context.streak >= 3) {
        return const [
          'Третий день подряд. Это уже не настроение, а навык.',
        ];
      }
      return const [
        'Два дня подряд — привычка начинается здесь.',
        'Сегодня снова здесь. Хорошо.',
      ];

    case JohnMoment.quizPassed:
      return const [
        'Засчитано. Не потому что правильно, а потому что понял.',
        'Хорошо. Теперь скажи это словами, а не вариантами ответа.',
      ];

    case JohnMoment.quizFailedFirstTime:
      return const [
        'Не сдал — это не приговор. Пойдём ещё раз, только медленнее.',
        'Ошибки в квизе — самые дешёвые. На смене они дороже.',
        'Стоп. Не жми наугад. Подумай, какой вкус ведёт в этом коктейле.',
      ];

    case JohnMoment.quizFailedAgain:
      if (context.failedAttemptsBefore >= 2) {
        return const [
          'Третий раз. Значит, дело не в памяти. Давай перечитаем урок — '
              'по одному разделу за раз.',
          'Мы ходим по кругу. Пропусти квиз, вернись в урок и посмотри '
              'только один слайд. Один.',
        ];
      }
      return const [
        'Опять. Бывает. Меняем подход: сначала теория, потом квиз.',
        'Не повторяй те же ответы. Я вижу, что ты угадываешь.',
      ];

    case JohnMoment.cocktailBuilt:
      if (context.stars >= 3) {
        return const [
          'Чисто. Так и держи — руки запомнят быстрее головы.',
          'Три звезды. Теперь сделай это на скорости, а не на удаче.',
        ];
      }
      if (context.stars == 2) {
        return const [
          'Почти. Одна деталь подвела — найди её сам.',
          'Годно. Но ты сам знаешь, где был неаккуратен.',
        ];
      }
      return const [
        'Не вышло. Значит, повторим — и на этот раз по шагам.',
        'Старт понятен. Собери ещё раз, не спеши.',
      ];
  }
}

/// Момент внутри мастерской, когда Джон вставляет слово.
enum JohnPracticeMoment {
  /// Выбор ингредиентов.
  ingredients,

  /// Выбор метода приготовления.
  method,
}

/// Подсказка Джона по ходу практики.
///
/// Никогда не называет правильный ответ: задача — направить мысль, а не
/// сделать задание за ученика. Поэтому здесь только вопросы и принципы.
String johnPracticeHint(
  JohnPracticeMoment moment, {
  int selectedCount = 0,
  int expectedCount = 0,
}) {
  switch (moment) {
    case JohnPracticeMoment.ingredients:
      final diff = selectedCount - expectedCount;
      if (selectedCount == 0) {
        return 'Ты уже сделал этот коктейль в уроке. Вспомни: что там было '
            'главным — крепость, кислота или пузырьки?';
      }
      if (diff > 0) {
        return 'У тебя на $diff больше, чем нужно. Спроси себя: это правда '
            'вкус, или ты просто боишься, что будет пусто?';
      }
      if (diff == 0) {
        return 'Состав собран. Дальше вопрос не «что», а «как»: одни и те же '
            'ингредиенты в шейкере и в бокале ведут себя по-разному.';
      }
      return 'Мало. Мысленно произнеси название и вспомни, чего не хватает: '
          'кислоты, сладости или газа.';
    case JohnPracticeMoment.method:
      return 'Одно правило на всю жизнь: если в составе есть сок или сироп — '
          'shake. Если только крепкое — stir. Дальше решает лёд.';
  }
}

/// Сколько дней прошло с последнего захода.
///
/// Отдельная функция, чтобы правило было одинаковым на главной и в тестах.
int? daysSince(DateTime? lastVisit, DateTime now) {
  if (lastVisit == null) return null;
  final last = DateTime(lastVisit.year, lastVisit.month, lastVisit.day);
  final today = DateTime(now.year, now.month, now.day);
  return today.difference(last).inDays;
}
