import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isDarkMode = false;
  bool _userHasSetTheme = false;
  bool _isInitialized = false;
  bool _debugGlassMode = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  bool get debugGlassMode => _debugGlassMode;

  /// Always returns an explicit mode — never ThemeMode.system,
  /// because some devices/builds ignore it on first frame.
  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Legacy getter kept for any callers that still reference currentTheme
  ThemeData get currentTheme => throw UnimplementedError(
      'Use AppTheme.lightTheme / AppTheme.darkTheme via MaterialApp instead');

  // ── WidgetsBindingObserver ────────────────────────────────────────────────

  @override
  void didChangePlatformBrightness() {
    if (_userHasSetTheme) return;
    final systemDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    if (_isDarkMode != systemDark) {
      _isDarkMode = systemDark;
      notifyListeners();
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> initializeTheme() async {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);

    final systemDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

    try {
      final prefs = await SharedPreferences.getInstance();
      // One-time migration: drop legacy saved value so app follows system theme.
      if (!(prefs.getBool('theme_init_v3') ?? false)) {
        await prefs.remove('is_dark_mode');
        await prefs.setBool('theme_init_v3', true);
      }
      final saved = prefs.getBool('is_dark_mode');
      if (saved != null) {
        _isDarkMode = saved;
        _userHasSetTheme = true;
      } else {
        _isDarkMode = systemDark;
        _userHasSetTheme = false;
      }
    } catch (_) {
      _isDarkMode = systemDark;
    }

    _isInitialized = true;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _userHasSetTheme = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _isDarkMode);
    } catch (_) {}
  }

  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    _userHasSetTheme = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _isDarkMode);
    } catch (_) {}
  }

  void toggleDebugGlassMode() {
    HapticFeedback.selectionClick();
    _debugGlassMode = !_debugGlassMode;
    notifyListeners();
  }
}
