import 'package:flutter/material.dart';

/// Насколько «позднo» сейчас в баре.
///
/// Школа живёт по реальному времени: вечером свет тёплый, лампы над стойкой
/// горят, а днём комната просто залита светом из окна. Это единственное
/// место, где считается время, — чтобы экраны не расходились между собой.
bool isEveningNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  return hour >= 18 || hour < 5;
}

/// Насколько сильно вечерний оверлей заливает комнату (0..1).
///
/// Ночью (после 23:00) комната темнее, чем в 18:00 — но не настолько, чтобы
/// текст стал нечитаемым.
double eveningStrength([DateTime? now]) {
  final t = now ?? DateTime.now();
  if (!isEveningNow(t)) return 0;
  final hour = t.hour;
  if (hour >= 23 || hour < 5) return 1.0;
  // 18:00 → 0.45, 22:00 → 1.0, линейно.
  return 0.45 + (hour - 18) / 4 * 0.55;
}

/// Состояние комнаты по прогрессу блока.
///
/// Только оверлеи: сами картинки комнат не трогаем, чтобы не тащить новый арт.
enum RoomStage {
  /// Ни один урок блока не сдан.
  empty,

  /// Блок начат: на стойке уже стоит один бокал.
  working,

  /// Блок закрыт: верхний свет и медаль.
  finished,
}

/// Вычисляет стадию комнаты по числу сданных и всех уроков блока.
RoomStage roomStageFor({
  required int completedLessons,
  required int totalLessons,
}) {
  if (totalLessons <= 0) return RoomStage.empty;
  if (completedLessons >= totalLessons) return RoomStage.finished;
  if (completedLessons > 0) return RoomStage.working;
  return RoomStage.empty;
}

/// Тёплый вечерний слой поверх комнаты.
///
/// Отдельный виджет, а не часть фона: так его можно включать точечно и
/// тестировать без сборки всего экрана.
class EveningLightOverlay extends StatelessWidget {
  final double strength;

  const EveningLightOverlay({super.key, this.strength = 1});

  @override
  Widget build(BuildContext context) {
    if (strength <= 0) return const SizedBox.shrink();
    final s = strength.clamp(0.0, 1.0);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFF9A3C).withAlpha((38 * s).round()),
              const Color(0xFF2A1206).withAlpha((60 * s).round()),
              const Color(0xFF140803).withAlpha((96 * s).round()),
            ],
            stops: const [0, .55, 1],
          ),
        ),
      ),
    );
  }
}
