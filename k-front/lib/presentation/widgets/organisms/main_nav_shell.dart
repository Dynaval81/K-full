// v1.2.0
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/controllers/tab_visibility_controller.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/presentation/screens/ai/ai_assistant_screen.dart';
import 'package:knoty/presentation/screens/chats_screen.dart';
import 'package:knoty/presentation/screens/school/school_screen.dart';
import 'package:knoty/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:knoty/presentation/screens/parent/parent_control_screen.dart';
import 'package:knoty/presentation/screens/teacher/my_classes_screen.dart';
import 'package:knoty/presentation/screens/admin/verwaltung_screen.dart';

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
) {
  final tabs = <_TabDef>[];

  if (visibility.showChatsTab)
    tabs.add(_TabDef(
      id: 'chats',
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Chats',
      screen: const ChatsScreen(key: PageStorageKey('chats')),
    ));

  if (visibility.showAiTab)
    tabs.add(_TabDef(
      id: 'ai',
      icon: Icons.psychology_rounded,
      label: 'KI',
      screen: const AiAssistantScreen(key: PageStorageKey('ai')),
    ));

  if (visibility.showScheduleTab)
    tabs.add(_TabDef(
      id: 'school',
      icon: Icons.school_rounded,
      label: 'Schule',
      screen: const SchoolScreen(key: PageStorageKey('school')),
    ));

  if (role.hasChildTab && visibility.showKindTab)
    tabs.add(_TabDef(
      id: 'kind',
      icon: Icons.child_care_rounded,
      label: 'Kind',
      screen: const ParentControlScreen(key: PageStorageKey('kind')),
    ));

  if (role.hasMyClassesTab && visibility.showClassesTab)
    tabs.add(_TabDef(
      id: 'classes',
      icon: Icons.class_rounded,
      label: 'Klassen',
      screen: const MyClassesScreen(key: PageStorageKey('classes')),
    ));

  if (role.hasManagementTab && visibility.showVerwaltungTab)
    tabs.add(_TabDef(
      id: 'verwaltung',
      icon: Icons.admin_panel_settings_rounded,
      label: 'Verwaltung',
      screen: const VerwaltungScreen(key: PageStorageKey('verwaltung')),
    ));

  // Dashboard — всегда последним
  tabs.add(_TabDef(
    id: 'dashboard',
    icon: Icons.dashboard_rounded,
    label: 'Dashboard',
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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int page) {
    if (_activeIndex != page) {
      setState(() => _activeIndex = page);
    }
  }

  // Пересчитываем список вкладок и восстанавливаем индекс
  void _syncTabs(List<_TabDef> newTabs) {
    if (newTabs.length == _tabs.length &&
        _zip(newTabs, _tabs).every((p) => p.$1.id == p.$2.id)) {
      return; // Ничего не изменилось
    }

    final activeId =
        _tabs.isNotEmpty && _activeIndex < _tabs.length
            ? _tabs[_activeIndex].id
            : 'chats';

    _tabs = newTabs;

    // Найти тот же экран в новом списке
    int newIndex = newTabs.indexWhere((t) => t.id == activeId);
    if (newIndex < 0) newIndex = newTabs.length - 1; // dashboard

    if (_activeIndex != newIndex) {
      _activeIndex = newIndex;
      // PageController пересоздаём с новой initialPage
      _pageController.dispose();
      _pageController = PageController(initialPage: newIndex);
    } else {
      _tabs = newTabs;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final role = user?.role ?? UserRole.student;
    final visibility = context.watch<TabVisibilityController>();

    final newTabs = _buildActiveTabs(role, visibility);
    _syncTabs(newTabs);

    final safeIndex = _activeIndex.clamp(0, _tabs.length - 1);

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const _SpringPagePhysics(),
        onPageChanged: _onPageChanged,
        children: _tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.12)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFE6B800),
          unselectedItemColor: Colors.grey,
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

// ── Telegram-style page physics: low friction, snappy, spring feel ─────────────
class _SpringPagePhysics extends PageScrollPhysics {
  const _SpringPagePhysics() : super(parent: const BouncingScrollPhysics());

  @override
  _SpringPagePhysics applyTo(ScrollPhysics? ancestor) =>
      const _SpringPagePhysics();

  /// Lower the minimum fling velocity so even a gentle flick switches pages.
  @override
  double get minFlingVelocity => 100.0; // default is 365 — much lower = snappier

  /// Tighter spring so the page follows the finger closely, snaps fast.
  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.5,
    stiffness: 150.0,
    damping: 20.0,
  );
}