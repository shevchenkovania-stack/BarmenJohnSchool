// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Коктейли';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabSearch => 'Поиск';

  @override
  String get tabFavorites => 'Избранное';

  @override
  String get tabBar => 'Бар';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get homeSubtitle => 'Найди свой следующий коктейль';

  @override
  String get homeSectionLabel => 'КОКТЕЙЛЬ МОМЕНТА';

  @override
  String get homeViewRecipe => 'Открыть рецепт';

  @override
  String get homeBrowseAll => 'Все коктейли';

  @override
  String get homeLoadError => 'Не удалось загрузить коктейль';

  @override
  String get searchAppBarTitle => 'Поиск';

  @override
  String get searchInputHint => 'Название коктейля...';

  @override
  String searchNoResults(String query) {
    return 'Ничего не найдено для \"$query\"';
  }

  @override
  String get searchPlaceholderText => 'Введите название для поиска';

  @override
  String get searchPlaceholderHint => 'напр. Margarita, Mojito, Negroni';

  @override
  String get favoritesTitle => 'Избранное';

  @override
  String get favoritesEmpty => 'Избранное пусто';

  @override
  String get favoritesEmptyHint =>
      'Нажмите ♥ на любой коктейль чтобы сохранить';

  @override
  String get detailIngredients => 'Ингредиенты';

  @override
  String get detailInstructions => 'Приготовление';

  @override
  String get cocktailListTitle => 'Все коктейли';

  @override
  String get cocktailListFilterHint => 'Фильтр по названию...';

  @override
  String get cocktailListEmpty => 'Коктейли не найдены';

  @override
  String cocktailListLoadingCount(int count) {
    return 'Загружено $count коктейлей';
  }

  @override
  String get barTitle => 'Управление баром';

  @override
  String get stopListTitle => 'Стоп-лист';

  @override
  String get stopListSubtitle => 'Чего нет сегодня';

  @override
  String get stopListEmpty => 'Стоп-лист пуст';

  @override
  String get stopListEmptyHint =>
      'Добавьте ингредиенты которые закончились сегодня';

  @override
  String get stopListAddHint => 'Название ингредиента...';

  @override
  String get stopListClearAll => 'Очистить всё';

  @override
  String get inventoryTitle => 'Инвентарь';

  @override
  String get inventorySubtitle => 'Что есть на баре';

  @override
  String get inventoryEmpty => 'Инвентарь пуст';

  @override
  String get inventoryEmptyHint => 'Добавьте ингредиенты вашего бара';

  @override
  String get inventoryAddHint => 'Название ингредиента...';

  @override
  String get inventorySearchHint => 'Поиск ингредиентов...';

  @override
  String get inventoryLoadingCatalog => 'Загрузка каталога ингредиентов...';

  @override
  String get inventoryNoCatalog => 'Каталог ещё не загружен';

  @override
  String get inventoryNoCatalogHint => 'Подождите пока загружается база';

  @override
  String inventorySelected(int count) {
    return '$count в наличии';
  }

  @override
  String get inventoryTabCatalog => 'Каталог';

  @override
  String get inventoryTabCustom => 'Свои';

  @override
  String get inventoryAddCustom => 'Добавить свой ингредиент';

  @override
  String get dashboardTitle => 'Дашборд';

  @override
  String get recipeModeSection => 'Режим рецептов';

  @override
  String get recipeModeStarter => '🔰 Стажёр';

  @override
  String get recipeModeExpert => '🏆 Эксперт';

  @override
  String get recipeModeDesc => 'Выберите режим по умолчанию';

  @override
  String get canMakeTitle => 'Могу приготовить';

  @override
  String get canMakeSubtitle => 'На основе инвентаря';

  @override
  String get canMakeEmpty => 'Нет подходящих коктейлей';

  @override
  String get canMakeEmptyHint => 'Сначала добавьте ингредиенты в инвентарь';

  @override
  String get canMakeLoading => 'Загрузка базы коктейлей...';

  @override
  String get myRecipesTitle => 'Мои рецепты';

  @override
  String get myRecipesSubtitle => 'Фирменные коктейли заведения';

  @override
  String get myRecipesEmpty => 'Нет рецептов';

  @override
  String get myRecipesEmptyHint => 'Добавьте фирменные коктейли вашего бара';

  @override
  String get addRecipeTitle => 'Новый рецепт';

  @override
  String get editRecipeTitle => 'Редактировать рецепт';

  @override
  String get recipeNameHint => 'Название коктейля';

  @override
  String get recipeGlassHint => 'Вид стакана (напр. Мартини)';

  @override
  String get recipeInstructionsHint => 'Пошаговое приготовление...';

  @override
  String get recipeIngredientHint => 'Ингредиент';

  @override
  String get recipeMeasureHint => 'Количество (напр. 50 мл)';

  @override
  String get addIngredientRow => 'Добавить ингредиент';

  @override
  String get recipeIngredientsSection => 'Ингредиенты';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguageSection => 'Язык';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionDelete => 'Удалить';

  @override
  String get actionAdd => 'Добавить';

  @override
  String get actionRetry => 'Повторить';

  @override
  String get actionConfirmDelete => 'Удалить этот элемент?';

  @override
  String get menuBuilderTitle => 'Конструктор меню';

  @override
  String get menuBuilderSubtitle => 'Создайте печатное меню';

  @override
  String get menuBuilderEmpty => 'Нет избранных коктейлей';

  @override
  String get menuBuilderEmptyHint => 'Сначала добавьте коктейли в Избранное';

  @override
  String get menuBuilderVenueHint => 'Название бара / ресторана';

  @override
  String get menuBuilderSelectAll => 'Выбрать все';

  @override
  String get menuBuilderDeselectAll => 'Снять все';

  @override
  String get menuBuilderPreview => 'Предпросмотр PDF';

  @override
  String get menuBuilderPrint => 'Печать';

  @override
  String get menuBuilderThemeClassic => 'Классика';

  @override
  String get menuBuilderThemeModern => 'Модерн';

  @override
  String get menuBuilderThemeMinimal => 'Минимализм';

  @override
  String menuBuilderSelected(int count) {
    return '$count коктейлей выбрано';
  }

  @override
  String get priceBookTitle => 'Прайс-лист';

  @override
  String get priceBookSubtitle => 'Себестоимость ингредиентов';

  @override
  String get priceBookEmpty => 'Прайс-лист пуст';

  @override
  String get priceBookEmptyHint =>
      'Добавьте цены ингредиентов чтобы считать себестоимость';

  @override
  String get priceBookAddTitle => 'Добавить цену';

  @override
  String get priceBookEditTitle => 'Редактировать цену';

  @override
  String get priceBookIngredientHint =>
      'Название ингредиента (напр. Ron Barcelo)';

  @override
  String get priceBookBottlePriceHint => 'Цена бутылки (напр. 25)';

  @override
  String get priceBookBottlePriceLabel => 'Цена бутылки';

  @override
  String get priceBookBottleSizeHint => 'Объём бутылки мл (напр. 700)';

  @override
  String get priceBookBottleSizeLabel => 'Объём мл';

  @override
  String get priceBookCurrencyHint => 'Валюта (напр. \$)';

  @override
  String get priceBookCurrencyLabel => 'Валюта';

  @override
  String get priceBookPerMl => 'за мл';

  @override
  String get recipeCostSection => 'Себестоимость';

  @override
  String get recipeCostNotAvailable =>
      'Добавьте цены в Прайс-лист чтобы увидеть себестоимость';

  @override
  String get recipeCostTotal => 'Себестоимость коктейля';

  @override
  String get recipeCostSelling => 'Цена продажи';

  @override
  String get recipeCostMargin => 'Маржа';

  @override
  String get recipeCostSellingHint => '0.00';

  @override
  String get kioskTitle => 'Цифровое меню';

  @override
  String get kioskSubtitle => 'Интерактивное меню для гостей на планшете';

  @override
  String get kioskSetupTitle => 'Настройка киоска';

  @override
  String get kioskSetupHint => 'Выберите коктейли и укажите цены для гостей';

  @override
  String get kioskLaunch => 'Запустить киоск';

  @override
  String get kioskSave => 'Сохранить настройки';

  @override
  String get kioskExitTitle => 'Выйти из киоска?';

  @override
  String get kioskExitMessage => 'Гости больше не увидят меню на этом экране.';

  @override
  String get kioskExitConfirm => 'Выйти';

  @override
  String get kioskFilterAll => 'Все';

  @override
  String get kioskFilterAlcoholic => 'Алкагольные';

  @override
  String get kioskFilterNonAlcoholic => 'Безалкагольные';

  @override
  String get kioskEmpty => 'Нет коктейлей в меню';

  @override
  String get kioskEmptyHint => 'Вернитесь и выберите коктейли для киоска';

  @override
  String kioskCocktailCount(int count) {
    return '$count коктейлей';
  }

  @override
  String get kioskPriceCurrency => 'MDL';

  @override
  String get kioskCurrencyLabel => 'Валюта';

  @override
  String get kioskSelectCocktail => 'Выберите хотя бы один коктейль';

  @override
  String get kioskVenueHint => 'Бар Алхимия';

  @override
  String get aiRecipeModeStarter => '🔰 Новичок';

  @override
  String get aiRecipeModeExpert => '🏆 Эксперт';

  @override
  String get aiRecipeLoading => 'AI готовит твой рецепт...';

  @override
  String get aiRecipeError => 'Не удалось загрузить рецепт AI';

  @override
  String get aiRecipeTryAgain => 'Попробовать снова';

  @override
  String get aiRecipeBasicInstructions => 'Базовые инструкции';

  @override
  String get aiRecipePreparation => 'Подготовка';

  @override
  String get aiRecipeToolsNeeded => 'Нужный инвентарь';

  @override
  String get aiRecipeCommonMistakes => 'Частые ошибки';

  @override
  String get aiRecipeProTips => 'Советы профи';

  @override
  String get aiRecipeHistory => 'История';

  @override
  String get aiRecipeTechniques => 'Техники';

  @override
  String get aiRecipePremiumIngredients => 'Премиальные рекомендации';

  @override
  String get aiRecipeProSecrets => 'Секреты шефа';

  @override
  String get aiRecipeVariations => 'Вариации';

  @override
  String get aiRecipeFoodPairing => 'Гастропара';

  @override
  String get aiRecipeCostBreakdown => 'Расчёт себестоимости';

  @override
  String get aiRecipeEstimatedCost => 'Себестоимость';

  @override
  String get aiRecipeSuggestedPrice => 'Цена продажи';

  @override
  String get aiRecipeStartTimer => 'Запустить таймер';

  @override
  String aiRecipeStepOf(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get modeSchool => 'ШКОЛА БАРМЕНА';

  @override
  String get modeSchoolSubtitle => 'Уроки • Квизы • XP • Диплом';

  @override
  String get modeCocktails => 'БАЗА КОКТЕЛЕЙ';

  @override
  String get modeCocktailsSubtitle => '300+ рецептов • Поиск • Избранное';

  @override
  String get modeMyBar => 'МОЙ БАР';

  @override
  String get modeMyBarSubtitle => 'Конструктор • Инвентарь • Свои рецепты';
}
