# -*- coding: utf-8 -*-
"""Разовый скрипт: вставляет passingScore в квизы Level 1 точечной заменой.

Данные не переформатируются: правится только отсутствующая строка
`"passingScore"`, чтобы diff оставался читаемым.

Правило порога — 75% от числа вопросов в попытке, округление вверх:
7 -> 5, 5 -> 4.
"""
import re

RULES = {
    'lesson_A_01': (7, 5),
    'lesson_A_02': (5, 4),
    'lesson_A_03': (5, 4),
    'lesson_A_04': (5, 4),
    'lesson_B_09': (5, 4),
}

PATH = 'data/content/quizzes_level1_part1.json'

with open(PATH, encoding='utf-8') as fh:
    text = fh.read()

total = 0
for lesson_id, (attempt, passing) in RULES.items():
    # Находим объект квиза по lessonId и добавляем passingScore после
    # questionsPerAttempt, если его там ещё нет.
    pattern = re.compile(
        r'("lessonId":\s*"%s".*?"questionsPerAttempt":\s*%d)(\s*,?)'
        % (lesson_id, attempt),
        re.S,
    )
    match = pattern.search(text)
    if not match:
        print('skip', lesson_id)
        continue
    block = text[match.start():match.end()]
    if '"passingScore"' in block:
        continue
    replacement = '%s,\n    "passingScore": %d%s' % (
        match.group(1), passing, match.group(2))
    text = text[:match.start()] + replacement + text[match.end():]
    total += 1
    print('ok', lesson_id, '->', passing)

with open(PATH, 'w', encoding='utf-8', newline='\n') as fh:
    fh.write(text)

print('changed', total)
