import 'package:flutter/material.dart';

/// Категория коктейля
enum CocktailCategory {
  classic,
}

extension CocktailCategoryX on CocktailCategory {
  String get label {
    switch (this) {
      case CocktailCategory.classic:
        return '🍸 Классические';
    }
  }

  String get description {
    switch (this) {
      case CocktailCategory.classic:
        return 'Алкогольные и безалкогольные коктейли';
    }
  }

  Color get accentColor {
    switch (this) {
      case CocktailCategory.classic:
        return const Color(0xFFE8B84B);
    }
  }
}

/// Метод приготовления коктейля (расширенный)
enum CocktailMethod { shake, stir, build, muddle, blend, layered }

extension CocktailMethodX on CocktailMethod {
  String get label {
    switch (this) {
      case CocktailMethod.shake:
        return 'Shake (шейкер)';
      case CocktailMethod.stir:
        return 'Stir (перемешать)';
      case CocktailMethod.build:
        return 'Build (в стакане)';
      case CocktailMethod.muddle:
        return 'Muddle (помять)';
      case CocktailMethod.blend:
        return 'Blend (блендер)';
      case CocktailMethod.layered:
        return 'Layered (слоями)';
    }
  }

  String get emoji {
    switch (this) {
      case CocktailMethod.shake:
        return '🍸';
      case CocktailMethod.stir:
        return '🥄';
      case CocktailMethod.build:
        return '🥃';
      case CocktailMethod.muddle:
        return '🌿';
      case CocktailMethod.blend:
        return '🧊';
      case CocktailMethod.layered:
        return '🎯';
    }
  }

  String get reason {
    switch (this) {
      case CocktailMethod.shake:
        return 'Смешиваем сок/кислоту с алкоголем — шейк делает текстуру мягче и «собирает» вкус';
      case CocktailMethod.stir:
        return 'Только алкоголь — стир охлаждает без лишнего воздуха, сохраняет чистоту вкуса';
      case CocktailMethod.build:
        return 'Газированный компонент — строим прямо в бокале чтобы не потерять пузырьки';
      case CocktailMethod.muddle:
        return 'Травы/ягоды — мнём пестиком чтобы высвободить эфирные масла и сок';
      case CocktailMethod.blend:
        return 'Замороженные/сливочные — блендер создаёт гладкую текстуру';
      case CocktailMethod.layered:
        return 'Разная плотность — наливаем по ложке, тяжёлый ингредиент внизу';
    }
  }

  /// Сложность для начинающих (1-5)
  int get difficulty {
    switch (this) {
      case CocktailMethod.build:
        return 1;
      case CocktailMethod.stir:
        return 2;
      case CocktailMethod.shake:
        return 3;
      case CocktailMethod.blend:
        return 3;
      case CocktailMethod.muddle:
        return 4;
      case CocktailMethod.layered:
        return 5;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  🎬 ВИЗУАЛЬНАЯ ТЕХНИКА (для улучшенных шагов приготовления)
  // ════════════════════════════════════════════════════════════════════════════

  /// Иконка техники (Material)
  IconData get techniqueIcon {
    switch (this) {
      case CocktailMethod.shake:
        return Icons.waterfall_chart; // шейкер
      case CocktailMethod.stir:
        return Icons.auto_fix_high; // перемешивание
      case CocktailMethod.build:
        return Icons.local_bar; // стакан
      case CocktailMethod.muddle:
        return Icons.spa; // пестик
      case CocktailMethod.blend:
        return Icons.blender; // блендер
      case CocktailMethod.layered:
        return Icons.layers; // слои
    }
  }

  /// Время выполнения
  String get duration {
    switch (this) {
      case CocktailMethod.shake:
        return '10-15 сек';
      case CocktailMethod.stir:
        return '20-30 сек';
      case CocktailMethod.build:
        return '1-2 мин';
      case CocktailMethod.muddle:
        return '30-60 сек';
      case CocktailMethod.blend:
        return '15-30 сек';
      case CocktailMethod.layered:
        return '2-3 мин';
    }
  }

  /// Тип льда
  String get iceRecommendation {
    switch (this) {
      case CocktailMethod.shake:
        return 'Кубики (много)';
      case CocktailMethod.stir:
        return 'Крупные кубики';
      case CocktailMethod.build:
        return 'Кубики';
      case CocktailMethod.muddle:
        return 'Дроблёный';
      case CocktailMethod.blend:
        return 'Дроблёный лёд';
      case CocktailMethod.layered:
        return 'Без льда';
    }
  }

  /// Температура бокала
  String get glassTemperature {
    switch (this) {
      case CocktailMethod.shake:
      case CocktailMethod.stir:
        return 'Охлаждённый (5 мин в морозилке)';
      case CocktailMethod.build:
      case CocktailMethod.muddle:
        return 'Комнатная';
      case CocktailMethod.blend:
        return 'Замороженный';
      case CocktailMethod.layered:
        return 'Комнатная';
    }
  }

  /// Подробное описание техники
  String get techniqueDescription {
    switch (this) {
      case CocktailMethod.shake:
        return 'Наполни шейкер льдом на 2/3. Влей все ингредиенты. Закрой плотно и встряхивай энергично над плечом 10-15 секунд до появления конденсата.';
      case CocktailMethod.stir:
        return 'Наполни стакан для смешивания льдом. Влей ингредиенты. Перемешивай барной ложкой 20-30 секунд — коктейль должен стать мутным от холода.';
      case CocktailMethod.build:
        return 'Наполни бокал льдом. Вливай ингредиенты в порядке: сначала спирт, затем миксеры. Аккуратно размешай 2-3 оборота.';
      case CocktailMethod.muddle:
        return 'Положи ингредиенты в бокал. Помни пестиком 10-15 раз, не раздавливая до каши. Добавь лёд и остальные ингредиенты.';
      case CocktailMethod.blend:
        return 'Загрузи все ингредиенты в блендер. Добавь дроблёный лёд. Взбивай 15-30 секунд до однородной массы.';
      case CocktailMethod.layered:
        return 'Наливай по барной ложке, начиная с самого плотного ингредиента. Держи ложку у стенки бокала, не брызгай.';
    }
  }
}

/// Тип бокала
enum CocktailGlass { coupe, rocks, highball, martini, flute, shot }

extension CocktailGlassX on CocktailGlass {
  String get label {
    switch (this) {
      case CocktailGlass.coupe:
        return 'Coupe / Сауэр';
      case CocktailGlass.rocks:
        return 'Rocks (Олд-фэшн)';
      case CocktailGlass.highball:
        return 'Highball / Коллинз';
      case CocktailGlass.martini:
        return 'Martini / Коктейльная рюмка';
      case CocktailGlass.flute:
        return 'Flute (Флюте)';
      case CocktailGlass.shot:
        return 'Shot (Рюмка)';
    }
  }

  String get emoji {
    switch (this) {
      case CocktailGlass.coupe:
      case CocktailGlass.martini:
        return '🍸';
      case CocktailGlass.rocks:
        return '🥃';
      case CocktailGlass.highball:
        return '🥤';
      case CocktailGlass.flute:
        return '🥂';
      case CocktailGlass.shot:
        return '🎯';
    }
  }

  /// Объём бокала в мл (примерный)
  int get typicalVolume {
    switch (this) {
      case CocktailGlass.coupe:
        return 150;
      case CocktailGlass.rocks:
        return 200;
      case CocktailGlass.highball:
        return 300;
      case CocktailGlass.martini:
        return 120;
      case CocktailGlass.flute:
        return 180;
      case CocktailGlass.shot:
        return 60;
    }
  }
}
