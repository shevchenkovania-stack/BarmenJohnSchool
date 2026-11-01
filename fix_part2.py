import json

# Read both files
with open('data/content/lessons_level1_part1.json', 'r', encoding='utf-8') as f:
    part1 = json.load(f)
    
with open('data/content/lessons_level1_part2.json', 'r', encoding='utf-8') as f:
    part2 = json.load(f)

# Copy titles from part1 to part2
for i, lesson in enumerate(part2):
    # Find matching lesson in part1 by number
    for p1_lesson in part1:
        if p1_lesson.get('lessonNumber') == lesson.get('lessonNumber'):
            # Copy structure from part1 if needed
            break
    
    # Fix the title based on lesson number
    num = lesson.get('lessonNumber', 0)
    if num == 9:
        lesson['title'] = 'Мохито - сборка + раздавливание'
        lesson['shortDescription'] = 'Ром + лайм + сахар + мята + содовая.'
    elif num == 10:
        lesson['title'] = 'Дайкири - встряхивание + процеживание'
        lesson['shortDescription'] = 'Ром + лайм + сахар. Классика!'
    elif num == 11:
        lesson['title'] = 'Негрони - размешивание + горечь'
        lesson['shortDescription'] = 'Джин + Кампари + Вермут красный.'
    elif num == 12:
        lesson['title'] = 'Экзамен Level 1'
        lesson['shortDescription'] = 'Проверь все знания!'

# Write back
with open('data/content/lessons_level1_part2.json', 'w', encoding='utf-8') as f:
    json.dump(part2, f, ensure_ascii=False, indent=2)

print('Fixed lessons_level1_part2.json')
