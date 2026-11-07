// certificate_document.dart
// Замени _CertificateDocument, _CertificateDetailScreen и _NoCertificatesMessage
// Требует: google_fonts: ^6.x.x в pubspec.yaml
// Пример: flutter pub add google_fonts

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:coin/core/theme/app_theme.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/lesson_repository.dart';
import 'package:coin/features/bartender_school/presentation/widgets/student_name_dialog.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';

// ─────────────────────────────────────────────
//  DIPLOMA THEME — цвета по уровням
// ─────────────────────────────────────────────
class _DiplomaTheme {
  final Color accent;
  final Color accentLight;
  final List<Color> borderGradient;
  final List<Color> bgGradient;
  final String emoji;
  final String levelLabel;

  const _DiplomaTheme({
    required this.accent,
    required this.accentLight,
    required this.borderGradient,
    required this.bgGradient,
    required this.emoji,
    required this.levelLabel,
  });

  static _DiplomaTheme of(int level) {
    switch (level) {
      case 1:
        return const _DiplomaTheme(
          accent: Color(0xFFC9894F),
          accentLight: Color(0xFFE8B87A),
          borderGradient: [
            Color(0xFF8B5E3C),
            Color(0xFFC9894F),
            Color(0xFF8B5E3C)
          ],
          bgGradient: [Color(0xFF1A0F05), Color(0xFF2D1A08), Color(0xFF1F1208)],
          emoji: '🌱',
          levelLabel: 'LEVEL I — APPRENTICE',
        );
      case 2:
        return const _DiplomaTheme(
          accent: Color(0xFFC8C8D8),
          accentLight: Color(0xFFE8E8F0),
          borderGradient: [
            Color(0xFF6A6A7A),
            Color(0xFFD4D4D4),
            Color(0xFF6A6A7A)
          ],
          bgGradient: [Color(0xFF0D0D12), Color(0xFF1A1A24), Color(0xFF0F0F18)],
          emoji: '🍸',
          levelLabel: 'LEVEL II — PROFESSIONAL',
        );
      case 3:
      default:
        return const _DiplomaTheme(
          accent: Color(0xFFD4AF37),
          accentLight: Color(0xFFF5D060),
          borderGradient: [
            Color(0xFF7B5C00),
            Color(0xFFD4AF37),
            Color(0xFFF5D060),
            Color(0xFFD4AF37),
            Color(0xFF7B5C00)
          ],
          bgGradient: [Color(0xFF0A0800), Color(0xFF1A1400), Color(0xFF100E00)],
          emoji: '🏆',
          levelLabel: 'LEVEL III — MASTER',
        );
    }
  }
}

