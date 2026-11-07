import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранилище ключа OpenAI.
///
/// В v1.0.0 AI-функции не входят в релиз (см.
/// `docs/review/06_AI_SCOPE_DECISION.md`): ключ нужен только конструктору
/// коктейлей, который пока недоступен из интерфейса. Сервис оставлен как
/// задел — однако, если ранее сохранённый ключ найден, он удаляется при
/// старте: держать чужой секрет в телефоне без работающей функции незачем.
class ApiKeyService extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  String? _cachedKey;

  static const _key = 'openai_api_key';

  /// Включены ли AI-функции в этой сборке. Для v1 — выключены.
  static const bool aiEnabled = false;

  ApiKeyService()
      : _storage = const FlutterSecureStorage();

  bool get hasKey => _cachedKey != null && _cachedKey!.isNotEmpty;

  String? get apiKey => _cachedKey;

  Future<void> load() async {
    try {
      final stored = await _storage.read(key: _key);
      if (!aiEnabled && stored != null && stored.isNotEmpty) {
        await _storage.delete(key: _key);
        _cachedKey = null;
        debugPrint('🔐 AI отключён в этой версии — сохранённый ключ удалён');
        notifyListeners();
        return;
      }
      _cachedKey = stored;
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
