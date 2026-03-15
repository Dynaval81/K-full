import 'package:flutter/foundation.dart';

/// Allows child screens to temporarily disable PageView horizontal swipe.
/// Used by [AiAssistantScreen] when navigating into sub-views.
class SwipeLockController extends ChangeNotifier {
  bool _locked = false;
  bool get locked => _locked;

  void lock() {
    if (!_locked) {
      _locked = true;
      notifyListeners();
    }
  }

  void unlock() {
    if (_locked) {
      _locked = false;
      notifyListeners();
    }
  }
}
