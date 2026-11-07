import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Звуковая атмосфера бара.
///
/// Правила:
/// - Все короткие эффекты (лёд, стук, ответ) играют один раз.
/// - Фоновый джаз крутится в цикле, громкость низкая.
/// - Если файла нет или плеер упал — сервис молча пропускает звук,
///   не падает и не показывает ошибку пользователю.
/// - В тестах и на платформах без аудио все методы — no-op.
///
/// Ожидаемые файлы в `assets/sounds/`:
///   shake.mp3        — лёд в шейкере
///   glass_tap.mp3    — стук бокала о стойку
///   correct.mp3      — правильный ответ в квизе
///   success.mp3      — награда/открытие
///   fail.mp3         — провал
///   bg_jazz.mp3      — фон бара (цикл)
///
/// Если файла нет — звук просто не играет.
class BarSoundService {
  BarSoundService._();

  static final BarSoundService instance = BarSoundService._();

  final AudioPlayer _fx = AudioPlayer();
  final AudioPlayer _bg = AudioPlayer();

  bool _enabled = true;
  bool _bgPlaying = false;

  /// Включить/выключить все звуки.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      await _fx.stop();
      await stopBg();
    }
  }

  bool get isEnabled => _enabled;

  Future<void> _play(String asset) async {
    if (!_enabled) return;
    try {
      await _fx.stop();
      await _fx.play(AssetSource(asset));
    } catch (_) {
      // Файла нет или платформа без аудио — молча игнорируем.
    }
  }

  /// Лёд в шейкере.
  Future<void> shake() => _play('sounds/shake.mp3');

  /// Стук бокала о стойку.
  Future<void> glassTap() => _play('sounds/glass_tap.mp3');

  /// Правильный ответ в квизе.
  Future<void> correct() => _play('sounds/correct.mp3');

  /// Награда, открытие диплома, бейдж.
  Future<void> success() => _play('sounds/success.mp3');

  /// Провал квиза/попытки.
  Future<void> fail() => _play('sounds/fail.mp3');

  /// Запустить фоновый джаз (низкая громкость, цикл).
  Future<void> playBg() async {
    if (!_enabled || _bgPlaying) return;
    try {
      await _bg.setReleaseMode(ReleaseMode.loop);
      await _bg.setVolume(0.15);
      await _bg.play(AssetSource('sounds/bg_jazz.mp3'));
      _bgPlaying = true;
    } catch (_) {
      // Файла нет — фон просто молчит.
    }
  }

  Future<void> stopBg() async {
    if (!_bgPlaying) return;
    try {
      await _bg.stop();
    } catch (_) {}
    _bgPlaying = false;
  }

  @mustCallSuper
  void dispose() {
    _fx.dispose();
    _bg.dispose();
  }
}
