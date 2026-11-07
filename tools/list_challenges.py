# -*- coding: utf-8 -*-
"""Печатает соответствие заданий Мастерской урокам.

Помогает проверить, что практика не опережает теорию.
"""
import glob
import io
import re
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

for path in sorted(glob.glob('lib/features/bartender_school/data/challenges/*.dart')):
    text = open(path, encoding='utf-8').read()
    ids = re.findall(r"id: '([^']+)'", text)
    lessons = re.findall(r"lessonId: '([^']+)'", text)
    names = re.findall(r"cocktailName: '([^']+)'", text)
    print(path.split('/')[-1])
    for cid, lesson, name in zip(ids, lessons, names):
        print('   ', cid, '->', lesson, '|', name)
