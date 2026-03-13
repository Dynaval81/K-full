import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabVisibilityController extends ChangeNotifier {
  bool _showChatsTab      = true;
  bool _showAiTab         = true;
  bool _showScheduleTab   = true;
  bool _showKindTab       = true; // parent only
  bool _showClassesTab    = true; // teacher only
  bool _showVerwaltungTab = true; // schoolAdmin / superAdmin
  bool _hasChanged        = false;

  bool get showChatsTab      => _showChatsTab;
  bool get showAiTab         => _showAiTab;
  bool get showScheduleTab   => _showScheduleTab;
  bool get showKindTab       => _showKindTab;
  bool get showClassesTab    => _showClassesTab;
  bool get showVerwaltungTab => _showVerwaltungTab;
  bool get hasChanged        => _hasChanged;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _showChatsTab      = prefs.getBool('tab_show_chats')      ?? true;
    _showAiTab         = prefs.getBool('tab_show_ai')         ?? true;
    _showScheduleTab   = prefs.getBool('tab_show_school')     ?? true;
    _showKindTab       = prefs.getBool('tab_show_kind')       ?? true;
    _showClassesTab    = prefs.getBool('tab_show_classes')    ?? true;
    _showVerwaltungTab = prefs.getBool('tab_show_verwaltung') ?? true;
    notifyListeners();
  }

  void setChatsTab(bool v)      => _set('tab_show_chats',      v, () => _showChatsTab = v);
  void setAiTab(bool v)         => _set('tab_show_ai',         v, () => _showAiTab = v);
  void setScheduleTab(bool v)   => _set('tab_show_school',     v, () => _showScheduleTab = v);
  void setKindTab(bool v)       => _set('tab_show_kind',       v, () => _showKindTab = v);
  void setClassesTab(bool v)    => _set('tab_show_classes',    v, () => _showClassesTab = v);
  void setVerwaltungTab(bool v) => _set('tab_show_verwaltung', v, () => _showVerwaltungTab = v);

  // Legacy aliases
  void setShowAiTab(bool v)       => setAiTab(v);
  void setShowChatsTab(bool v)    => setChatsTab(v);
  void setShowScheduleTab(bool v) => setScheduleTab(v);

  void _set(String key, bool v, VoidCallback apply) {
    apply();
    _hasChanged = true;
    notifyListeners();
    unawaited(_persist(key, v)); // intentional fire-and-forget
  }

  Future<void> _persist(String key, bool v) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, v);
    } catch (e) {
      debugPrint('[TabVisibility] persist error: $e');
    }
  }

  void resetChangedFlag() => _hasChanged = false;
}