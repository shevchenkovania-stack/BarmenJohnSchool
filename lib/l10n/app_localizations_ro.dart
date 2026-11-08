// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get appTitle => 'Cocktailuri';

  @override
  String get tabHome => 'Acasă';

  @override
  String get tabSearch => 'Căutare';

  @override
  String get tabFavorites => 'Favorite';

  @override
  String get tabBar => 'Bar';

  @override
  String get tabSettings => 'Setări';

  @override
  String get homeSubtitle => 'Descoperă-ți următorul cocktail';

  @override
  String get homeSectionLabel => 'COCKTAILUL MOMENTULUI';

  @override
  String get homeViewRecipe => 'Vezi rețeta';

  @override
  String get homeBrowseAll => 'Toate cocktailurile';

  @override
  String get homeLoadError => 'Nu s-a putut încărca cocktailul';

  @override
  String get searchAppBarTitle => 'Căutare';

  @override
  String get searchInputHint => 'Numele cocktailului...';

  @override
  String searchNoResults(String query) {
    return 'Niciun rezultat pentru \"$query\"';
  }

  @override
  String get searchPlaceholderText => 'Tastează un nume pentru a căuta';

  @override
  String get searchPlaceholderHint => 'ex. Margarita, Mojito, Negroni';

  @override
  String get favoritesTitle => 'Favorite';

  @override
  String get favoritesEmpty => 'Nicio preferată';

  @override
  String get favoritesEmptyHint => 'Apasă ♥ pe orice cocktail pentru a salva';

  @override
  String get detailIngredients => 'Ingrediente';

  @override
  String get detailInstructions => 'Preparare';

  @override
  String get cocktailListTitle => 'Toate cocktailurile';

  @override
  String get cocktailListFilterHint => 'Filtrează după nume...';

  @override
  String get cocktailListEmpty => 'Nu s-au găsit cocktailuri';

  @override
  String cocktailListLoadingCount(int count) {
    return 'Încărcat $count cocktailuri';
  }

  @override
  String get barTitle => 'Managementul barului';

  @override
  String get stopListTitle => 'Stop-list';

  @override
  String get stopListSubtitle => 'Indisponibil azi';

  @override
  String get stopListEmpty => 'Stop-list gol';

  @override
  String get stopListEmptyHint => 'Adaugă ingredientele terminate azi';

  @override
  String get stopListAddHint => 'Numele ingredientului...';

  @override
  String get stopListClearAll => 'Curăță tot';

  @override
  String get inventoryTitle => 'Inventar';

  @override
  String get inventorySubtitle => 'Ce aveți în stoc';

  @override
  String get inventoryEmpty => 'Inventar gol';

  @override
  String get inventoryEmptyHint => 'Adaugă ingredientele disponibile la bar';

  @override
  String get inventoryAddHint => 'Numele ingredientului...';

  @override
  String get inventorySearchHint => 'Caută ingrediente...';

  @override
  String get inventoryLoadingCatalog =>
      'Se încarcă catalogul de ingrediente...';

  @override
  String get inventoryNoCatalog => 'Catalogul nu este încărcat';

  @override
  String get inventoryNoCatalogHint => 'Așteptați până se încarcă baza de date';

  @override
  String inventorySelected(int count) {
    return '$count în stoc';
  }

  @override
  String get inventoryTabCatalog => 'Catalog';

  @override
  String get inventoryTabCustom => 'Proprii';

  @override
  String get inventoryAddCustom => 'Adaugă ingredient propriu';

  @override
  String get dashboardTitle => 'Panou de control';

  @override
  String get recipeModeSection => 'Mod rețete';

  @override
  String get recipeModeStarter => '🔰 Începător';

  @override
  String get recipeModeExpert => '🏆 Expert';

  @override
  String get recipeModeDesc => 'Selectați modul implicit pentru rețete';

  @override
  String get canMakeTitle => 'Pot prepara acum';

  @override
  String get canMakeSubtitle => 'Bazat pe inventar';

  @override
  String get canMakeEmpty => 'Niciun cocktail potrivit';

  @override
  String get canMakeEmptyHint => 'Adaugă mai întâi ingrediente la inventar';

  @override
  String get canMakeLoading => 'Se încarcă baza de cocktailuri...';

  @override
  String get myRecipesTitle => 'Rețetele mele';

  @override
  String get myRecipesSubtitle => 'Cocktailurile specifice localului';

  @override
  String get myRecipesEmpty => 'Nicio rețetă';

  @override
  String get myRecipesEmptyHint => 'Adaugă cocktailurile specifice barului tău';

  @override
  String get addRecipeTitle => 'Rețetă nouă';

  @override
  String get editRecipeTitle => 'Editează rețeta';

  @override
  String get recipeNameHint => 'Numele cocktailului';

  @override
  String get recipeGlassHint => 'Tip pahar (ex. Martini)';

  @override
  String get recipeInstructionsHint => 'Preparare pas cu pas...';

  @override
  String get recipeIngredientHint => 'Ingredient';

  @override
  String get recipeMeasureHint => 'Cantitate (ex. 50 ml)';

  @override
  String get addIngredientRow => 'Adaugă ingredient';

  @override
  String get recipeIngredientsSection => 'Ingrediente';

  @override
  String get settingsTitle => 'Setări';

  @override
  String get settingsLanguageSection => 'Limbă';

  @override
  String get actionSave => 'Salvează';

  @override
  String get actionCancel => 'Anulează';

  @override
  String get actionDelete => 'Șterge';

  @override
  String get actionAdd => 'Adaugă';

  @override
  String get actionRetry => 'Reîncearcă';

  @override
  String get actionConfirmDelete => 'Șterge acest element?';

  @override
  String get menuBuilderTitle => 'Constructor meniu';

  @override
  String get menuBuilderSubtitle => 'Crează un meniu imprimabil';

  @override
  String get menuBuilderEmpty => 'Niciun favorit pentru meniu';

  @override
  String get menuBuilderEmptyHint => 'Adaugă mai întâi cocktailuri la Favorite';

  @override
  String get menuBuilderVenueHint => 'Numele barului / restaurantului';

  @override
  String get menuBuilderSelectAll => 'Selectează tot';

  @override
  String get menuBuilderDeselectAll => 'Deselectează tot';

  @override
  String get menuBuilderPreview => 'Previzualizare PDF';

  @override
  String get menuBuilderPrint => 'Tipărire';

  @override
  String get menuBuilderThemeClassic => 'Clasic';

  @override
  String get menuBuilderThemeModern => 'Modern';

  @override
  String get menuBuilderThemeMinimal => 'Minimal';

  @override
  String menuBuilderSelected(int count) {
    return '$count cocktailuri selectate';
  }

  @override
  String get priceBookTitle => 'Lista de prețuri';

  @override
  String get priceBookSubtitle => 'Costul ingredientelor';

  @override
  String get priceBookEmpty => 'Lista de prețuri goală';

  @override
  String get priceBookEmptyHint =>
      'Adaugă prețuri pentru a calcula costul cocktailurilor';

  @override
  String get priceBookAddTitle => 'Adaugă preț';

  @override
  String get priceBookEditTitle => 'Editează prețul';

  @override
  String get priceBookIngredientHint =>
      'Numele ingredientului (ex. Ron Barcelo)';

  @override
  String get priceBookBottlePriceHint => 'Prețul sticlei (ex. 25)';

  @override
  String get priceBookBottlePriceLabel => 'Prețul sticlei';

  @override
  String get priceBookBottleSizeHint => 'Volumul sticlei ml (ex. 700)';

  @override
  String get priceBookBottleSizeLabel => 'Volum ml';

  @override
  String get priceBookCurrencyHint => 'Valută (ex. \$)';

  @override
  String get priceBookCurrencyLabel => 'Valută';

  @override
  String get priceBookPerMl => 'pe ml';

  @override
  String get recipeCostSection => 'Calculator cost';

  @override
  String get recipeCostNotAvailable =>
      'Adaugă prețuri în Lista de prețuri pentru a vedea costul';

  @override
  String get recipeCostTotal => 'Costul cocktailului';

  @override
  String get recipeCostSelling => 'Preț de vânzare';

  @override
  String get recipeCostMargin => 'Marja';

  @override
  String get recipeCostSellingHint => '0.00';

  @override
  String get kioskTitle => 'Meniu Digital';

  @override
  String get kioskSubtitle => 'Meniu interactiv pe tabletă pentru oaspeți';

  @override
  String get kioskSetupTitle => 'Configurare Kiosk';

  @override
  String get kioskSetupHint =>
      'Selectați cocktailuri și setați prețurile pentru oaspeți';

  @override
  String get kioskLaunch => 'Lansează Kiosk';

  @override
  String get kioskSave => 'Salvează configurația';

  @override
  String get kioskExitTitle => 'Ieși din Kiosk?';

  @override
  String get kioskExitMessage =>
      'Oaspeții nu vor mai vedea meniul pe acest ecran.';

  @override
  String get kioskExitConfirm => 'Ieși';

  @override
  String get kioskFilterAll => 'Toate';

  @override
  String get kioskFilterAlcoholic => 'Alcoolice';

  @override
  String get kioskFilterNonAlcoholic => 'Nealcoolice';

  @override
  String get kioskEmpty => 'Niciun cocktail în meniu';

  @override
  String get kioskEmptyHint => 'Înapoi și selectați cocktailuri pentru kiosk';

  @override
  String kioskCocktailCount(int count) {
    return '$count cocktailuri';
  }

  @override
  String get kioskPriceCurrency => 'MDL';

  @override
  String get kioskCurrencyLabel => 'Valută';

  @override
  String get kioskSelectCocktail => 'Selectați cel puțin un cocktail';

  @override
  String get kioskVenueHint => 'Bar Alchemy';

  @override
  String get aiRecipeModeStarter => '🔰 Începător';

  @override
  String get aiRecipeModeExpert => '🏆 Expert';

  @override
  String get aiRecipeLoading => 'AI-ul îți pregătește rețeta...';

  @override
  String get aiRecipeError => 'Nu am putut încărca rețeta AI';

  @override
  String get aiRecipeTryAgain => 'Încearcă din nou';

  @override
  String get aiRecipeBasicInstructions => 'Instrucțiuni de bază';

  @override
  String get aiRecipePreparation => 'Pregătire';

  @override
  String get aiRecipeToolsNeeded => 'Unelte necesare';

  @override
  String get aiRecipeCommonMistakes => 'Greșeli frecvente';

  @override
  String get aiRecipeProTips => 'Sfaturi de profesionist';

  @override
  String get aiRecipeHistory => 'Istorie';

  @override
  String get aiRecipeTechniques => 'Tehnici';

  @override
  String get aiRecipePremiumIngredients => 'Recomandări premium';

  @override
  String get aiRecipeProSecrets => 'Secretele bucătarului șef';

  @override
  String get aiRecipeVariations => 'Variațiuni';

  @override
  String get aiRecipeFoodPairing => 'Asociere gastronomică';

  @override
  String get aiRecipeCostBreakdown => 'Calculul costului';

  @override
  String get aiRecipeEstimatedCost => 'Cost estimat';

  @override
  String get aiRecipeSuggestedPrice => 'Preț de vânzare';

  @override
  String get aiRecipeStartTimer => 'Pornește cronometrul';

  @override
  String aiRecipeStepOf(int current, int total) {
    return 'Pasul $current din $total';
  }

  @override
  String get modeSchool => 'ȘCOALA BARTENDER';

  @override
  String get modeSchoolSubtitle => 'Lecții • Quiz • XP • Diplomă';

  @override
  String get modeCocktails => 'BAZA DE COCKTAILURI';

  @override
  String get modeCocktailsSubtitle => '300+ rețete • Căutare • Favorite';

  @override
  String get modeMyBar => 'BARUL MEU';

  @override
  String get modeMyBarSubtitle => 'Constructor • Inventar • Rețete proprii';
}
