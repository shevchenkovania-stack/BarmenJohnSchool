import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coin/features/bartender_school/data/quest_flow.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';

/// Проверка правил финала на настоящем контенте A_01.
///
/// Это не матрица случаев, а четыре сценария, которые спека называет
/// явно: всё сделал правильно, собрал часть, исправился, провалился.
void main() {
  late QuestFlow flow;

  setUpAll(() {
    final raw = jsonDecode(
      File('data/content/lessons_level1_part1.json').readAsStringSync(),
    ) as List;
    final lesson = Lesson.fromJson(
      raw.cast<Map<String, dynamic>>().firstWhere((l) => l['id'] == 'lesson_A_01'),
    );
    flow = lesson.quest!;
  });

  QuestFlowState play({required int evidence, required List<String> serves}) {
    final s = QuestFlowState(flow);
    for (var i = 0; i < evidence; i++) {
      s.ask(flow.investigation.items[i].id);
    }
    for (final id in serves) {
      s.serve(id);
    }
    return s;
  }

  test('контент читается: три вопроса, три подачи, четыре правила', () {
    expect(flow.investigation.items.length, 3);
    expect(flow.serve.options.length, 3);
    expect(flow.rules.length, 4);
    expect(flow.isValid, isTrue);
    expect(flow.serve.maxAttempts, 2);
  });

  test('всё выяснил и попал сразу — complete, 30 XP', () {
    final s = play(evidence: 3, serves: ['light_slow_sipping']);
    expect(s.ending, QuestEnding.complete);
    expect(flow.rewardFor(s.ending!)!.xp, 30);
  });

  test('спросил дважды и попал — partial', () {
    final s = play(evidence: 2, serves: ['light_slow_sipping']);
    expect(s.ending, QuestEnding.partial);
  });

  test('ошибся, исправился — recovered, но не complete', () {
    final s = play(evidence: 3, serves: ['short_strong', 'light_slow_sipping']);
    expect(s.correctionUsed, isTrue);
    expect(s.ending, QuestEnding.recovered);
    expect(flow.rewardFor(s.ending!)!.xp, 20);
  });

  test('угадал без расследования — incomplete', () {
    final s = play(evidence: 1, serves: ['light_slow_sipping']);
    expect(s.ending, QuestEnding.incomplete);
  });

  test('ничего не спросил и промахнулся — incomplete', () {
    final s = play(evidence: 0, serves: ['short_strong']);
    expect(s.ending, QuestEnding.incomplete);
    expect(s.askedItems, isEmpty);
  });

  test('повторный вопрос не добавляет факт', () {
    final s = QuestFlowState(flow);
    expect(s.ask('yesterday_drink'), isTrue);
    expect(s.ask('yesterday_drink'), isFalse);
    expect(s.evidenceCount, 1);
  });

  test('третьей попытки нет', () {
    final s = play(
      evidence: 3,
      serves: ['short_strong', 'sweet_alcohol_free', 'light_slow_sipping'],
    );
    expect(s.attempts.length, 2);
    expect(s.ending, QuestEnding.incomplete);
  });
}
