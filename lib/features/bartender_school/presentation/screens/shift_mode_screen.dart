import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/core/services/bar_sound_service.dart';
import 'package:coin/features/bartender_school/data/practice_challenges.dart';
import 'package:coin/features/bartender_school/data/guests.dart';
import 'package:coin/features/bartender_school/data/john_reactions.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// Режим «Смена»: поток заказов от гостей под общим таймером.
///
/// Пользователь собирает 3 коктейля подряд. Каждый заказ оценивается
/// звёздами, в конце — разбор Джона по скорости и качеству.
class ShiftModeScreen extends StatefulWidget {
  const ShiftModeScreen({super.key});

  @override
  State<ShiftModeScreen> createState() => _ShiftModeScreenState();
}

class _ShiftModeScreenState extends State<ShiftModeScreen> {
  static const _shiftDuration = Duration(minutes: 3);
  static const _orderCount = 3;

  final _random = Random();
  final List<_ShiftOrder> _orders = [];
  int _currentIndex = 0;

  // Состояние текущего заказа.
  String? _selectedMethod;
  final Set<String> _selectedIngredients = {};
  int? _earnedStars;

  // Таймер смены.
  Timer? _tick;
  int _secondsLeft = _shiftDuration.inSeconds;
  bool _shiftFinished = false;

  // Итоги.
  final List<int> _starsPerOrder = [];
  int _totalSeconds = 0;

  /// Память Сергея о прошлой смене (ключ в SharedPreferences).
  static const _sergeyMemoryKey = 'guest_sergey_last_stars';
  String? _sergeyMemory;

