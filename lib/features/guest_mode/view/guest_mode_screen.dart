import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/l10n/app_localizations.dart';

/// Full-screen immersive kiosk / digital menu screen.
///
/// Designed to be placed on a tablet at the bar: guests browse cocktails,
/// filter by category, and tap to see the full recipe with price.
///
/// Key UX decisions:
///   - Immersive sticky mode hides system bars (no distractions for guests)
///   - Custom header with venue name, no AppBar
///   - 2-column grid with large photo cards
///   - Filter chips: All / Alcoholic / Non-Alcoholic
///   - Tap card → modal bottom sheet with full detail
///   - Exit via back button → confirmation dialog (prevents accidental exits)
class GuestModeScreen extends StatefulWidget {
  final String venueName;
  final List<Cocktail> cocktails;
  final Map<String, double> prices;
  final String currency;

  const GuestModeScreen({
    super.key,
    required this.venueName,
    required this.cocktails,
    required this.prices,
    this.currency = 'MDL',
  });

  @override
  State<GuestModeScreen> createState() => _GuestModeScreenState();
}

class _GuestModeScreenState extends State<GuestModeScreen> {
  static const _filterAll = '__all__';
  static const _filterAlco = 'Alcoholic';
  static const _filterNonAlco = 'Non alcoholic';

  String _activeFilter = _filterAll;

