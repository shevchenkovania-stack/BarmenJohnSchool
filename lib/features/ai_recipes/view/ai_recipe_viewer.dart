import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/services/recipe_ai_service.dart';
import 'package:coin/core/services/settings_service.dart';
import 'package:coin/core/services/saved_recipe_service.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/ai_recipes/models/detailed_recipe.dart';
import 'package:coin/features/ai_recipes/view/saved_recipes_page.dart';

/// AI Recipe Viewer with mode toggle (Starter / Expert).
/// Supports cache load, save, regenerate, print, and library navigation.
class AiRecipeViewer extends StatefulWidget {
  final Cocktail cocktail;

  /// If true — skip API and load from cache immediately.
  final bool forceCache;

  /// Initial recipe mode (defaults to starter if not provided)
  final RecipeMode? initialMode;

  const AiRecipeViewer({
    super.key,
    required this.cocktail,
    this.forceCache = false,
    this.initialMode,
  });

  @override
  State<AiRecipeViewer> createState() => _AiRecipeViewerState();
}

class _AiRecipeViewerState extends State<AiRecipeViewer> {
  late RecipeMode _mode;
  DetailedRecipe? _recipe;
  bool _isLoading = true;
  String? _error;
  bool _isCached = false; // true = loaded from local storage
  bool _isSaving = false; // true = save in progress

