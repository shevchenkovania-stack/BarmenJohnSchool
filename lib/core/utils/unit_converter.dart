/// Converts between common bar measurement units.
///
/// Supported units: ml, oz, cl, tsp, tbsp, dash.
/// All conversions go through ml as the base unit.
class UnitConverter {
  UnitConverter._();

  // ── Base factors (1 unit → ml) ────────────────────────────────────────────
  static const Map<String, double> _toMl = {
    'ml': 1.0,
    'cl': 10.0,
    'oz': 29.5735,
    'fl oz': 29.5735,
    'tsp': 4.92892,
    'tbsp': 14.7868,
    'dash': 0.92, // bar standard ≈ 0.92 ml
    'drop': 0.05,
    'l': 1000.0,
    'cup': 236.588,
    'pint': 473.176,
  };

  /// Converts [value] from [fromUnit] to [toUnit].
  ///
  /// Returns `null` if either unit is unknown.
  static double? convert(double value, String fromUnit, String toUnit) {
    final from = _toMl[fromUnit.toLowerCase().trim()];
    final to = _toMl[toUnit.toLowerCase().trim()];
    if (from == null || to == null) return null;
    return value * from / to;
  }

  /// Returns all supported unit names.
  static List<String> get supportedUnits => _toMl.keys.toList();

  /// Formats [ml] value into a human-friendly string.
  ///
  /// - < 10 ml → shows as ml with 1 decimal
  /// - ≥ 10 ml and < 1000 ml → shows as whole ml
  /// - ≥ 1000 ml → shows as liters
  static String formatMl(double ml) {
    if (ml >= 1000) {
      return '${(ml / 1000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')} l';
    }
    if (ml < 10) {
      return '${ml.toStringAsFixed(1)} ml';
    }
    return '${ml.round()} ml';
  }

  /// Tries to parse a measure string like "1 oz", "50ml", "2 cl" into ml.
  ///
  /// Returns `null` if parsing fails.
  static double? parseMeasureToMl(String measure) {
    final clean = measure.trim().toLowerCase();
    final match = RegExp(r'^([\d./]+)\s*([a-z\s]+)$').firstMatch(clean);
    if (match == null) return null;

    final rawNum = match.group(1)!;
    final unit = match.group(2)!.trim();

    // Handle fractions like "1/2"
    double? num;
    if (rawNum.contains('/')) {
      final parts = rawNum.split('/');
      if (parts.length == 2) {
        final a = double.tryParse(parts[0]);
        final b = double.tryParse(parts[1]);
        if (a != null && b != null && b != 0) num = a / b;
      }
    } else {
      num = double.tryParse(rawNum);
    }

    if (num == null) return null;
    return convert(num, unit, 'ml');
  }
}
