import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';

/// StarCraft-style mission briefing screen.
/// Показывается перед каждым блоком (A/B/C).
class MissionBriefingScreen extends StatelessWidget {
  final String blockId;

  const MissionBriefingScreen({super.key, required this.blockId});

  @override
  Widget build(BuildContext context) {
    final data = _briefingData[blockId];
    if (data == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F1A),
        body: Center(
            child: Text('Данные не найдены',
                style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  // Expanded вместо двух Spacer: на 360 px подпись с
                  // широким letterSpacing не переполняет Row, а сжимается.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'MISSION BRIEFING',
                        maxLines: 1,
                        style: GoogleFonts.cinzel(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD4AF37),
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Title
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // John's portrait with glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withAlpha(100),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: AssetImage(data.assetPath),
                        backgroundColor: const Color(0xFF1A1F2E),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // John's narration
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withAlpha(50),
                        ),
                      ),
                      child: Text(
                        data.johnNarration,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Objectives
                    _Objectives(blockId: blockId),
                    const SizedBox(height: 24),
                    // Goal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFD4AF37).withAlpha(30),
                            const Color(0xFFD4AF37).withAlpha(10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withAlpha(50),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flag_rounded,
                                  color: Color(0xFFD4AF37), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ЦЕЛЬ',
                                style: GoogleFonts.cinzel(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD4AF37),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.goal,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            // Start button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0F1A).withAlpha(0),
                    const Color(0xFF0A0F1A),
                  ],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onStart(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFFD4AF37).withAlpha(100),
                  ),
                  child: Text(
                    'НАЧАТЬ ГЛАВУ',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStart(BuildContext context) {
    final progress = context.read<ProgressService>();
    progress.markBlockIntroSeen(blockId);
    Navigator.pop(context);
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _BriefingData {
  final String title;
  final String assetPath;
  final String johnNarration;
  final String goal;

  const _BriefingData({
    required this.title,
    required this.assetPath,
    required this.johnNarration,
    required this.goal,
  });
}

const Map<String, _BriefingData> _briefingData = {
  'A': _BriefingData(
    title: 'Глава A: Пробуждение вкуса',
    assetPath: 'images/barista_john_teach.png',
    johnNarration:
        'Прежде чем смешивать коктейли, ты учишься чувствовать. Язык — первый инструмент бармена: кислота, сладость, горечь, соль и тело напитка. Четыре урока — и ты начнёшь слышать вкус. Я через это прошёл — и скажу тебе, без вкуса за стойкой делать нечего.',
    goal: 'Научиться различать вкусы и понимать баланс',
  ),
  'B': _BriefingData(
    title: 'Глава B: Руки и инструменты',
    assetPath: 'images/barista_john_practice.png',
    johnNarration:
        'Теперь вкус должен перейти в руки. Станция, джиггер, шейкер и лёд учат точности: 30 мл — это 30 мл, а shake — техника, а не суета. Поверь, я через это прошёл — первые коктейли у меня разлетались по всей барной стойке.',
    goal: 'Освоить технику и инструменты бармена',
  ),
  'C': _BriefingData(
    title: 'Глава C: Мастерство и авторские коктейли',
    assetPath: 'images/barista_john_exam.png',
    johnNarration:
        'Ты знаешь вкус, руки помнят технику. Теперь — время создавать. Маддл, тики, сложные билды. Это уровень, где ты перестаёшь повторять и начинаешь говорить своим голосом. Я жду от тебя не просто cocktails — я жду твою подпись.',
    goal: 'Создавать авторские коктейли и освоить сложные техники',
  ),
};

// ── Objectives Widget ────────────────────────────────────────────────────────

class _Objectives extends StatelessWidget {
  final String blockId;

  const _Objectives({required this.blockId});

  @override
  Widget build(BuildContext context) {
    final objectives = _getObjectives();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt_rounded,
                  color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                'ЧТО ПРЕДСТОИТ',
                style: GoogleFonts.cinzel(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...objectives.map((obj) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFFD4AF37), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        obj,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<String> _getObjectives() {
    switch (blockId) {
      case 'A':
        return [
          '4 урока о вкусах: сладкое, кислое, горькое, солёное, умами',
          'Научишься балансировать коктейль как эквалайзер',
          'Поймёшь, почему один вкус ведёт, а остальные подпевают',
          'Освоишь калибровку кислоты и сладости',
        ];
      case 'B':
        return [
          '4 урока о технике: stir, shake, build, muddle',
          'Научишься работать с джиггером и шейкером',
          'Поймёшь, почему 30 мл — это 30 мл, а не "примерно"',
          'Освоишь 7 классических коктейлей',
        ];
      case 'C':
        return [
          '3 урока о сложных техниках и авторских коктейлях',
          'Научишься muddle, тики-билдам, многослойным напиткам',
          'Поймёшь, как создавать свои рецепты',
          'Сдашь финальный экзамен и получишь диплом',
        ];
      default:
        return [];
    }
  }
}
