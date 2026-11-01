# 🔒 Спрятанные фичи (Hidden Features)

> **Дата:** Август 2026  
> **Причина:** Упрощение навигации для релиза "Школа бармена"  
> **Статус:** Код сохранён, убран из UI

---

## 📋 СПИСОК СПРЯТАННЫХ ФИЧ

### 1. 🏪 Bar Manager (Управление баром)
**Файлы:**
- `lib/features/bar_manager/bar_manager_screen.dart` (165 строк)
- `lib/features/bar_manager/inventory/view/inventory_screen.dart` (469 строк)
- `lib/features/bar_manager/can_make/view/can_make_screen.dart` (340 строк)
- `lib/features/bar_manager/custom_recipes/view/custom_recipes_screen.dart` (158 строк)
- `lib/features/bar_manager/stop_list/view/stop_list_screen.dart` (114 строк)
- `lib/features/bar_manager/price_book/view/price_book_screen.dart` (603 строк)

**Что делает:**
- Инвентарь ингредиентов
- "Что могу приготовить"
- Мои рецепты (авторские)
- Стоп-лист
- Прайс-лист

**Почему спрятано:** Для профессиональных барменов, не для обучения  
**Как вернуть:** Раскомментировать в `main_shell.dart` строку с `BarManagerScreen()`

---

### 2. 📱 Kiosk / Guest Mode (Цифровое меню)
**Файлы:**
- `lib/features/guest_mode/view/kiosk_setup_screen.dart` (593 строки)
- `lib/features/guest_mode/view/guest_mode_screen.dart` (810 строк)

**Что делает:**
- Настройка цифрового меню для планшета
- Immersive режим для гостей
- Фильтры: All / Alcoholic / Non-Alcoholic
- Просмотр коктейлей с ценами

**Почему спрятано:** Для баров, не для обучения  
**Как вернуть:** Добавить кнопку в Bar Manager или Settings

---

### 3. 📋 Menu Builder (Конструктор меню)
**Файлы:**
- `lib/features/menu_builder/view/menu_builder_screen.dart` (482 строки)
- `lib/features/menu_builder/service/menu_pdf_service.dart` (476 строк)

**Что делает:**
- Создание PDF меню из избранных коктейлей
- Выбор темы оформления
- Установка цен
- Печать / сохранение PDF

**Почему спрятано:** Для владельцев баров, не для студентов  
**Как вернуть:** Добавить в Settings или Bar Manager

---

### 4. 📱 QR Menu (QR-код меню)
**Файлы:**
- `lib/features/qr_menu/view/qr_menu_screen.dart` (353 строки)
- `lib/features/qr_menu/service/qr_menu_server.dart` (85 строк)
- `lib/features/qr_menu/service/html_menu_builder.dart` (144 строки)

**Что делает:**
- Локальный HTTP сервер
- Генерация QR-кода
- Гости сканируют → видят HTML меню

**Почему спрятано:** Для баров, требует WiFi  
**Как вернуть:** Добавить в Kiosk Setup или Menu Builder

---

### 5. ☕ Coffee List / Coffee Single
**Файлы:**
- `lib/features/coffee_list/view/coffee_list_screen.dart` (207 строк)
- `lib/features/coffee_list/widgets/coffee_list_widget.dart` (39 строк)
- `lib/features/coffee_single/view/coffee_single_screen.dart` (108 строк)

**Что делает:**
- Список кофейных напитков
- Поиск кофе
- Детали кофе

**Почему спрятано:** Не относится к коктейлям, старый код  
**Как вернуть:** Если нужен — переделать под "Coffee School"

---

### 6. 💰 Cost Calculator (Калькулятор себестоимости)
**Файлы:**
- `lib/features/cost_calculator/view/bottle_prices_screen.dart` (493 строки)
- `lib/features/cost_calculator/widgets/cocktail_cost_calculator.dart` (489 строк)

