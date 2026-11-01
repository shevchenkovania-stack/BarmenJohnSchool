import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';

/// PDF menu generator service.
///
/// Features:
///   - Downloads cocktail photos from network and embeds them
///   - Supports per-cocktail price display
///   - Three visual themes: classic (dark/gold), modern (bold black), minimal (clean gray)
///   - Google Fonts (Nunito family) with built-in fallback when offline
///
/// Usage:
///   ```dart
///   await MenuPdfService.previewAndPrint(
///     context: context,
///     venueName: 'Sunset Bar',
///     cocktails: selectedList,
///     theme: 'classic',
///     prices: {'11007': 12.5, '11008': 10.0},
///   );
///   ```
class MenuPdfService {
  MenuPdfService._(); // static-only class

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Builds PDF and opens the built-in preview screen.
  ///
  /// [prices] — map of cocktail idDrink → price to display in the menu.
  static Future<void> previewAndPrint({
    required BuildContext context,
    required String venueName,
    required List<Cocktail> cocktails,
    required String theme,
    Map<String, double> prices = const {},
  }) async {
    final doc = await _buildDocument(
      venueName: venueName,
      cocktails: cocktails,
      theme: theme,
      prices: prices,
    );
    final bytes = await doc.save();

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfPreviewScreen(
            title: venueName.isEmpty ? 'Menu' : venueName,
            pdfBytes: bytes,
          ),
        ),
      );
    }
  }

  // ─── Document builder ──────────────────────────────────────────────────────

  static Future<pw.Document> _buildDocument({
    required String venueName,
    required List<Cocktail> cocktails,
    required String theme,
    required Map<String, double> prices,
  }) async {
    final doc = pw.Document();
    final cfg = _ThemeConfig.fromTheme(theme);

    // ── Load Google Fonts with fallback to built-in Helvetica ──
    pw.Font fontRegular;
    pw.Font fontBold;
    pw.Font fontLight;
    pw.Font fontExtraBold;
    try {
      fontRegular = await PdfGoogleFonts.nunitoRegular();
      fontBold = await PdfGoogleFonts.nunitoBold();
      fontLight = await PdfGoogleFonts.nunitoLight();
      fontExtraBold = await PdfGoogleFonts.nunitoExtraBold();
    } catch (_) {
      // Offline fallback: use built-in Helvetica
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
      fontLight = pw.Font.helvetica();
      fontExtraBold = pw.Font.helveticaBold();
    }

    // ── Download all cocktail photos in parallel (6-second timeout) ──
    // Images that fail to load are stored as null → a letter placeholder is used.
    final Map<String, pw.ImageProvider?> images = {};
    await Future.wait(cocktails.map((c) async {
      if (c.strDrinkThumb.isNotEmpty) {
        try {
          images[c.idDrink] = await networkImage(c.strDrinkThumb)
              .timeout(const Duration(seconds: 6));
        } catch (_) {
          images[c.idDrink] = null;
        }
      }
    }));

    doc.addPage(
      pw.MultiPage(
        // pageFormat and margin must live inside pageTheme, not at MultiPage level
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 36),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
            // Built-in Helvetica handles characters the Google Font may miss (e.g. em-dash)
            fontFallback: [pw.Font.helvetica()],
          ),
          buildBackground: (ctx) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: cfg.background),
          ),
        ),

        header: (ctx) => _buildHeader(
          venueName: venueName,
          cfg: cfg,
          fontExtraBold: fontExtraBold,
          fontRegular: fontRegular,
          isFirstPage: ctx.pageNumber == 1,
        ),
        footer: (ctx) => _buildFooter(ctx, cfg, fontRegular),

        build: (ctx) => cocktails
            .map((c) => _buildCocktailRow(
                  cocktail: c,
                  cfg: cfg,
                  image: images[c.idDrink],
                  price: prices[c.idDrink],
                  fontBold: fontBold,
                  fontRegular: fontRegular,
                  fontLight: fontLight,
                ))
            .toList(),
      ),
    );

    return doc;
  }

  // ─── Page header ───────────────────────────────────────────────────────────

  static pw.Widget _buildHeader({
    required String venueName,
    required _ThemeConfig cfg,
    required pw.Font fontExtraBold,
    required pw.Font fontRegular,
    required bool isFirstPage,
  }) {
    if (!isFirstPage) {
      // Subsequent pages: thin separator only
      return pw.Column(children: [
        pw.Divider(color: cfg.accent, thickness: 0.5),
        pw.SizedBox(height: 12),
      ]);
    }

    // First page: full venue title block
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: cfg.accent, thickness: 2),
        pw.SizedBox(height: 12),

        // Venue name
        if (venueName.isNotEmpty) ...[
          pw.Center(
            child: pw.Text(
              venueName.toUpperCase(),
              style: pw.TextStyle(
                font: fontExtraBold,
                fontSize: 28,
                color: cfg.titleColor,
                letterSpacing: 4,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
        ],

        // Subtitle
        pw.Center(
          child: pw.Text(
            'COCKTAIL MENU',
            style: pw.TextStyle(
              font: fontRegular,
              fontSize: 10,
              color: cfg.accent,
              letterSpacing: 5,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: cfg.accent, thickness: 2),
        pw.SizedBox(height: 20),
      ],
    );
  }

  // ─── Page footer ───────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(
    pw.Context ctx,
    _ThemeConfig cfg,
    pw.Font font,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Prices may vary',
            style:
                pw.TextStyle(font: font, fontSize: 8, color: cfg.subtitleColor),
          ),
          pw.Text(
            '${ctx.pageNumber} / ${ctx.pagesCount}',
            style:
                pw.TextStyle(font: font, fontSize: 8, color: cfg.subtitleColor),
          ),
        ],
      ),
    );
  }

  // ─── Single cocktail row ────────────────────────────────────────────────────

  static pw.Widget _buildCocktailRow({
    required Cocktail cocktail,
    required _ThemeConfig cfg,
    required pw.ImageProvider? image,
    required double? price,
    required pw.Font fontBold,
    required pw.Font fontRegular,
    required pw.Font fontLight,
  }) {
    // Sanitize: replace em-dash / en-dash with plain hyphen
    // (Nunito does not include U+2014 / U+2013)
    String s(String t) => t.replaceAll('\u2014', '-').replaceAll('\u2013', '-');

    const double imageSize = 72.0;

    // Ingredient list: first 6 items with their measures
    final ingredients = cocktail.ingredients.take(6).toList();
    final measures = cocktail.measures;
    final ingParts = List<String>.generate(ingredients.length, (i) {
      final m = (i < measures.length && measures[i].trim().isNotEmpty)
          ? measures[i].trim()
          : '';
      return m.isNotEmpty
          ? '${s(ingredients[i])} (${s(m)})'
          : s(ingredients[i]);
    });
    final ingText = ingParts.join('  ·  ');

    // Category · Glass line
    final meta = [s(cocktail.strCategory), s(cocktail.strGlass)]
        .where((t) => t.isNotEmpty)
        .join('  ·  ');

    // First letter placeholder (shown when image fails to load)
    final initial =
        cocktail.strDrink.isNotEmpty ? cocktail.strDrink[0].toUpperCase() : '?';

    final name = s(cocktail.strDrink).toUpperCase();

    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // ── Photo or letter placeholder ──
            pw.Container(
              width: imageSize,
              height: imageSize,
              decoration: pw.BoxDecoration(
                color: cfg.cardColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: image != null
                  ? pw.ClipRRect(
                      horizontalRadius: 10,
                      verticalRadius: 10,
                      child: pw.Image(
                        image,
                        width: imageSize,
                        height: imageSize,
                        fit: pw.BoxFit.cover,
                      ),
                    )
                  : pw.Center(
                      child: pw.Text(
                        initial,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 30,
                          color: cfg.accent,
                        ),
                      ),
                    ),
            ),

            pw.SizedBox(width: 16),

            // ── Text block ──
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Name + price in one row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: cfg.titleColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (price != null && price > 0)
                        pw.Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 14,
                            color: cfg.accent,
                          ),
                        ),
                    ],
                  ),

                  // Category · Glass
                  if (meta.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      meta,
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 8,
                        color: cfg.subtitleColor,
                      ),
                    ),
                  ],

                  pw.SizedBox(height: 6),

                  // Ingredients
                  pw.Text(
                    ingText,
                    style: pw.TextStyle(
                      font: fontLight,
                      fontSize: 9,
                      color: cfg.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(color: cfg.borderColor, thickness: 0.5),
        pw.SizedBox(height: 10),
      ],
    );
  }
}

