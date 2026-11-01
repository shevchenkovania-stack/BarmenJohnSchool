import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the bartender's kiosk configuration between app sessions.
///
/// Stores:
///   - [venueName]    — bar/restaurant name shown in the kiosk header
///   - [prices]       — map of cocktailId → guest-facing price
///   - [selectedIds]  — set of cocktailIds included in the kiosk menu
///   - [currency]     — currency label (default MDL)
///
/// Uses SharedPreferences so settings survive app restarts.
class GuestMenuService extends ChangeNotifier {
  static const _keyVenue = 'kiosk_venue';
  static const _keyPrices = 'kiosk_prices';
  static const _keySelectedIds = 'kiosk_selected_ids';
  static const _keyCurrency = 'kiosk_currency';

  final SharedPreferences _prefs;

  String _venueName = '';
  Map<String, double> _prices = {};
  Set<String> _selectedIds = {};
  String _currency = 'MDL';

  GuestMenuService(this._prefs) {
    _load();
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  String get venueName => _venueName;
  Map<String, double> get prices => Map.unmodifiable(_prices);
  Set<String> get selectedIds => Set.unmodifiable(_selectedIds);
  String get currency => _currency;

  // ─── Mutators ─────────────────────────────────────────────────────────────

  /// Persists the complete kiosk configuration and notifies listeners.
  Future<void> save({
    required String venueName,
    required Map<String, double> prices,
    required Set<String> selectedIds,
    String currency = 'MDL',
  }) async {
    _venueName = venueName;
    _prices = Map.from(prices);
    _selectedIds = Set.from(selectedIds);
    _currency = currency;

    await _prefs.setString(_keyVenue, venueName);
    await _prefs.setString(_keyCurrency, currency);
    await _prefs.setString(
      _keyPrices,
      jsonEncode(prices.map((k, v) => MapEntry(k, v))),
    );
    await _prefs.setStringList(_keySelectedIds, selectedIds.toList());

    notifyListeners();
  }

  /// Clears the kiosk configuration.
  Future<void> clear() async {
    _venueName = '';
    _prices = {};
    _selectedIds = {};
    _currency = 'MDL';

    await _prefs.remove(_keyVenue);
    await _prefs.remove(_keyPrices);
    await _prefs.remove(_keySelectedIds);
    await _prefs.remove(_keyCurrency);

    notifyListeners();
  }

  // ─── Storage ──────────────────────────────────────────────────────────────

  void _load() {
    _venueName = _prefs.getString(_keyVenue) ?? '';
    _currency = _prefs.getString(_keyCurrency) ?? 'MDL';

    final pricesJson = _prefs.getString(_keyPrices);
    if (pricesJson != null) {
      try {
        final decoded = jsonDecode(pricesJson) as Map<String, dynamic>;
        _prices = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {
        _prices = {};
      }
    }

    final ids = _prefs.getStringList(_keySelectedIds) ?? [];
    _selectedIds = ids.toSet();
  }
}