// ─────────────────────────────────────────────
//  CERTIFICATES LIST SCREEN (Главный экран)
// ─────────────────────────────────────────────
class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const JohnThemedAppBar(
        room: JohnSchoolRoom.honorsHall,
        title: 'Дипломный зал',
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.honorsHall,
        child: Consumer2<ProgressService, LessonRepository>(
          builder: (context, progressService, lessonRepo, _) {
            // Use isSchoolCompleted for gating diploma access
            final level1Complete =
                progressService.isSchoolCompleted(lessonRepo: lessonRepo);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CertificateCard(
                    level: 1,
                    title: 'Диплом Бармена',
                    subtitle: 'Базовый курс',
                    icon: '🌱',
                    gradientColors: [
                      Colors.green.shade600,
                      Colors.green.shade800
                    ],
                    isEarned: level1Complete,
                    requirements: const [
                      'Пройти 13 уроков базового курса',
                      'Выучить основы баланса коктейлей',
                      'Освоить базовые инструменты',
                    ],
                    onTap: () => _openCertificate(context, 1, 'Диплом Бармена',
                        progressService, level1Complete),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openCertificate(BuildContext context, int level, String title,
      ProgressService progress, bool isEarned) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificateDetailScreen(
          level: level,
          title: title,
          xp: progress.totalXP,
          streak: progress.streak,
          isLocked: !isEarned,
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final int level;
  final String title;
  final String subtitle;
  final String icon;
  final List<Color> gradientColors;
  final bool isEarned;
  final List<String> requirements;
  final VoidCallback? onTap;

  const _CertificateCard({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.isEarned,
    required this.requirements,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: isEarned
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF561923), Color(0xFF2C0D13)],
                )
              : null,
          color: isEarned ? null : const Color(0xEE25150F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEarned ? const Color(0xFFD4A84E) : const Color(0x668F6A32),
            width: isEarned ? 1.8 : 1,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: const Color(0x88D4A84E),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(isEarned ? 30 : 20),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: isEarned
                          ? Image.asset('images/ui_icon_term_medal.png')
                          : const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFFAA9980),
                              size: 34,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isEarned
                                    ? Colors.white.withAlpha(40)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'LEVEL $level',
                                style: TextStyle(
                                  color: isEarned
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isEarned)
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 24),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: TextStyle(
                            color:
                                isEarned ? Colors.white : AppColors.textPrimary,
                            fontSize: 18,
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isEarned
                                ? Colors.white.withAlpha(200)
                                : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...requirements.take(2).map((req) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                children: [
                                  Icon(
                                    isEarned ? Icons.check : Icons.close,
                                    size: 14,
                                    color: isEarned
                                        ? Colors.white.withAlpha(200)
                                        : AppColors.textSecondary
                                            .withAlpha(100),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      req,
                                      style: TextStyle(
                                        color: isEarned
                                            ? Colors.white.withAlpha(200)
                                            : AppColors.textSecondary
                                                .withAlpha(150),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  if (isEarned)
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 18),
                ],
              ),
            ),
            if (!isEarned)
              // Раньше плашка лежала в Positioned.fill+Center и пересекала
              // заголовок карточки, затемняя её целиком.
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.divider.withAlpha(120), width: 1),
                  ),
                  child: const Text(
                    'Не получен',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DETAIL SCREEN
// ─────────────────────────────────────────────
class CertificateDetailScreen extends StatefulWidget {
  final int level;
  final String title;
  final int xp;
  final int streak;
  final bool isLocked;

  const CertificateDetailScreen({
    super.key,
    required this.level,
    required this.title,
    required this.xp,
    required this.streak,
    this.isLocked = false,
  });

  @override
  State<CertificateDetailScreen> createState() =>
      _CertificateDetailScreenState();
}

class _CertificateDetailScreenState extends State<CertificateDetailScreen> {
  @override
  void initState() {
    super.initState();
    // If no name entered, show dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = context.read<ProgressService>();
      if (!progress.hasEnteredName) {
        StudentNameDialog.show(context);
      }
    });
  }

  Future<void> _showEditNameDialog() async {
    await StudentNameDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _DiplomaTheme.of(widget.level).accent;
    final progress = context.watch<ProgressService>();
    final studentName = progress.studentFullName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const JohnThemedAppBar(
        room: JohnSchoolRoom.honorsHall,
        title: 'Церемония диплома',
      ),
      body: JohnRoomBackground(
        room: JohnSchoolRoom.honorsHall,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const _CertificateMentorHeader(),
              const SizedBox(height: 16),
              // Diploma document — always visible (with lock overlay if not earned)
              Stack(
                children: [
                  CertificateDocument(
                    level: widget.level,
                    title: widget.title,
                    xp: widget.xp,
                    streak: widget.streak,
                    studentName: studentName,
                  ),
                  if (widget.isLocked)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {}, // Block interaction
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white70,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Диплом пока заблокирован',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withAlpha(200),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32),
                                  child: Text(
                                    'Пройди все 13 уроков и сдай экзамен, чтобы получить диплом',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(150),
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (!widget.isLocked) ...[
                _ActionButton(
                  icon: Icons.edit_outlined,
                  label: studentName.trim().isEmpty
                      ? 'Ввести имя'
                      : 'Изменить имя',
                  isPrimary: false,
                  onTap: _showEditNameDialog,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.print_outlined,
                  label: 'Распечатать',
                  isPrimary: true,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Функция печати в разработке'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  accentColor: accentColor,
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.download_outlined,
                  label: 'Сохранить PDF',
                  isPrimary: false,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Функция скачивания в разработке'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  accentColor: accentColor,
                ),
                const SizedBox(height: 32),
              ], // end if (!widget.isLocked)
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateMentorHeader extends StatelessWidget {
  const _CertificateMentorHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(70)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'images/barista_john_celebrate.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Бармен Джон вручает диплом только после честной практики и финального экзамена.',
              style: TextStyle(
                color: AppColors.textSecondary.withAlpha(220),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  final Color accentColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: isPrimary ? accentColor.withAlpha(20) : Colors.transparent,
              border: Border.all(
                  color: accentColor.withAlpha(isPrimary ? 150 : 80)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: accentColor),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.cinzel(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: accentColor,
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

// ─────────────────────────────────────────────
//  MAIN CERTIFICATE DOCUMENT WIDGET
// ─────────────────────────────────────────────
class CertificateDocument extends StatelessWidget {
  final int level;
  final String title;
  final int xp;
  final int streak;
  final String studentName;

  const CertificateDocument({
    super.key,
    required this.level,
    required this.title,
    required this.xp,
    required this.streak,
    required this.studentName,
  });

  String get _subtitle {
    switch (level) {
      case 1:
        return 'Certificate of Bartending Apprenticeship';
      case 2:
        return 'Certificate of Professional Bartending';
      case 3:
        return 'Master Certificate of Mixology';
      default:
        return 'Certificate of Excellence';
    }
  }

  String get _bodyText {
    switch (level) {
      case 1:
        return 'Подтверждает успешное прохождение базового курса\nбарменского мастерства и освоение основ баланса коктейлей.\nЭто учебный диплом, а не лицензия на продажу алкоголя.';
      case 2:
        return 'Подтверждает профессиональное владение техниками\nзамены ингредиентов и сочетания вкусов.';
      case 3:
        return 'Будущий мастер-курс. В первом релизе доступен честный диплом Level 1.';
      default:
        return '';
    }
  }

  String _getDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = _DiplomaTheme.of(level);
    final displayName = studentName.trim().isEmpty
        ? 'Введите имя студента'
        : studentName.trim();

    return Container(
      // Outer border — gradient shimmer frame
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.borderGradient,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.bgGradient,
          ),
        ),
        child: Stack(
          children: [
            // Watermark
            Positioned.fill(
              child: Center(
                child: Text(
                  'JD',
                  style: GoogleFonts.cinzel(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withAlpha(4),
                    letterSpacing: 12,
                  ),
                ),
              ),
            ),

            // Corner ornaments
            Positioned(
                top: 0, left: 0, child: _CornerOrnament(color: theme.accent)),
            Positioned(
                top: 0,
                right: 0,
                child: Transform(
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    alignment: Alignment.center,
                    child: _CornerOrnament(color: theme.accent))),
            Positioned(
                bottom: 0,
                left: 0,
                child: Transform(
                    transform: Matrix4.identity()..scale(1.0, -1.0),
                    alignment: Alignment.center,
                    child: _CornerOrnament(color: theme.accent))),
            Positioned(
                bottom: 0,
                right: 0,
                child: Transform(
                    transform: Matrix4.identity()..scale(-1.0, -1.0),
                    alignment: Alignment.center,
                    child: _CornerOrnament(color: theme.accent))),

            // Extra inner border for level 3
            if (level == 3)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.accent.withAlpha(40)),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),

            // Main content
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // School name
                Text(
                  'JOHN ROCK BARTENDER SCHOOL',
                  style: GoogleFonts.cinzel(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                    color: theme.accent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Est. — The Art of Mixology',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withAlpha(100),
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 16),
                _OrnamentalRule(color: theme.accent, isDiamond: level == 3),
                const SizedBox(height: 14),

                // Level badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.accent.withAlpha(120)),
                    color: theme.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: Text(
                    theme.levelLabel,
                    style: GoogleFonts.cinzel(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
                      color: theme.accent,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // "Настоящим удостоверяется"
                Text(
                  level == 3
                      ? 'Настоящим с честью удостоверяется'
                      : 'Настоящим удостоверяется',
                  style: GoogleFonts.ebGaramond(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withAlpha(120),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // Diploma title
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: theme.accentLight,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    color: Colors.white.withAlpha(100),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Body text
                Text(
                  _bodyText,
                  style: GoogleFonts.ebGaramond(
                    fontSize: 12,
                    color: Colors.white.withAlpha(120),
                    height: 1.7,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Student name placeholder
                Text(
                  displayName,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: studentName.trim().isEmpty ? 20 : 26,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    color: studentName.trim().isEmpty
                        ? Colors.white.withAlpha(100)
                        : Colors.white,
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 180,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.accent.withAlpha(160),
                        Colors.transparent
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Stats row
                _StatsRow(
                    xp: xp,
                    streak: streak,
                    accentColor: theme.accent,
                    accentLight: theme.accentLight),

                const SizedBox(height: 24),

                // Footer with signature + date + seal
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withAlpha(40),
                            Colors.transparent
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SigBlock(
                            value: 'John Rock',
                            label: 'ОСНОВАТЕЛЬ ШКОЛЫ',
                            isItalic: true,
                            color: theme.accent,
                          ),
                          const SizedBox(width: 48),
                          _SigBlock(
                            value: _getDate(),
                            label: 'ДАТА ВЫДАЧИ',
                            isItalic: false,
                            color: Colors.white.withAlpha(130),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Seal emoji badge
                Align(
                  alignment: Alignment.centerRight,
                  child: _SealBadge(
                    emoji: theme.emoji,
                    color: theme.accent,
                    bgColor: theme.bgGradient.first,
                    isGold: level == 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SUB-WIDGETS
// ─────────────────────────────────────────────

class _CornerOrnament extends StatelessWidget {
  final Color color;
  const _CornerOrnament({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(44, 44),
      painter: _CornerPainter(color: color),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final paintThin = Paint()
      ..color = color.withAlpha(160)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;

    // Outer L
    canvas.drawLine(const Offset(4, 4), const Offset(4, 24), paint);
    canvas.drawLine(const Offset(4, 4), const Offset(24, 4), paint);
    // Inner L
    canvas.drawLine(const Offset(9, 9), const Offset(9, 18), paintThin);
    canvas.drawLine(const Offset(9, 9), const Offset(18, 9), paintThin);
    // Dot
    canvas.drawCircle(const Offset(4, 4), 1.8, Paint()..color = color);
    // Arc
    final arcPaint = Paint()
      ..color = color.withAlpha(120)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;
    canvas.drawArc(const Rect.fromLTWH(4, 4, 14, 14), 0, 1.57, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrnamentalRule extends StatelessWidget {
  final Color color;
  final bool isDiamond;
  const _OrnamentalRule({required this.color, this.isDiamond = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, color],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: isDiamond
              ? CustomPaint(
                  size: const Size(20, 12),
                  painter: _DiamondOrnamentPainter(color: color))
              : CustomPaint(
                  size: const Size(16, 10),
                  painter: _CircleOrnamentPainter(color: color)),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleOrnamentPainter extends CustomPainter {
  final Color color;
  _CircleOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(cx - 5, cy), p);
    canvas.drawLine(Offset(cx + 5, cy), Offset(size.width, cy), p);
    canvas.drawCircle(Offset(cx, cy), 1.5, Paint()..color = color);
    canvas.drawCircle(Offset(cx, cy), 4, p..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiamondOrnamentPainter extends CustomPainter {
  final Color color;
  _DiamondOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(0, cy), Offset(cx - 7, cy), p);
    canvas.drawLine(Offset(cx + 7, cy), Offset(size.width, cy), p);
    final path = Path()
      ..moveTo(cx, cy - 4)
      ..lineTo(cx + 4, cy)
      ..lineTo(cx, cy + 4)
      ..lineTo(cx - 4, cy)
      ..close();
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), 6.5, p..strokeWidth = 0.4);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatsRow extends StatelessWidget {
  final int xp;
  final int streak;
  final Color accentColor;
  final Color accentLight;

  const _StatsRow({
    required this.xp,
    required this.streak,
    required this.accentColor,
    required this.accentLight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(label: 'ОПЫТ XP', value: '$xp', accentLight: accentLight),
        _divider(accentColor),
        _StatItem(
            label: 'СЕРИЯ ДНЕЙ', value: '$streak', accentLight: accentLight),
        _divider(accentColor),
        _StatItem(label: 'УРОКОВ', value: '—', accentLight: accentLight),
      ],
    );
  }

  Widget _divider(Color c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(width: 0.5, height: 32, color: c.withAlpha(60)),
      );
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color accentLight;

  const _StatItem(
      {required this.label, required this.value, required this.accentLight});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: accentLight,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cinzel(
            fontSize: 7,
            letterSpacing: 1.5,
            color: Colors.white.withAlpha(80),
          ),
        ),
      ],
    );
  }
}

class _SigBlock extends StatelessWidget {
  final String value;
  final String label;
  final bool isItalic;
  final Color color;

  const _SigBlock({
    required this.value,
    required this.label,
    required this.isItalic,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 15,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Container(width: 80, height: 0.5, color: Colors.white.withAlpha(40)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.cinzel(
            fontSize: 7,
            letterSpacing: 1.5,
            color: Colors.white.withAlpha(60),
          ),
        ),
      ],
    );
  }
}

class _SealBadge extends StatelessWidget {
  final String emoji;
  final Color color;
  final Color bgColor;
  final bool isGold;

  const _SealBadge({
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.isGold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: color.withAlpha(180)),
        boxShadow: isGold
            ? [
                BoxShadow(
                    color: color.withAlpha(60), blurRadius: 12, spreadRadius: 1)
              ]
            : null,
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NO CERTIFICATES MESSAGE
// ─────────────────────────────────────────────
class NoCertificatesMessage extends StatelessWidget {
  const NoCertificatesMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Image.asset(
            'images/ui_icon_term_medal.png',
            width: 56,
            height: 56,
            color: AppColors.textSecondary.withAlpha(80),
          ),
          const SizedBox(height: 16),
          Text(
            'ДИПЛОМЫ ЕЩЁ НЕ ПОЛУЧЕНЫ',
            style: GoogleFonts.cinzel(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Пройди уроки John Rock Bartender School\nи получи дипломы!',
            style: GoogleFonts.ebGaramond(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
