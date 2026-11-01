import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ro'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cocktails'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @tabBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get tabBar;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover your next drink'**
  String get homeSubtitle;

  /// No description provided for @homeSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'COCKTAIL OF THE MOMENT'**
  String get homeSectionLabel;

  /// No description provided for @homeViewRecipe.
  ///
  /// In en, this message translates to:
  /// **'View Recipe'**
  String get homeViewRecipe;

  /// No description provided for @homeBrowseAll.
  ///
  /// In en, this message translates to:
  /// **'Browse all cocktails'**
  String get homeBrowseAll;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load cocktail'**
  String get homeLoadError;

  /// No description provided for @searchAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAppBarTitle;

  /// No description provided for @searchInputHint.
  ///
  /// In en, this message translates to:
  /// **'Cocktail name...'**
  String get searchInputHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @searchPlaceholderText.
  ///
  /// In en, this message translates to:
  /// **'Type a cocktail name to search'**
  String get searchPlaceholderText;

  /// No description provided for @searchPlaceholderHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Margarita, Mojito, Negroni'**
  String get searchPlaceholderHint;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap ♥ on any cocktail to save it here'**
  String get favoritesEmptyHint;

  /// No description provided for @detailIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get detailIngredients;

  /// No description provided for @detailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get detailInstructions;

  /// No description provided for @cocktailListTitle.
  ///
  /// In en, this message translates to:
  /// **'All Cocktails'**
  String get cocktailListTitle;

  /// No description provided for @cocktailListFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by name...'**
  String get cocktailListFilterHint;

  /// No description provided for @cocktailListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cocktails found'**
  String get cocktailListEmpty;

  /// No description provided for @cocktailListLoadingCount.
  ///
  /// In en, this message translates to:
  /// **'Loading... {count} cocktails so far'**
  String cocktailListLoadingCount(int count);

  /// No description provided for @barTitle.
  ///
  /// In en, this message translates to:
  /// **'Bar Manager'**
  String get barTitle;

  /// No description provided for @stopListTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop List'**
  String get stopListTitle;

  /// No description provided for @stopListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unavailable today'**
  String get stopListSubtitle;

  /// No description provided for @stopListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Stop list is empty'**
  String get stopListEmpty;

  /// No description provided for @stopListEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients that ran out today'**
  String get stopListEmptyHint;

  /// No description provided for @stopListAddHint.
  ///
  /// In en, this message translates to:
  /// **'Ingredient name...'**
  String get stopListAddHint;

  /// No description provided for @stopListClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get stopListClearAll;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @inventorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'What you have in stock'**
  String get inventorySubtitle;

  /// No description provided for @inventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Inventory is empty'**
  String get inventoryEmpty;

  /// No description provided for @inventoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients available at your bar'**
  String get inventoryEmptyHint;

  /// No description provided for @inventoryAddHint.
  ///
  /// In en, this message translates to:
  /// **'Ingredient name...'**
  String get inventoryAddHint;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search ingredients...'**
  String get inventorySearchHint;

  /// No description provided for @inventoryLoadingCatalog.
  ///
  /// In en, this message translates to:
  /// **'Loading ingredient catalog...'**
  String get inventoryLoadingCatalog;

  /// No description provided for @inventoryNoCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog not loaded yet'**
  String get inventoryNoCatalog;

  /// No description provided for @inventoryNoCatalogHint.
  ///
  /// In en, this message translates to:
  /// **'Wait a moment while the database loads'**
  String get inventoryNoCatalogHint;

  /// No description provided for @inventorySelected.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String inventorySelected(int count);

  /// No description provided for @inventoryTabCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get inventoryTabCatalog;

  /// No description provided for @inventoryTabCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get inventoryTabCustom;

  /// No description provided for @inventoryAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add custom ingredient'**
  String get inventoryAddCustom;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @recipeModeSection.
  ///
  /// In en, this message translates to:
  /// **'Recipe Mode'**
  String get recipeModeSection;

  /// No description provided for @recipeModeStarter.
  ///
  /// In en, this message translates to:
  /// **'🔰 Starter'**
  String get recipeModeStarter;

  /// No description provided for @recipeModeExpert.
  ///
  /// In en, this message translates to:
  /// **'🏆 Expert'**
  String get recipeModeExpert;

  /// No description provided for @recipeModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Select default mode for recipes'**
  String get recipeModeDesc;

  /// No description provided for @canMakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Can Make Now'**
  String get canMakeTitle;

  /// No description provided for @canMakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on your inventory'**
  String get canMakeSubtitle;

  /// No description provided for @canMakeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cocktails match your inventory'**
  String get canMakeEmpty;

  /// No description provided for @canMakeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients to inventory first'**
  String get canMakeEmptyHint;

  /// No description provided for @canMakeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading cocktail database...'**
  String get canMakeLoading;

  /// No description provided for @myRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Recipes'**
  String get myRecipesTitle;

  /// No description provided for @myRecipesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your bar\'s signature cocktails'**
  String get myRecipesSubtitle;

  /// No description provided for @myRecipesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet'**
  String get myRecipesEmpty;

  /// No description provided for @myRecipesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add your bar\'s signature cocktails'**
  String get myRecipesEmptyHint;

  /// No description provided for @addRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'New Recipe'**
  String get addRecipeTitle;

  /// No description provided for @editRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Recipe'**
  String get editRecipeTitle;

  /// No description provided for @recipeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Cocktail name'**
  String get recipeNameHint;

  /// No description provided for @recipeGlassHint.
  ///
  /// In en, this message translates to:
  /// **'Glass type (e.g. Martini glass)'**
  String get recipeGlassHint;

  /// No description provided for @recipeInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step preparation...'**
  String get recipeInstructionsHint;

  /// No description provided for @recipeIngredientHint.
  ///
  /// In en, this message translates to:
  /// **'Ingredient'**
  String get recipeIngredientHint;

  /// No description provided for @recipeMeasureHint.
  ///
  /// In en, this message translates to:
  /// **'Amount (e.g. 50 ml)'**
  String get recipeMeasureHint;

  /// No description provided for @addIngredientRow.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient'**
  String get addIngredientRow;

  /// No description provided for @recipeIngredientsSection.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeIngredientsSection;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get actionConfirmDelete;

  /// No description provided for @menuBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu Builder'**
  String get menuBuilderTitle;

  /// No description provided for @menuBuilderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a printable menu'**
  String get menuBuilderSubtitle;

  /// No description provided for @menuBuilderEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites to build a menu'**
  String get menuBuilderEmpty;

  /// No description provided for @menuBuilderEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add cocktails to Favorites first'**
  String get menuBuilderEmptyHint;

  /// No description provided for @menuBuilderVenueHint.
  ///
  /// In en, this message translates to:
  /// **'Bar / Restaurant name'**
  String get menuBuilderVenueHint;

  /// No description provided for @menuBuilderSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get menuBuilderSelectAll;

  /// No description provided for @menuBuilderDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get menuBuilderDeselectAll;

  /// No description provided for @menuBuilderPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview PDF'**
  String get menuBuilderPreview;

  /// No description provided for @menuBuilderPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get menuBuilderPrint;

  /// No description provided for @menuBuilderThemeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get menuBuilderThemeClassic;

  /// No description provided for @menuBuilderThemeModern.
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get menuBuilderThemeModern;

  /// No description provided for @menuBuilderThemeMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get menuBuilderThemeMinimal;

  /// No description provided for @menuBuilderSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} cocktails selected'**
  String menuBuilderSelected(int count);

  /// No description provided for @priceBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Price Book'**
  String get priceBookTitle;

  /// No description provided for @priceBookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredient costs'**
  String get priceBookSubtitle;

  /// No description provided for @priceBookEmpty.
  ///
  /// In en, this message translates to:
  /// **'No prices yet'**
  String get priceBookEmpty;

  /// No description provided for @priceBookEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient prices to calculate cocktail costs'**
  String get priceBookEmptyHint;

  /// No description provided for @priceBookAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient Price'**
  String get priceBookAddTitle;

  /// No description provided for @priceBookEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Price'**
  String get priceBookEditTitle;

  /// No description provided for @priceBookIngredientHint.
  ///
  /// In en, this message translates to:
  /// **'Ingredient name (e.g. Ron Barcelo)'**
  String get priceBookIngredientHint;

  /// No description provided for @priceBookBottlePriceHint.
  ///
  /// In en, this message translates to:
  /// **'Bottle price (e.g. 25)'**
  String get priceBookBottlePriceHint;

  /// No description provided for @priceBookBottlePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Bottle price'**
  String get priceBookBottlePriceLabel;

  /// No description provided for @priceBookBottleSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Bottle size ml (e.g. 700)'**
  String get priceBookBottleSizeHint;

  /// No description provided for @priceBookBottleSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume ml'**
  String get priceBookBottleSizeLabel;

  /// No description provided for @priceBookCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Currency (e.g. \$)'**
  String get priceBookCurrencyHint;

  /// No description provided for @priceBookCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get priceBookCurrencyLabel;

  /// No description provided for @priceBookPerMl.
  ///
  /// In en, this message translates to:
  /// **'per ml'**
  String get priceBookPerMl;

  /// No description provided for @recipeCostSection.
  ///
  /// In en, this message translates to:
  /// **'Cost Calculator'**
  String get recipeCostSection;

  /// No description provided for @recipeCostNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Add ingredient prices in Price Book to see cost'**
  String get recipeCostNotAvailable;

  /// No description provided for @recipeCostTotal.
  ///
  /// In en, this message translates to:
  /// **'Cost per cocktail'**
  String get recipeCostTotal;

  /// No description provided for @recipeCostSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling price'**
  String get recipeCostSelling;

  /// No description provided for @recipeCostMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get recipeCostMargin;

  /// No description provided for @recipeCostSellingHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get recipeCostSellingHint;

  /// No description provided for @kioskTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Menu'**
  String get kioskTitle;

  /// No description provided for @kioskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive tablet menu for guests'**
  String get kioskSubtitle;

  /// No description provided for @kioskSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Kiosk Setup'**
  String get kioskSetupTitle;

  /// No description provided for @kioskSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Select cocktails and set guest-facing prices'**
  String get kioskSetupHint;

  /// No description provided for @kioskLaunch.
  ///
  /// In en, this message translates to:
  /// **'Launch Kiosk'**
  String get kioskLaunch;

  /// No description provided for @kioskSave.
  ///
  /// In en, this message translates to:
  /// **'Save Setup'**
  String get kioskSave;

  /// No description provided for @kioskExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Kiosk?'**
  String get kioskExitTitle;

  /// No description provided for @kioskExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Guests will no longer see the menu on this screen.'**
  String get kioskExitMessage;

  /// No description provided for @kioskExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get kioskExitConfirm;

  /// No description provided for @kioskFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get kioskFilterAll;

  /// No description provided for @kioskFilterAlcoholic.
  ///
  /// In en, this message translates to:
  /// **'Alcoholic'**
  String get kioskFilterAlcoholic;

  /// No description provided for @kioskFilterNonAlcoholic.
  ///
  /// In en, this message translates to:
  /// **'Non-Alcoholic'**
  String get kioskFilterNonAlcoholic;

  /// No description provided for @kioskEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cocktails in menu'**
  String get kioskEmpty;

  /// No description provided for @kioskEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Go back and select cocktails for the kiosk'**
  String get kioskEmptyHint;

  /// No description provided for @kioskCocktailCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cocktails'**
  String kioskCocktailCount(int count);

  /// No description provided for @kioskPriceCurrency.
  ///
  /// In en, this message translates to:
  /// **'MDL'**
  String get kioskPriceCurrency;

  /// No description provided for @kioskCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get kioskCurrencyLabel;

  /// No description provided for @kioskSelectCocktail.
  ///
  /// In en, this message translates to:
  /// **'Select at least one cocktail'**
  String get kioskSelectCocktail;

  /// No description provided for @kioskVenueHint.
  ///
  /// In en, this message translates to:
  /// **'Bar Alchemy'**
  String get kioskVenueHint;

  /// No description provided for @aiRecipeModeStarter.
  ///
  /// In en, this message translates to:
  /// **'🔰 Starter'**
  String get aiRecipeModeStarter;

  /// No description provided for @aiRecipeModeExpert.
  ///
  /// In en, this message translates to:
  /// **'🏆 Expert'**
  String get aiRecipeModeExpert;

  /// No description provided for @aiRecipeLoading.
  ///
  /// In en, this message translates to:
  /// **'AI is preparing your recipe...'**
  String get aiRecipeLoading;

  /// No description provided for @aiRecipeError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load AI recipe'**
  String get aiRecipeError;

  /// No description provided for @aiRecipeTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get aiRecipeTryAgain;

  /// No description provided for @aiRecipeBasicInstructions.
  ///
  /// In en, this message translates to:
  /// **'Basic Instructions'**
  String get aiRecipeBasicInstructions;

  /// No description provided for @aiRecipePreparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get aiRecipePreparation;

  /// No description provided for @aiRecipeToolsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Tools Needed'**
  String get aiRecipeToolsNeeded;

  /// No description provided for @aiRecipeCommonMistakes.
  ///
  /// In en, this message translates to:
  /// **'Common Mistakes'**
  String get aiRecipeCommonMistakes;

  /// No description provided for @aiRecipeProTips.
  ///
  /// In en, this message translates to:
  /// **'Pro Tips'**
  String get aiRecipeProTips;

  /// No description provided for @aiRecipeHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get aiRecipeHistory;

  /// No description provided for @aiRecipeTechniques.
  ///
  /// In en, this message translates to:
  /// **'Techniques'**
  String get aiRecipeTechniques;

  /// No description provided for @aiRecipePremiumIngredients.
  ///
  /// In en, this message translates to:
  /// **'Premium Recommendations'**
  String get aiRecipePremiumIngredients;

  /// No description provided for @aiRecipeProSecrets.
  ///
  /// In en, this message translates to:
  /// **'Chef Secrets'**
  String get aiRecipeProSecrets;

  /// No description provided for @aiRecipeVariations.
  ///
  /// In en, this message translates to:
  /// **'Variations'**
  String get aiRecipeVariations;

  /// No description provided for @aiRecipeFoodPairing.
  ///
  /// In en, this message translates to:
  /// **'Food Pairing'**
  String get aiRecipeFoodPairing;

  /// No description provided for @aiRecipeCostBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Cost Breakdown'**
  String get aiRecipeCostBreakdown;

  /// No description provided for @aiRecipeEstimatedCost.
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get aiRecipeEstimatedCost;

  /// No description provided for @aiRecipeSuggestedPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get aiRecipeSuggestedPrice;

  /// No description provided for @aiRecipeStartTimer.
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get aiRecipeStartTimer;

  /// No description provided for @aiRecipeStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String aiRecipeStepOf(int current, int total);

  /// No description provided for @modeSchool.
  ///
  /// In en, this message translates to:
  /// **'BARTENDER SCHOOL'**
  String get modeSchool;

  /// No description provided for @modeSchoolSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lessons • Quizzes • XP • Diploma'**
  String get modeSchoolSubtitle;

  /// No description provided for @modeCocktails.
  ///
  /// In en, this message translates to:
  /// **'COCKTAIL BASE'**
  String get modeCocktails;

  /// No description provided for @modeCocktailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'300+ recipes • Search • Favorites'**
  String get modeCocktailsSubtitle;

  /// No description provided for @modeMyBar.
  ///
  /// In en, this message translates to:
  /// **'MY BAR'**
  String get modeMyBar;

  /// No description provided for @modeMyBarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Constructor • Inventory • Custom recipes'**
  String get modeMyBarSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ro', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