**Что делает:**
- Расчёт себестоимости коктейлей
- Цены на бутылки
- Рекомендуемая цена продажи

**Почему спрятано:** Для владельцев баров, не для студентов  
**Как вернуть:** Добавить в Settings → "Бизнес инструменты"

---

### 7. 🛑 Stop List (Стоп-лист)
**Файлы:**
- `lib/features/bar_manager/stop_list/view/stop_list_screen.dart` (114 строк)

**Что делает:**
- Список ингредиентов которых нет сегодня
- Исключение из "Могу приготовить"

**Почему спрятано:** Для ежедневной работы бара  
**Как вернуть:** Добавить в Bar Manager

---

### 8. 💲 Price Book (Прайс-лист)
**Файлы:**
- `lib/features/bar_manager/price_book/view/price_book_screen.dart` (603 строки)
- `lib/features/bar_manager/price_book/view/moldova_catalog_sheet.dart` (345 строк)

**Что делает:**
- Каталог цен на ингредиенты
- Молдовский каталог (предзаполненный)
- Расчёт цены за 1 ml

**Почему спрятано:** Для бухгалтерии/закупок  
**Как вернуть:** Добавить в Bar Manager или Settings

---

## 🔄 ТЕКУЩАЯ НАВИГАЦИЯ (после изменений)

### Было (5 вкладок):
```
┌──────┬────────┬────────────┬──────────┬──────┐
│ Home │ Search │ Конструктор│Favorites │ Бар  │
└──────┴────────┴────────────┴──────────┴──────┘
```

### Стало (3 вкладки):
```
┌────────┬──────────┬──────────┐
│ 🎓 Учеба│ 📚 Рецепты│ 🍸 Практика│
└────────┴──────────┴──────────┘
```

| Вкладка | Что внутри | Приоритет |
|---------|-----------|-----------|
| 🎓 **Учиться** | School Home → Уроки, Quiz, Дипломы | ОСНОВНОЕ |
| 📚 **Рецепты** | Библиотека + Поиск + Избранное | Справочник |
| 🍸 **Практика** | Конструктор + "Что могу приготовить" | Применение |

---

## 📍 ГДЕ НАЙТИ СПРЯТАННЫЕ ФИЧИ

### Через настройки (Settings):
- **Bar Manager** → кнопка в Settings (опционально)
- **Cost Calculator** → Settings → "Бизнес инструменты"

### Через код (раскомментировать):
```dart
// lib/shell/main_shell.dart
// Раскомментировать строку:
// BarManagerScreen(),

// lib/features/bar_manager/bar_manager_screen.dart
// Раскомментировать карточки:
// _FeatureCard(... InventoryScreen ...),
// _FeatureCard(... StopListScreen ...),
// _FeatureCard(... PriceBookScreen ...),
```

---

## 🎯 ПЛАН ВОЗВРАТА (Future Releases)

### Релиз 2 (Профессиональный):
- ✅ Bar Manager (Инвентарь + Can Make + Мои рецепты)
- ✅ Cost Calculator
- ✅ Stop List

### Релиз 3 (Бизнес):
- ✅ Menu Builder (PDF)
- ✅ QR Menu
- ✅ Kiosk Mode

### Релиз 4 (Кофе):
- ✅ Coffee School (если нужен)

---

## 📊 СТАТИСТИКА

| Категория | Файлов | Строк кода | Статус |
|-----------|--------|------------|--------|
| Спрятано | 15 | ~5,500 | ✅ Сохранено |
| Активно | 20 | ~15,000 | 🟢 В UI |
| **Всего** | **35** | **~20,500** | ✅ |

---

## 💡 ПРИМЕЧАНИЯ

- **Все файлы сохранены** — ничего не удалено
- **Код не изменён** — только убран из навигации
- **Можно вернуть** в любой момент раскомментированием
- **Документация** — этот файл обновляется при каждом изменении

---

**Последнее обновление:** Август 2026  
**Обновил:** AI Assistant
