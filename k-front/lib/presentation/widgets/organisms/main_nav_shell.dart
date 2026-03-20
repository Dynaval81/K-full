// v1.3.1
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/core/controllers/tab_visibility_controller.dart';
import 'package:knoty/core/controllers/swipe_lock_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/data/models/user_model.dart';
import 'package:knoty/presentation/screens/ai/ai_assistant_screen.dart';
import 'package:knoty/presentation/screens/chats_screen.dart';
import 'package:knoty/presentation/screens/school/school_screen.dart';
import 'package:knoty/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:knoty/presentation/screens/parent/parent_control_screen.dart';
import 'package:knoty/presentation/screens/teacher/my_classes_screen.dart';
import 'package:knoty/presentation/screens/admin/verwaltung_screen.dart';
import 'package:knoty/presentation/widgets/offline_banner.dart';

class _TabDef {
  final String id;
  final IconData icon;
  final String label;
  final Widget screen;

  const _TabDef({
    required this.id,
    required this.icon,
    required this.label,
    required this.screen,
  });
}

// Фабрика вкладок по роли и настройкам видимости.
// PageView получает ТОЛЬКО активные вкладки — скрытые не рендерятся.
List<_TabDef> _buildActiveTabs(
  UserRole role,
  TabVisibilityController visibility,
  AppLocalizations l10n,
  User? user,
) {
  final tabs = <_TabDef>[];

  if (visibility.showChatsTab)
    tabs.add(_TabDef(
      id: 'chats',
      icon: Icons.chat_bubble_outline_rounded,
      label: l10n.tabChats,
      screen: const ChatsScreen(key: PageStorageKey('chats')),
    ));

  if (visibility.showAiTab)
    tabs.add(_TabDef(
      id: 'ai',
      icon: Icons.psychology_rounded,
      label: l10n.navTabAi,
      screen: const AiAssistantScreen(key: PageStorageKey('ai')),
    ));

  if (visibility.showScheduleTab)
    tabs.add(_TabDef(
      id: 'school',
      icon: Icons.school_rounded,
      label: l10n.navTabSchool,
      screen: _SchoolGate(
        key: const PageStorageKey('school'),
        isVerified: user?.isSchoolVerified ?? false,
        child: const SchoolScreen(key: ValueKey('school_inner')),
      ),
    ));

  if (role.hasChildTab && visibility.showKindTab)
    tabs.add(_TabDef(
      id: 'kind',
      icon: Icons.child_care_rounded,
      label: l10n.settingsTabKind,
      screen: const ParentControlScreen(key: PageStorageKey('kind')),
    ));

  if (role.hasMyClassesTab && visibility.showClassesTab)
    tabs.add(_TabDef(
      id: 'classes',
      icon: Icons.class_rounded,
      label: l10n.settingsTabClasses,
      screen: const MyClassesScreen(key: PageStorageKey('classes')),
    ));

  if (role.hasManagementTab && visibility.showVerwaltungTab)
    tabs.add(_TabDef(
      id: 'verwaltung',
      icon: Icons.admin_panel_settings_rounded,
      label: l10n.settingsTabVerwaltung,
      screen: const VerwaltungScreen(key: PageStorageKey('verwaltung')),
    ));

  // Dashboard — всегда последним
  tabs.add(_TabDef(
    id: 'dashboard',
    icon: Icons.dashboard_rounded,
    label: l10n.tabDashboard,
    screen: const DashboardScreen(key: PageStorageKey('dashboard')),
  ));

  return tabs;
}

// ── Shell ─────────────────────────────────────────────────────────────────────

