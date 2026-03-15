import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:knoty/constants/palette.dart';
import 'package:knoty/locale_provider.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final Widget illustration;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });
}

// ── Locale-aware page content ─────────────────────────────────────────────────

List<_OnboardingPage> _buildPages(String langCode) {
  switch (langCode) {
    case 'ru':
      return [
        _OnboardingPage(
          illustration: const _ChatIllustration(),
          title: 'Добро пожаловать в Knoty',
          subtitle: 'Образовательный мессенджер для учеников, учителей и родителей Германии.',
        ),
        _OnboardingPage(
          illustration: const _SchoolIllustration(),
          title: 'Связан со школой',
          subtitle: 'Зарегистрируйтесь с кодом активации и присоединитесь к сообществу школы.',
        ),
        _OnboardingPage(
          illustration: const _ShieldIllustration(),
          title: 'Безопасно и конфиденциально',
          subtitle: 'Без рекламы, без передачи данных. Только для образовательных учреждений.',
        ),
      ];
    case 'en':
      return [
        _OnboardingPage(
          illustration: const _ChatIllustration(),
          title: 'Welcome to Knoty',
          subtitle: 'The educational messenger for students, teachers and parents in Germany.',
        ),
        _OnboardingPage(
          illustration: const _SchoolIllustration(),
          title: 'Connected to your school',
          subtitle: 'Register with your activation code and join your school community.',
        ),
        _OnboardingPage(
          illustration: const _ShieldIllustration(),
          title: 'Safe & privacy first',
          subtitle: 'No ads, no data sharing. For educational institutions only.',
        ),
      ];
    default: // 'de'
      return [
        _OnboardingPage(
          illustration: const _ChatIllustration(),
          title: 'Willkommen bei Knoty',
          subtitle: 'Der Bildungs-Messenger für Schüler, Lehrer und Eltern in Deutschland.',
        ),
        _OnboardingPage(
          illustration: const _SchoolIllustration(),
          title: 'Mit deiner Schule verbunden',
          subtitle: 'Registriere dich mit deinem Aktivierungscode und tritt deiner Schulgemeinschaft bei.',
        ),
        _OnboardingPage(
          illustration: const _ShieldIllustration(),
          title: 'Sicher & datenschutzkonform',
          subtitle: 'Keine Werbung, keine Datenweitergabe. Nur für Bildungseinrichtungen in Deutschland.',
        ),
      ];
  }
}

String _skipLabel(String lang) =>
    lang == 'ru' ? 'Пропустить' : lang == 'en' ? 'Skip' : 'Überspringen';
String _nextLabel(String lang) =>
    lang == 'ru' ? 'Далее' : lang == 'en' ? 'Next' : 'Weiter';
String _startLabel(String lang) =>
    lang == 'ru' ? 'Начать' : lang == 'en' ? 'Get started' : 'Loslegen';

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    final lang = context.watch<LocaleProvider>().locale.languageCode;
    final pages = _buildPages(lang);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button
            Positioned(
              top: 8,
              right: 16,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  _skipLabel(lang),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ),

            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: pages.length,
                    itemBuilder: (context, index) =>
                        _PageContent(page: pages[index]),
                  ),
                ),
                _BottomControls(
                  currentPage: _currentPage,
                  pageCount: pages.length,
                  onNext: _nextPage,
                  onFinish: _finishOnboarding,
                  lang: lang,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page content ──────────────────────────────────────────────────────────────

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
          page.illustration,
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

// ── Bottom controls ───────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final String lang;

  const _BottomControls({
    required this.currentPage,
    required this.pageCount,
    required this.onNext,
    required this.onFinish,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLastPage = currentPage == pageCount - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
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
              child: Text(isLastPage ? _startLabel(lang) : _nextLabel(lang)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustrations ─────────────────────────────────────────────────────────────

/// Slide 1 — Chat bubbles composition
class _ChatIllustration extends StatelessWidget {
  const _ChatIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KPalette.gold.withValues(alpha: 0.08),
            ),
          ),
          // Bottom-left bubble (received)
          Positioned(
            left: 8, bottom: 20,
            child: _Bubble(
              width: 110, height: 44,
              color: cs.surfaceContainer,
              radius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              child: Row(children: [
                Container(width: 28, height: 8, decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 6),
                Container(width: 44, height: 8, decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4))),
              ]),
            ),
          ),
          // Top-right bubble (sent)
          Positioned(
            right: 8, top: 20,
            child: _Bubble(
              width: 120, height: 44,
              color: KPalette.gold,
              radius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: Row(children: [
                Container(width: 50, height: 8, decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 6),
                Container(width: 30, height: 8, decoration: BoxDecoration(color: KPalette.ink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4))),
              ]),
            ),
          ),
          // Center icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KPalette.gold,
              boxShadow: [BoxShadow(color: KPalette.gold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: KPalette.ink, size: 26),
          ),
        ],
      ),
    );
  }
}

/// Slide 2 — School composition
class _SchoolIllustration extends StatelessWidget {
  const _SchoolIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KPalette.gold.withValues(alpha: 0.08),
            ),
          ),
          // People icons (students)
          Positioned(
            bottom: 16,
            child: Row(children: [
              _SmallAvatar(icon: Icons.person_rounded, color: cs.surfaceContainer),
              const SizedBox(width: 8),
              _SmallAvatar(icon: Icons.person_rounded, color: KPalette.gold.withValues(alpha: 0.25)),
              const SizedBox(width: 8),
              _SmallAvatar(icon: Icons.person_rounded, color: cs.surfaceContainer),
            ]),
          ),
          // Book top-left
          Positioned(
            left: 12, top: 24,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.menu_book_rounded, color: KPalette.gold, size: 24),
            ),
          ),
          // Certificate top-right
          Positioned(
            right: 12, top: 24,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.workspace_premium_rounded, color: KPalette.gold, size: 24),
            ),
          ),
          // Center school icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KPalette.gold,
              boxShadow: [BoxShadow(color: KPalette.gold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.school_rounded, color: KPalette.ink, size: 26),
          ),
        ],
      ),
    );
  }
}

/// Slide 3 — Shield / security composition
class _ShieldIllustration extends StatelessWidget {
  const _ShieldIllustration();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KPalette.gold.withValues(alpha: 0.08),
            ),
          ),
          // Orbit dots
          ...List.generate(6, (i) {
            final angle = i * 3.14159 / 3;
            final r = 68.0;
            final dx = r * (i % 2 == 0 ? 0.87 : -0.87) * (i < 3 ? 1 : -1);
            final dy = r * (i < 3 ? -0.5 : 0.5) * (i % 3 == 0 ? 0 : 1);
            return Positioned(
              left: 100 + dx - 6,
              top: 90 + dy - 6,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KPalette.gold.withValues(alpha: (i % 2 == 0) ? 0.4 : 0.2),
                ),
              ),
            );
          }),
          // No-ads badge
          Positioned(
            left: 10, top: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.block_rounded, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Ads', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          // DSGVO badge
          Positioned(
            right: 6, top: 28,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('DSGVO', style: TextStyle(fontSize: 11, color: KPalette.gold, fontWeight: FontWeight.w700)),
            ),
          ),
          // Center shield icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KPalette.gold,
              boxShadow: [BoxShadow(color: KPalette.gold.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.shield_rounded, color: KPalette.ink, size: 26),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final BorderRadius radius;
  final Widget child;

  const _Bubble({
    required this.width,
    required this.height,
    required this.color,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Center(child: child),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SmallAvatar({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 20, color: KPalette.gold),
    );
  }
}
