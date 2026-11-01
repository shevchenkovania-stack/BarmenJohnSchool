import 'package:hive_flutter/hive_flutter.dart';

part 'menu_builder.g.dart'; // сгенерировано build_runner

/// Модель меню для печати.
///
/// Хранит список коктейлей которые войдут в печатное меню,
/// а также тему оформления и название заведения.
///
/// **Поля:**
/// - [id] — уникальный идентификатор (timestamp создания)
/// - [venueName] — название бара/ресторана (например "Sunset Bar")
/// - [selectedCocktailIds] — ID избранных коктейлей для меню
/// - [theme] — тема оформления ('classic', 'modern', 'minimal')
/// - [createdAt] — дата создания меню
@HiveType(typeId: 3)
class MenuBuilder extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String venueName;

  @HiveField(2)
  late List<String> selectedCocktailIds;

  @HiveField(3)
  late String theme;

  @HiveField(4)
  late DateTime createdAt;

  MenuBuilder() {
    id = DateTime.now().millisecondsSinceEpoch.toString();
    createdAt = DateTime.now();
    theme = 'classic'; // тема по умолчанию
    selectedCocktailIds = [];
    venueName = '';
  }

  /// Создаёт копию объекта (для редактирования без изменения оригинала)
  MenuBuilder copyWith({
    String? id,
    String? venueName,
    List<String>? selectedCocktailIds,
    String? theme,
    DateTime? createdAt,
  }) {
    return MenuBuilder()
      ..id = id ?? this.id
      ..venueName = venueName ?? this.venueName
      ..selectedCocktailIds = selectedCocktailIds ?? this.selectedCocktailIds
      ..theme = theme ?? this.theme
      ..createdAt = createdAt ?? this.createdAt;
  }
}
