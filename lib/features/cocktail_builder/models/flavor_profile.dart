/// Профиль вкуса коктейля.
///
/// Используется для отображения баланса вкуса
/// в готовом коктейле (полоски/слайдеры).
class FlavorProfile {
  final int strength; // Крепость: 0-10
  final int sweetness; // Сладость: 0-10
  final int acidity; // Кислотность: 0-10
  final int bitterness; // Горечь: 0-10
  final bool sparkling; // Газированность: да/нет

  const FlavorProfile({
    required this.strength,
    required this.sweetness,
    required this.acidity,
    required this.bitterness,
    required this.sparkling,
  });

  /// Создать из JSON
  factory FlavorProfile.fromJson(Map<String, dynamic> json) {
    return FlavorProfile(
      strength: _parseInt(json['strength']),
      sweetness: _parseInt(json['sweetness']),
      acidity: _parseInt(json['acidity']),
      bitterness: _parseInt(json['bitterness']),
      sparkling: json['sparkling'] == 'Да' ||
          json['sparkling'] == true ||
          json['sparkling'] == 'Yes',
    );
  }

  /// Конвертировать в JSON
  Map<String, dynamic> toJson() => {
        'strength': strength,
        'sweetness': sweetness,
        'acidity': acidity,
        'bitterness': bitterness,
        'sparkling': sparkling ? 'Да' : 'Нет',
      };

  /// Безопасный парсинг числа
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 5;
    return 5; // значение по умолчанию
  }
}
