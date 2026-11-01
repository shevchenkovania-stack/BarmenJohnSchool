import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Local HTTP server that serves the HTML cocktail menu over WiFi.
///
/// How it works:
///   1. [start] detects the device's local IPv4 address (no permissions needed)
///   2. Starts a shelf HTTP server on [_port]
///   3. Every request to any path returns the pre-built HTML page
///   4. QR code encodes the URL → guests on the same WiFi open the menu in browser
///   5. [stop] shuts the server down; called automatically on screen dispose
class QrMenuServer {
  // Fixed port — easy to remember, not commonly used
  static const int _port = 8765;

  HttpServer? _server;
  String? _localIp;

  bool get isRunning => _server != null;
  String? get url => _localIp != null ? 'http://$_localIp:$_port' : null;

  /// Starts the server with the provided [htmlContent].
  /// Returns the full URL (e.g. "http://192.168.1.5:8765") or null on failure.
  Future<String?> start({required String htmlContent}) async {
    await stop(); // stop any previously running instance

    _localIp = await _detectLocalIp();
    if (_localIp == null) return null;

    // All requests (regardless of path) return the same HTML menu page
    final handler = const Pipeline().addHandler(
      (Request _) => Response.ok(
        htmlContent,
        headers: {'Content-Type': 'text/html; charset=utf-8'},
      ),
    );

    try {
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4, // listen on all network interfaces
        _port,
      );
      return url;
    } catch (_) {
      _localIp = null;
      return null;
    }
  }

  /// Stops the HTTP server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _localIp = null;
  }

  /// Returns the device's local IPv4 address using dart:io (no permissions needed).
  /// Prefers addresses that start with 192.168.x.x or 10.x.x.x (typical LAN).
  static Future<String?> _detectLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      String? fallback;

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final ip = addr.address;
          // Prefer private LAN ranges
          if (ip.startsWith('192.168.') || ip.startsWith('10.')) return ip;
          fallback ??= ip;
        }
      }

      return fallback;
    } catch (_) {
      return null;
    }
  }
}
