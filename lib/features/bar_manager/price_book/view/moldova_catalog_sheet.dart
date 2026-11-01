import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/data/moldovan_spirits_catalog.dart';
import 'package:coin/core/models/ingredient_price.dart';
import 'package:coin/core/repositories/price_repository.dart';
import 'package:coin/core/theme/app_theme.dart';

/// Modal bottom sheet showing the pre-filled Moldovan spirits catalog.
///
/// Bar owner opens this from the Price Book screen.
/// One tap on any item → instantly saved to Price Book with MDL price pre-set.
/// Items already in the Price Book are shown with a checkmark (no duplicates).
///
/// Usage:
///   MoldovaCatalogSheet.show(context);
class MoldovaCatalogSheet extends StatefulWidget {
  const MoldovaCatalogSheet({super.key});

  /// Convenience method to open the sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoldovaCatalogSheet(),
    );
  }

  @override
  State<MoldovaCatalogSheet> createState() => _MoldovaCatalogSheetState();
}

class _MoldovaCatalogSheetState extends State<MoldovaCatalogSheet> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Filtered list ─────────────────────────────────────────────────────────

  List<MoldovanSpirit> get _filtered {
    var list = _selectedCategory == 'All'
        ? MoldovanSpiritsCatalog.all
        : MoldovanSpiritsCatalog.byCategory(_selectedCategory);

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((s) => s.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ─── Add a spirit to Price Book ────────────────────────────────────────────

  Future<void> _addSpirit(MoldovanSpirit spirit, PriceRepository repo) async {
    // Skip if already exists (case-insensitive key)
    if (repo.findByName(spirit.name) != null) {
      _showSnack('${spirit.name} is already in Price Book');
      return;
    }

    final price = IngredientPrice(
      name: spirit.name,
      bottlePrice: spirit.priceInMdl,
      bottleSizeMl: spirit.bottleSizeMl,
      currency: 'MDL',
    );

    await repo.save(price);
    if (mounted) _showSnack('Added: ${spirit.name}');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<PriceRepository>();
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    '🇲🇩  Moldova Spirits Catalog',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${MoldovanSpiritsCatalog.all.length} items',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search spirits…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),

            // ── Category chips ──
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: MoldovanSpiritsCatalog.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = MoldovanSpiritsCatalog.categories[i];
                  final selected = cat == _selectedCategory;
                  final icon = MoldovanSpiritsCatalog.categoryIcons[cat];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        icon != null ? '$icon  $cat' : cat,
                        style: TextStyle(
                          color:
                              selected ? Colors.black : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // ── List ──
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No spirits found',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _SpiritTile(
                        spirit: filtered[i],
                        inBook: repo.findByName(filtered[i].name) != null,
                        onAdd: () => _addSpirit(filtered[i], repo),
                      ),
                    ),
            ),

            // ── Add All button ──
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      int added = 0;
                      for (final s in filtered) {
                        if (repo.findByName(s.name) == null) {
                          await _addSpirit(s, repo);
                          added++;
                        }
                      }
                      if (mounted) {
                        _showSnack(added > 0
                            ? 'Added $added spirits to Price Book'
                            : 'All items already in Price Book');
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: Text(
                      _selectedCategory == 'All'
                          ? 'Add All (${filtered.length})'
                          : 'Add all $_selectedCategory (${filtered.length})',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single spirit row ─────────────────────────────────────────────────────────

class _SpiritTile extends StatelessWidget {
  final MoldovanSpirit spirit;
  final bool inBook;
  final VoidCallback onAdd;

  const _SpiritTile({
    required this.spirit,
    required this.inBook,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),

      // Category emoji
      leading: Text(
        MoldovanSpiritsCatalog.categoryIcons[spirit.category] ?? '🍶',
        style: const TextStyle(fontSize: 24),
      ),

      // Name + size
      title: Text(
        spirit.name,
        style: TextStyle(
          color: inBook ? AppColors.textSecondary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '${spirit.bottleSizeMl.toInt()} ml',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),

      // Price + action
      trailing: inBook
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 22)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${spirit.priceInMdl.toInt()} MDL',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

      // Tap the whole row to add too
      onTap: inBook ? null : onAdd,
    );
  }
}
