# Временный QA-скрипт: сверка контента Level 1/2 (идеи, квизы, практика, артворк)
$ErrorActionPreference = 'Stop'
$content = 'data/content'

function Load($name) { Get-Content (Join-Path $content $name) -Raw -Encoding UTF8 | ConvertFrom-Json }

$lessonFiles = @('lessons_level1_part1.json','lessons_level1_part2.json','lessons_level2.json','lessons_level3.json','lessons_wisdom.json')
$quizFiles   = @('quizzes_level1_part1.json','quizzes_level1_part2.json','quizzes_level2.json','quizzes_level3.json')

$lessons = @()
foreach ($f in $lessonFiles) {
  $arr = Load $f
  foreach ($l in $arr) { $lessons += [pscustomobject]@{ file=$f; id=$l.id; title=$l.title; block=$l.block; order=$l.order; prereq=$l.unlockCondition.prerequisiteLessonId; slides=@($l.slides).Count; level=$l.level } }
}

Write-Output "=== LESSONS ($($lessons.Count)) ==="
$lessons | ForEach-Object { "{0,-14} lvl={1,-3} block={2,-3} order={3,-4} slides={4,-3} prereq={5,-14} file={6} :: {7}" -f $_.id, $_.level, $_.block, $_.order, $_.slides, $_.prereq, $_.file, $_.title }

$quizzes = @()
foreach ($f in $quizFiles) {
  $arr = Load $f
  foreach ($q in $arr) {
    foreach ($qq in $q.quizzes) { }
    $quizzes += [pscustomobject]@{ file=$f; lessonId=$q.lessonId; questions=@($q.questions).Count }
  }
}
Write-Output ""
Write-Output "=== QUIZ FILES shape (first item keys) ==="
$firstQuiz = (Load 'quizzes_level1_part1.json')[0]
Write-Output (($firstQuiz | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -join ', ')
