import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';

/// Визуальный якорь для слайдера — текстовая метка под конкретным значением.
class SliderAnchor {
  final int value;
  final String label;

  const SliderAnchor({required this.value, required this.label});
}

/// Умный слайдер с визуальными якорями.
///
/// Показывает текстовые метки под слайдером, чтобы пользователь
/// понимал что означает каждое значение.
/// Также показывает подсказку о влиянии настройки.
class SmartSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;
  final Color color;
  final List<SliderAnchor> anchors;
  final int min;
  final int max;
  final String? hint;

  const SmartSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.color,
    required this.anchors,
    this.min = 0,
    this.max = 10,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с иконкой
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            if (hint != null)
              GestureDetector(
                onTap: () => _showHintDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ),
            // Текущее значение
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                _getCurrentAnchorLabel(),
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // Слайдер
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          // Визуальные якоря
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: anchors.map((anchor) {
                final isActive = value == anchor.value;
                return Text(
                  anchor.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? color
                        : AppColors.textSecondary.withOpacity(0.6),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentAnchorLabel() {
    // Находим ближайший якорь
    SliderAnchor? closest;
    int minDiff = 999;
    for (final anchor in anchors) {
      final diff = (anchor.value - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = anchor;
      }
    }
    return closest?.label ?? '$value';
  }

  void _showHintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        content: Text(hint!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}

/// Слайдер баланса: Сухой ↔ Сладкий
///
/// Связанный параметр: при изменении баланса меняются
/// и сладость, и кислотность (инверсно).
class BalanceSlider extends StatelessWidget {
  final int value; // 0-10, где 5 = баланс
  final ValueChanged<int> onChanged;

  const BalanceSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _anchors = [
    SliderAnchor(value: 0, label: 'Сухой'),
    SliderAnchor(value: 3, label: 'Полусухой'),
    SliderAnchor(value: 5, label: 'Баланс'),
    SliderAnchor(value: 7, label: 'Сладкий'),
    SliderAnchor(value: 10, label: 'Десерт'),
  ];

  static const _hint = 'Влияет на соотношение сладости и кислотности:\n'
      '• Сухой — меньше сиропа, больше кислоты (цитрусы)\n'
      '• Баланс — классическая формула 1:1:1\n'
      '• Сладкий — добавить сироп или ликёр\n'
      '• Десерт — кремовый, сладкий, как десерт';

  @override
  Widget build(BuildContext context) {
    return SmartSlider(
      label: 'Баланс вкуса',
      icon: Icons.balance_outlined,
      value: value,
      onChanged: onChanged,
      color: const Color(0xFFE8B84B), // золотой
      anchors: _anchors,
      hint: _hint,
    );
  }
}

/// Слайдер интенсивности: Лёгкий ↔ Крепкий
///
/// Влияет на крепость (ABV) и рекомендации по льду.
class IntensitySlider extends StatelessWidget {
  final int value; // 0-10
  final ValueChanged<int> onChanged;

  const IntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _anchors = [
    SliderAnchor(value: 0, label: 'Лёгкий'),
    SliderAnchor(value: 3, label: 'Средний'),
    SliderAnchor(value: 6, label: 'Крепкий'),
    SliderAnchor(value: 10, label: 'Очень крепкий'),
  ];

  static const _hint = 'Влияет на крепость и количество миксера:\n'
      '• Лёгкий — много миксера, мало алкоголя, много льда\n'
      '• Средний — баланс спирта и миксера\n'
      '• Крепкий — меньше миксера, больше алкоголя\n'
      '• Очень крепкий — минимум миксера, чистый алкоголь';

  @override
  Widget build(BuildContext context) {
    return SmartSlider(
      label: 'Интенсивность',
      icon: Icons.local_fire_department_outlined,
      value: value,
      onChanged: onChanged,
      color: const Color(0xFFE85D4E), // красный
      anchors: _anchors,
      hint: _hint,
    );
  }
}

/// Слайдер кислотности с визуальными якорями.
class AciditySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const AciditySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _anchors = [
    SliderAnchor(value: 0, label: 'Нет'),
    SliderAnchor(value: 3, label: 'Лайм'),
    SliderAnchor(value: 6, label: 'Лимон'),
    SliderAnchor(value: 9, label: 'Уксус'),
  ];

  static const _hint = 'Влияет на кислотность коктейля:\n'
      '• Нет — без цитрусов, мягкий вкус\n'
      '• Лайм — лёгкая кислинка, освежает\n'
      '• Лимон — средняя кислотность, лимонный вкус\n'
      '• Уксус — высокая кислотность, для кислых коктейлей';

  @override
  Widget build(BuildContext context) {
    return SmartSlider(
      label: 'Кислотность',
      icon: Icons.water_drop_outlined,
      value: value,
      onChanged: onChanged,
      color: Colors.cyanAccent,
      anchors: _anchors,
      hint: _hint,
    );
  }
}

/// Слайдер сладости с визуальными якорями.
class SweetnessSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const SweetnessSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _anchors = [
    SliderAnchor(value: 0, label: 'Сухой'),
    SliderAnchor(value: 3, label: 'Полусухой'),
    SliderAnchor(value: 6, label: 'Сбалансированный'),
    SliderAnchor(value: 9, label: 'Сладкий'),
  ];

  static const _hint = 'Влияет на количество подсластителя:\n'
      '• Сухой — без сиропа, можно каплю биттера\n'
      '• Полусухой — 5-10мл сиропа или сладкий ликёр\n'
      '• Сбалансированный — 10-15мл сиропа\n'
      '• Сладкий — 15-25мл сиропа + ликёр';

  @override
  Widget build(BuildContext context) {
    return SmartSlider(
      label: 'Сладость',
      icon: Icons.cake_outlined,
      value: value,
      onChanged: onChanged,
      color: Colors.pinkAccent,
      anchors: _anchors,
      hint: _hint,
    );
  }
}

/// Слайдер горечи с визуальными якорями.
class BitternessSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const BitternessSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const _anchors = [
    SliderAnchor(value: 0, label: 'Нет'),
    SliderAnchor(value: 3, label: 'Апероль'),
    SliderAnchor(value: 6, label: 'Кампари'),
    SliderAnchor(value: 9, label: 'Ангостура'),
  ];

  static const _hint = 'Влияет на добавление горьких компонентов:\n'
      '• Нет — без горечи, мягкий вкус\n'
      '• Апероль — лёгкая горчинка, как в Апероль-спритц\n'
      '• Кампари — средняя горечь, итальянский стиль\n'
      '• Ангостура — высокая горечь, для Old Fashioned';

  @override
  Widget build(BuildContext context) {
    return SmartSlider(
      label: 'Горечь',
      icon: Icons.medication_outlined,
      value: value,
      onChanged: onChanged,
      color: Colors.amber,
      anchors: _anchors,
      hint: _hint,
    );
  }
}
