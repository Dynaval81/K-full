import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Lightweight connectivity checker using dart:io.
/// Pings a well-known host every 5 seconds.
/// No external packages needed.
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  Timer? _timer;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  Future<void> _check() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
