# Конструктор Коктейлей — Полное техническое описание

## 📋 АРХИТЕКТУРА

### Файловая структура
```
lib/features/cocktail_builder/
├── models/
│   ├── cocktail_types.dart       # Enum: метод приготовления, тип бокала
│   ├── flavor_profile.dart       # Профиль вкуса (крепость, сладость, кислотность)
│   ├── generated_cocktail.dart   # Модель сгенерированного коктейля
│   └── mixology_explanation.dart # Объяснение миксолога
├── services/
│   ├── cocktail_safety_service.dart  # Безопасность: blacklist, аллергены, конфликты
│   └── mixologist_ai_service.dart    # AI сервис (OpenAI API)
├── view/
│   ├── cocktail_algorithm.dart       # Алгоритм: метод, бокал, промпт
│   ├── cocktail_builder_screen.dart  # UI экран (2074 строки)
│   └── generated_cocktail.dart       # Экран результата (устарел?)
└── viewmodel/
    └── cocktail_builder_viewmodel.dart  # ViewModel (391 строка)
```

---

## 🔄 ПОТОК ДАННЫХ

```
Пользователь выбирает ингредиенты → Настраивает профиль вкуса
  → Нажимает "Создать коктейль" → ViewModel вызывает CocktailAlgorithm.buildPrompt()
    → Промпт отправляется в MixologistAIService.createCocktailVariants()
      → OpenAI API возвращает JSON → Парсинг в GeneratedCocktail
        → Отображение _ResultScreen
```

---

## 📊 МОДЕЛИ ДАННЫХ

### GeneratedCocktail (основная модель)
```dart
name: String                    // Название коктейля
description: String             // Описание (2-3 предложения)
ingredients: List<CocktailIngredient>  // Ингредиенты с объёмами в мл
steps: List<String>             // Пошаговая инструкция
method: CocktailMethod          // Shake/Stir/Build/Muddle/Blend/Layered
glass: CocktailGlass            // Coupe/Rocks/Highball/Martini/Flute/Shot

// Метрики
abv: double                     // Алкоголь % (0-100)
sugarGrams: double              // Граммы сахара
calories: int                   // Калории
allergens: List<String>         // Аллергены

// Доп. информация
wowEffect: String               // ВАУ-эффект подачи
whyItWorks: String              // Объяснение почему работает
garnish: String?                // Украшение
serving: String?                // Как подавать
flavorProfile: FlavorProfile?   // Профиль вкуса
explanation: MixologyExplanation? // Объяснение миксолога
proTip: String?                 // Совет профи
fact: String?                   // Факт
secret: String?                 // Секрет
```

### CocktailIngredient
```dart
name: String
amountMl: int                   // Объём в мл
```

### FlavorProfile
```dart
strength: int (0-10)
sweetness: int (0-10)
acidity: int (0-10)
bitterness: int (0-10)
sparkling: bool
```

### MixologyExplanation
```dart
base: String    // Почему выбран алкоголь
balance: String // Как достигнут баланс
aroma: String   // Ароматы
overall: String // Общее впечатление
```

---

## 🧩 КОМПОНЕНТЫ UI

### CocktailBuilderScreen (главный экран)
- **AppBar**: заголовок + кнопка "Начать заново"
- **2 состояния**:
  1. `_BuilderForm` — форма ввода
  2. `_ResultScreen` — результат (показывается сразу, без промежуточного экрана)

### _BuilderForm (форма ввода)
1. **HeroCard** — приветственный баннер
2. **SectionCard: Ингредиенты**
   - Список из инвентаря (чекбоксы)
   - Кнопка "Свой" — добавить кастомный ингредиент
   - Отображение выбранных (Chip с удалением)
   - Кастомные ингредиенты (с кнопкой удаления ×)
3. **SectionCard: Профиль Вкуса**
   - 4 слайдера: крепость, сладость, кислотность, горечь (0-10)
   - Тоггл: газированность