  @override
  void initState() {
    _mode = RecipeMode.expert; // Always use Expert mode
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe({bool forceApi = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isCached = false;
    });

    // 1. Check cache first (unless forceApi = true)
    if (!forceApi) {
      final svc = context.read<SavedRecipeService>();
      final cached = svc.load(widget.cocktail.idDrink, _mode);
      if (cached != null) {
        setState(() {
          _recipe = cached;
          _isLoading = false;
          _isCached = true;
        });
        print(
            '📂 Loaded from cache: ${widget.cocktail.strDrink} (${_mode.name})');
        return;
      }
    }

    // 2. Call AI API
    try {
      final settings = context.read<SettingsService>();
      final locale = settings.locale.languageCode;
      print('🌍 Using locale from settings: $locale');
      final service = RecipeAIService();
      final recipe = await service.expand(
        cocktail: widget.cocktail,
        mode: _mode,
        locale: locale,
      );
      setState(() {
        _recipe = recipe;
        _isLoading = false;
        _isCached = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveRecipe() async {
    if (_recipe == null || _isCached) return;
    setState(() => _isSaving = true);
    final svc = context.read<SavedRecipeService>();
    await svc.save(widget.cocktail, _mode, _recipe!);
    setState(() {
      _isSaving = false;
      _isCached = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Рецепт сохранён в библиотеку!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _printRecipe() async {
    if (_recipe == null) return;
    final cocktail = widget.cocktail;
    final recipe = _recipe!;

    try {
      // Load Cyrillic-capable font from Google Fonts
      final font = await PdfGoogleFonts.notoSansRegular();
      final fontBold = await PdfGoogleFonts.notoSansBold();
      final fontItalic = await PdfGoogleFonts.notoSansItalic();

      // Download cocktail image
      Uint8List? imageBytes;
      try {
        final resp = await http
            .get(Uri.parse(cocktail.strDrinkThumb))
            .timeout(const Duration(seconds: 8));
        if (resp.statusCode == 200) imageBytes = resp.bodyBytes;
      } catch (_) {}

      final doc = pw.Document();
      final image = imageBytes != null ? pw.MemoryImage(imageBytes) : null;

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // ── Header ──
          pw.Row(children: [
            if (image != null)
              pw.Container(
                width: 80,
                height: 80,
                decoration:
                    pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Image(image, fit: pw.BoxFit.cover),
              ),
            pw.SizedBox(width: 16),
            pw.Expanded(
                child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(cocktail.strDrink,
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color:
                        recipe.isExpert ? PdfColors.amber : PdfColors.blue100,
                    borderRadius: pw.BorderRadius.circular(20),
                  ),
                  child: pw.Text(
                    recipe.isExpert ? 'EXPERT MODE' : 'STARTER MODE',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: recipe.isExpert
                            ? PdfColors.black
                            : PdfColors.blue900),
                  ),
                ),
              ],
            )),
          ]),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 12),

          if (recipe.isExpert) ...[
            // History
            if (recipe.history != null) ...[
              _pdfLabel('История', fontBold),
              pw.Text(recipe.history!,
                  style: pw.TextStyle(font: font, fontSize: 11)),
              pw.SizedBox(height: 12),
            ],
            // Sensory profile
            if (recipe.sensoryProfile != null &&
                recipe.sensoryProfile!.isNotEmpty) ...[
              _pdfLabel('Сенсорный профиль', fontBold),
              ...recipe.sensoryProfile!.entries.map(
                (e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text('${e.key.toUpperCase()}: ${e.value}',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                ),
              ),
              pw.SizedBox(height: 12),
            ],
            // Techniques
            if (recipe.techniques != null && recipe.techniques!.isNotEmpty) ...[
              _pdfLabel('Техники', fontBold),
              pw.Wrap(
                  spacing: 6,
                  children: recipe.techniques!
                      .map(
                        (t) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.amber),
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(t,
                              style: pw.TextStyle(font: font, fontSize: 9)),
                        ),
                      )
                      .toList()),
              pw.SizedBox(height: 12),
            ],
            // Premium ingredients
            if (recipe.premiumIngredients != null &&
                recipe.premiumIngredients!.isNotEmpty) ...[
              _pdfLabel('Премиум ингредиенты', fontBold),
              ...recipe.premiumIngredients!.map(
                (i) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ${i.name}',
                            style: pw.TextStyle(
                                font: fontBold,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11)),
                        pw.Text('  Рекомендую: ${i.recommendation}',
                            style: pw.TextStyle(font: font, fontSize: 10)),
                        pw.Text('  ${i.reason}',
                            style: pw.TextStyle(
                                font: fontItalic,
                                fontStyle: pw.FontStyle.italic,
                                fontSize: 9,
                                color: PdfColors.grey700)),
                      ]),
                ),
              ),
              pw.SizedBox(height: 8),
            ],
            // Service presentation
            if (recipe.servicePresentation != null &&
                recipe.servicePresentation!.isNotEmpty) ...[
              _pdfLabel('Подача', fontBold),
              ...recipe.servicePresentation!.asMap().entries.map(
                    (e) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text('${e.key + 1}. ${e.value}',
                          style: pw.TextStyle(font: font, fontSize: 10)),
                    ),
                  ),
              pw.SizedBox(height: 12),
            ],
            // Pro secrets
            if (recipe.proSecrets != null && recipe.proSecrets!.isNotEmpty) ...[
              _pdfLabel('Секреты мастера', fontBold),
              ...recipe.proSecrets!.map(
                (s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text('• $s',
                      style: pw.TextStyle(font: font, fontSize: 10)),
                ),
              ),
              pw.SizedBox(height: 12),
            ],
            // Cost
            if (recipe.estimatedCostMdl != null) ...[
              _pdfLabel('Экономика', fontBold),
              pw.Text('Себестоимость: ${recipe.estimatedCostMdl} MDL',
                  style: pw.TextStyle(font: font, fontSize: 11)),
              if (recipe.suggestedPriceMdl != null)
                pw.Text('Цена в меню: ${recipe.suggestedPriceMdl} MDL',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfColors.amber800)),
            ],
          ] else ...[
            // STARTER
            if (recipe.toolsNeeded.isNotEmpty) ...[
              _pdfLabel('Инструменты', fontBold),
              pw.Text(recipe.toolsNeeded.join(', '),
                  style: pw.TextStyle(font: font, fontSize: 11)),
              pw.SizedBox(height: 12),
            ],
            _pdfLabel('Шаги приготовления', fontBold),
            ...recipe.steps.map(
              (s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${s.stepNumber}. ${s.title}',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11)),
                      pw.Text(s.description,
                          style: pw.TextStyle(font: font, fontSize: 10)),
                      if (s.durationSeconds > 0)
                        pw.Text('Время: ${s.durationSeconds} сек',
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 9,
                                color: PdfColors.grey600)),
                      if (s.tip != null)
                        pw.Text('Совет: ${s.tip}',
                            style: pw.TextStyle(
                                font: fontItalic,
                                fontStyle: pw.FontStyle.italic,
                                fontSize: 9,
                                color: PdfColors.amber800)),
                    ]),
              ),
            ),
            if (recipe.commonMistakes.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              _pdfLabel('Частые ошибки', fontBold),
              ...recipe.commonMistakes.map(
                (m) => pw.Text('• $m',
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ),
            ],
            if (recipe.proTips.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              _pdfLabel('Советы', fontBold),
              ...recipe.proTips.map(
                (t) => pw.Text('• $t',
                    style: pw.TextStyle(font: font, fontSize: 10)),
              ),
            ],
          ],

          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text('Создано с помощью AI Recipe Expert',
              style: pw.TextStyle(
                  font: font, fontSize: 8, color: PdfColors.grey500)),
        ],
      ));

      await Printing.layoutPdf(
        onLayout: (_) => doc.save(),
        name:
            '${cocktail.strDrink} — ${recipe.isExpert ? "Expert" : "Starter"} Recipe',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка печати: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  pw.Widget _pdfLabel(String text, pw.Font font) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(text.toUpperCase(),
            style: pw.TextStyle(
                font: font,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber800,
                letterSpacing: 1)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Top bar: action buttons
      Row(children: [
        const Spacer(),
        // Library button
        _IconBtn(
          icon: Icons.bookmarks_outlined,
          tooltip: 'Библиотека рецептов',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SavedRecipesPage()),
          ),
        ),
      ]),
      const SizedBox(height: 8),

      // Action row: save / regenerate / print (only when recipe loaded)
      if (!_isLoading && _recipe != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            // Cache badge
            if (_isCached)
              Expanded(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withAlpha(60)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.folder_outlined, color: Colors.blue, size: 14),
                  SizedBox(width: 4),
                  Text('Из библиотеки',
                      style: TextStyle(color: Colors.blue, fontSize: 11)),
                ]),
              )),
            if (!_isCached) const Spacer(),
            const SizedBox(width: 8),
            // Save button (only if not cached)
            if (!_isCached)
              _ActionBtn(
                icon: _isSaving ? Icons.hourglass_top : Icons.star_border,
                label: _isSaving ? '...' : 'Сохранить',
                color: AppColors.primary,
                onTap: _isSaving ? null : _saveRecipe,
              ),
            // Regenerate button (only if cached)
            if (_isCached)
              _ActionBtn(
                icon: Icons.refresh,
                label: 'Обновить',
                color: AppColors.textSecondary,
                onTap: () => _loadRecipe(forceApi: true),
              ),
            const SizedBox(width: 8),
            // Print button
            _ActionBtn(
              icon: Icons.print_outlined,
              label: 'Печать',
              color: AppColors.textSecondary,
              onTap: _printRecipe,
            ),
          ]),
        ),

      Expanded(
        child: _isLoading
            ? _LoadingState()
            : _error != null
                ? _ErrorState(error: _error!, onRetry: _loadRecipe)
                : _ExpertRecipeView(recipe: _recipe!), // Always Expert mode
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL ACTION WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.textSecondary, size: 20),
          ),
        ),
      );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(80)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPERT MODE
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertRecipeView extends StatelessWidget {
  final DetailedRecipe recipe;
  const _ExpertRecipeView({required this.recipe});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ExpertHeader(
            totalTime: recipe.totalTimeSeconds,
            difficulty: recipe.difficulty ?? 'intermediate',
          ),
          const SizedBox(height: 20),
          if (recipe.history != null && recipe.history!.isNotEmpty) ...[
            _SectionTitle('📜 История'),
            const SizedBox(height: 8),
            _HistoryCard(history: recipe.history!),
            const SizedBox(height: 20),
          ],
          if (recipe.sensoryProfile != null &&
              recipe.sensoryProfile!.isNotEmpty) ...[
            _SectionTitle('👃 Сенсорный профиль'),
            const SizedBox(height: 12),
            _SensoryRow(profile: recipe.sensoryProfile!),
            const SizedBox(height: 20),
          ],
          if (recipe.techniques != null && recipe.techniques!.isNotEmpty) ...[
            _SectionTitle('⚗️ Техники'),
            const SizedBox(height: 10),
            _TechniqueChips(techniques: recipe.techniques!),
            const SizedBox(height: 20),
          ],
          if (recipe.premiumIngredients != null &&
              recipe.premiumIngredients!.isNotEmpty) ...[
            _SectionTitle('💎 Премиум ингредиенты'),
            const SizedBox(height: 10),
            ...recipe.premiumIngredients!
                .map((i) => _PremiumIngredientCard(ingredient: i)),
            const SizedBox(height: 8),
          ],
          if (recipe.servicePresentation != null &&
              recipe.servicePresentation!.isNotEmpty) ...[
            _SectionTitle('🍸 Подача'),
            const SizedBox(height: 10),
            _ServicePresentationCard(steps: recipe.servicePresentation!),
            const SizedBox(height: 20),
          ],
          // Recipe steps - THE ACTUAL RECIPE!
          if (recipe.steps.isNotEmpty) ...[
            _SectionTitle('📝 Пошаговый рецепт'),
            const SizedBox(height: 12),
            ...recipe.steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              return _StepCard(
                stepNumber: step.stepNumber,
                title: step.title,
                description: step.description,
                durationSeconds: step.durationSeconds,
                tip: step.tip,
                isLast: idx == recipe.steps.length - 1,
              );
            }),
            const SizedBox(height: 20),
          ],
          if (recipe.proSecrets != null && recipe.proSecrets!.isNotEmpty) ...[
            _SectionTitle('🔐 Секреты мастера'),
            const SizedBox(height: 8),
            ...recipe.proSecrets!.map((s) =>
                _TipTile(text: s, icon: Icons.lock, color: AppColors.primary)),
            const SizedBox(height: 20),
          ],
          if (recipe.variations != null && recipe.variations!.isNotEmpty) ...[
            _SectionTitle('🎨 Вариации'),
            const SizedBox(height: 8),
            ...recipe.variations!.map((v) => _VariationTile(text: v)),
            const SizedBox(height: 20),
          ],
          if (recipe.foodPairing != null && recipe.foodPairing!.isNotEmpty) ...[
            _SectionTitle('🍽️ Гастро-пэйринг'),
            const SizedBox(height: 10),
            _FoodPairingRow(items: recipe.foodPairing!),
            const SizedBox(height: 20),
          ],
          if (recipe.estimatedCostMdl != null) ...[
            _SectionTitle('💰 Экономика'),
            const SizedBox(height: 10),
            _CostCard(
                cost: recipe.estimatedCostMdl!,
                price: recipe.suggestedPriceMdl),
          ],
          const SizedBox(height: 32),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      );
}