// ─── Theme configuration ───────────────────────────────────────────────────────

/// Color palette for a given menu theme.
class _ThemeConfig {
  final PdfColor background;
  final PdfColor cardColor;
  final PdfColor titleColor;
  final PdfColor textColor;
  final PdfColor subtitleColor;
  final PdfColor accent;
  final PdfColor borderColor;

  const _ThemeConfig({
    required this.background,
    required this.cardColor,
    required this.titleColor,
    required this.textColor,
    required this.subtitleColor,
    required this.accent,
    required this.borderColor,
  });

  factory _ThemeConfig.fromTheme(String theme) {
    switch (theme) {
      // ── Classic: dark navy, gold accents ──────────────────────────────────
      case 'classic':
        return const _ThemeConfig(
          background: PdfColor.fromInt(0xFF1A1825),
          cardColor: PdfColor.fromInt(0xFF252336),
          titleColor: PdfColors.white,
          textColor: PdfColor.fromInt(0xFFB0ABCF),
          subtitleColor: PdfColor.fromInt(0xFF7A7598),
          accent: PdfColor.fromInt(0xFFE8A838),
          borderColor: PdfColor.fromInt(0xFF2F2D45),
        );

      // ── Modern: white, bold black, dark accent ────────────────────────────
      case 'modern':
        return const _ThemeConfig(
          background: PdfColors.white,
          cardColor: PdfColor.fromInt(0xFFF0F0F0),
          titleColor: PdfColors.black,
          textColor: PdfColor.fromInt(0xFF333333),
          subtitleColor: PdfColor.fromInt(0xFF888888),
          accent: PdfColor.fromInt(0xFF1A1A1A),
          borderColor: PdfColor.fromInt(0xFFDDDDDD),
        );

      // ── Minimal: white, thin lines, warm gray accents ─────────────────────
      case 'minimal':
      default:
        return const _ThemeConfig(
          background: PdfColors.white,
          cardColor: PdfColor.fromInt(0xFFF7F5F0),
          titleColor: PdfColor.fromInt(0xFF1A1A1A),
          textColor: PdfColor.fromInt(0xFF555555),
          subtitleColor: PdfColor.fromInt(0xFFAAAAAA),
          accent: PdfColor.fromInt(0xFF8B6914),
          borderColor: PdfColor.fromInt(0xFFE8E4DC),
        );
    }
  }
}

// ─── PDF preview screen ────────────────────────────────────────────────────────

/// Full-screen PDF preview with print/save buttons.
class _PdfPreviewScreen extends StatelessWidget {
  final String title;
  final Uint8List pdfBytes;

  const _PdfPreviewScreen({
    required this.title,
    required this.pdfBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
      ),
      body: PdfPreview(
        // Provide pre-built bytes — no second generation needed
        build: (_) => pdfBytes,
        pdfFileName: '$title.pdf',
        useActions: true,
        canChangePageFormat: false,
        canDebug: false,
      ),
    );
  }
}