4. **SectionCard: Настроение**
   - Dropdown: Аромат (5 вариантов)
   - Dropdown: Текстура (4 варианта)
   - Dropdown: Цель (5 вариантов)
5. **_GenerateButton** — кнопка генерации

### _ResultScreen (результат)
1. Кнопка "Новый коктейль" (назад)
2. _HeroResultCard — название + описание
3. _QuickInfoCard — метод + бокал (2 карточки)
4. _MetricsPanel — ABV, сахар, калории
5. _AllergenWarning (если есть аллергены)
6. Состав (список ингредиентов с объёмами)
7. Приготовление (пошагово)
8. ВАУ-деталь, Почему работает, Совет профи, Факт, Секрет
9. Кнопки: "Сохранить в избранное", "Создать другой"

### Устаревшие компоненты (НЕ используются)
- `_VariantsScreen` — экран списка вариантов (удалён из потока)
- `_VariantCard` — карточка варианта

---

## 🤖 AI ИНТЕГРАЦИЯ

### MixologistAIService
- **API**: OpenAI GPT-4o
- **URL**: `https://api.openai.com/v1/chat/completions`
- **Формат ответа**: JSON
- **Temperature**: 0.7

### Методы сервиса
```dart
createCocktailFromPrompt(prompt)     // Создать 1 коктейль
createCocktailVariants(prompt)       // Создать список (сейчас 1)
_buildPrompt(...)                    // Построить промпт (устарел)
_callAPI(prompt)                     // Вызов OpenAI API
```

### Промпт (CocktailAlgorithm.buildPrompt)
Включает:
- Ингредиенты пользователя
- Профиль вкуса с конкретными рекомендациями
- Рекомендуемый метод приготовления
- Рекомендуемый бокал
- ВАУ-эффект
- Предупреждения безопасности
- Формат ответа JSON

---

## 🛡️ БЕЗОПАСНОСТЬ (CocktailSafetyService)

### Blacklist (полный запрет)
- Бытовая химия (мыло, хлорка, ацетон)
- Лекарства (аспирин, ибупрофен)
- Наркотики
- Токсичные растения (белладонна, дурман)

### Greylist (предупреждения)
- Сырые яйца (сальмонелла)
- Сырая рыба
- Энергетики + алкоголь
- Абсент/Everclear (высокий ABV)

### Конфликтующие сочетания
- Молоко + лимон/лайм (створаживание)
- Сливки + высокая кислотность (расслоение)
- Энергетик + водка/джин (нагрузка на сердце)
- Кола + молоко

### Аллергены
- Молочные продукты
- Орехи (миндаль, фундук)
- Глютен (пиво, виски)
- Яйца
- Соя
- Цитрусовые

### База данных ингредиентов (50+ записей)
Содержит:
- name, abv, sugarGramsPer100ml, category, allergens, isRaw

### Методы расчёта
```dart
validateIngredients()              // Проверка blacklist/greylist
validateCombination()              // Проверка конфликтов
detectAllergens()                  // Обнаружение аллергенов
calculateAbv()                     // Расчёт ABV
calculateSugarGrams()              // Расчёт сахара
getIngredientCategories()          // Категории ингредиентов
getBeginnerWarnings()              // Предупреждения для начинающих
```

---

## 🎯 АЛГОРИТМ (CocktailAlgorithm)

### Определение метода приготовления
Логика приоритетов:
1. **Muddle**: есть травы/ягоды → Muddle & Shake
2. **Blend**: мороженое/банан/замороженные → Blend
3. **Layered**: сливки + спирт → Layered
4. **Build**: газированные → Build in Glass
5. **Shake**: соки/сливки/яйца → Shake & Strain
6. **Stir**: только алкоголь → Stir

### Определение бокала
Логика:
1. Шампанское/просекко → Flute
2. Газированные/Build → Highball
3. Layered/крепкий Stir → Martini
4. Крепкий Stir (7+) → Rocks
5. Shake/Muddle → Coupe
6. Default → Coupe

