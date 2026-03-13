import 'package:intl/intl.dart';

/// Helper to format time consistently
String formatTime(DateTime time) {
  return DateFormat('HH:mm').format(time);
}
