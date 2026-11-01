// TEMP QA: статическая целостность контента школы (Level 1 в приоритете).
// Читает data/content/*.json напрямую + список практик из кода.
// Пишет отчёт в test/qa/INTEGRITY.txt.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/term_service.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';

// Берем множество прямо из enum, чтобы тест не отста от кода: если тип
// добавлен в SlideType, он автоматически считается поддержанным.
final _slideTypes = SlideType.values.map((e) => e.name).toSet();
const _questionTypes = {
  'singleChoice', 'multipleChoice', 'trueFalse', 'imageMatch', 'dragOrder',
  'matching', 'slider', 'sequence',
};

final List<String> report = [];
void say(String s) {
  report.add(s);
  // ignore: avoid_print
  print('QA> $s');
}

List<Map<String, dynamic>> _loadList(String path) {
  final data = json.decode(File(path).readAsStringSync());
  return (data as List).cast<Map<String, dynamic>>();
}

void main() {
  final lessonFiles = {
    'L1-A/B': 'data/content/lessons_level1_part1.json',
    'L1-C': 'data/content/lessons_level1_part2.json',
    'L2': 'data/content/lessons_level2.json',
    'L3-legacy': 'data/content/lessons_level3.json',
    'L3-part1': 'data/content/lessons_level3_part1.json',
    'wisdom': 'data/content/lessons_wisdom.json',
  };
  final quizFiles = {
    'L1-A/B': 'data/content/quizzes_level1_part1.json',
    'L1-C': 'data/content/quizzes_level1_part2.json',
    'L2': 'data/content/quizzes_level2.json',
    'L3': 'data/content/quizzes_level3.json',
    'L3-part1': 'data/content/quizzes_level3_part1.json',
  };

  // Файлы, которые реально загружает приложение (main.dart:
  // LessonRepository()..loadCoreCurriculum()..loadWisdom()). loadLevel3()
  // нигде не вызывается, поэтому lessons_level3.json / _part1.json — это
  // МЁРТВЫЙ legacy-контент: он не попадает в _lessons и не может ни с кем
  // конфликтовать в рантайме. Сверку ID, нумерации блоков и цепочек
  // unlockCondition (то, что ломает живой Level 1/2) ведём только по активным
  // файлам, иначе legacy даёт ложные [DUP-ID]/[GAP]/[DEAD-LOCK].
  const activeLessonFiles = {
    'L1-A/B',
    'L1-C',
    'L2',
    'wisdom',
  };

  final lessons = <String, Map<String, dynamic>>{};
  final lessonOrigin = <String, String>{};
  final quizzes = <String, Map<String, dynamic>>{};

  test('контент читается и перепроверяется', () {
    for (final e in lessonFiles.entries) {
      final f = File(e.value);
      if (!f.existsSync()) {
        say('[SKIP] нет файла ${e.value}');
        continue;
      }
      if (!activeLessonFiles.contains(e.key)) {
        final count = _loadList(e.value).length;
        say('[LEGACY-SKIPPED] ${e.key} (${e.value}): $count уроков не загружаются '
            'в рантайме (loadLevel3 не вызывается) — вне сверки живого прогресса');
        continue;
      }
      for (final l in _loadList(e.value)) {
        final id = l['id'] as String;
        if (lessons.containsKey(id)) {
          say('[DUP-ID] урок $id встречается и в "${lessonOrigin[id]}", и в "${e.key}" — '
              'один перезатрёт другой в прогрессе и в репозитории');
        } else {
          lessons[id] = l;
          lessonOrigin[id] = e.key;
        }
      }
    }
    for (final e in quizFiles.entries) {
      final f = File(e.value);
      if (!f.existsSync()) continue;
      try {
        for (final q in _loadList(e.value)) {
          final id = q['lessonId'] as String;
          if (quizzes.containsKey(id)) {
            say('[DUP-QUIZ] квиз на $id объявлен дважды (${e.key})');
          }
          quizzes[id] = q;
        }
      } catch (err) {
        say('[BROKEN-JSON] ${e.value}: $err — весь файл квизов не загрузится в приложении');
      }
    }

    // ── 1. Структура уроков ────────────────────────────────────────────────
    final byBlock = <String, List<Map<String, dynamic>>>{};
    for (final l in lessons.values) {
      byBlock.putIfAbsent(l['blockId'] as String, () => []).add(l);
    }
    say('── полка уроков по блокам ──');
    for (final b in byBlock.keys.toList()..sort()) {
      final list = byBlock[b]!..sort((x, y) => (x['lessonNumber'] as int).compareTo(y['lessonNumber'] as int));
      final nums = list.map((l) => l['lessonNumber']).join(',');
      say('блок $b: ${list.length} уроков, номера [$nums] (${list.map((l) => l['id']).join(' ')})');
      for (var i = 1; i < list.length; i++) {
        if ((list[i]['lessonNumber'] as int) - (list[i - 1]['lessonNumber'] as int) != 1) {
          say('[GAP] блок $b: разрыв в нумерации уроков ${list[i - 1]['lessonNumber']} → ${list[i]['lessonNumber']}');
        }
      }
    }

    // ── 2. Цепочка разблокировки ──────────────────────────────────────────
    for (final l in lessons.values) {
      final cond = l['unlockCondition'];
      if (cond == null) continue;
      if (!lessons.containsKey(cond)) {
        say('[DEAD-LOCK] урок ${l['id']} требует несуществующий "$cond" — навсегда заперт');
      }
    }

    // ── 3. Слайды: типы и картинки ────────────────────────────────────────
    final typeCensus = <String, int>{};
    for (final l in lessons.values) {
      final slides = (l['slides'] as List).cast<Map<String, dynamic>>();
      for (final s in slides) {
        final t = s['type'] as String;
        typeCensus[t] = (typeCensus[t] ?? 0) + 1;
        if (!_slideTypes.contains(t)) {
          say('[UNKNOWN-SLIDE] ${l['id']}: тип "$t" не в enum → молча отрисуется как theory');
        }
        final img = s['imageUrl'];
        if (img is String && img.isNotEmpty && !File(img).existsSync()) {
          say('[MISSING-ART] ${l['id']}: картинка слайда "$img" не найдена на диске');
        }
      }
      if (slides.isEmpty) say('[EMPTY] ${l['id']}: ноль слайдов');
      final kp = (l['keyPoints'] as List?) ?? [];
      if (kp.length != 3) say('[KEYPOINTS] ${l['id']}: ${kp.length} тезисов на лицевой стороне карточки (дизайн-стандарт — 3)');
      if ((l['terms'] as List?)?.isEmpty ?? true) {
        say('[NO-TERMS] ${l['id']}: нет терминов → бейдж «0/N» на карточке пустой, словарь не пополняется');
      }
    }
    say('типы слайдов: ${typeCensus.entries.map((e) => "${e.key}=${e.value}").join(', ')}');
    for (final t in typeCensus.keys) {
      if (!_slideTypes.contains(t)) continue;
      if (t == 'balanceTrainer' || t == 'interactive') {
        say('[INTERACTIVE] тип "$t" (${typeCensus[t]} шт) — требует сбора и оценки ответа');
      }
    }

    // ── 4. Урок ↔ квиз ────────────────────────────────────────────────────
    say('── связка урок ↔ квиз ──');
    for (final l in lessons.values.where((l) => ['A', 'B', 'C'].contains(l['blockId']))) {
      final q = quizzes[l['id']];
      if (q == null) {
        say('[NO-QUIZ] ${l['id']}: квиза нет → после «К тесту» экран «Вопросы пока недоступны», урок незавершаем');
        continue;
      }
      final pool = (q['questions'] as List).cast<Map<String, dynamic>>();
      final per = q['questionsPerAttempt'] ?? 5;
      if (pool.length < per) {
        say('[POOL-SMALL] ${l['id']}: в пуле ${pool.length} вопросов, на попытку нужно $per');
      }
      final ids = <String>{};
      for (final question in pool) {
        final id = question['id'] as String;
        if (!ids.add(id)) say('[DUP-Q] ${l['id']}: повтор вопроса "$id"');
        final type = question['type'] as String;
        if (!_questionTypes.contains(type)) {
          say('[UNKNOWN-QTYPE] $id: тип "$type" не в enum → молча станет singleChoice без options');
        }
        final options = question['options'];
        final ci = question['correctAnswerIndex'];
        final cis = question['correctAnswerIndices'];
        if (type == 'singleChoice' || type == 'trueFalse') {
          if (options is! List || options.isEmpty) {
            say('[Q-BROKEN] $id: $type без options');
          } else if (ci is! int || ci < 0 || ci >= options.length) {
            say('[Q-BROKEN] $id: correctAnswerIndex=$ci вне диапазона options (0..${options.length - 1})');
          }
        }
        if (type == 'multipleChoice') {
          if (options is! List || cis is! List || cis.isEmpty) {
            say('[Q-BROKEN] $id: multipleChoice без options/correctAnswerIndices');
          } else {
            for (final i in cis) {
              if (i is! int || i < 0 || i >= options.length) {
                say('[Q-BROKEN] $id: индекс $i вне диапазона options');
              }
            }
            if (cis.length == options.length) {
              say('[Q-SUSPECT] $id: multipleChoice, где правильными помечены ВСЕ ${options.length} вариантов');
            }
          }
        }
        if (type == 'sequence' || type == 'slider' || type == 'matching') {
          final payload = question[type == 'sequence' ? 'sequence' : type == 'slider' ? 'sliders' : 'pairs'];
          if (payload == null) {
            say('[Q-BROKEN] $id: тип "$type" без полезной нагрузки');
          } else {
            say('[Q-INTERACTIVE] $id (${l['id']}): тип "$type" — в AGENTS.md запрещено, пока UI не оценивает');
          }
        }
        final ex = question['explanation'];
        if (ex is! String || ex.trim().isEmpty) {
          say('[Q-NO-EXPL] $id: пустое объяснение после ответа');
        }
        final img = question['imageUrl'];
        if (img is String && img.isNotEmpty && !File(img).existsSync()) {
          say('[MISSING-ART] $id: картинка вопроса "$img" не найдена');
        }
      }
    }
    for (final qid in quizzes.keys) {
      if (!lessons.containsKey(qid)) {
        say('[ORPHAN-QUIZ] квиз на "$qid", урока с таким id нет');
      }
    }

    // ── 5. Практика ───────────────────────────────────────────────────────
    say('── практика ↔ уроки ──');
    final methods = methodDescriptions.keys.toSet();
    for (final c in allPracticeChallenges) {
      if (!lessons.containsKey(c.lessonId)) {
        say('[PRACTICE-ORPHAN] ${c.id}: ссылка на несуществующий урок "${c.lessonId}"');
      }
      final correct = c.correctIngredients.toSet();
      final wrong = c.wrongOptions.toSet();
      final overlap = correct.intersection(wrong);
      if (overlap.isNotEmpty) {
        say('[PRACTICE-BUG] ${c.id}: ингредиент есть одновременно в правильных и в ложных: $overlap');
      }
      if (correct.length < 2) say('[PRACTICE-THIN] ${c.id}: всего ${correct.length} правильных ингредиента');
      for (final k in c.proportions.keys) {
        if (!correct.contains(k)) {
          say('[PRACTICE-BUG] ${c.id}: пропорция задана для «$k», которого нет в правильном списке');
        }
      }
      for (final k in correct) {
        if (!c.proportions.containsKey(k)) {
          say('[PRACTICE-GAP] ${c.id}: для «$k» нет цели пропорции → шаг «Настрой пропорции» для него нечем оценить');
        }
      }
      // Шаг джиггера: Slider(min 0, max 120, divisions 120) → шаг 1мл.
      for (final p in c.proportions.entries) {
        final lo = p.value.targetMl - p.value.toleranceMl;
        final hi = p.value.targetMl + p.value.toleranceMl;
        final reachable = [for (var ml = 0; ml <= 120; ml += 1) ml]
            .where((ml) => ml >= lo && ml <= hi)
            .toList();
        if (reachable.isEmpty) {
          say('[3★-UNREACHABLE] ${c.id}: «${p.key}» цель ${p.value.targetMl}мл ±'
              '${p.value.toleranceMl} → зона ${lo}..${hi}мл пуста на шкале '
              '0..120мл с шагом 1мл — 3★ не выдаётся никогда');
        } else if (lo < 0 || hi > 120) {
          say('[PROP-EDGE] ${c.id}: «${p.key}» зона ${lo}..${hi}мл вылезает за '
              'шкалу 0..120мл');
        }
      }
      if (!methods.contains(c.correctMethod)) {
        say('[PRACTICE-BUG] ${c.id}: метод "${c.correctMethod}" отсутствует в methodDescriptions');
      }
      // Спойлер = все правильные идут раньше любого ложного: тогда ответ
      // угадывается только по позиции и по числу плиток в начале. Более
      // слабое («первая плитка правильная») спойлером не считается.
      final opts = c.allOptions;
      final lastCorrectIdx = [
        for (var i = 0; i < opts.length; i++)
          if (correct.contains(opts[i])) i
      ].fold<int>(-1, (a, b) => b);
      final firstWrongIdx = opts.indexWhere((o) => wrong.contains(o));
      if (firstWrongIdx > 0 && lastCorrectIdx < firstWrongIdx) {
        say('[PRACTICE-SPOILER] ${c.id}: все правильные (${lastCorrectIdx + 1} шт.) идут в начале, первый ложный только на $firstWrongIdx — ответ угадывается по позиции');
      }
    }
    final l1Lessons = lessons.values.where((l) => ['A', 'B', 'C'].contains(l['blockId'])).map((l) => l['id'] as String).toSet();
    final covered = allPracticeChallenges.where((c) => l1Lessons.contains(c.lessonId)).map((c) => c.lessonId).toSet();
    final uncovered = l1Lessons.where((id) => !covered.contains(id)).toList();
    say('уроки Level 1 без практики: ${uncovered.join(', ')} (всего уроков ${l1Lessons.length}, покрыто ${covered.length})');
    final byLesson = <String, List<String>>{};
    for (final c in allPracticeChallenges) {
      byLesson.putIfAbsent(c.lessonId, () => []).add(c.cocktailName);
    }
    for (final e in byLesson.entries.where((e) => l1Lessons.contains(e.key))) {
      say('практика на ${e.key}: ${e.value.join(' | ')}');
    }
    // Дубли коктейлей между уровнями
    final byCocktail = <String, Set<String>>{};
    for (final c in allPracticeChallenges) {
      final block = c.blockId;
      byCocktail.putIfAbsent(c.cocktailName, () => {}).add(block);
    }
    final dupes = byCocktail.entries.where((e) => e.value.length > 1)
        .where((e) => e.value.any((b) => ['A', 'B', 'C'].contains(b)) && e.value.any((b) => ['D', 'E', 'F'].contains(b)))
        .toList();
    if (dupes.isNotEmpty) {
      final parts = dupes.map((e) {
        final blocks = e.value.toList()..sort();
        return '${e.key}($blocks)';
      }).join(', ');
      say('[LEVEL-DUPE] один и тот же коктейль практикуется и в Level 1, и в Level 2: '
          '$parts — прогресс звёзд общий, Level 2 теряет новизну');
    }
    say('практика: шаг джиггера 1мл (Slider 0..120, divisions 120), зелёная зона '
        'отсчитывается от фактического трека (отступ = радиус оверлея 16px)');
    for (final id in level1DiplomaChallengeIds) {
      if (!allPracticeChallenges.any((c) => c.id == id)) {
        say('[DIPLOMA-BUG] обязательный для диплома Level 1 "${id}" не найден среди заданий — диплом невозможно получить');
      }
    }
    for (final id in level2DiplomaChallengeIds) {
      if (!allPracticeChallenges.any((c) => c.id == id)) {
        say('[DIPLOMA-BUG] обязательный для диплома Level 2 "${id}" не найден среди заданий');
      }
    }

    // ── 7. Термины ↔ гейт основного квиза ─────────────────────────────────
    say('── терминологический гейт (lesson → TermQuiz → Quiz) ──');
    final termService = TermService();
    for (final l in lessons.values.where((l) => ['A', 'B', 'C'].contains(l['blockId']))) {
      final id = l['id'] as String;
      final terms = ((l['terms'] as List?) ?? []).cast<String>();
      if (terms.isEmpty) continue;
      final unresolved = <String>[];
      final mismatched = <String>[];
      for (final t in terms) {
        final td = termService.getTerm(t);
        if (td == null) {
          unresolved.add(t);
        } else if (td.russianName != t) {
          mismatched.add('"$t" → в словаре как "${td.russianName}"');
        }
      }
      if (unresolved.isNotEmpty) {
        say('[TERM-DEADLOCK] $id: термины не найдены в словаре: ${unresolved.join(', ')} — '
            'TermQuiz не может их отметить выученными, areLessonTermsLearned()==false навсегда, '
            'основной квиз урока недоступен');
      }
      if (mismatched.isNotEmpty) {
        say('[TERM-DEADLOCK] $id: имя в уроке отличается от имени в словаре: ${mismatched.join('; ')} — '
            'метка ставится по другому ключу, основной квиз не откроется');
      }
      // Гейт терминов детерминирован: за прогон спрашивается каждый
      // невыученный термин (не больше 6), поэтому число проходов —
      // арифметика, а не лотерея (раньше: 2.8–4.2 прохода на A_01/B_07).
      final gateSize = terms.length.clamp(3, 6);
      final passes = (terms.length / gateSize).ceil();
      if (passes > 2) {
        say('[TERM-PASSES] $id: терминов ${terms.length} → $passes прогонов гейта (по $gateSize за проход)');
      }
    }

    // ── 7b. Картинки карточек уроков ───────────────────────────────────
    final cardSrc = File('lib/features/bartender_school/presentation/widgets/lesson_card.dart').readAsStringSync();
    final mapped = RegExp(r"case '(lesson_[^']+)':\s*return '([^']+)'").allMatches(cardSrc);
    final mapping = {for (final m in mapped) m.group(1)!: m.group(2)!};
    final usedPaths = <String, List<String>>{};
    for (final e in mapping.entries) {
      if (!File(e.value).existsSync()) {
        say('[MISSING-CARD-ART] ${e.key}: файл ${e.value} отсутствует');
      }
      usedPaths.putIfAbsent(e.value, () => []).add(e.key);
    }
    for (final e in usedPaths.entries.where((e) => e.value.length > 1)) {
      say('[DUP-CARD-ART] ${e.value.join(' и ')} используют одну картинку ${e.value.first} → ${e.key}');
    }
    final noCardArt = lessons.values
        .where((l) => ['A', 'B', 'C'].contains(l['blockId']))
        .map((l) => l['id'] as String)
        .where((id) => !mapping.containsKey(id))
        .toList();
    if (noCardArt.isNotEmpty) {
      say('[CARD-ART-FALLBACK] уроки Level 1 без собственного изображения в _lessonArtworkPath: ${noCardArt.join(', ')} '
          '(экранные карточки упадут в дефолт)');
    }
    say('маппинг картинок карточек: ${mapping.length} уроков');

    // ── 7. Сводка по текстам ──────────────────────────────────────────────
    final latinTitleLessons = lessons.values
        .where((l) => ['A', 'B', 'C'].contains(l['blockId']))
        .map((l) => l['title'] as String)
        .where((t) => !RegExp(r'[а-яА-ЯёЁ]').hasMatch(t))
        .toList();
    if (latinTitleLessons.isNotEmpty) {
      say('[I18N] заголовки уроков без кириллицы: ${latinTitleLessons.join(' | ')}');
    }
    final emojiFields = lessons.values.where((l) => ['A', 'B', 'C'].contains(l['blockId']))
        .where((l) => (l['emoji'] as String?)?.isNotEmpty ?? false).length;
    say('[DESIGN] эмодзи как иконка уроков: $emojiFields из ${l1Lessons.length} (плюс methodDescriptions и quiz-фидбэк)');

    File('test/qa/INTEGRITY.txt').writeAsStringSync(report.join('\n'));
  });
}
