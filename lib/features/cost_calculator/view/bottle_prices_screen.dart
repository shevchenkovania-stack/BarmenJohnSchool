import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/services/cost_calculator_service.dart';
import 'package:coin/core/models/bottle_price.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Экран управления ценами на бутылки
class BottlePricesScreen extends StatefulWidget {
  const BottlePricesScreen({super.key});

  @override
  State<BottlePricesScreen> createState() => _BottlePricesScreenState();
}

class _BottlePricesScreenState extends State<BottlePricesScreen> {
  List<String> _allIngredients = [];
  bool _isLoadingIngredients = false;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  // Загрузка списка ингредиентов из API
  Future<void> _loadIngredients() async {
    setState(() => _isLoadingIngredients = true);
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.thecocktaildb.com/api/json/v1/1/list.php?i=list'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final drinks = data['drinks'] as List<dynamic>;
        setState(() {
          _allIngredients = drinks
              .map((d) => d['strIngredient1'] as String)
              .where((i) => i != null && i.trim().isNotEmpty)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading ingredients: $e');
    } finally {
      setState(() => _isLoadingIngredients = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Цены на ингредиенты'),
        backgroundColor: AppColors.surface,
      ),
      body: Consumer<CostCalculatorService>(
        builder: (context, service, _) {
          return Column(
            children: [
              // Info card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Укажите цены и объём бутылок для расчёта себестоимости коктейлей',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // Add button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _showAddPriceDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить ингредиент'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // List of prices
              Expanded(
                child: FutureBuilder<List<BottlePrice>>(
                  future: BottlePrice.getAll(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_drink_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Нет сохранённых цен',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    final prices = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: prices.length,
                      itemBuilder: (context, index) {
                        final price = prices[index];
                        return _PriceCard(
                          price: price,
                          onEdit: () => _showEditPriceDialog(context, price),
                          onDelete: () => _deletePrice(context, price),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddPriceDialog(BuildContext context) {
    String? selectedIngredient;
    String currentInputText = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final volumeController = TextEditingController();
          final priceController = TextEditingController();

          return AlertDialog(
            title: const Text('Добавить ингредиент'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Autocomplete для ингредиентов
                  Autocomplete<String>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.length < 1) {
                        return const Iterable<String>.empty();
                      }
                      return _allIngredients.where((ingredient) => ingredient
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (option) {
                      setDialogState(() {
                        selectedIngredient = option;
                        currentInputText = option;
                      });
                    },
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Название ингредиента',
                          hintText: 'Начните вводить: Sum...',
                          prefixIcon: Icon(Icons.local_bar),
                          suffixIcon: Icon(Icons.search, color: Colors.grey),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            currentInputText = value;
                          });
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.primary.withAlpha(50)),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  leading: const Icon(Icons.local_drink,
                                      color: AppColors.primary),
                                  title: Text(
                                    option,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: volumeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Объём бутылки (мл)',
                      hintText: 'например: 750',
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Цена бутылки (MDL)',
                      hintText: 'например: 250',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Берём выбранное название или введённое вручную
                  final name =
                      selectedIngredient?.trim() ?? currentInputText.trim();
                  final volume = double.tryParse(volumeController.text) ?? 0;
                  final price = double.tryParse(priceController.text) ?? 0;

                  if (name.isEmpty || volume <= 0 || price <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Заполните все поля корректно')),
                    );
                    return;
                  }

                  final bottlePrice = BottlePrice(
                    ingredientId: name.toLowerCase(),
                    ingredientName: name,
                    bottleVolume: volume,
                    bottlePrice: price,
                    lastUpdated: DateTime.now(),
                  );

                  Provider.of<CostCalculatorService>(context, listen: false)
                      .setPrice(bottlePrice);
                  Navigator.pop(ctx);
                },
                child: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, BottlePrice price) {
    final volumeController =
        TextEditingController(text: price.bottleVolume.toString());
    final priceController =
        TextEditingController(text: price.bottlePrice.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Редактировать ${price.ingredientName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: volumeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Объём бутылки (мл)',
                prefixIcon: Icon(Icons.water_drop),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена бутылки (MDL)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final volume = double.tryParse(volumeController.text) ?? 0;
              final newPrice = double.tryParse(priceController.text) ?? 0;

              if (volume <= 0 || newPrice <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректные значения')),
                );
                return;
              }

              final updated = BottlePrice(
                ingredientId: price.ingredientId,
                ingredientName: price.ingredientName,
                bottleVolume: volume,
                bottlePrice: newPrice,
                lastUpdated: DateTime.now(),
              );

              Provider.of<CostCalculatorService>(context, listen: false)
                  .setPrice(updated);
              Navigator.pop(ctx);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deletePrice(BuildContext context, BottlePrice price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить цену?'),
        content: Text(
            'Вы уверены что хотите удалить цену для "${price.ingredientName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              BottlePrice.delete(price.ingredientId);
              Provider.of<CostCalculatorService>(context, listen: false)
                  .loadPrices();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final BottlePrice price;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PriceCard(
      {required this.price, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    price.ingredientName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.water_drop,
                  label: '${price.bottleVolume.toInt()} ml',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.attach_money,
                  label: '${price.bottlePrice.toInt()} MDL',
                ),
                const Spacer(),
                _InfoChip(
                  icon: Icons.calculate,
                  label:
                      '${(price.pricePerMl * 100).toStringAsFixed(2)} MDL/100ml',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
