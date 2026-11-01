import 'package:flutter/material.dart';

/// Shared visual language for every screen in the Old Bartender's Wisdom.
class WisdomPalette {
  static const ink = Color(0xFF352114);
  static const darkInk = Color(0xFF21130C);
  static const parchment = Color(0xFFF3DFAF);
  static const parchmentLight = Color(0xFFFFF0C8);
  static const parchmentDark = Color(0xFFD6AD67);
  static const antiqueGold = Color(0xFFC7953E);
  static const oldGold = Color(0xFF8E5C24);
  static const wax = Color(0xFF7D211D);
  static const waxLight = Color(0xFFB34B39);
  static const wood = Color(0xFF3A2112);
}

class WisdomMapBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const WisdomMapBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: WisdomPalette.darkInk),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'images/wisdom_map_parchment_v2.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1A1B0D06),
                  Color(0x00FFFFFF),
                  Color(0x301B0D06)
                ],
                stops: [0, 0.52, 1],
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class WisdomParchmentPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool highlighted;

  const WisdomParchmentPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFEDBF),
            Color(0xFFF2D69A),
            Color(0xFFE3BC75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? WisdomPalette.antiqueGold
              : WisdomPalette.oldGold.withAlpha(125),
          width: highlighted ? 2 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(75),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
          if (highlighted)
            BoxShadow(
              color: WisdomPalette.antiqueGold.withAlpha(115),
              blurRadius: 24,
              spreadRadius: 2,
            ),
        ],
      ),
      child: child,
    );
  }
}

class WisdomWaxSeal extends StatelessWidget {
  final double size;
  final String mark;

  const WisdomWaxSeal({super.key, this.size = 50, this.mark = 'J'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.25, -0.3),
          colors: [
            WisdomPalette.waxLight,
            WisdomPalette.wax,
            Color(0xFF49110F)
          ],
        ),
        border: Border.all(
            color: const Color(0xFFE18D62).withAlpha(145), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(95),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * .68,
          height: size * .68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE18D62).withAlpha(155)),
          ),
          child: Center(
            child: Text(
              mark,
              style: TextStyle(
                color: const Color(0xFFF0B28C),
                fontSize: size * .34,
                fontWeight: FontWeight.w900,
                fontFamily: 'serif',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WisdomOrnamentDivider extends StatelessWidget {
  const WisdomOrnamentDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
            child: Divider(color: WisdomPalette.oldGold, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Transform.rotate(
            angle: .78,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: WisdomPalette.antiqueGold,
                border: Border.all(color: WisdomPalette.oldGold),
              ),
            ),
          ),
        ),
        const Expanded(
            child: Divider(color: WisdomPalette.oldGold, thickness: 1)),
      ],
    );
  }
}
