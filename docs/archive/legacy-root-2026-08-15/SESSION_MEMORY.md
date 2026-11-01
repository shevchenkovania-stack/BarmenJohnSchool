# Session Memory — Coin app

## Context
- **Project:** Flutter cocktail app (барное приложение)
- **Current branch:** `constructor` (есгь незакоммиченные изменения)
- **New branch to create:** `feat/rule-based-builder`
- **Goal:** Заменить AI (GPT-4o) генерацию коктейлей на Rule-based engine, убрать затраты на OpenAI токены

## Core Problem
OpenAI API ключи:
- Хардкод в 3 местах (recipe_ai_service.dart, mixologist_ai_service.dart, .env)
- Зашиты в APK
- Трата денег на токены при нулевом доходе с приложения

## Chosen Solution: Variant 2 — Rule-based engine (replaces AI)

**How it works:**
1. Пользователь выбирает ингредиенты (алко и безалко)
2. Engine матчит их против ~600 коктейлей из TheCocktailDB (уже загружены через `preloadAll()`)
3. Если ингредиенты совпадают с известным коктейлем (~90+%) → показываем рецепт
4. Если совпадений нет → честно говорим "из этих ингредиентов нет известных коктейлей"
5. Safety checks (уже есть в CocktailSafetyService)
6. Безалкогольные коктейли (~90 из 600) поддерживаются "из коробки" через поле `strAlcoholic`

## Architecture changes needed

### What to REMOVE (AI parts):
- `MixologistAIService` (lib/features/cocktail_builder/services/mixologist_ai_service.dart)
- `RecipeAIService` (lib/core/services/recipe_ai_service.dart)
- Все вызовы OpenAI в `CocktailAlgorithm.buildPrompt()` и `buildVariantsPrompt()`
- Зависимость от `flutter_dotenv` (если AI убрали полностью)
- `.env` из assets в pubspec.yaml

### What to ADD:
- `CocktailMatcherService` — сервис для матчинга ингредиентов против БД TheCocktailDB
- Использовать `CocktailRepository.getAllCached()` как источник данных
- Перенести логику `CocktailWithAvailability.check()` (уже есть в can_make/) в новый сервис
- Добавить "partial match" — если до классического коктейля не хватает 1-2 ингредиента, показать "вам не хватает только X"

### What to REUSE (already exists):
- `Cocktail` model (lib/core/models/cocktail.dart) — уже есть данные
- `CocktailRepository` (lib/core/repositories/cocktail_repository.dart) — с preloadAll()
- `CocktailSafetyService` (lib/features/cocktail_builder/services/cocktail_safety_service.dart)
- `CocktailAlgorithm.detectMethod()`, `detectGlass()`, `detectWowEffect()` — работают без AI
- `CocktailAlgorithm.calculateProfile()` — считает ABV, сахар, калории
- UI screens, widgets, слайдеры, стили — всё остается
- `GeneratedCocktail` model — можно переиспользовать формат

### State management:
- Provider + ChangeNotifier (остаётся без изменений)

### Business model:
- BYOK (Bring Your Own Key) — в будущем можно добавить как опцию (для пользователей, которые хотят AI-улучшения)
- Rule-based engine — бесплатно для всех пользователей по умолчанию

## Files to modify:
1. `lib/features/cocktail_builder/viewmodel/cocktail_builder_viewmodel.dart` — заменить `_aiService` на `CocktailMatcherService`
2. `lib/main.dart` — убрать провайдеры для AI сервисов
3. `lib/features/cocktail_builder/view/cocktail_algorithm.dart` — убрать buildPrompt/buildVariantsPrompt, оставить вспомогательные методы
4. `lib/core/services/recipe_ai_service.dart` — удалить или вынести в BYOK
5. `pubspec.yaml` — убрать `.env` из assets, убрать `flutter_dotenv` если не используется больше нигде

## Files to create:
1. `lib/features/cocktail_builder/services/cocktail_matcher_service.dart` — новый движок матчинга

## Notes about current branch:
- Текущая ветка: `constructor`
- Есть незакоммиченные изменения в ~20 файлах
- Нужно либо закоммитить их, либо создать ветку с ними
- Бранч для новой фичи: `feat/rule-based-builder`

## Status: Шаги 1-5 выполнены

### Что сделано:
1. ✅ `CocktailMatcherService` — матчинг ингредиентов против TheCocktailDB
2. ✅ `CocktailBuilderViewModel` — AI заменён на Matcher + опциональный AI Enhancer
3. ✅ BYOK — экран ввода OpenAI ключа в Settings (flutter_secure_storage)
4. ✅ `AiEnhancerService` — опционально улучшает proTip/fact/wowEffect через GPT-4o-mini
5. ✅ Очистка:
   - `.env` удалён из assets APK
   - `flutter_dotenv` удалён из зависимостей
   - dotenv loading удалён из main.dart
   - API ключ удалён из .env
   - `MixologistAIService` провайдер удалён из main.dart
   - старые AI сервисы остались (recipe_ai_service, mixologist_ai_service) для обратной совместимости других экранов

### Новая архитектура:
```
Пользователь выбирает ингредиенты
    ↓
CocktailMatcherService.match(ingredients) ← Rule-based, БЕСПЛАТНО
    ↓
Есть user API ключ? ─── Да ──→ AiEnhancerService.enhance(result)
    │                              ↓
    Нет                      proTip/fact/wowEffect добавлены
    │                              (GPT-4o-mini, платит юзер)
    ↓
Показываем UI (тот же, без изменений)
```

## Next session:
- Удалить старые AI сервисы если не нужны (recipe_ai_service, mixologist_ai_service)
- закоммитить и запушить feat/rule-based-builder
- обновить .gitignore (добавить .env)