class _TipTile extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _TipTile({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13))),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EXPERT WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ExpertHeader extends StatelessWidget {
  final int totalTime;
  final String difficulty;
  const _ExpertHeader({required this.totalTime, required this.difficulty});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.primary.withAlpha(30), AppColors.surface]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(50)),
        ),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    '⏱️ ${totalTime ~/ 60}:${(totalTime % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Difficulty: ${difficulty.toUpperCase()}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star, color: Colors.black, size: 16),
              SizedBox(width: 4),
              Text('PRO',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
          ),
        ]),
      );
}

class _HistoryCard extends StatelessWidget {
  final String history;
  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(history,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14, height: 1.6)),
      );
}

class _SensoryRow extends StatefulWidget {
  final Map<String, String> profile;
  const _SensoryRow({required this.profile});
  @override
  State<_SensoryRow> createState() => _SensoryRowState();
}

class _SensoryRowState extends State<_SensoryRow> {
  String? _expanded;

  static const _labels = {
    'aroma': ('👃', 'Аромат'),
    'taste': ('👅', 'Вкус'),
    'texture': ('💧', 'Текстура'),
    'finish': ('✨', 'Финал'),
  };

  @override
  Widget build(BuildContext context) {
    final keys = ['aroma', 'taste', 'texture', 'finish'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
          children: keys.map((key) {
        final info = _labels[key];
        if (info == null || !widget.profile.containsKey(key))
          return const SizedBox.shrink();
        final isSelected = _expanded == key;
        return Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _expanded = _expanded == key ? null : key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider),
              ),
              child: Column(children: [
                Text(info.$1, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(info.$2,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.black : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
              ]),
            ),
          ),
        );
      }).toList()),
      if (_expanded != null && widget.profile.containsKey(_expanded)) ...[
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withAlpha(60)),
          ),
          child: Text(widget.profile[_expanded]!,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, height: 1.5)),
        ),
      ],
    ]);
  }
}

