import 'package:coin/features/bartender_school/data/progress_service.dart';
import 'package:coin/features/bartender_school/data/term_service.dart';
import 'package:coin/features/bartender_school/presentation/widgets/john_school_visuals.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Glossary screen that uses the unified TermService.
/// Shows term learning progress and groups by category.
class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Все';

  final TermService _termService = TermService();

  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    final cats = _termService.termsByCategory.keys.toList()..sort();
    _categories = ['Все', ...cats];
  }

  List<TermData> _getFilteredTerms() {
    final allTerms = TermService.allTerms;
    List<TermData> terms;

    if (_selectedCategory == 'Все') {
      terms = allTerms;
    } else {
      terms =
          allTerms.where((term) => term.category == _selectedCategory).toList();
    }

    if (_searchQuery.isEmpty) return terms;

    return terms.where((term) {
      return term.russianName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          term.englishName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          term.definition.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const room = JohnSchoolRoom.recipeArchive;
    final style = JohnRoomStyle.forRoom(room);

    return Consumer<ProgressService>(
      builder: (context, progress, _) {
        final filteredTerms = _getFilteredTerms();
        final totalLearned = progress.totalLearnedTerms;
        final totalTerms = TermService.allTerms.length;

        return Scaffold(
          backgroundColor: const Color(0xFF120B08),
          appBar: JohnThemedAppBar(
            room: room,
            title: 'Справочник терминов',
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: style.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: style.accent.withAlpha(125)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'images/ui_icon_term_medal.png',
                      width: 17,
                      height: 17,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$totalLearned/$totalTerms',
                      style: TextStyle(
                        color: style.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: JohnRoomBackground(
            room: room,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: JohnParchmentPanel(
                    room: room,
                    padding: EdgeInsets.zero,
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Найти термин в архиве...',
                        hintStyle: TextStyle(
                          color: const Color(0xFF493421).withAlpha(150),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6D4C28),
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF2F2014),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? style.accent
                                  : style.surfaceLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? style.accent
                                    : style.accent.withAlpha(100),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: style.accent.withAlpha(55),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? style.ink
                                    : style.onDark.withAlpha(200),
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredTerms.isEmpty
                      ? Center(
                          child: JohnWoodPanel(
                            room: room,
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: .65,
                                  child: Image.asset(
                                    'images/ui_icon_book_theory.png',
                                    width: 50,
                                    height: 50,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Термины не найдены',
                                  style: TextStyle(
                                    color: style.onDark,
                                    fontFamily: 'serif',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTerms.length,
                          itemBuilder: (context, index) {
                            final term = filteredTerms[index];
                            final isLearned =
                                progress.isTermLearned(term.russianName);
                            return _TermCard(
                              term: term,
                              isLearned: isLearned,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TermCard extends StatelessWidget {
  final TermData term;
  final bool isLearned;

  const _TermCard({required this.term, this.isLearned = false});

  @override
  Widget build(BuildContext context) {
    const room = JohnSchoolRoom.recipeArchive;
    final style = JohnRoomStyle.forRoom(room);
    const learnedColor = Color(0xFF547A50);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: JohnParchmentPanel(
        room: room,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLearned
                          ? learnedColor.withAlpha(30)
                          : style.accent.withAlpha(35),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isLearned
                            ? learnedColor.withAlpha(115)
                            : style.accent.withAlpha(110),
                      ),
                    ),
                    child: Text(
                      term.englishName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isLearned ? learnedColor : const Color(0xFF6D471E),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    term.russianName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5A4430),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isLearned)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: learnedColor,
                    size: 19,
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              term.definition,
              style: const TextStyle(
                color: Color(0xFF2F2014),
                fontFamily: 'serif',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (term.example.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [style.surfaceLight, style.surface],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: style.accent.withAlpha(90)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'images/ui_icon_tip_citrus.png',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        term.example,
                        style: TextStyle(
                          color: style.onDark.withAlpha(205),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Image.asset(
                  'images/ui_icon_book_theory.png',
                  width: 15,
                  height: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  'Урок: ${_formatLessonId(term.lessonId)}',
                  style: TextStyle(
                    color: const Color(0xFF5A4430).withAlpha(180),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLessonId(String lessonId) {
    final parts = lessonId.split('_');
    if (parts.length >= 3) return '${parts[1]}${parts[2]}';
    return lessonId;
  }
}
