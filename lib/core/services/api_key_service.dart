import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyService extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  String? _cachedKey;

  static const _key = 'openai_api_key';

  ApiKeyService()
      : _storage = const FlutterSecureStorage();

  bool get hasKey => _cachedKey != null && _cachedKey!.isNotEmpty;

  String? get apiKey => _cachedKey;

  Future<void> load() async {
    try {
      _cachedKey = await _storage.read(key: _key);
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Failed to load API key: $e');
    }
  }

  Future<void> saveKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clearKey();
      return;
    }
    await _storage.write(key: _key, value: trimmed);
    _cachedKey = trimmed;
    notifyListeners();
  }

  Future<void> clearKey() async {
    await _storage.delete(key: _key);
    _cachedKey = null;
    notifyListeners();
  }
}