class _TechniqueChips extends StatelessWidget {
  final List<String> techniques;
  const _TechniqueChips({required this.techniques});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: techniques
            .map((t) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Text(t,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ))
            .toList(),
      );
}

class _PremiumIngredientCard extends StatelessWidget {
  final PremiumIngredient ingredient;
  const _PremiumIngredientCard({required this.ingredient});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(40)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.star, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(ingredient.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14))),
          ]),
          if (ingredient.recommendation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Рекомендую: ',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Expanded(
                  child: Text(ingredient.recommendation,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12))),
            ]),
          ],
          if (ingredient.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.science_outlined,
                    color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(ingredient.reason,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic))),
              ]),
            ),
          ],
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP CARD - The actual recipe steps
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final int durationSeconds;
  final String? tip;
  final bool isLast;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.durationSeconds,
    this.tip,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withAlpha(15),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step header with number
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (durationSeconds > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${durationSeconds}с',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            // Tip (if exists)
            if (tip != null && tip!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

class _ServicePresentationCard extends StatelessWidget {
  final List<String> steps;
  const _ServicePresentationCard({required this.steps});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withAlpha(40)),
        ),
        child: Column(
            children: steps.asMap().entries.map((e) {
          final idx = e.key;
          return Padding(
            padding: EdgeInsets.only(bottom: idx < steps.length - 1 ? 14 : 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Center(
                    child: Text('${idx + 1}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(e.value,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.5))),
            ]),
          );
        }).toList()),
      );
}

class _FoodPairingRow extends StatelessWidget {
  final List<String> items;
  const _FoodPairingRow({required this.items});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items
            .map((item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Text(item,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12)),
                ))
            .toList(),
      );
}

class _VariationTile extends StatelessWidget {
  final String text;
  const _VariationTile({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.swap_horiz,
              color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13))),
        ]),
      );
}

class _CostCard extends StatelessWidget {
  final int cost;
  final int? price;
  const _CostCard({required this.cost, this.price});

  @override
  Widget build(BuildContext context) {
    final margin = price != null ? price! - cost : null;
    final mp = margin != null ? (margin / cost * 100).round() : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Себестоимость:',
              style: TextStyle(color: AppColors.textSecondary)),
          Text('$cost MDL',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ]),
        if (price != null) ...[
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Цена в меню:',
                style: TextStyle(color: AppColors.textSecondary)),
            Text('$price MDL',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ]),
        ],
        if (mp != null) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Маржа:',
                style: TextStyle(color: AppColors.textSecondary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('+$margin MDL ($mp%)',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ]),
        ],
      ]),
    );
  }
}