### ВАУ-эффект
Определяется по ингредиентам:
- Цитрусовые → выжигание цедры
- Ягоды → раздавливание
- Травы → хлопки/поджигание
- Шоколад → ободок
- Специи → посыпка

### Расчёт профиля коктейля
```dart
calculateProfile(ingredientsWithAmounts):
  abv = (сумма мл_алкоголь × ABV%) / общий объём × 100
  sugarGrams = сумма (мл / 100 × сахарНа100мл)
  calories = алкоголь × 0.789 × 7 + сахар × 4
  allergens = уникальные аллергены всех ингредиентов
```

---

## 🔧 VIEWMODEL (CocktailBuilderViewModel)

### Состояния
```dart
_selectedIngredients: Set<String>     // Выбранные ингредиенты
_customIngredients: List<String>      // Кастомные ингредиенты

// Настройки вкуса
_strength: int (0-10)
_sweetness: int (0-10)
_acidity: int (0-10)
_bitterness: int (0-10)
_sparkling: bool

// Настроение
_aroma: String
_texture: String
_goal: String

// Состояния
_isGenerating: bool
_generatedCocktail: GeneratedCocktail?
_error: String?

// Устаревшие (не используются в текущем потоке)
variants: List<GeneratedCocktail>
selectedVariant: GeneratedCocktail?
```

### Методы
```dart
// Ингредиенты
toggleIngredient(name)
selectAll()
clearIngredients()
addCustomIngredient(name)
removeCustomIngredient(name)

// Настройки вкуса
setStrength/Sweetness/Acidity/Bitterness(value)
toggleSparkling()
setAroma/Texture/Goal(value)

// Генерация
generateCocktail()              // Старый метод (1 коктейль)
generateVariants()              // Текущий метод (с логами)
createNew()                     // Сброс

// Безопасность
validateIngredients()
validateCombinations()
getBeginnerWarnings()
detectAllergens()

// Устаревшие
selectVariant(cocktail)
clearSelectedVariant()
```

---

## ⚠️ ПРОБЛЕМЫ И ТЕХНИЧЕСКИЙ ДОЛГ

### 1. Устаревший код
- **_VariantsScreen** (строки 65-154) — не используется в потоке, можно удалить
- **_VariantCard** (строки 160-324) — не используется, можно удалить
- **selectedVariant** в ViewModel — не используется
- **variants** List в ViewModel — используется только для хранения 1 результата

### 2. Дублирование логики
- `generateCocktail()` и `generateVariants()` — почти идентичны
- `_buildPrompt()` в AIService и `buildPrompt()` в Algorithm — дублируют промпт

### 3. API ключ
- Хардкод API ключа в `mixologist_ai_service.dart` строка 16
- Нужно вынести в .env или secure storage

### 4. Локализация
- Все строки захардкожены на русском
- Нужно добавить в ARB файлы

### 5. Безопасность
- Нет кэширования результатов
- Нет ограничения частоты запросов
- Нет offline fallback

### 6. UI проблемы
- 2074 строки в одном файле экрана — нужно разбить
- Нет loading skeleton
- Нет error state с retry
- Нет анимации появления результата

### 7. Логирование
- Избыточное логирование (логи в каждом шаге)
- Нужно убрать или сделать конфигурируемым

### 8. Производительность
- Нет debounce для слайдеров
- Перестроение всего дерева при каждом notifyListeners()

---

## 💡 РЕКОМЕНДАЦИИ ДЛЯ ДОРАБОТКИ

### Удалить
- `_VariantsScreen` класс
- `_VariantCard` класс
- Поле `selectedVariant` в ViewModel
- Метод `selectVariant()` и `clearSelectedVariant()`
- Метод `generateCocktail()` (устарел)
- Метод `_buildPrompt()` в AIService (дублирует Algorithm)
- Файл `view/generated_cocktail.dart` (если не используется)