class MainNavShell extends StatefulWidget {
  final int initialIndex;
  const MainNavShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  PageController _pageController = PageController();
  int _activeIndex = 0;
  List<_TabDef> _tabs = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_activeIndex == index) return;
    setState(() => _activeIndex = index);
    // Always release the swipe lock when the user explicitly taps a tab.
    // This prevents the AI screen (or any screen that locks swipe) from
    // leaving the shell permanently frozen if its own unlock path was missed.
    context.read<SwipeLockController>().unlock();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int page) {
    if (_activeIndex != page) {
      setState(() => _activeIndex = page);
    }
  }

  // Пересчитываем список вкладок и восстанавливаем индекс.
  // PageView использует NeverScrollableScrollPhysics — позиция меняется ТОЛЬКО
  // через animateToPage/jumpToPage. Это гарантирует, что замена контроллера
  // с initialPage корректно отрабатывает без конфликтов с live-физикой.
  void _syncTabs(List<_TabDef> newTabs) {
    if (newTabs.length == _tabs.length &&
        _zip(newTabs, _tabs).every(
          (p) => p.$1.id == p.$2.id && p.$1.label == p.$2.label,
        )) {
      return; // ничего не изменилось
    }

    final activeId = _tabs.isNotEmpty && _activeIndex < _tabs.length
        ? _tabs[_activeIndex].id
        : 'chats';

    _tabs = newTabs;

    int newIndex = newTabs.indexWhere((t) => t.id == activeId);
    if (newIndex < 0) newIndex = newTabs.length - 1; // вкладка удалена → Dashboard

    if (_activeIndex != newIndex) {
      _activeIndex = newIndex;
      // Пересоздаём контроллер с правильной initialPage.
      // С NeverScrollableScrollPhysics это работает корректно: live-физики нет,
      // позиция контролируется только программно.
      _pageController.dispose();
      _pageController = PageController(initialPage: newIndex);
      // Страховка: если по какой-то причине позиция сместилась — корректируем.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_activeIndex);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final role = user?.role ?? UserRole.student;
    final visibility = context.watch<TabVisibilityController>();
    final swipeLocked = context.watch<SwipeLockController>().locked;

    final l10n = AppLocalizations.of(context)!;
    final newTabs = _buildActiveTabs(role, visibility, l10n, user);
    _syncTabs(newTabs);

    final safeIndex = _activeIndex.clamp(0, _tabs.length - 1);

    // Key включает активный индекс: при смене набора вкладок PageView
    // пересоздаётся с чистым ScrollPosition и применяет initialPage контроллера,
    // а не переносит старые пиксели из предыдущего состояния.
    final pageViewKey = ValueKey('pv_${_tabs.map((t) => t.id).join('_')}');

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _SwipeTabDetector(
              tabCount: _tabs.length,
              activeIndex: safeIndex,
              onSwipe: _onTabTapped,
              locked: swipeLocked,
              child: PageView(
                key: pageViewKey,
                controller: _pageController,
                // NeverScrollableScrollPhysics обязателен: с live-физикой (SpringPhysics)
                // при смене числа дочерних виджетов позиция сбивается, вызывая мигание.
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: _tabs.map((t) => t.screen).toList(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: cs.surface,
          selectedItemColor: const Color(0xFFE6B800),
          unselectedItemColor: cs.onSurfaceVariant,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: _tabs
              .map((t) => BottomNavigationBarItem(
                    key: ValueKey(t.id),
                    icon: Icon(t.icon),
                    label: t.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// Утилита zip для двух списков
Iterable<(A, B)> _zip<A, B>(List<A> a, List<B> b) sync* {
  final len = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) yield (a[i], b[i]);
}

// ── School gate ────────────────────────────────────────────────────────────────
// Shows a frosted lock overlay for unverified users instead of hiding the tab.

class _SchoolGate extends StatelessWidget {
  final bool isVerified;
  final Widget child;

  const _SchoolGate({super.key, required this.isVerified, required this.child});

  @override
  Widget build(BuildContext context) {
    if (isVerified) return child;

    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            color: cs.surface.withValues(alpha: 0.85),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6B800).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      size: 32, color: Color(0xFFE6B800)),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.schoolLockedTitle,
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: cs.onSurface),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    l10n.schoolLockedBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Swipe detector ─────────────────────────────────────────────────────────────
// Обрабатывает горизонтальные свайпы поверх NeverScrollableScrollPhysics PageView.
// Свайп вызывает _onTabTapped, который анимирует переход через animateToPage.

class _SwipeTabDetector extends StatefulWidget {
  final int tabCount;
  final int activeIndex;
  final ValueChanged<int> onSwipe;
  final bool locked;
  final Widget child;

  const _SwipeTabDetector({
    required this.tabCount,
    required this.activeIndex,
    required this.onSwipe,
    required this.locked,
    required this.child,
  });

  @override
  State<_SwipeTabDetector> createState() => _SwipeTabDetectorState();
}

class _SwipeTabDetectorState extends State<_SwipeTabDetector> {
  double _dragStart = 0;
  static const double _threshold      = 50.0;   // px
  static const double _velocityMin    = 300.0;  // px/s (raised — taps can hit 200)
  static const double _minDisplacement = 20.0;  // px — required to rule out tap drift

  @override
  Widget build(BuildContext context) {
    if (widget.locked) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (d) => _dragStart = d.globalPosition.dx,
      onHorizontalDragEnd: (d) {
        final dx       = d.globalPosition.dx - _dragStart;
        final velocity = d.primaryVelocity ?? 0;
        // Both a minimum displacement AND threshold/velocity are required.
        // Without _minDisplacement, quick chip taps with slight finger drift
        // can produce high velocity (>200 px/s) and falsely trigger tab switches.
        final isSwipe  = dx.abs() >= _minDisplacement &&
                         (dx.abs() > _threshold || velocity.abs() > _velocityMin);
        if (!isSwipe) return;
        final idx = widget.activeIndex;
        if ((dx < 0 || velocity < -_velocityMin) && idx < widget.tabCount - 1) {
          widget.onSwipe(idx + 1);
        } else if ((dx > 0 || velocity > _velocityMin) && idx > 0) {
          widget.onSwipe(idx - 1);
        }
      },
      child: widget.child,
    );
  }
}
