import 'package:flutter/widgets.dart';
import 'dart:async';

/// 🫀 Heartbeat Service
/// Manages periodic heartbeat requests with lifecycle awareness
class HeartbeatService with WidgetsBindingObserver {
  static final HeartbeatService _instance = HeartbeatService._internal();
  factory HeartbeatService() => _instance;
  HeartbeatService._internal();

  Timer? _heartbeatTimer;
  bool _isRunning = false;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  /// Start the heartbeat service
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
  }

  /// Stop the heartbeat service
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Pause heartbeat when app goes to background
  void _pauseHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Resume heartbeat when app comes to foreground
  void _resumeHeartbeat() {
    if (_isRunning) {
      _startHeartbeat();
    }
  }

  /// Start the periodic heartbeat timer
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      _sendHeartbeat();
    });
  }

  /// Send heartbeat request
  Future<void> _sendHeartbeat() async {
    try {
      // TODO: Implement actual heartbeat API call
      print('🫀 Heartbeat sent at ${DateTime.now()}');
    } catch (e) {
      print('❌ Heartbeat failed: $e');
    }
  }

  // WidgetsBindingObserver implementation
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _pauseHeartbeat();
        break;
      case AppLifecycleState.resumed:
        _resumeHeartbeat();
        break;
      case AppLifecycleState.detached:
        stop();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No action needed for these states
        break;
    }
  }

  /// Get current heartbeat status
  bool get isRunning => _isRunning;
  bool get isActive => _heartbeatTimer?.isActive ?? false;
}
