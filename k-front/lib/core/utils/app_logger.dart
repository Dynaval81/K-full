import 'package:flutter/foundation.dart';

/// Глобальный буфер логов — хранит последние [maxLines] строк.
/// Используется для прикладывания логов к bug report.
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const int maxLines = 150;
  final List<String> _buffer = [];

  /// Инициализация — перехватывает debugPrint и Flutter ошибки.
  void init() {
    // Перехватываем debugPrint
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        _write(message);
      }
      // Оригинальный вывод в консоль
      debugPrintSynchronously(message ?? '', wrapWidth: wrapWidth);
    };

    // Перехватываем Flutter framework ошибки
    FlutterError.onError = (FlutterErrorDetails details) {
      _write('[FLUTTER_ERROR] ${details.exceptionAsString()}');
      _write('[FLUTTER_ERROR_STACK] ${details.stack?.toString().split('\n').take(5).join(' | ')}');
      FlutterError.presentError(details);
    };
  }

  void _write(String line) {
    final timestamp = _timestamp();
    _buffer.add('$timestamp $line');
    if (_buffer.length > maxLines) {
      _buffer.removeAt(0);
    }
  }

  /// Возвращает последние логи как строку для отправки.
  String getLogs() => _buffer.join('\n');

  /// Очищает буфер.
  void clear() => _buffer.clear();

  String _timestamp() {
    final now = DateTime.now();
    return '[${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}]';
  }
}
