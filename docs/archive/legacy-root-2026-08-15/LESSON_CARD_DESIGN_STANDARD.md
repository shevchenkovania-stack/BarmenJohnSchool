# Lesson Card Design Standard

## Purpose

This document records the current design decision for Bartender School lesson cards, so the format can be restored or continued without guessing.

## Core Rule

Each lesson card has two different roles:

1. Front side in the level grid: topic preview.
2. Opened card after tap: John introduces the lesson and sends the student into the lesson.

Do not mix both roles into one surface.

## Level Grid Card

The grid card must stay clean and visual.

- Use a thematic lesson image when an artwork exists.
- Do not show John on top of thematic artwork.
- Do not show John speech text on the grid card when artwork exists.
- Keep the lesson number, title, progress/status indicators, and artwork.
- The grid card answers: "What is this lesson about?"

Current restored Level A artwork mapping:

- `lesson_A_01` -> `images/lesson_a_01_balance.png`
- `lesson_A_02` -> `images/lesson_a_02_acid.png`
- `lesson_A_03` -> `images/lesson_a_03_sweetness.png`
- `lesson_A_04` -> `images/lesson_a_04_bitters.png`

If a lesson has no thematic artwork yet, the old small John hint can be used as fallback.

## Opened Card

When a student taps a lesson card, the opened card should use John, not the thematic image.

Opened card structure:

- Top: John avatar, John label, lesson title.
- Middle: John story from `lesson.historicalStory`.
- Middle secondary: lesson short description and compact metadata.
- Bottom: fixed `Начать урок` button.
- Bottom secondary: `К ключевым точкам` flip action.

Important UX rule:

- `Начать урок` must be visible without scrolling on normal mobile screens.
- Only the story/description middle area may scroll.
- Do not put the main button inside the scrollable area.

The opened card answers: "Why does this matter, and what should I do next?"

## John Avatar Selection

Use John image by lesson block:

- Block A: `images/barista_john_teach.png`
- Block B: `images/barista_john_practice.png`
- Block C: `images/barista_john_exam.png`

This keeps the same character but changes his role:

- A: mentor explains taste and theory.
- B: mentor trains hands and technique.
- C: mentor prepares the student for exam/practice.

## Content Fields

Preferred content source:

- `historicalStory`: main John story for the opened card.
- `shortDescription`: short supporting explanation.
- `estimatedMinutes`: time chip.
- `terms`: glossary chip and terms count.

Fallback if `historicalStory` is missing:

> Первый навык бармена - не рецепт. Первый навык - понять, зачем этот урок нужен за настоящей стойкой.

## Current Implementation

Primary files:

- `lib/features/bartender_school/presentation/widgets/lesson_card.dart`
- `lib/features/bartender_school/presentation/screens/flip_card_screen.dart`

Current state:

- Front grid cards keep thematic artwork for A01-A04.
- Opened cards now use the John story layout for all lessons.
- The old emoji/key-points opened front was replaced by the John story entry.
- The detailed key-points side remains available through card flip/back side.
- The `Начать урок` button is fixed outside the scrollable middle content.

## Do Not Regress

- Do not place John over the thematic artwork on the grid card.
- Do not place lesson artwork and John together on the opened card.
- Do not hide `Начать урок` below scroll.
- Do not remove the story role from John: he should feel like a mentor, not a decoration.
- Do not make the card a marketing block. It is part of the school flow.
