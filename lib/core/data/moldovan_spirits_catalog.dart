/// Static catalog of spirits and mixers commonly found in Moldovan bars.
///
/// Prices are suggested averages in MDL (Moldovan Leu) as of 2024.
/// Bar owners can adjust prices after import — this catalog is just
/// a starting point so nobody has to type every bottle from scratch.
///
/// Usage:
///   final all     = MoldovanSpiritsCatalog.all;
///   final divins  = MoldovanSpiritsCatalog.byCategory('Divin');
library;

// ─── Model ────────────────────────────────────────────────────────────────────

class MoldovanSpirit {
  final String name;
  final String category;
  final double bottleSizeMl;
  final double priceInMdl; // suggested bar purchase price

  const MoldovanSpirit({
    required this.name,
    required this.category,
    required this.bottleSizeMl,
    required this.priceInMdl,
  });
}

// ─── Catalog ──────────────────────────────────────────────────────────────────

abstract class MoldovanSpiritsCatalog {
  MoldovanSpiritsCatalog._();

  static const all = <MoldovanSpirit>[
    // ── DIVIN (Moldovan cognac) ──────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Kvint 3*',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 180),
    MoldovanSpirit(
        name: 'Kvint 5*',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 280),
    MoldovanSpirit(
        name: 'Kvint VSOP',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 450),
    MoldovanSpirit(
        name: 'Kvint XO',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 850),
    MoldovanSpirit(
        name: 'Kvint 10 Years',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 650),
    MoldovanSpirit(
        name: 'Barza Albă 3*',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 160),
    MoldovanSpirit(
        name: 'Barza Albă 5*',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 250),
    MoldovanSpirit(
        name: 'Barza Albă VSOP',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 400),
    MoldovanSpirit(
        name: 'Stăuceni 3*',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 170),
    MoldovanSpirit(
        name: 'Stăuceni 5*',
        category: 'Divin',
        bottleSizeMl: 500,
        priceInMdl: 260),

    // ── WINE — Moldovan producers ────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Purcari Feteasca Neagra',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 180),
    MoldovanSpirit(
        name: 'Purcari Rara Neagra',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 160),
    MoldovanSpirit(
        name: 'Negru de Purcari',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 260),
    MoldovanSpirit(
        name: 'Purcari Pinot Grigio',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 170),
    MoldovanSpirit(
        name: 'Castel Mimi Merlot',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 190),
    MoldovanSpirit(
        name: 'Castel Mimi Chardonnay',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 200),
    MoldovanSpirit(
        name: 'Cricova Merlot',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 120),
    MoldovanSpirit(
        name: 'Cricova Cabernet',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 120),
    MoldovanSpirit(
        name: 'Cricova Prosecco',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 155),
    MoldovanSpirit(
        name: 'Mileștii Mici Muscat',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 100),
    MoldovanSpirit(
        name: 'Mileștii Mici Riesling',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 90),
    MoldovanSpirit(
        name: 'AROMA Merlot',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 80),
    MoldovanSpirit(
        name: 'AROMA Cabernet',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 80),
    MoldovanSpirit(
        name: 'AROMA Pinot Grigio',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 85),
    MoldovanSpirit(
        name: 'Crama Asconi Pinot Noir',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 160),
    MoldovanSpirit(
        name: 'Chateau Vartely Merlot',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 130),
    MoldovanSpirit(
        name: 'Et Cetera Red',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 140),
    MoldovanSpirit(
        name: 'Vinăria Bostavan Rosé',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 110),
    MoldovanSpirit(
        name: 'Lion-Gri Sauvignon',
        category: 'Wine',
        bottleSizeMl: 750,
        priceInMdl: 95),

    // ── VODKA ────────────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Sputnik Vodka',
        category: 'Vodka',
        bottleSizeMl: 500,
        priceInMdl: 110),
    MoldovanSpirit(
        name: 'Absolut Vodka',
        category: 'Vodka',
        bottleSizeMl: 500,
        priceInMdl: 220),
    MoldovanSpirit(
        name: 'Stolichnaya',
        category: 'Vodka',
        bottleSizeMl: 500,
        priceInMdl: 200),
    MoldovanSpirit(
        name: 'Grey Goose',
        category: 'Vodka',
        bottleSizeMl: 500,
        priceInMdl: 520),
    MoldovanSpirit(
        name: 'Finlandia',
        category: 'Vodka',
        bottleSizeMl: 500,
        priceInMdl: 180),