### Добавить
1. **История** — сохранять последние 10 коктейлей
2. **Избранное** — сохранить понравившиеся (есть кнопка, не реализовано)
3. **Поделиться** — экспорт рецепта (картинка/текст)
4. **Рейтинг** — оценка коктейля 1-5 звёзд
5. **Кэширование** — кешировать результат на 5 минут
6. **Error handling** — красивые ошибки с retry
7. **Skeleton loading** — плейсхолдер во время генерации
8. **Анимации** — плавное появление результата
9. **Offline mode** — шаблоны коктейлей без AI
10. **Порции** — выбор размера порции (1x, 2x, 4x)
11. **Масштабирование** — пересчёт объёмов при изменении порции
12. **Таймер** — таймер для техники приготовления
13. **Видео** — ссылки на YouTube с техниками
14. **Парные коктейли** — "похожие на этот"
15. **Статистика** — сколько коктейлей создано

### Улучшить
1. Разбить `cocktail_builder_screen.dart` на файлы по компонентам
2. Вынести API ключ в .env
3. Добавить локализацию
4. Оптимизировать rebuild'ы (selective notifyListeners)
5. Добавить тесты (unit для Algorithm, widget для UI)
6. Рефакторинг промпта — вынести в шаблон с переменными

---

## 📱 ИНТЕГРАЦИЯ С ДРУГИМИ МОДУЛЯМИ

### Зависимости
```dart
import 'package:coin/core/repositories/inventory_repository.dart';  // Ингредиенты
import 'package:coin/core/repositories/cocktail_repository.dart';   // База коктейлей
import 'package:coin/core/services/favorites_service.dart';         // Избранное
import 'package:coin/core/theme/app_theme.dart';                    // Тема
```

### Provider регистрация
```dart
ChangeNotifierProvider(
  create: (_) => CocktailBuilderViewModel(
    aiService: MixologistAIService(),
    inventory: context.read<InventoryRepository>(),
    cocktailRepo: context.read<CocktailRepository>(),
  ),
)
```

---

## 🎨 UI ЦВЕТА

```dart
AppColors.background      // Фон
AppColors.primary         // Основной акцент (золотой)
AppColors.textPrimary     // Основной текст
AppColors.textSecondary   // Вторичный текст
AppColors.surfaceLight    // Светлая поверхность
```

---

## 📝 ФОРМАТ AI JSON ОТВЕТА

```json
{
  "name": "Название",
  "description": "Описание",
  "ingredients": [
    {"name": "ингредиент", "amountMl": 50}
  ],
  "method": "shake",
  "glass": "coupe",
  "steps": ["шаг 1", "шаг 2", "шаг 3"],
  "abv": 15.0,
  "sugarGrams": 12.5,
  "calories": 180,
  "allergens": [],
  "wowEffect": "ВАУ-эффект",
  "whyItWorks": "Объяснение",
  "proTip": "Совет профи",
  "fact": "Факт",
  "flavorProfile": {
    "strength": 5,
    "sweetness": 3,
    "acidity": 4,
    "bitterness": 1,
    "sparkling": true
  }
}
```

---

## 📐 РАЗМЕРЫ КОДА

| Файл | Строк | Назначение |
|------|-------|------------|
| cocktail_builder_screen.dart | 2074 | UI экран |
| cocktail_safety_service.dart | 542 | Безопасность |
| cocktail_algorithm.dart | 557 | Алгоритм |
| mixologist_ai_service.dart | 337 | AI сервис |
| cocktail_builder_viewmodel.dart | 391 | ViewModel |
| generated_cocktail.dart | 227 | Модель |
| cocktail_types.dart | 95 | Enum'ы |
| mixology_explanation.dart | 39 | Модель |
| flavor_profile.dart | 49 | Модель |

**Итого**: ~4311 строк кода

---

*Дата создания документа: 10 марта 2026*
*Версия: 1.0*
