import 'package:flutter/material.dart';

/// The rooms of John's school share materials, but each keeps its own mood.
enum JohnSchoolRoom {
  foyer,
  flavorLab,
  toolBench,
  classicsLounge,
  workshop,
  recipeArchive,
  honorsHall,
}

@immutable
class JohnRoomStyle {
  final String backgroundAsset;
  final Color accent;
  final Color accentSoft;
  final Color surface;
  final Color surfaceLight;
  final Color ink;
  final Color onDark;

  const JohnRoomStyle({
    required this.backgroundAsset,
    required this.accent,
    required this.accentSoft,
    required this.surface,
    required this.surfaceLight,
    required this.ink,
    required this.onDark,
  });

  static const _gold = Color(0xFFD0A24C);
  static const _cream = Color(0xFFF8E8BD);

  static JohnRoomStyle forRoom(JohnSchoolRoom room) {
    return switch (room) {
      JohnSchoolRoom.foyer => const JohnRoomStyle(
          backgroundAsset: 'images/john_room_school_hall.jpg',
          accent: _gold,
          accentSoft: Color(0xFF775B28),
          surface: Color(0xFF24160F),
          surfaceLight: Color(0xFF3A261A),
          ink: Color(0xFF2E1B10),
          onDark: _cream,
        ),
      JohnSchoolRoom.flavorLab => const JohnRoomStyle(
          backgroundAsset: 'images/john_room_flavor_lab.jpg',
          accent: Color(0xFFD69B32),
          accentSoft: Color(0xFF6D7A35),
          surface: Color(0xFF342916),
          surfaceLight: Color(0xFF4F3C1C),
          ink: Color(0xFF352617),
          onDark: Color(0xFFFFEBC0),
        ),
      JohnSchoolRoom.toolBench => const JohnRoomStyle(
          backgroundAsset: 'images/john_room_tool_bench.jpg',
          accent: Color(0xFFC99A45),
          accentSoft: Color(0xFF2D7780),
          surface: Color(0xFF102D31),
          surfaceLight: Color(0xFF1B4145),
          ink: Color(0xFF102326),
          onDark: Color(0xFFE7E0C7),
        ),
      JohnSchoolRoom.classicsLounge => const JohnRoomStyle(
          backgroundAsset: 'images/john_room_classics_lounge.jpg',
          accent: Color(0xFFD2A550),
          accentSoft: Color(0xFF8F3040),
          surface: Color(0xFF351116),
          surfaceLight: Color(0xFF571C28),
          ink: Color(0xFF351116),
          onDark: Color(0xFFFFE8C0),
        ),
      JohnSchoolRoom.workshop => const JohnRoomStyle(
          backgroundAsset: 'images/john_room_workshop.jpg',
          accent: Color(0xFFD0A24C),
          accentSoft: Color(0xFF7F5B2B),
          surface: Color(0xFF21150F),
          surfaceLight: Color(0xFF3C271B),
          ink: Color(0xFF29170D),
          onDark: Color(0xFFF7E7C0),
        ),
      JohnSchoolRoom.recipeArchive => const JohnRoomStyle(
          backgroundAsset: 'images/john_room_recipe_archive.jpg',
          accent: Color(0xFFCDA14E),
          accentSoft: Color(0xFF496B50),
          surface: Color(0xFF13271E),
          surfaceLight: Color(0xFF223F31),
          ink: Color(0xFF24331F),
          onDark: Color(0xFFF5E7BF),
        ),
      JohnSchoolRoom.honorsHall => const JohnRoomStyle(
          backgroundAsset: 'images/john_room_honors_hall.jpg',
          accent: Color(0xFFD4A84E),
          accentSoft: Color(0xFF8E2833),
          surface: Color(0xFF2D0E13),
          surfaceLight: Color(0xFF4D1821),
          ink: Color(0xFF321016),
          onDark: Color(0xFFFFE9BF),
        ),
    };
  }