  @override
  void initState() {
    super.initState();
    // Enter full immersive kiosk mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when leaving the kiosk
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  List<Cocktail> get _filtered {
    if (_activeFilter == _filterAll) return widget.cocktails;
    if (_activeFilter == _filterNonAlco) {
      return widget.cocktails
          .where((c) => c.strAlcoholic.toLowerCase().contains('non'))
          .toList();
    }
    return widget.cocktails
        .where((c) => c.strAlcoholic == _filterAlco)
        .toList();
  }

  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context);
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.kioskExitTitle,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.kioskExitMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.kioskExitConfirm),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  void _showDetail(Cocktail cocktail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CocktailDetailSheet(
        cocktail: cocktail,
        price: widget.prices[cocktail.idDrink],
        currency: widget.currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name =
        widget.venueName.isNotEmpty ? widget.venueName : 'Cocktail Menu';
    final visible = _filtered;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final should = await _onWillPop();
        if (should && mounted) {
          // ignore: use_build_context_synchronously
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Kiosk header ─────────────────────────────────────────────
            _KioskHeader(
              venueName: name,
              onExit: _onWillPop,
            ),

            // ── Filter chips ─────────────────────────────────────────────
            _FilterRow(
              activeFilter: _activeFilter,
              onFilterChanged: (f) => setState(() => _activeFilter = f),
              l10n: l10n,
            ),

            // ── Grid ─────────────────────────────────────────────────────
            Expanded(
              child: visible.isEmpty
                  ? _EmptyState(l10n: l10n)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (_, i) => _CocktailCard(
                        cocktail: visible[i],
                        price: widget.prices[visible[i].idDrink],
                        currency: widget.currency,
                        onTap: () => _showDetail(visible[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Kiosk header ─────────────────────────────────────────────────────────────

class _KioskHeader extends StatelessWidget {
  final String venueName;
  final Future<bool> Function() onExit;

  const _KioskHeader({required this.venueName, required this.onExit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              // Subtle exit button for staff
              IconButton(
                icon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.textSecondary, size: 20),
                tooltip: 'Exit kiosk',
                onPressed: () async {
                  final should = await onExit();
                  if (should && context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              Expanded(
                child: Text(
                  venueName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Balance the left icon
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'C O C K T A I L   M E N U',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              letterSpacing: 6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Gold divider line
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary,
                  AppColors.primary,
                  Colors.transparent,
                ],
                stops: [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Filter row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final AppLocalizations l10n;

  const _FilterRow({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final filters = {
      '__all__': l10n.kioskFilterAll,
      'Alcoholic': l10n.kioskFilterAlcoholic,
      'Non alcoholic': l10n.kioskFilterNonAlcoholic,
    };

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.entries.map((e) {
            final isActive = e.key == activeFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onFilterChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: isActive ? Colors.black : AppColors.textSecondary,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Cocktail card ─────────────────────────────────────────────────────────────

class _CocktailCard extends StatelessWidget {
  final Cocktail cocktail;
  final double? price;
  final String currency;
  final VoidCallback onTap;

  const _CocktailCard({
    required this.cocktail,
    required this.price,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo — occupies ~60% of card height
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  CachedNetworkImage(
                    imageUrl: cocktail.strDrinkThumb,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.shimmerBase,
                      child: const Center(
                        child: Icon(Icons.local_bar_rounded,
                            color: AppColors.textSecondary, size: 36),
                      ),
                    ),
                    errorWidget: (_, __, ___) => _LetterPlaceholder(
                        letter: cocktail.strDrink.isNotEmpty
                            ? cocktail.strDrink[0].toUpperCase()
                            : '?'),
                  ),
                  // Bottom gradient for text legibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC1A1825)],
                        ),
                      ),
                    ),
                  ),
                  // Alcoholic badge top-right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _AlcoholicBadge(alcoholic: cocktail.strAlcoholic),
                  ),
                ],
              ),
            ),

            // Name + price row
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cocktail.strDrink,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (price != null && price! > 0)
                      Text(
                        '${price!.toStringAsFixed(0)} $currency',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      )
                    else
                      Text(
                        cocktail.strCategory,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Letter placeholder for cocktails without photo ───────────────────────────

class _LetterPlaceholder extends StatelessWidget {
  final String letter;
  const _LetterPlaceholder({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ─── Alcoholic badge ──────────────────────────────────────────────────────────

class _AlcoholicBadge extends StatelessWidget {
  final String alcoholic;
  const _AlcoholicBadge({required this.alcoholic});

  @override
  Widget build(BuildContext context) {
    final isNon = alcoholic.toLowerCase().contains('non');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isNon
            ? Colors.green.withAlpha(200)
            : AppColors.primary.withAlpha(200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isNon ? '0%' : '🍸',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Cocktail detail bottom sheet ─────────────────────────────────────────────

class _CocktailDetailSheet extends StatelessWidget {
  final Cocktail cocktail;
  final double? price;
  final String currency;

  const _CocktailDetailSheet({
    required this.cocktail,
    required this.price,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView(
                controller: scrollCtl,
                padding: EdgeInsets.zero,
                children: [
                  // Hero image
                  SizedBox(
                    height: screenH * 0.32,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: cocktail.strDrinkThumb,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.shimmerBase),
                          errorWidget: (_, __, ___) => _LetterPlaceholder(
                              letter: cocktail.strDrink.isNotEmpty
                                  ? cocktail.strDrink[0].toUpperCase()
                                  : '?'),
                        ),
                        // Gradient bottom
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 80,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, AppColors.surface],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + price row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                cocktail.strDrink,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            if (price != null && price! > 0) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.primary, width: 1.5),
                                ),
                                child: Text(
                                  '${price!.toStringAsFixed(0)}\n$currency',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Meta row
                        Wrap(
                          spacing: 8,
                          children: [
                            _MetaChip(
                                label: cocktail.strAlcoholic,
                                color: cocktail.strAlcoholic
                                        .toLowerCase()
                                        .contains('non')
                                    ? Colors.green
                                    : AppColors.primary),
                            if (cocktail.strGlass.isNotEmpty)
                              _MetaChip(
                                  label: cocktail.strGlass,
                                  color: AppColors.textSecondary),
                            if (cocktail.strCategory.isNotEmpty)
                              _MetaChip(
                                  label: cocktail.strCategory,
                                  color: AppColors.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Ingredients
                        const Text(
                          'I N G R E D I E N T S',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(
                          cocktail.ingredients.length,
                          (i) => _IngredientRow(
                            ingredient: cocktail.ingredients[i],
                            measure: i < cocktail.measures.length
                                ? cocktail.measures[i]
                                : '',
                          ),
                        ),

                        // Instructions
                        if (cocktail.strInstructions.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'P R E P A R A T I O N',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            cocktail.strInstructions,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ingredient row ───────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  final String ingredient;
  final String measure;
  const _IngredientRow({required this.ingredient, required this.measure});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ingredient,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (measure.isNotEmpty)
            Text(
              measure,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

// ─── Meta chip ────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_bar_rounded,
              color: AppColors.textSecondary, size: 64),
          const SizedBox(height: 16),
          Text(l10n.kioskEmpty,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
