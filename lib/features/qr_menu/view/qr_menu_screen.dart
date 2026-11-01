import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:coin/core/models/cocktail.dart';
import 'package:coin/core/theme/app_theme.dart';
import '../service/qr_menu_server.dart';
import '../service/html_menu_builder.dart';

/// Screen that starts a local HTTP server and shows a QR code.
///
/// Bar owner opens this screen → server starts → QR code appears.
/// Guests on the same WiFi scan the QR → browser opens the HTML menu.
/// Server is stopped automatically when the screen is disposed.
class QrMenuScreen extends StatefulWidget {
  final String venueName;
  final List<Cocktail> cocktails;
  final Map<String, double> prices;
  final String currency;

  const QrMenuScreen({
    super.key,
    required this.venueName,
    required this.cocktails,
    required this.prices,
    this.currency = 'MDL',
  });

  @override
  State<QrMenuScreen> createState() => _QrMenuScreenState();
}

// Three possible server states
enum _Status { starting, running, noNetwork }

class _QrMenuScreenState extends State<QrMenuScreen> {
  final _server = QrMenuServer();

  _Status _status = _Status.starting;
  String? _url;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  @override
  void dispose() {
    _server.stop(); // always shut down when leaving the screen
    super.dispose();
  }

  // ─── Server control ────────────────────────────────────────────────────────

  Future<void> _startServer() async {
    setState(() {
      _status = _Status.starting;
      _url = null;
    });

    // Build HTML once — same content served for every request
    final html = HtmlMenuBuilder.build(
      venueName: widget.venueName,
      cocktails: widget.cocktails,
      prices: widget.prices,
      currency: widget.currency,
    );

    final url = await _server.start(htmlContent: html);

    if (!mounted) return;
    if (url != null) {
      setState(() {
        _status = _Status.running;
        _url = url;
      });
    } else {
      setState(() {
        _status = _Status.noNetwork;
      });
    }
  }

  Future<void> _stopServer() async {
    await _server.stop();
    if (mounted)
      setState(() {
        _status = _Status.starting;
        _url = null;
      });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QR Menu'),
        actions: [
          if (_status == _Status.running)
            IconButton(
              icon: const Icon(Icons.stop_circle_rounded,
                  color: Colors.redAccent),
              tooltip: 'Stop server',
              onPressed: _stopServer,
            ),
        ],
      ),
      body: switch (_status) {
        _Status.starting => _buildLoading(),
        _Status.running => _buildRunning(),
        _Status.noNetwork => _buildNoNetwork(),
      },
    );
  }

  // ─── Loading state ─────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 20),
          Text(
            'Starting server…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Running state — QR code visible ──────────────────────────────────────

  Widget _buildRunning() {
    final url = _url!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          // ── Status badge ──
          const _StatusBadge(label: 'Server is running', color: Colors.green),
          const SizedBox(height: 32),

          // ── QR Code ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(60),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: url,
              version: QrVersions.auto,
              size: 230,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Copyable URL ──
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copied'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    url,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Instructions ──
          const _InfoCard(
            icon: Icons.wifi_rounded,
            text: 'Guests must be connected to the same WiFi network.\n'
                'Scan the QR code \u2192 menu opens in the phone browser.',
          ),
          const SizedBox(height: 8),
          const _InfoCard(
            icon: Icons.phone_android_rounded,
            text: 'Works on any smartphone \u2014 no app needed.\n'
                'Keep this screen open while guests are browsing.',
          ),
          const SizedBox(height: 32),

          // ── Restart button ──
          OutlinedButton.icon(
            onPressed: _startServer,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Restart server'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
            ),
          ),
        ],
      ),
    );
  }

  // ─── No network state ──────────────────────────────────────────────────────

  Widget _buildNoNetwork() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'Cannot detect local IP address.\n\nMake sure the device is connected to a WiFi network, then try again.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _startServer,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────

/// Coloured pill badge with an animated dot.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 9),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Small info card with icon + text.
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
