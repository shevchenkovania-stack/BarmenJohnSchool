import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/favorites_service.dart';
import 'package:coin/core/services/guest_menu_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';
import 'package:coin/features/guest_mode/view/guest_mode_screen.dart';
import 'package:coin/features/menu_builder/service/menu_pdf_service.dart';
import 'package:coin/features/qr_menu/view/qr_menu_screen.dart';

/// Bartender-facing setup screen for the kiosk / digital menu feature.
///
/// The bartender:
///   1. Enters the venue/bar name
///   2. Selects which cocktails (from favorites) appear in the guest menu
///   3. Sets the guest-facing price for each selected cocktail
///   4. Taps "Launch Kiosk" → opens [GuestModeScreen] in immersive full-screen
///
/// Configuration is auto-saved via [GuestMenuService] so it persists across
/// app sessions.
class KioskSetupScreen extends StatefulWidget {
  const KioskSetupScreen({super.key});

  @override
  State<KioskSetupScreen> createState() => _KioskSetupScreenState();
}

class _KioskSetupScreenState extends State<KioskSetupScreen> {
  final _venueCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController(text: 'MDL');
  final Set<String> _selectedIds = {};
  final Map<String, TextEditingController> _priceCtls = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill from saved config
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<GuestMenuService>();
      if (svc.venueName.isNotEmpty) {
        _venueCtrl.text = svc.venueName;
      }
      if (svc.currency.isNotEmpty) {
        _currencyCtrl.text = svc.currency;
      }
      if (svc.selectedIds.isNotEmpty) {
        setState(() {
          _selectedIds.addAll(svc.selectedIds);
          for (final entry in svc.prices.entries) {
            _priceCtlFor(entry.key).text = entry.value.toStringAsFixed(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _venueCtrl.dispose();
    _currencyCtrl.dispose();
    for (final c in _priceCtls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _priceCtlFor(String id) =>
      _priceCtls.putIfAbsent(id, () => TextEditingController());

  Map<String, double> _collectPrices() {
    final out = <String, double>{};
    for (final entry in _priceCtls.entries) {
      final v = double.tryParse(entry.value.text.trim());
      if (v != null && v > 0) out[entry.key] = v;
    }
    return out;
  }

  Future<void> _save() async {
    final svc = context.read<GuestMenuService>();
    await svc.save(
      venueName: _venueCtrl.text.trim(),
      prices: _collectPrices(),
      selectedIds: Set.from(_selectedIds),
      currency: _currencyCtrl.text.trim().isNotEmpty
          ? _currencyCtrl.text.trim()
          : 'MDL',
    );
  }

  Future<void> _launch() async {
    if (_selectedIds.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.kioskSelectCocktail),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    await _save();

    if (!mounted) return;

    final fav = context.read<FavoritesService>();
    final selected =
        fav.favorites.where((c) => _selectedIds.contains(c.idDrink)).toList();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuestModeScreen(
          venueName: _venueCtrl.text.trim(),
          cocktails: selected,
          prices: _collectPrices(),
          currency: _currencyCtrl.text.trim().isNotEmpty
              ? _currencyCtrl.text.trim()
              : 'MDL',
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _onQr() async {
    if (_selectedIds.isEmpty) return;
    await _save();
    if (!mounted) return;
    final fav = context.read<FavoritesService>();
    final selected =
        fav.favorites.where((c) => _selectedIds.contains(c.idDrink)).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrMenuScreen(
          venueName: _venueCtrl.text.trim(),
          cocktails: selected,
          prices: _collectPrices(),
        ),
      ),
    );
  }

  Future<void> _onPdf() async {
    if (_selectedIds.isEmpty) return;
    await _save();
    if (!mounted) return;
    final fav = context.read<FavoritesService>();
    final selected =
        fav.favorites.where((c) => _selectedIds.contains(c.idDrink)).toList();
    await MenuPdfService.previewAndPrint(
      context: context,
      venueName: _venueCtrl.text.trim(),
      cocktails: selected,
      theme: 'classic',
      prices: _collectPrices(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.kioskSetupTitle),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              l10n.kioskSave,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _LaunchBar(
        selectedCount: _selectedIds.length,
        onLaunch: _launch,
        onQr: _onQr,
        onPdf: _onPdf,
        l10n: l10n,
      ),
      body: Consumer<FavoritesService>(
        builder: (_, fav, __) {
          final cocktails = fav.favorites;

          if (cocktails.isEmpty) {
            return _EmptyFavorites(l10n: l10n);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Venue name ───────────────────────────────────────────────
              _SectionLabel(text: l10n.menuBuilderVenueHint),
              const SizedBox(height: 8),
              TextField(
                controller: _venueCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: l10n.kioskVenueHint,
                  prefixIcon: const Icon(Icons.storefront_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // ── Currency ─────────────────────────────────────────────────
              _SectionLabel(text: l10n.kioskCurrencyLabel),
              const SizedBox(height: 8),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _currencyCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'MDL',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Cocktail selection ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SectionLabel(
                      text: l10n.kioskSetupHint,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedIds.addAll(cocktails.map((c) => c.idDrink));
                    }),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.menuBuilderSelectAll,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedIds.clear()),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.menuBuilderDeselectAll,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...cocktails.map(
                (c) => _CocktailSetupTile(
                  cocktail: c,
                  isSelected: _selectedIds.contains(c.idDrink),
                  priceCtl: _priceCtlFor(c.idDrink),
                  currency: _currencyCtrl.text.trim().isNotEmpty
                      ? _currencyCtrl.text.trim()
                      : 'MDL',
                  onToggle: () => setState(() {
                    if (_selectedIds.contains(c.idDrink)) {
                      _selectedIds.remove(c.idDrink);
                    } else {
                      _selectedIds.add(c.idDrink);
                    }
                  }),
                ),
              ),

              const SizedBox(height: 80), // space for bottom bar
            ],
          );
        },
      ),
    );
  }
}

// ─── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ─── Cocktail tile with toggle + price input ──────────────────────────────────

class _CocktailSetupTile extends StatelessWidget {
  final Cocktail cocktail;
  final bool isSelected;
  final TextEditingController priceCtl;
  final String currency;
  final VoidCallback onToggle;

  const _CocktailSetupTile({
    required this.cocktail,
    required this.isSelected,
    required this.priceCtl,
    required this.currency,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: cocktail.strDrinkThumb,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(width: 44, height: 44, color: AppColors.divider),
                errorWidget: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: AppColors.divider,
                    child: const Icon(Icons.local_bar_rounded,
                        color: AppColors.textSecondary, size: 20)),
              ),
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              child: Text(
                cocktail.strDrink,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),

            // Price input (only when selected)
            if (isSelected) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                height: 36,
                child: TextField(
                  controller: priceCtl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    suffixText: currency,
                    hintText: '0',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: AppColors.primary.withAlpha(100)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      key: ValueKey(true), color: AppColors.primary)
                  : const Icon(Icons.radio_button_unchecked_rounded,
                      key: ValueKey(false), color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom launch bar ────────────────────────────────────────────────────────

class _LaunchBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onLaunch;
  final VoidCallback onQr;
  final VoidCallback onPdf;
  final AppLocalizations l10n;

  const _LaunchBar({
    required this.selectedCount,
    required this.onLaunch,
    required this.onQr,
    required this.onPdf,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.kioskCocktailCount(selectedCount),
                  style:
                      const TextStyle(color: AppColors.primary, fontSize: 13),
                ),
              ),
            // Row 1: PDF only (QR Menu hidden for first release)
            // TODO: Uncomment QR Menu button when ready for next release
            /*
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedCount > 0 ? onQr : null,
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('QR Menu'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedCount > 0 ? onPdf : null,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(l10n.menuBuilderPreview),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            */
            // PDF button only for now
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: selectedCount > 0 ? onPdf : null,
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: Text(l10n.menuBuilderPreview),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Row 2: Launch Kiosk (full width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedCount > 0 ? onLaunch : null,
                icon: const Icon(Icons.tablet_mac_rounded),
                label: Text(l10n.kioskLaunch),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyFavorites({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border_rounded,
                color: AppColors.textSecondary, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.kioskEmpty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.menuBuilderEmptyHint,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