    // ── WHISKY ───────────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Johnnie Walker Red',
        category: 'Whisky',
        bottleSizeMl: 500,
        priceInMdl: 320),
    MoldovanSpirit(
        name: 'Johnnie Walker Black',
        category: 'Whisky',
        bottleSizeMl: 500,
        priceInMdl: 480),
    MoldovanSpirit(
        name: 'Jack Daniel\'s',
        category: 'Whisky',
        bottleSizeMl: 500,
        priceInMdl: 380),
    MoldovanSpirit(
        name: 'Chivas Regal 12',
        category: 'Whisky',
        bottleSizeMl: 500,
        priceInMdl: 450),
    MoldovanSpirit(
        name: 'Jameson Irish',
        category: 'Whisky',
        bottleSizeMl: 500,
        priceInMdl: 360),
    MoldovanSpirit(
        name: 'Glenfiddich 12',
        category: 'Whisky',
        bottleSizeMl: 500,
        priceInMdl: 580),

    // ── GIN ──────────────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Gordon\'s Gin',
        category: 'Gin',
        bottleSizeMl: 500,
        priceInMdl: 220),
    MoldovanSpirit(
        name: 'Tanqueray', category: 'Gin', bottleSizeMl: 500, priceInMdl: 350),
    MoldovanSpirit(
        name: 'Bombay Sapphire',
        category: 'Gin',
        bottleSizeMl: 500,
        priceInMdl: 380),
    MoldovanSpirit(
        name: 'Hendrick\'s',
        category: 'Gin',
        bottleSizeMl: 500,
        priceInMdl: 560),

    // ── RUM ──────────────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Bacardi Blanco',
        category: 'Rum',
        bottleSizeMl: 500,
        priceInMdl: 230),
    MoldovanSpirit(
        name: 'Havana Club 3*',
        category: 'Rum',
        bottleSizeMl: 500,
        priceInMdl: 220),
    MoldovanSpirit(
        name: 'Havana Club 7*',
        category: 'Rum',
        bottleSizeMl: 500,
        priceInMdl: 310),
    MoldovanSpirit(
        name: 'Captain Morgan',
        category: 'Rum',
        bottleSizeMl: 500,
        priceInMdl: 240),
    MoldovanSpirit(
        name: 'Malibu Coconut',
        category: 'Rum',
        bottleSizeMl: 500,
        priceInMdl: 260),

    // ── TEQUILA ──────────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Jose Cuervo Silver',
        category: 'Tequila',
        bottleSizeMl: 500,
        priceInMdl: 320),
    MoldovanSpirit(
        name: 'Sierra Silver',
        category: 'Tequila',
        bottleSizeMl: 500,
        priceInMdl: 280),
    MoldovanSpirit(
        name: 'Olmeca Blanco',
        category: 'Tequila',
        bottleSizeMl: 500,
        priceInMdl: 300),

    // ── VERMOUTH ─────────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Martini Bianco',
        category: 'Vermouth',
        bottleSizeMl: 1000,
        priceInMdl: 180),
    MoldovanSpirit(
        name: 'Martini Rosso',
        category: 'Vermouth',
        bottleSizeMl: 1000,
        priceInMdl: 180),
    MoldovanSpirit(
        name: 'Martini Extra Dry',
        category: 'Vermouth',
        bottleSizeMl: 1000,
        priceInMdl: 180),
    MoldovanSpirit(
        name: 'Cinzano Bianco',
        category: 'Vermouth',
        bottleSizeMl: 1000,
        priceInMdl: 160),
    MoldovanSpirit(
        name: 'Cinzano Rosso',
        category: 'Vermouth',
        bottleSizeMl: 1000,
        priceInMdl: 160),
    MoldovanSpirit(
        name: 'Campari',
        category: 'Vermouth',
        bottleSizeMl: 500,
        priceInMdl: 280),

    // ── LIQUEUR ──────────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Baileys Original',
        category: 'Liqueur',
        bottleSizeMl: 500,
        priceInMdl: 320),
    MoldovanSpirit(
        name: 'Kahlua',
        category: 'Liqueur',
        bottleSizeMl: 500,
        priceInMdl: 290),
    MoldovanSpirit(
        name: 'Amaretto Disaronno',
        category: 'Liqueur',
        bottleSizeMl: 500,
        priceInMdl: 350),
    MoldovanSpirit(
        name: 'Cointreau',
        category: 'Liqueur',
        bottleSizeMl: 500,
        priceInMdl: 380),
    MoldovanSpirit(
        name: 'Triple Sec',
        category: 'Liqueur',
        bottleSizeMl: 500,
        priceInMdl: 150),
    MoldovanSpirit(
        name: 'Blue Curaçao',
        category: 'Liqueur',
        bottleSizeMl: 700,
        priceInMdl: 160),
    MoldovanSpirit(
        name: 'Peach Schnapps',
        category: 'Liqueur',
        bottleSizeMl: 500,
        priceInMdl: 170),
    MoldovanSpirit(
        name: 'Aperol',
        category: 'Liqueur',
        bottleSizeMl: 700,
        priceInMdl: 280),

    // ── BEER ─────────────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Chișinău Beer',
        category: 'Beer',
        bottleSizeMl: 500,
        priceInMdl: 25),
    MoldovanSpirit(
        name: 'Heineken', category: 'Beer', bottleSizeMl: 500, priceInMdl: 40),
    MoldovanSpirit(
        name: 'Stella Artois',
        category: 'Beer',
        bottleSizeMl: 500,
        priceInMdl: 38),
    MoldovanSpirit(
        name: 'Corona Extra',
        category: 'Beer',
        bottleSizeMl: 355,
        priceInMdl: 45),

    // ── MIXER / SYRUP ────────────────────────────────────────────────────────
    MoldovanSpirit(
        name: 'Simple Syrup',
        category: 'Mixer',
        bottleSizeMl: 1000,
        priceInMdl: 40),
    MoldovanSpirit(
        name: 'Grenadine Syrup',
        category: 'Mixer',
        bottleSizeMl: 700,
        priceInMdl: 80),
    MoldovanSpirit(
        name: 'Lime Juice',
        category: 'Mixer',
        bottleSizeMl: 1000,
        priceInMdl: 60),
    MoldovanSpirit(
        name: 'Lemon Juice',
        category: 'Mixer',
        bottleSizeMl: 1000,
        priceInMdl: 55),
    MoldovanSpirit(
        name: 'Angostura Bitters',
        category: 'Mixer',
        bottleSizeMl: 200,
        priceInMdl: 120),
    MoldovanSpirit(
        name: 'Peychaud\'s Bitters',
        category: 'Mixer',
        bottleSizeMl: 200,
        priceInMdl: 130),
    MoldovanSpirit(
        name: 'Tonic Water',
        category: 'Mixer',
        bottleSizeMl: 1000,
        priceInMdl: 35),
    MoldovanSpirit(
        name: 'Soda Water',
        category: 'Mixer',
        bottleSizeMl: 1000,
        priceInMdl: 20),
  ];

  // ── Helpers ─────────────────────────────────────────────────────────────────

  /// All distinct category names in display order.
  static final categories = <String>[
    'All',
    'Divin',
    'Wine',
    'Whisky',
    'Vodka',
    'Gin',
    'Rum',
    'Tequila',
    'Vermouth',
    'Liqueur',
    'Beer',
    'Mixer',
  ];

  /// Category icon mapping for display.
  static const categoryIcons = <String, String>{
    'Divin': '🥃',
    'Wine': '🍷',
    'Vodka': '🍸',
    'Whisky': '🥃',
    'Gin': '🫙',
    'Rum': '🍹',
    'Tequila': '🌵',
    'Vermouth': '🍸',
    'Liqueur': '🍋',
    'Beer': '🍺',
    'Mixer': '🧃',
  };

  /// Filters [all] by category (pass 'All' to return everything).
  static List<MoldovanSpirit> byCategory(String category) {
    if (category == 'All') return all;
    return all.where((s) => s.category == category).toList();
  }

  /// Searches by name (case-insensitive partial match).
  static List<MoldovanSpirit> search(String query) {
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((s) => s.name.toLowerCase().contains(q)).toList();
  }
}