  @override
  void initState() {
    super.initState();
    _loadSergeyMemory();
    _buildOrders();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _finishShift();
    });
  }

  void _loadSergeyMemory() {
    try {
      final prefs = context.read<SharedPreferences>();
      final last = prefs.getInt(_sergeyMemoryKey);
      if (last == null) return;
      _sergeyMemory = last >= 2
          ? '«В прошлый раз было неплохо. Повтори.»'
          : '«В прошлый раз перекислил. Будь внимательнее.»';
    } catch (_) {
      // Без памяти гость просто не вспоминает прошлое.
    }
  }

  Future<void> _saveSergeyMemory() async {
    try {
      final prefs = context.read<SharedPreferences>();
      final avg = _orders.isEmpty ? 0.0 : _totalStars / _orders.length;
      await prefs.setInt(_sergeyMemoryKey, avg.round());
    } catch (_) {}
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _buildOrders() {
    // Берём коктейли Level 1 (блоки A/B/C).
    final pool = allPracticeChallenges
        .where((c) => c.blockId == 'A' || c.blockId == 'B' || c.blockId == 'C')
        .toList()
      ..shuffle(_random);
    final guests = [...barGuests]..shuffle(_random);
    // Сергей — постоянный гость смены: он всегда приходит первым.
    final sergeyIndex = guests.indexWhere((g) => g.name == 'Сергей');
    if (sergeyIndex > 0) {
      guests.insert(0, guests.removeAt(sergeyIndex));
    }
    for (var i = 0; i < _orderCount && i < pool.length; i++) {
      _orders.add(_ShiftOrder(
        challenge: pool[i],
        guest: guests[i % guests.length],
      ));
    }
  }

  void _submitOrder() {
    if (_selectedMethod == null) return;
    final order = _orders[_currentIndex];
    final challenge = order.challenge;

    var stars = 0;
    // Метод.
    if (_selectedMethod == challenge.correctMethod) stars++;
    // Ингредиенты: все правильные и нет лишних.
    final correct = challenge.correctIngredients.toSet();
    final selected = _selectedIngredients;
    if (selected.containsAll(correct) &&
        selected.difference(correct).isEmpty) {
      stars++;
    }
    // Бонус за скорость: если осталось больше половины времени.
    if (_secondsLeft > _shiftDuration.inSeconds ~/ 2) stars++;

    _starsPerOrder.add(stars);
    _earnedStars = stars;
    BarSoundService.instance.glassTap();
    if (stars >= 2) {
      BarSoundService.instance.success();
    } else {
      BarSoundService.instance.fail();
    }
    setState(() {});
  }

  void _nextOrder() {
    if (_currentIndex < _orders.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedMethod = null;
        _selectedIngredients.clear();
        _earnedStars = null;
      });
    } else {
      _finishShift();
    }
  }

  void _finishShift() {
    if (_shiftFinished) return;
    _shiftFinished = true;
    _tick?.cancel();
    _totalSeconds = _shiftDuration.inSeconds - _secondsLeft;
    _saveSergeyMemory();
    setState(() {});
  }

  String get _timeString {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _totalStars =>
      _starsPerOrder.fold(0, (a, b) => a + b);

  String get _johnVerdict {
    final avg = _orders.isEmpty ? 0 : _totalStars / _orders.length;
    if (avg >= 2.5) {
      final verdict = johnReaction(
        JohnMoment.cocktailBuilt,
        const JohnContext(streak: 0, daysSinceLastVisit: 0),
      );
      return '$verdict\n\n«${_orders.length} коктейля за ${_totalSeconds ~/ 60} мин ${_totalSeconds % 60} сек. Чисто, быстро, гости довольны.»';
    }
    if (avg >= 1.5) {
      return '«Нормально для первой смены. $_totalStars/${_orders.length * 3} звёзд. '
          'Есть к чему стремиться — повторяй уроки где ошибся.»';
    }
    return '«Сложно, да? Не переживай. Разберём ошибки: '
        'смотри метод и ингредиенты внимательнее. Пробуй ещё раз.»';
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_shiftFinished) return _buildResults();
    if (_orders.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Нет доступных коктейлей для смены')),
      );
    }
    final order = _orders[_currentIndex];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: JohnThemedAppBar(
        room: JohnSchoolRoom.workshop,
        title: 'Смена ${_currentIndex + 1}/${_orders.length}',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _timeString,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _secondsLeft < 30 ? Colors.redAccent : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.workshop,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GuestCard(
                order: order,
                memory: order.guest.name == 'Сергей' ? _sergeyMemory : null,
              ),
              const SizedBox(height: 16),
              if (_earnedStars == null)
                _buildPractice(order)
              else
                _buildOrderResult(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPractice(_ShiftOrder order) {
    final challenge = order.challenge;
    final methods = _methodOptions(challenge.correctMethod);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Заказ: ${challenge.cocktailEmoji} ${challenge.cocktailName}',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Метод приготовления:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: methods.map((m) {
            final selected = _selectedMethod == m;
            return ChoiceChip(
              label: Text(m),
              selected: selected,
              onSelected: (_) => setState(() => _selectedMethod = m),
              selectedColor: AppColors.primary.withAlpha(60),
              backgroundColor: AppColors.surfaceLight,
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text(
          'Ингредиенты (отметь все нужные):',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...challenge.allOptions.map((ing) {
          final selected = _selectedIngredients.contains(ing);
          return CheckboxListTile(
            title: Text(
              ing,
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
            value: selected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedIngredients.add(ing);
                } else {
                  _selectedIngredients.remove(ing);
                }
              });
            },
            activeColor: AppColors.primary,
          );
        }),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _selectedMethod == null ? null : _submitOrder,
          child: const Text('Подать коктейль'),
        ),
      ],
    );
  }

  Widget _buildOrderResult(_ShiftOrder order) {
    final stars = _earnedStars!;
    final isLast = _currentIndex == _orders.length - 1;
    return Column(
      children: [
        Text(
          stars >= 2 ? 'Гость доволен!' : 'Гость не впечатлён…',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: stars >= 2 ? AppColors.accent : Colors.redAccent,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Icon(
              i < stars ? Icons.star_rounded : Icons.star_border_rounded,
              size: 40,
              color: i < stars ? AppColors.primary : AppColors.textSecondary,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          order.guest.signaturePhrase,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _nextOrder,
          child: Text(isLast ? 'Завершить смену' : 'Следующий заказ'),
        ),
      ],
    );
  }

  Widget _buildResults() {
    final avg = _orders.isEmpty
        ? 0.0
        : _totalStars / _orders.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const JohnThemedAppBar(
        room: JohnSchoolRoom.workshop,
        title: 'Итог смены',
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.workshop,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                '$_totalStars / ${_orders.length * 3} звёзд',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Средний балл: ${avg.toStringAsFixed(1)} ⭐',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Время: ${_totalSeconds ~/ 60} мин ${_totalSeconds % 60} сек',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'images/barista_john.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 40),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _johnVerdict,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Вернуться в мастерскую'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _methodOptions(String correct) {
    const all = ['shake', 'stir', 'build', 'muddle', 'blend', 'layer'];
    final options = {correct};
    final others = all.where((m) => m != correct).toList()..shuffle(_random);
    for (final m in others) {
      if (options.length >= 3) break;
      options.add(m);
    }
    return options.toList()..shuffle(_random);
  }
}

class _ShiftOrder {
  final PracticeChallenge challenge;
  final Guest guest;
  const _ShiftOrder({required this.challenge, required this.guest});
}

class _GuestCard extends StatelessWidget {
  final _ShiftOrder order;
  final String? memory;
  const _GuestCard({required this.order, this.memory});

  @override
  Widget build(BuildContext context) {
    final g = order.guest;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(g.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  g.preferenceLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                if (memory != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    memory!,
                    style: TextStyle(
                      color: AppColors.textSecondary.withAlpha(190),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
