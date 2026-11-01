# B2B Cocktail App — Architecture Plan

## Core Decision Summary

| Decision | Choice | Why |
|---|---|---|
| MVP storage | Local (Hive + SharedPreferences) | No backend cost, fast to build |
| Future backend | Firebase (drop-in via repo swap) | No UI changes needed |
| State management | Provider (keep existing) | Already in place, sufficient |
| Local DB | Hive | NoSQL, fast, Flutter-native, no SQL overhead |
| i18n | Flutter built-in `intl` + ARB files | Infrastructure now, translations later |
| Pro gating | `ProService` (bool flag today, RevenueCat later) | Swappable without touching screens |

---

## What happens when you sell to venues

Today (MVP): everything on one phone, no cloud, no accounts.

Later (Phase 2), without rewriting screens:
- Swap `InventoryRepository` from Hive → Firestore
- Add `AuthService` → bartender logs in, sees their venue's data
- Add `VenueService` → owner manages multiple locations
- Add RevenueCat → in-app subscription replaces local Pro flag
- All screens/viewmodels stay **exactly the same** because they talk to abstract repository interfaces, not to Hive or Firebase directly

---

## Folder Structure

```
lib/
  core/
    api/
      cocktail_api.dart                   # HTTP client (TheCocktailDB)
    db/
      hive_service.dart                   # Hive init + box registry
      adapters/                           # Generated HiveTypeAdapters
    models/
      cocktail.dart                       # API model (already done)
      custom_recipe.dart                  # Venue's own recipe (NEW)
      inventory_item.dart                 # What bar has in stock (NEW)
      stop_item.dart                      # What's unavailable today (NEW)
      cost_entry.dart                     # Bottle price for margin calc (NEW)
    repositories/
      cocktail_repository.dart            # API data (already done)
      custom_recipe_repository.dart       # Hive CRUD — own recipes
      inventory_repository.dart           # Hive CRUD — stock items
      stop_list_repository.dart           # Hive CRUD — today's stops
      cost_repository.dart                # Hive CRUD — bottle prices
    services/
      favorites_service.dart              # SharedPrefs (already done)
      pro_service.dart                    # Free/Pro flag (NEW)
    theme/
      app_theme.dart                      # (already done)
    l10n/
      app_en.arb                          # English strings (base)
      app_ru.arb                          # Russian (empty now, fill later)
      app_ro.arb                          # Romanian (empty now, fill later)
    utils/
      unit_converter.dart                 # oz ↔ ml ↔ cl
      serving_calculator.dart             # recipe × N servings
    constants/
      app_constants.dart                  # API URLs, Hive box names
  features/
    home/                                 # (already done)
    cocktail_list/                        # (already done)
    cocktail_detail/                      # (already done)
    search/                               # (already done)
    favorites/                            # (already done)
    bar_manager/                          # NEW — Pro section
      stop_list/
        view/stop_list_screen.dart
        stop_list_viewmodel.dart
      inventory/
        view/inventory_screen.dart
        inventory_viewmodel.dart
      can_make/
        view/can_make_screen.dart         # "What can I make now?"
        can_make_viewmodel.dart
      custom_recipes/
        view/
          custom_recipes_screen.dart
          add_edit_recipe_screen.dart
        custom_recipe_viewmodel.dart
      cost_calculator/
        view/cost_calculator_screen.dart
        cost_calculator_viewmodel.dart
      event_calculator/
        view/event_calculator_screen.dart
        event_calculator_viewmodel.dart
    settings/
      view/settings_screen.dart          # Language picker + Pro status
      settings_viewmodel.dart
  shell/
    main_shell.dart                       # Bottom nav (already done)
  coffee_list_app.dart                    # MyApp (already done)
  main.dart                               # Entry point (already done)
```

---

## Layer Rules (how each layer talks to the next)

```
Screen → ViewModel → Repository → (Hive or API or Firebase)
                  ↘ Service (favorites, pro)
```

- Screens know nothing about Hive or HTTP — only ViewModels
- ViewModels know nothing about Hive or HTTP — only Repositories
- Repositories have abstract interface + concrete implementation
- Swapping Hive → Firebase = only the implementation file changes

---

## New Dependencies to Add

```yaml
# pubspec.yaml additions
hive_flutter: ^1.1.0          # Local DB (custom recipes, inventory, stop-list)
hive: ^2.2.3
hive_generator: ^2.0.1        # Code generation for model adapters
build_runner: ^2.4.9          # Runs hive_generator
intl: ^0.19.0                 # i18n string formatting
flutter_localizations:        # Built into Flutter SDK — just enable it
  sdk: flutter
```

---

## i18n Strategy

**Why infrastructure now:**
Adding i18n later = touching every single file that has a text string.
Adding it now = 2 hours of setup, then just write strings in ARB files normally.

**How it works:**
1. Every text string lives in `app_en.arb` (English is the base language)
2. Russian and Romanian ARB files are created empty now, filled by translator later
3. Language stored in SharedPreferences, changeable in Settings screen
4. No translation needed to continue development — just write English

**Example ARB file:**
```json
// lib/core/l10n/app_en.arb
{
  "appTitle": "Cocktails",
  "tabHome": "Home",
  "tabSearch": "Search",
  "tabFavorites": "Favorites",
  "tabBarManager": "Bar Manager",
  "stopListTitle": "Stop List",
  "inventoryTitle": "Inventory"
}
```

---

## Pro Feature Gating

Simple wrapper — today it's a local flag, later it's a real subscription:

```dart
// core/services/pro_service.dart
class ProService extends ChangeNotifier {
  bool get isPro => _prefs.getBool('is_pro') ?? false;

  // Called when user buys subscription (or for testing)
  Future<void> activate() async { ... notifyListeners(); }
}
```

Every Pro screen checks:
```dart
if (!context.read<ProService>().isPro) {
  showUpgradeDialog(context);
  return;
}
```

---

## Bottom Navigation (updated shell)

| Tab | Screen | Pro? |
|---|---|---|
| Home | Random cocktail | Free |
| Search | Debounced search | Free |
| Favorites | Saved cocktails | Free |
| Bar | Bar Manager hub | Pro |
| Settings | Language + subscription | Free |

---

## Build Order (phases)

**Phase 1 — Infrastructure (no visible features yet)**
1. Add Hive + intl to pubspec.yaml
2. Create HiveService (init + box names)
3. Create models with HiveType annotations (custom_recipe, inventory_item, stop_item, cost_entry)
4. Create abstract repository interfaces + Hive implementations
5. Create ProService
6. Set up i18n: ARB files + MaterialApp localizationsDelegates
7. Update MultiProvider in main.dart with all new repositories

**Phase 2 — Bar Manager features (one by one)**
8. Stop List screen
9. Inventory screen
10. "What can I make?" screen
11. Custom Recipes (list + add/edit)
12. Cost Calculator
13. Event Calculator

**Phase 3 — Settings + i18n**
14. Settings screen (language picker, pro status, about)
15. Fill Russian ARB file
16. Fill Romanian ARB file

---

## When ready to add backend (no screen rewrites needed)

Replace only the implementation files:
- `InventoryRepositoryHive` → `InventoryRepositoryFirestore`
- `CustomRecipeRepositoryHive` → `CustomRecipeRepositoryFirestore`
- `ProService.isPro` → RevenueCat entitlement check
- Add `AuthService` + login screen
- MultiProvider in main.dart updated — screens unchanged
