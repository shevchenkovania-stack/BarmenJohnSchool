import 'package:hive_flutter/hive_flutter.dart';
import 'package:coin/core/constants/app_constants.dart';

// build_runner генерирует этот файл командой:
// dart run build_runner build --delete-conflicting-outputs
part 'stop_item.g.dart';

/// Один ингредиент в стоп-листе (закончился сегодня).
///
/// Хранится в Hive box [AppConstants.stopListBox].
@HiveType(typeId: AppConstants.stopItemTypeId)
class StopItem extends HiveObject {
  /// Название ингредиента
  @HiveField(0)
  late String name;

  StopItem({required this.name});
}
