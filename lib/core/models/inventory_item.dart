import 'package:hive_flutter/hive_flutter.dart';
import 'package:coin/core/constants/app_constants.dart';

// build_runner генерирует этот файл командой:
// dart run build_runner build --delete-conflicting-outputs
part 'inventory_item.g.dart';

/// Один ингредиент в инвентаре бара.
///
/// Хранится в Hive box [AppConstants.inventoryBox].
/// [typeId] должен совпадать с [AppConstants.inventoryItemTypeId].
@HiveType(typeId: AppConstants.inventoryItemTypeId)
class InventoryItem extends HiveObject {
  /// Название ингредиента (регистр сохраняется как введён, сравнение — toLowerCase)
  @HiveField(0)
  late String name;

  InventoryItem({required this.name});
}
