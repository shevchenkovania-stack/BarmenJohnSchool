import 'package:coin/core/models/cocktail.dart';

/// Generates a self-contained HTML menu page from a list of cocktails.
///
/// The produced HTML:
///   - Is mobile-first (fits any phone screen)
///   - Uses the app's dark/gold visual identity
///   - Shows cocktail photos from TheCocktailDB CDN (with letter fallback)
///   - Displays price in the chosen currency when provided
///   - Has zero external dependencies — works without internet if images are cached
class HtmlMenuBuilder {
  HtmlMenuBuilder._();

  /// Builds and returns a full HTML document string.
  ///
  /// [venueName] appears as the page title and header.
  /// [prices]    map of idDrink → menu price (0 or absent = not shown).
  /// [currency]  currency symbol / code shown after the price (default: MDL).
  static String build({
    required String venueName,
    required List<Cocktail> cocktails,
    required Map<String, double> prices,
    String currency = 'MDL',
  }) {
    final title = venueName.isNotEmpty ? venueName : 'Cocktail Menu';
    final cards = cocktails
        .map((c) => _buildCard(c, prices[c.idDrink], currency))
        .join('\n');
    final year = DateTime.now().year;

    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
<meta name="theme-color" content="#1a1825">
<title>${_esc(title)}</title>
<style>
*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent}
:root{
  --bg:#1a1825;--card:#252336;--card2:#2a2740;
  --gold:#e8a838;--gold2:#c8911c;
  --text:#ffffff;--sub:#b0abcf;--border:#2f2d45
}
body{background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;min-height:100vh;padding-bottom:32px}

/* ── Header ── */
.hdr{text-align:center;padding:36px 20px 0}
.hdr-line{height:2px;background:linear-gradient(90deg,transparent 0%,var(--gold) 30%,var(--gold) 70%,transparent 100%);margin:0 32px 14px}
.hdr-venue{font-size:clamp(20px,6vw,30px);font-weight:800;letter-spacing:4px;text-transform:uppercase;line-height:1.1}
.hdr-sub{font-size:10px;letter-spacing:5px;color:var(--gold);margin-top:6px;text-transform:uppercase}
.hdr-line2{height:1px;background:linear-gradient(90deg,transparent 0%,var(--border) 30%,var(--border) 70%,transparent 100%);margin:14px 32px 0}

/* ── Grid ── */
.grid{padding:20px 14px 0;max-width:600px;margin:0 auto}

/* ── Card ── */
.card{display:flex;background:var(--card);border-radius:14px;margin-bottom:12px;overflow:hidden;border:1px solid var(--border);transition:transform .12s,box-shadow .12s}
.card:active{transform:scale(.985);box-shadow:0 2px 12px rgba(232,168,56,.15)}

/* Photo block */
.ci{width:86px;height:86px;flex-shrink:0;position:relative;overflow:hidden;background:var(--border)}
.ci img{width:100%;height:100%;object-fit:cover;display:block}
.ci-ph{width:100%;height:100%;display:none;align-items:center;justify-content:center;font-size:28px;font-weight:800;color:var(--gold);background:var(--card2)}

/* Body */
.cb{padding:10px 12px;flex:1;min-width:0;display:flex;flex-direction:column;gap:3px}
.ct{display:flex;justify-content:space-between;align-items:baseline;gap:6px}
.cn{font-size:14px;font-weight:700;letter-spacing:.4px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;flex:1}
.cp{font-size:15px;font-weight:800;color:var(--gold);white-space:nowrap;flex-shrink:0}
.cm{font-size:10px;color:var(--sub);text-transform:uppercase;letter-spacing:.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.ci2{font-size:11px;color:var(--sub);line-height:1.45;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical}

/* ── Footer ── */
.ft{text-align:center;margin-top:28px;color:var(--border);font-size:11px;letter-spacing:2px}
.ft span{color:var(--gold);opacity:.4}
</style>
</head>
<body>

<div class="hdr">
  <div class="hdr-line"></div>
  <div class="hdr-venue">${_esc(title)}</div>
  <div class="hdr-sub">Cocktail&nbsp;&nbsp;Menu</div>
  <div class="hdr-line2"></div>
</div>

<div class="grid">
$cards
</div>

<div class="ft"><span>✦</span>&nbsp; $year &nbsp;<span>✦</span></div>

<script>
// Replace broken images with letter placeholder
document.querySelectorAll('.ci img').forEach(function(img){
  img.onerror=function(){
    this.style.display='none';
    var ph=this.nextElementSibling;
    if(ph){ph.style.display='flex';}
  };
});
</script>
</body>
</html>''';
  }

  // ── Single cocktail card HTML ──────────────────────────────────────────────

  static String _buildCard(Cocktail c, double? price, String currency) {
    final initial = c.strDrink.isNotEmpty ? c.strDrink[0].toUpperCase() : '?';
    final meta =
        [c.strCategory, c.strGlass].where((s) => s.isNotEmpty).join(' · ');
    final ings = c.ingredients.take(6).join(', ');
    final priceTag = (price != null && price > 0)
        ? '<span class="cp">${price.toStringAsFixed(0)}&nbsp;$currency</span>'
        : '';

    return '''<div class="card">
  <div class="ci">
    <img src="${_esc(c.strDrinkThumb)}" loading="lazy" alt="${_esc(c.strDrink)}">
    <div class="ci-ph">$initial</div>
  </div>
  <div class="cb">
    <div class="ct">
      <span class="cn">${_esc(c.strDrink)}</span>
      $priceTag
    </div>
    ${meta.isNotEmpty ? '<div class="cm">${_esc(meta)}</div>' : ''}
    ${ings.isNotEmpty ? '<div class="ci2">${_esc(ings)}</div>' : ''}
  </div>
</div>''';
  }

  // ── HTML escape ────────────────────────────────────────────────────────────

  /// Escapes characters that are unsafe inside HTML text / attribute values.
  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
