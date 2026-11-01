import 'package:flutter/material.dart';

/// Пресет стиля коктейля — быстрый выбор профиля вкуса.
///
/// Бармен выбирает один пресет, и все слайдеры автоматически
/// устанавливаются на базовые значения для этого стиля.
enum StylePreset {
  refreshing, // Лайм, мята, содовая, низкая крепость
  classic, // Баланс, биттеры, средний сахар
  bold, // Крепко, мало льда, выдержанные спирты
  dessert, // Сливки, шоколад, сиропы, низкая кислотность
  experimental // Копчение, инфьюзы, нестандартные текстуры
}

extension StylePresetX on StylePreset {
  /// Название пресета
  String get label {
    switch (this) {
      case StylePreset.refreshing:
        return 'Освежающий';
      case StylePreset.classic:
        return 'Классический';
      case StylePreset.bold:
        return 'Крепкий';
      case StylePreset.dessert:
        return 'Десертный';
      case StylePreset.experimental:
        return 'Эксперимент';
    }
  }

  /// Описание пресета — что ожидать
  String get description {
    switch (this) {
      case StylePreset.refreshing:
        return 'Лайм, мята, лёгкий, газированный';
      case StylePreset.classic:
        return 'Баланс, биттеры, проверенные сочетания';
      case StylePreset.bold:
        return 'Крепкий, минимум миксера, выдержанные спирты';
      case StylePreset.dessert:
        return 'Сливки, шоколад, сладкий, бархатистый';
      case StylePreset.experimental:
        return 'Копчение, инфьюзы, нестандартные техники';
    }
  }

  /// Иконка для пресета
  IconData get icon {
    switch (this) {
      case StylePreset.refreshing:
        return Icons.water_drop_outlined;
      case StylePreset.classic:
        return Icons.balance_outlined;
      case StylePreset.bold:
        return Icons.local_fire_department_outlined;
      case StylePreset.dessert:
        return Icons.cake_outlined;
      case StylePreset.experimental:
        return Icons.science_outlined;
    }
  }

  /// Цвет акцента для пресета
  Color get accentColor {
    switch (this) {
      case StylePreset.refreshing:
        return const Color(0xFF4ECDC4); // мятный
      case StylePreset.classic:
        return const Color(0xFFE8B84B); // золотой
      case StylePreset.bold:
        return const Color(0xFFE85D4E); // красный
      case StylePreset.dessert:
        return const Color(0xFFCF6B9A); // розовый
      case StylePreset.experimental:
        return const Color(0xFF9B59B6); // фиолетовый
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  БАЗОВЫЕ ЗНАЧЕНИЯ ДЛЯ СЛАЙДЕРОВ
  // ════════════════════════════════════════════════════════════════════════════

  /// Крепость: 0-10
  int get baseStrength {
    switch (this) {
      case StylePreset.refreshing:
        return 3;
      case StylePreset.classic:
        return 5;
      case StylePreset.bold:
        return 8;
      case StylePreset.dessert:
        return 4;
      case StylePreset.experimental:
        return 6;
    }
  }

  /// Сладость: 0-10
  int get baseSweetness {
    switch (this) {
      case StylePreset.refreshing:
        return 4;
      case StylePreset.classic:
        return 5;
      case StylePreset.bold:
        return 3;
      case StylePreset.dessert:
        return 8;
      case StylePreset.experimental:
        return 5;
    }
  }

  /// Кислотность: 0-10
  int get baseAcidity {
    switch (this) {
      case StylePreset.refreshing:
        return 7;
      case StylePreset.classic:
        return 5;
      case StylePreset.bold:
        return 3;
      case StylePreset.dessert:
        return 2;
      case StylePreset.experimental:
        return 5;
    }
  }

  /// Горечь: 0-10
  int get baseBitterness {
    switch (this) {
      case StylePreset.refreshing:
        return 2;
      case StylePreset.classic:
        return 5;
      case StylePreset.bold:
        return 6;
      case StylePreset.dessert:
        return 2;
      case StylePreset.experimental:
        return 5;
    }
  }

  /// Газированность по умолчанию
  bool get baseSparkling {
    switch (this) {
      case StylePreset.refreshing:
        return true;
      case StylePreset.classic:
        return false;
      case StylePreset.bold:
        return false;
      case StylePreset.dessert:
        return false;
      case StylePreset.experimental:
        return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  КОНТЕКСТ ПОДАЧИ (значения по умолчанию)
  // ════════════════════════════════════════════════════════════════════════════

  /// Доминирующий аромат по умолчанию
  String get defaultAroma {
    switch (this) {
      case StylePreset.refreshing:
        return 'Цитрусовый';
      case StylePreset.classic:
        return 'Травяной';
      case StylePreset.bold:
        return 'Пряный';
      case StylePreset.dessert:
        return 'Сладкий';
      case StylePreset.experimental:
        return 'Дымный';
    }
  }

  /// Текстура по умолчанию
  String get defaultTexture {
    switch (this) {
      case StylePreset.refreshing:
        return 'Лёгкое';
      case StylePreset.classic:
        return 'Сбалансированное';
      case StylePreset.bold:
        return 'Плотное';
      case StylePreset.dessert:
        return 'Бархатистое';
      case StylePreset.experimental:
        return 'Сложное';
    }
  }

  /// Цель по умолчанию
  String get defaultGoal {
    switch (this) {
      case StylePreset.refreshing:
        return 'Аперитив';
      case StylePreset.classic:
        return 'Вечеринка';
      case StylePreset.bold:
        return 'Дижестив';
      case StylePreset.dessert:
        return 'Десерт';
      case StylePreset.experimental:
        return 'Вечеринка';
    }
  }
}
