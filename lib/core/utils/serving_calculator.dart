import 'package:coin/core/utils/unit_converter.dart';

/// Scales cocktail ingredient amounts for a given number of servings.
///
/// Used in the detail screen and custom recipe editor so the bartender
/// can quickly calculate amounts for a batch (e.g., 6 cocktails at once).
class ServingCalculator {
  ServingCalculator._();

  /// Scales a single [measure] string by [servings].
  ///
  /// Examples:
  ///   scale('2 oz', 4)  → '8 oz'
  ///   scale('1/2 oz', 3) → '1.5 oz'
  ///   scale('Splash', 2) → 'Splash ×2'  (non-numeric measures kept readable)
  static String scale(String measure, int servings) {
    if (servings == 1) return measure;
    if (measure.isEmpty) return measure;

    final clean = measure.trim();

    // Try to extract leading number (incl. fractions like "1 1/2" or "1/2")
    final match = RegExp(r'^([\d\s/]+)([\s\S]*)$').firstMatch(clean);
    if (match == null) return '$clean ×$servings';

    final rawNum = match.group(1)!.trim();
    final rest = match.group(2) ?? '';

    final num = _parseNumber(rawNum);
    if (num == null) return '$clean ×$servings';

    final scaled = num * servings;
    final formatted = _formatNumber(scaled);
    return '$formatted$rest';
  }

  /// Scales all measures in parallel lists [measures] by [servings].
  ///
  /// [ingredients] and [measures] must be the same length.
  static List<String> scaleAll(List<String> measures, int servings) {
    return measures.map((m) => scale(m, servings)).toList();
  }

  /// Converts all measures to ml and returns them as formatted strings.
  ///
  /// Falls back to the original string if conversion is not possible.
  static List<String> toMl(List<String> measures) {
    return measures.map((m) {
      final ml = UnitConverter.parseMeasureToMl(m);
      if (ml == null) return m;
      return UnitConverter.formatMl(ml);
    }).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Parses numbers including mixed fractions: "1 1/2" → 1.5, "3/4" → 0.75.
  static double? _parseNumber(String raw) {
    final clean = raw.trim();

    // Mixed fraction: "1 1/2"
    final mixed = RegExp(r'^(\d+)\s+(\d+)/(\d+)$').firstMatch(clean);
    if (mixed != null) {
      final whole = double.parse(mixed.group(1)!);
      final num = double.parse(mixed.group(2)!);
      final den = double.parse(mixed.group(3)!);
      if (den == 0) return null;
      return whole + num / den;
    }

    // Simple fraction: "1/2"
    final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(clean);
    if (frac != null) {
      final num = double.parse(frac.group(1)!);
      final den = double.parse(frac.group(2)!);
      if (den == 0) return null;
      return num / den;
    }

    // Plain decimal or integer
    return double.tryParse(clean);
  }

  /// Formats a number cleanly: removes unnecessary decimal zeros.
  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    // Try to keep 2 decimal places max, strip trailing zeros
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}
