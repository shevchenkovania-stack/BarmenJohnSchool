import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:coin/features/home/view/home_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/wisdom_vault_screen.dart';
import 'package:coin/features/bartender_school/presentation/screens/workshop_screen.dart';
import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/domain/entities/progress.dart';
// 🔒 Конструктор спрятан — см. WORKSHOP_SPEC.md
// import 'package:coin/features/cocktail_builder/view/cocktail_builder_screen.dart';

// 🔒 Спрятанные фичи (см. HIDDEN_FEATURES.md):
// import 'package:coin/features/bartender_school/presentation/screens/school_home_screen.dart';
// import 'package:coin/features/favorites/view/favorites_screen.dart';
// import 'package:coin/features/bar_manager/bar_manager_screen.dart';

/// Главная оболочка приложения с нижней навигацией.
///
/// Три таба: 🎓 Учеба / 📜 Мудрость / 🍸 Практика
///
/// Вкладка "Мастерская" заблокирована пока не пройден первый урок (A_01).
///
/// [IndexedStack] сохраняет состояние каждого таба при переключении —
/// загруженные данные не теряются когда пользователь переходит между вкладками.
///
/// 🔒 Спрятанные фичи см. в HIDDEN_FEATURES.md
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Экраны создаются один раз — IndexedStack их не пересоздаёт
  static const _screens = [
    HomeScreen(), // 🎓 Главный экран — школа бармена (с большой картинкой)
    WisdomVaultScreen(), // 📜 Мудрость старого бармена
    WorkshopScreen(), // 🍸 Мастерская — практика бармена
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressService>(
      builder: (context, progress, _) {
        // Мастерская открыта после прохождения первого урока
        final isWorkshopUnlocked =
            progress.getLessonStatus('lesson_A_01') == LessonStatus.completed;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF24160F),
              border: Border(top: BorderSide(color: Color(0xFF8F6A32))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 16,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFFD0A24C),
              unselectedItemColor: const Color(0xFFAA9980),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
              ),
              currentIndex: _currentIndex,
              onTap: (i) {
                // Блокируем вкладку Мастерской если первый урок не пройден
                if (i == 2 && !isWorkshopUnlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        '🔒 Пройди первый урок, чтобы открыть Мастерскую',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: const Color(0xFF252336),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  return;
                }
                setState(() => _currentIndex = i);
              },
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: _NavAsset(
                    path: 'images/ui_icon_term_medal.png',
                    selected: _currentIndex == 0,
                  ),
                  label: 'Школа',
                ),
                BottomNavigationBarItem(
                  icon: _NavAsset(
                    path: 'images/wisdom_chest.jpg',
                    selected: _currentIndex == 1,
                  ),
                  label: 'Мудрость',
                ),
                BottomNavigationBarItem(
                  icon: isWorkshopUnlocked
                      ? _NavAsset(
                          path: 'images/ui_icon_tool_station.png',
                          selected: _currentIndex == 2,
                        )
                      : const Icon(Icons.lock_outline_rounded),
                  label: 'Мастерская',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavAsset extends StatelessWidget {
  final String path;
  final bool selected;

  const _NavAsset({required this.path, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 34,
      height: 34,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selected ? const Color(0x24D0A24C) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: selected ? Border.all(color: const Color(0x88D0A24C)) : null,
      ),
      child: Image.asset(path, fit: BoxFit.contain),
    );
  }
}
