import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/settings_service.dart';
import '../../l10n/app_localizations.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishTutorial() async {
    await SettingsService().completeTutorial();
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> slides = [
      {
        'title': l10n.tutorial_title_1,
        'description': l10n.tutorial_desc_1,
        'icon': Icons.view_in_ar_rounded,
        'color': AppTheme.arteRed,
        'secondaryColor': const Color(0xFFFF5252),
      },
      {
        'title': l10n.tutorial_title_2,
        'description': l10n.tutorial_desc_2,
        'icon': Icons.auto_awesome_rounded,
        'color': AppTheme.arteBlue,
        'secondaryColor': const Color(0xFF40C4FF),
      },
      {
        'title': l10n.tutorial_title_3,
        'description': l10n.tutorial_desc_3,
        'icon': Icons.groups_rounded,
        'color': AppTheme.arteYellow,
        'secondaryColor': const Color(0xFFFFD740),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundBlack : AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < slides.length - 1)
                    TextButton(
                      onPressed: _finishTutorial,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : AppTheme.textGrey,
                      ),
                      child: Text(
                        l10n.tutorial_skip,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48), // Placeholder to maintain height
                ],
              ),
            ),

            // PageView for Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Premium Illustration / Icon Container
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  slide['color'],
                                  slide['secondaryColor'],
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: slide['color'].withValues(alpha: 0.3),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                slide['icon'],
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Title
                          Text(
                            slide['title'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textBlack,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            slide['description'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: isDark ? Colors.white70 : AppTheme.textGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation & Indicator Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators (Dots)
                  Row(
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 10,
                        width: _currentPage == index ? 28 : 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? slides[_currentPage]['color']
                              : (isDark ? Colors.white24 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),

                  // Next / Start Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: _currentPage == slides.length - 1
                        ? ElevatedButton(
                            onPressed: _finishTutorial,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: slides[_currentPage]['color'],
                              elevation: 4,
                              shadowColor: slides[_currentPage]['color'].withValues(alpha: 0.4),
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              l10n.tutorial_start,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: slides[_currentPage]['color'],
                                boxShadow: [
                                  BoxShadow(
                                    color: slides[_currentPage]['color'].withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