  static JohnSchoolRoom roomForBlock(String? blockId) {
    return switch (blockId) {
      'A' => JohnSchoolRoom.flavorLab,
      'B' => JohnSchoolRoom.toolBench,
      'C' => JohnSchoolRoom.classicsLounge,
      _ => JohnSchoolRoom.foyer,
    };
  }
}

class JohnRoomBackground extends StatelessWidget {
  final JohnSchoolRoom room;
  final Widget child;
  final double imageOpacity;

  const JohnRoomBackground({
    super.key,
    required this.room,
    required this.child,
    this.imageOpacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: const Color(0xFF120B08)),
        Opacity(
          opacity: imageOpacity,
          child: Image.asset(
            style.backgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.medium,
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x35100805),
                Color(0x15000000),
                Color(0xA60B0705),
              ],
              stops: [0, .44, 1],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class JohnWoodPanel extends StatelessWidget {
  final JohnSchoolRoom room;
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool highlighted;
  final BorderRadius borderRadius;

  const JohnWoodPanel({
    super.key,
    required this.room,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.highlighted = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        // Панель непрозрачная: раньше `surface`/`surfaceLight` шли с альфой
        // 0xEB–0xF3 (92–95%), и фон комнаты (лимоны, травы, бутылки)
        // просвечивал сквозь текст урока. Теперь цвета сплошные, и глубина
        // дерева держится градиентом и обводкой, а не прозрачностью.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.surfaceLight, style.surface],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: highlighted ? style.accent : style.accent.withAlpha(105),
          width: highlighted ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          if (highlighted)
            BoxShadow(
              color: style.accent.withAlpha(85),
              blurRadius: 18,
              spreadRadius: 1,
            ),
        ],
      ),
      child: child,
    );
  }
}

/// Intrinsic-height room vignette used inside scrolling pages.
class JohnRoomSection extends StatelessWidget {
  final JohnSchoolRoom room;
  final Widget child;
  final EdgeInsets padding;

  const JohnRoomSection({
    super.key,
    required this.room,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              style.backgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x30000000), Color(0xB5100805)],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class JohnParchmentPanel extends StatelessWidget {
  final JohnSchoolRoom room;
  final Widget child;
  final EdgeInsets padding;

  const JohnParchmentPanel({
    super.key,
    required this.room,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCEAB9), Color(0xFFE7C681)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.accent.withAlpha(190), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(95),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class JohnSectionPlaque extends StatelessWidget {
  final JohnSchoolRoom room;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? iconAsset;

  const JohnSectionPlaque({
    super.key,
    required this.room,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return JohnWoodPanel(
      room: room,
      highlighted: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (iconAsset != null) ...[
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: style.accent.withAlpha(28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: style.accent.withAlpha(130)),
              ),
              child: Image.asset(iconAsset!),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: style.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: style.onDark,
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: style.onDark.withAlpha(180),
                      fontSize: 12,
                      height: 1.35,
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

class JohnBrassDivider extends StatelessWidget {
  final JohnSchoolRoom room;

  const JohnBrassDivider({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final color = JohnRoomStyle.forRoom(room).accent;
    return Row(
      children: [
        Expanded(child: Divider(color: color.withAlpha(145))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Transform.rotate(
            angle: .785,
            child: Container(width: 7, height: 7, color: color),
          ),
        ),
        Expanded(child: Divider(color: color.withAlpha(145))),
      ],
    );
  }
}

class JohnStatusBadge extends StatelessWidget {
  final JohnSchoolRoom room;
  final String label;
  final bool strong;

  const JohnStatusBadge({
    super.key,
    required this.room,
    required this.label,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: strong ? style.accent : style.accent.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.accent.withAlpha(175)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: strong ? style.ink : style.accent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
    );
  }
}

class JohnThemedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final JohnSchoolRoom room;
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const JohnThemedAppBar({
    super.key,
    required this.room,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final style = JohnRoomStyle.forRoom(room);
    return AppBar(
      backgroundColor: style.surface,
      foregroundColor: style.onDark,
      shadowColor: Colors.black,
      elevation: 8,
      centerTitle: true,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: style.onDark,
          fontFamily: 'serif',
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: style.accent.withAlpha(130)),
      ),
    );
  }
}
