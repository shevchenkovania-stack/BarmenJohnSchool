// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cocktails';

  @override
  String get tabHome => 'Home';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabFavorites => 'Favorites';

  @override
  String get tabBar => 'Bar';

  @override
  String get tabSettings => 'Settings';

  @override
  String get homeSubtitle => 'Discover your next drink';

  @override
  String get homeSectionLabel => 'COCKTAIL OF THE MOMENT';

  @override
  String get homeViewRecipe => 'View Recipe';

  @override
  String get homeBrowseAll => 'Browse all cocktails';

  @override
  String get homeLoadError => 'Could not load cocktail';

  @override
  String get searchAppBarTitle => 'Search';

  @override
  String get searchInputHint => 'Cocktail name...';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchPlaceholderText => 'Type a cocktail name to search';

  @override
  String get searchPlaceholderHint => 'e.g. Margarita, Mojito, Negroni';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmpty => 'No favorites yet';

  @override
  String get favoritesEmptyHint => 'Tap ♥ on any cocktail to save it here';

  @override
  String get detailIngredients => 'Ingredients';

  @override
  String get detailInstructions => 'Instructions';

  @override
  String get cocktailListTitle => 'All Cocktails';

  @override
  String get cocktailListFilterHint => 'Filter by name...';

  @override
  String get cocktailListEmpty => 'No cocktails found';

  @override
  String cocktailListLoadingCount(int count) {
    return 'Loading... $count cocktails so far';
  }

  @override
  String get barTitle => 'Bar Manager';

  @override
  String get stopListTitle => 'Stop List';

  @override
  String get stopListSubtitle => 'Unavailable today';

  @override
  String get stopListEmpty => 'Stop list is empty';

  @override
  String get stopListEmptyHint => 'Add ingredients that ran out today';

  @override
  String get stopListAddHint => 'Ingredient name...';

  @override
  String get stopListClearAll => 'Clear All';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get inventorySubtitle => 'What you have in stock';

  @override
  String get inventoryEmpty => 'Inventory is empty';

  @override
  String get inventoryEmptyHint => 'Add ingredients available at your bar';

  @override
  String get inventoryAddHint => 'Ingredient name...';

  @override
  String get inventorySearchHint => 'Search ingredients...';

  @override
  String get inventoryLoadingCatalog => 'Loading ingredient catalog...';

  @override
  String get inventoryNoCatalog => 'Catalog not loaded yet';

  @override
  String get inventoryNoCatalogHint => 'Wait a moment while the database loads';

  @override
  String inventorySelected(int count) {
    return '$count in stock';
  }

  @override
  String get inventoryTabCatalog => 'Catalog';

  @override
  String get inventoryTabCustom => 'Custom';

  @override
  String get inventoryAddCustom => 'Add custom ingredient';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get recipeModeSection => 'Recipe Mode';

  @override
  String get recipeModeStarter => '🔰 Starter';

  @override
  String get recipeModeExpert => '🏆 Expert';

  @override
  String get recipeModeDesc => 'Select default mode for recipes';

  @override
  String get canMakeTitle => 'Can Make Now';

  @override
  String get canMakeSubtitle => 'Based on your inventory';

  @override
  String get canMakeEmpty => 'No cocktails match your inventory';

  @override
  String get canMakeEmptyHint => 'Add ingredients to inventory first';

  @override
  String get canMakeLoading => 'Loading cocktail database...';

  @override
  String get myRecipesTitle => 'My Recipes';

  @override
  String get myRecipesSubtitle => 'Your bar\'s signature cocktails';

  @override
  String get myRecipesEmpty => 'No recipes yet';

  @override
  String get myRecipesEmptyHint => 'Add your bar\'s signature cocktails';

  @override
  String get addRecipeTitle => 'New Recipe';

  @override
  String get editRecipeTitle => 'Edit Recipe';

  @override
  String get recipeNameHint => 'Cocktail name';

  @override
  String get recipeGlassHint => 'Glass type (e.g. Martini glass)';

  @override
  String get recipeInstructionsHint => 'Step-by-step preparation...';

  @override
  String get recipeIngredientHint => 'Ingredient';

  @override
  String get recipeMeasureHint => 'Amount (e.g. 50 ml)';

  @override
  String get addIngredientRow => 'Add ingredient';

  @override
  String get recipeIngredientsSection => 'Ingredients';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionConfirmDelete => 'Delete this item?';

  @override
  String get menuBuilderTitle => 'Menu Builder';

  @override
  String get menuBuilderSubtitle => 'Create a printable menu';

  @override
  String get menuBuilderEmpty => 'No favorites to build a menu';

  @override
  String get menuBuilderEmptyHint => 'Add cocktails to Favorites first';

  @override
  String get menuBuilderVenueHint => 'Bar / Restaurant name';

  @override
  String get menuBuilderSelectAll => 'Select all';

  @override
  String get menuBuilderDeselectAll => 'Deselect all';

  @override
  String get menuBuilderPreview => 'Preview PDF';

  @override
  String get menuBuilderPrint => 'Print';

  @override
  String get menuBuilderThemeClassic => 'Classic';

  @override
  String get menuBuilderThemeModern => 'Modern';

  @override
  String get menuBuilderThemeMinimal => 'Minimal';

  @override
  String menuBuilderSelected(int count) {
    return '$count cocktails selected';
  }

  @override
  String get priceBookTitle => 'Price Book';

  @override
  String get priceBookSubtitle => 'Ingredient costs';

  @override
  String get priceBookEmpty => 'No prices yet';

  @override
  String get priceBookEmptyHint =>
      'Add ingredient prices to calculate cocktail costs';

  @override
  String get priceBookAddTitle => 'Add Ingredient Price';

  @override
  String get priceBookEditTitle => 'Edit Price';

  @override
  String get priceBookIngredientHint => 'Ingredient name (e.g. Ron Barcelo)';

  @override
  String get priceBookBottlePriceHint => 'Bottle price (e.g. 25)';

  @override
  String get priceBookBottlePriceLabel => 'Bottle price';

  @override
  String get priceBookBottleSizeHint => 'Bottle size ml (e.g. 700)';

  @override
  String get priceBookBottleSizeLabel => 'Volume ml';

  @override
  String get priceBookCurrencyHint => 'Currency (e.g. \$)';

  @override
  String get priceBookCurrencyLabel => 'Currency';

  @override
  String get priceBookPerMl => 'per ml';

  @override
  String get recipeCostSection => 'Cost Calculator';

  @override
  String get recipeCostNotAvailable =>
      'Add ingredient prices in Price Book to see cost';

  @override
  String get recipeCostTotal => 'Cost per cocktail';

  @override
  String get recipeCostSelling => 'Selling price';

  @override
  String get recipeCostMargin => 'Margin';

  @override
  String get recipeCostSellingHint => '0.00';

  @override
  String get kioskTitle => 'Digital Menu';

  @override
  String get kioskSubtitle => 'Interactive tablet menu for guests';

  @override
  String get kioskSetupTitle => 'Kiosk Setup';

  @override
  String get kioskSetupHint => 'Select cocktails and set guest-facing prices';

  @override
  String get kioskLaunch => 'Launch Kiosk';

  @override
  String get kioskSave => 'Save Setup';

  @override
  String get kioskExitTitle => 'Exit Kiosk?';

  @override
  String get kioskExitMessage =>
      'Guests will no longer see the menu on this screen.';

  @override
  String get kioskExitConfirm => 'Exit';

  @override
  String get kioskFilterAll => 'All';

  @override
  String get kioskFilterAlcoholic => 'Alcoholic';

  @override
  String get kioskFilterNonAlcoholic => 'Non-Alcoholic';

  @override
  String get kioskEmpty => 'No cocktails in menu';

  @override
  String get kioskEmptyHint => 'Go back and select cocktails for the kiosk';

  @override
  String kioskCocktailCount(int count) {
    return '$count cocktails';
  }

  @override
  String get kioskPriceCurrency => 'MDL';

  @override
  String get kioskCurrencyLabel => 'Currency';

  @override
  String get kioskSelectCocktail => 'Select at least one cocktail';

  @override
  String get kioskVenueHint => 'Bar Alchemy';

  @override
  String get aiRecipeModeStarter => '🔰 Starter';

  @override
  String get aiRecipeModeExpert => '🏆 Expert';

  @override
  String get aiRecipeLoading => 'AI is preparing your recipe...';

  @override
  String get aiRecipeError => 'Failed to load AI recipe';

  @override
  String get aiRecipeTryAgain => 'Try Again';

  @override
  String get aiRecipeBasicInstructions => 'Basic Instructions';

  @override
  String get aiRecipePreparation => 'Preparation';

  @override
  String get aiRecipeToolsNeeded => 'Tools Needed';

  @override
  String get aiRecipeCommonMistakes => 'Common Mistakes';

  @override
  String get aiRecipeProTips => 'Pro Tips';

  @override
  String get aiRecipeHistory => 'History';

  @override
  String get aiRecipeTechniques => 'Techniques';

  @override
  String get aiRecipePremiumIngredients => 'Premium Recommendations';

  @override
  String get aiRecipeProSecrets => 'Chef Secrets';

  @override
  String get aiRecipeVariations => 'Variations';

  @override
  String get aiRecipeFoodPairing => 'Food Pairing';

  @override
  String get aiRecipeCostBreakdown => 'Cost Breakdown';

  @override
  String get aiRecipeEstimatedCost => 'Estimated Cost';

  @override
  String get aiRecipeSuggestedPrice => 'Selling Price';

  @override
  String get aiRecipeStartTimer => 'Start Timer';

  @override
  String aiRecipeStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get modeSchool => 'BARTENDER SCHOOL';

  @override
  String get modeSchoolSubtitle => 'Lessons • Quizzes • XP • Diploma';

  @override
  String get modeCocktails => 'COCKTAIL BASE';

  @override
  String get modeCocktailsSubtitle => '300+ recipes • Search • Favorites';

  @override
  String get modeMyBar => 'MY BAR';

  @override
  String get modeMyBarSubtitle => 'Constructor • Inventory • Custom recipes';
}
