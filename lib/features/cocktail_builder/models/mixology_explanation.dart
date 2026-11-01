/// Объяснение миксолога — почему коктейль именно такой.
///
/// Содержит профессиональное объяснение:
/// - почему выбрана эта база
/// - как достигнут баланс
/// - какие ароматы доминируют
/// - общее впечатление
class MixologyExplanation {
  final String base; // Почему выбран этот алкоголь
  final String balance; // Как достигнут баланс вкуса
  final String aroma; // Какие ароматы доминируют
  final String overall; // Почему это хороший коктейль

  const MixologyExplanation({
    required this.base,
    required this.balance,
    required this.aroma,
    required this.overall,
  });

  /// Создать из JSON
  factory MixologyExplanation.fromJson(Map<String, dynamic> json) {
    return MixologyExplanation(
      base: json['base'] ?? '',
      balance: json['balance'] ?? '',
      aroma: json['aroma'] ?? '',
      overall: json['overall'] ?? '',
    );
  }

  /// Конвертировать в JSON
  Map<String, dynamic> toJson() => {
        'base': base,
        'balance': balance,
        'aroma': aroma,
        'overall': overall,
      };
}
