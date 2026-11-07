/// Постоянные гости бара Джона.
///
/// Каждый гость — личность с предпочтениями. В режиме «Смена» они
/// заказывают коктейли и реагируют на качество.
library;

/// Предпочтение по вкусу — влияет на то, как гость оценивает коктейль.
enum GuestPreference {
  /// Любит покислее (больше цитруса).
  sour,

  /// Любит послаще.
  sweet,

  /// Любит покрепче (больше алкоголя).
  strong,

  /// Классика, как в рецепте.
  classic,
}

class Guest {
  final String name;
  final String emoji;
  final GuestPreference preference;
  final String signaturePhrase;

  const Guest({
    required this.name,
    required this.emoji,
    required this.preference,
    required this.signaturePhrase,
  });

  String get preferenceLabel {
    return switch (preference) {
      GuestPreference.sour => 'любит покислее',
      GuestPreference.sweet => 'любит послаще',
      GuestPreference.strong => 'любит покрепче',
      GuestPreference.classic => 'ценит классику',
    };
  }
}

/// Пул гостей для режима «Смена».
const List<Guest> barGuests = [
  Guest(
    name: 'Сергей',
    emoji: '🧔',
    preference: GuestPreference.sour,
    signaturePhrase: 'В прошлый раз перекислил, будь внимательнее.',
  ),
  Guest(
    name: 'Анна',
    emoji: '👩',
    preference: GuestPreference.sweet,
    signaturePhrase: 'Мне нравится, когда есть лёгкая сладость.',
  ),
  Guest(
    name: 'Дмитрий',
    emoji: '👨',
    preference: GuestPreference.strong,
    signaturePhrase: 'Покрепче, я за рулём не сяду.',
  ),
  Guest(
    name: 'Марина',
    emoji: '👩‍🦰',
    preference: GuestPreference.classic,
    signaturePhrase: 'Как в рецепте — и будет правильно.',
  ),
  Guest(
    name: 'Олег',
    emoji: '🧑',
    preference: GuestPreference.sour,
    signaturePhrase: 'Без лимона не тот напиток.',
  ),
  Guest(
    name: 'Елена',
    emoji: '👩‍🦱',
    preference: GuestPreference.sweet,
    signaturePhrase: 'Горьковато — можно помягче.',
  ),
];
