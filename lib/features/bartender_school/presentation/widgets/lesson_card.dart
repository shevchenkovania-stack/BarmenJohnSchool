import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/domain/entities/lesson.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

/// School lesson card with John callouts and lesson-specific artwork.
class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final LessonStatus status;
  final VoidCallback onTap;
  final bool practiceComplete;
  final int termsLearned;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.status,
    required this.onTap,
    this.practiceComplete = false,
    this.termsLearned = 0,
  });

  bool get _theoryDone => status == LessonStatus.completed;
  bool get _practicePending => _theoryDone && !practiceComplete;

  Color get _blockAccentColor {
    if (const ['A', 'B', 'C'].contains(lesson.blockId)) {
      return JohnRoomStyle.forRoom(
        JohnRoomStyle.roomForBlock(lesson.blockId),
      ).accent;
    }
    switch (lesson.blockId) {
      case 'B':
        return const Color(0xFF52D6C6);
      case 'C':
        return const Color(0xFFB57CFF);
      case 'D':
        return const Color(0xFF58B6FF);
      case 'E':
        return const Color(0xFFFFB65C);
      case 'F':
        return const Color(0xFF7DDC8A);
      default:
        return AppColors.primary;
    }
  }

  Color get _blockShadowColor {
    if (const ['A', 'B', 'C'].contains(lesson.blockId)) {
      return JohnRoomStyle.forRoom(
        JohnRoomStyle.roomForBlock(lesson.blockId),
      ).accent;
    }
    switch (lesson.blockId) {
      case 'B':
        return const Color(0xFF52D6C6);
      case 'C':
        return const Color(0xFFB57CFF);
      case 'D':
        return const Color(0xFF58B6FF);
      case 'E':
        return const Color(0xFFFFB65C);
      case 'F':
        return const Color(0xFF7DDC8A);
      default:
        return AppColors.primary;
    }
  }

  LinearGradient _cardGradient() {
    switch (lesson.blockId) {
      case 'A':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF04A3B20), Color(0xF22F301C), Color(0xF05A431F)],
        );
      case 'B':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF20E282C), Color(0xF21A3B3E), Color(0xF2293430)],
        );
      case 'C':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF22E0E15), Color(0xF24D1822), Color(0xF236181A)],
        );
      case 'D':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16283A), Color(0xFF1D3350), Color(0xFF274569)],
        );
      case 'E':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2415), Color(0xFF4A2C18), Color(0xFF5A381F)],
        );
      case 'F':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143022), Color(0xFF1D4330), Color(0xFF24523C)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceLight,
            AppColors.surface,
            Color(0xFF201E30)
          ],
        );
    }
  }

  String? get _lessonArtworkPath {
    switch (lesson.id) {
      case 'lesson_A_01':
        return 'images/lesson_a_01_balance.jpg';
      case 'lesson_A_02':
        return 'images/lesson_a_02_acid.jpg';
      case 'lesson_A_03':
        return 'images/lesson_a_03_sweetness.jpg';
      case 'lesson_A_04':
        return 'images/lesson_a_04_bitters.jpg';
      case 'lesson_B_05':
        return 'images/lesson_b_05_setup.jpg';
      case 'lesson_B_06':
        return 'images/lesson_b_06_precision.jpg';
      case 'lesson_B_07':
        return 'images/lesson_b_07_shake.jpg';
      case 'lesson_B_08':
        return 'images/lesson_b_08_ice.jpg';
      case 'lesson_B_09':
        return 'images/lesson_b_05_setup.jpg';
      case 'lesson_C_09':
        return 'images/lesson_c_09_mojito.jpg';
      case 'lesson_C_10':
        return 'images/lesson_c_10_daiquiri.jpg';
      case 'lesson_C_11':
        return 'images/lesson_c_11_negroni.jpg';
      case 'lesson_C_12':
        return 'images/lesson_c_12_exam.jpg';
      case 'lesson_D_13':
        return 'images/lesson_d_13_spec.jpg';
      case 'lesson_D_14':
        return 'images/lesson_d_14_substitution.jpg';
      case 'lesson_D_15':
        return 'images/lesson_d_15_texture.jpg';
      case 'lesson_D_16':
        return 'images/lesson_d_16_temperature.jpg';
      case 'lesson_E_17':
        return 'images/lesson_e_17_whiskey_sour.jpg';
      case 'lesson_E_18':
        return 'images/lesson_e_18_old_fashioned.jpg';
      case 'lesson_E_19':
        return 'images/lesson_e_19_dry_martini.jpg';
      case 'lesson_E_20':
        return 'images/lesson_e_20_margarita.jpg';
      case 'lesson_F_21':
        return 'images/lesson_f_21_prep_safety.jpg';
      case 'lesson_F_22':
        return 'images/lesson_f_22_guest_brief.jpg';
      case 'lesson_F_23':
        return 'images/lesson_f_23_service_rush.jpg';
      case 'lesson_F_24':
        return 'images/lesson_f_24_exam.jpg';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = status == LessonStatus.locked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLocked ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: isLocked ? null : _cardGradient(),
              color: isLocked ? AppColors.surface.withAlpha(110) : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLocked
                    ? AppColors.divider.withAlpha(80)
                    : _blockAccentColor.withAlpha(_theoryDone ? 220 : 140),
                width: _theoryDone ? 2 : 1,
              ),
              boxShadow: isLocked
                  ? null
                  : [
                      BoxShadow(
                        color: _blockShadowColor.withAlpha(
                          _theoryDone ? 70 : 28,
                        ),
                        blurRadius: _theoryDone ? 24 : 16,
                        spreadRadius: _theoryDone ? 2 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // ── Card content ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  child: Column(
                    children: [
                      // Top row: lesson number + completed seal
                      Row(
                        children: [
                          _LessonNumber(
                            number: lesson.lessonNumber,
                            isLocked: isLocked,
                          ),
                          const Spacer(),
                          if (_theoryDone)
                            _GoldenSeal(practicePending: _practicePending),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Expanded(
                        child: _lessonArtworkPath == null
                            ? _JohnLessonHint(
                                lesson: lesson,
                                isLocked: isLocked,
                              )
                            : _LessonArtwork(
                                assetPath: _lessonArtworkPath!,
                                fallbackEmoji: lesson.emoji,
                                isLocked: isLocked,
                                accentColor: _blockAccentColor,
                              ),
                      ),

                      const SizedBox(height: 8),

                      // Title
                      Text(
                        lesson.title,
                        style: TextStyle(
                          color: isLocked
                              ? AppColors.textSecondary.withAlpha(90)
                              : AppColors.textPrimary,
                          fontSize: 12,
                          fontFamily:
                              const ['A', 'B', 'C'].contains(lesson.blockId)
                                  ? 'serif'
                                  : null,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 6),

                      // Bottom indicators row
                      _BottomIndicators(
                        isLocked: isLocked,
                        practicePending: _practicePending,
                        practiceComplete: practiceComplete,
                        termsLearned: termsLearned,
                        totalTerms: lesson.terms.length,
                      ),
                    ],
                  ),
                ),

                // ── Locked fog overlay ────────────────────────────
                if (isLocked)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: Container(
                          color: Colors.black.withAlpha(20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Main lesson-card visual: artwork plus John's short guidance ─────────────
// ─── Premium thematic artwork for lesson cards ───────────────────────────────
class _LessonArtwork extends StatelessWidget {
  final String assetPath;
  final String fallbackEmoji;
  final bool isLocked;
  final Color accentColor;

  const _LessonArtwork({
    required this.assetPath,
    required this.fallbackEmoji,
    required this.isLocked,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.surface.withAlpha(70)
            : AppColors.background.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLocked
              ? AppColors.divider.withAlpha(35)
              : accentColor.withAlpha(70),
        ),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.58,
          heightFactor: 0.58,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceLight.withAlpha(120),
                    child: Center(
                      child: Text(
                        fallbackEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(isLocked ? 100 : 0),
                        Colors.black.withAlpha(isLocked ? 135 : 26),
                      ],
                    ),
                  ),
                ),
                if (isLocked)
                  Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: Colors.white.withAlpha(190),
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Lesson number badge ───────────────────────────────────────────────────
class _LessonNumber extends StatelessWidget {
  final int number;
  final bool isLocked;

  const _LessonNumber({required this.number, required this.isLocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isLocked
            ? AppColors.divider.withAlpha(30)
            : AppColors.primary.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isLocked ? Colors.transparent : AppColors.primary.withAlpha(80),
        ),
      ),
      child: Text(
        number.toString().padLeft(2, '0'),
        style: TextStyle(
          color: isLocked
              ? AppColors.textSecondary.withAlpha(60)
              : AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Golden wax seal for completed lessons ─────────────────────────────────
class _GoldenSeal extends StatelessWidget {
  final bool practicePending;

  const _GoldenSeal({required this.practicePending});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: practicePending
              ? [const Color(0xFFFF9800), const Color(0xFFE65100)]
              : [const Color(0xFFFFD700), const Color(0xFFDAA520)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (practicePending ? Colors.orange : const Color(0xFFDAA520))
                .withAlpha(80),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          practicePending ? Icons.handyman_rounded : Icons.check_rounded,
          color: Colors.white,
          size: 13,
        ),
      ),
    );
  }
}

// ─── Bottom indicators (practice + terms) ──────────────────────────────────
class _BottomIndicators extends StatelessWidget {
  final bool isLocked;
  final bool practicePending;
  final bool practiceComplete;
  final int termsLearned;
  final int totalTerms;

  const _BottomIndicators({
    required this.isLocked,
    required this.practicePending,
    required this.practiceComplete,
    required this.termsLearned,
    required this.totalTerms,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) return const SizedBox(height: 14);

    final showPractice = practicePending || practiceComplete;
    final showTerms = totalTerms > 0;

    if (!showPractice && !showTerms) return const SizedBox(height: 14);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showPractice)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: practicePending
                  ? Colors.orange.withAlpha(30)
                  : AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              practicePending ? '🍸' : '✓',
              style: TextStyle(
                fontSize: 9,
                color: practicePending ? Colors.orange : AppColors.primary,
              ),
            ),
          ),
        if (showPractice && showTerms) const SizedBox(width: 4),
        if (showTerms)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight.withAlpha(130),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              termsLearned < totalTerms ? '$termsLearned/$totalTerms' : '✓',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── John's avatar as the card's central visual ─────────────────────────
class _JohnLessonHint extends StatelessWidget {
  final Lesson lesson;
  final bool isLocked;

  const _JohnLessonHint({
    required this.lesson,
    required this.isLocked,
  });

  String get _speechText {
    if (isLocked) return 'Сначала открой предыдущий шаг.';

    if (lesson.id == 'lesson_C_12') {
      return 'Это уже проверка за стойкой.';
    }

    switch (lesson.blockId) {
      case 'A':
        return 'Сначала учимся слышать вкус.';
      case 'B':
        return 'Теперь руки должны стать точными.';
      case 'C':
        return 'Собираем классику для экзамена.';
      default:
        return 'Идем шаг за шагом.';
    }
  }

  String get _assetPath {
    if (lesson.blockId == 'B') return 'images/barista_john_practice.png';
    if (lesson.blockId == 'C') return 'images/barista_john_exam.png';
    return 'images/barista_john_teach.png';
  }

  String get _roleLabel {
    if (lesson.blockId == 'B') return 'ПРАКТИКА';
    if (lesson.blockId == 'C') return 'ЭКЗАМЕН';
    return 'ТЕОРИЯ';
  }

  bool get _isBlockFocus => lesson.blockId == 'B' || lesson.blockId == 'C';

  Color get _accentColor {
    switch (lesson.blockId) {
      case 'B':
        return const Color(0xFF52D6C6);
      case 'C':
        return const Color(0xFFB57CFF);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isLocked
        ? AppColors.textSecondary.withAlpha(90)
        : AppColors.textPrimary;

    if (_isBlockFocus) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.surface.withAlpha(60)
                  : _accentColor.withAlpha(26),
              shape: BoxShape.circle,
              border: Border.all(
                color: isLocked
                    ? AppColors.divider.withAlpha(40)
                    : _accentColor.withAlpha(140),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withAlpha(isLocked ? 18 : 34),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLocked
                ? Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: AppColors.textSecondary.withAlpha(100),
                      size: 26,
                    ),
                  )
                : ClipOval(
                    child: Image.asset(
                      _assetPath,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          lesson.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.surface.withAlpha(100)
                  : _accentColor.withAlpha(22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isLocked
                    ? AppColors.divider.withAlpha(40)
                    : _accentColor.withAlpha(90),
              ),
            ),
            child: Text(
              _roleLabel,
              style: TextStyle(
                color: isLocked
                    ? AppColors.textSecondary.withAlpha(120)
                    : _accentColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isLocked
                  ? AppColors.surface.withAlpha(120)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLocked
                    ? AppColors.divider.withAlpha(35)
                    : _accentColor.withAlpha(70),
              ),
            ),
            child: Text(
              _speechText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                height: 1.22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isLocked
                ? AppColors.surface.withAlpha(60)
                : _accentColor.withAlpha(18),
            shape: BoxShape.circle,
            border: Border.all(
              color: isLocked
                  ? AppColors.divider.withAlpha(40)
                  : _accentColor.withAlpha(120),
              width: 1.5,
            ),
          ),
          child: isLocked
              ? Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: AppColors.textSecondary.withAlpha(100),
                    size: 22,
                  ),
                )
              : ClipOval(
                  child: Image.asset(
                    _assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        lesson.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -4,
                top: 18,
                child: Transform.rotate(
                  angle: 0.785,
                  child: Container(
                    width: 8,
                    height: 8,
                    color: isLocked
                        ? AppColors.surface.withAlpha(120)
                        : AppColors.surface,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: 46),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: isLocked
                      ? AppColors.surface.withAlpha(120)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLocked
                        ? AppColors.divider.withAlpha(35)
                        : AppColors.primary.withAlpha(70),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Джон:',
                      style: TextStyle(
                        color: isLocked
                            ? AppColors.textSecondary.withAlpha(100)
                            : AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _speechText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
