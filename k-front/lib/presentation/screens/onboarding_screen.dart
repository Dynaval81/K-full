import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:knoty/constants/palette.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.chat_bubble_rounded,
      title: 'Willkommen bei Knoty',
      subtitle:
          'Der Bildungs-Messenger für Schüler, Lehrer und Eltern in Deutschland.',
    ),
    _OnboardingPage(
      icon: Icons.school_rounded,
      title: 'Mit deiner Schule verbunden',
      subtitle:
          'Registriere dich mit deinem Aktivierungscode und tritt deiner Schulgemeinschaft bei.',
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      title: 'Sicher & datenschutzkonform',
      subtitle:
          'Keine Werbung, keine Datenweitergabe. Nur für Bildungseinrichtungen in Deutschland.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    context.go('/auth');
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button top-right
            Positioned(
              top: 8,
              right: 16,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Überspringen',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ),

            // Page content + bottom controls
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) =>
                        _PageContent(page: _pages[index]),
                  ),
                ),
                _BottomControls(
                  currentPage: _currentPage,
                  pageCount: _pages.length,
                  onNext: _nextPage,
                  onFinish: _finishOnboarding,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: KPalette.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: KPalette.gold,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const _BottomControls({
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLastPage = currentPage == pageCount - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (i) {
              final isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? KPalette.gold : cs.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Action button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: KPalette.gold,
                foregroundColor: KPalette.ink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: isLastPage ? onFinish : onNext,
              child: Text(isLastPage ? 'Loslegen' : 'Weiter'),
            ),
          ),
        ],
      ),
    );
  }
}
