import 'package:flutter/material.dart';

/// Карточка «ДЖОН» на главной: одна живая реплика вместо ряда цифр.
///
/// Джон наблюдает, а не оценивает: здесь нет ни похвалы за нажатие, ни
/// укора за пропуск. Текст берётся из `john_reaction`, поэтому его можно
/// проверить тестом.
class JohnHomeCard extends StatelessWidget {
  final String line;
  final String? ctaLabel;
  final VoidCallback? onTap;

  const JohnHomeCard({
    super.key,
    required this.line,
    this.ctaLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2114), Color(0xFF3A2C1A)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD0A24C).withAlpha(150)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF4A3720),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFD0A24C),
                  width: 1.6,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'images/barista_john_teach.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: Color(0xFFD0A24C),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'ДЖОН',
                        style: TextStyle(
                          color: Color(0xFFD0A24C),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFD0A24C).withAlpha(70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    line,
                    style: const TextStyle(
                      color: Color(0xFFF3E7D0),
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (ctaLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      ctaLabel!,
                      style: const TextStyle(
                        color: Color(0xFFD0A24C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
