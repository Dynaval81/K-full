import 'package:flutter/material.dart';
import '../utils/glass_kit.dart';
import '../theme_provider.dart';
import 'package:provider/provider.dart';

class VTalkFloatingDateHeader extends StatelessWidget {
  final DateTime date;
  final bool isVisible;
  final String? formattedDate;

  const VTalkFloatingDateHeader({
    Key? key,
    required this.date,
    this.isVisible = true,
    this.formattedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final displayDate = formattedDate ?? _formatDate(date);
    
    return Positioned(
      top: 60, // Позиция под шапкой
      left: 0,
      right: 0,
      child: Center(
        child: GlassKit.liquidGlass(
          radius: 12,
          isDark: isDark,
          opacity: 0.2,
          useBlur: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              displayDate,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Сегодня';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    } else if (now.year == date.year) {
      return '${date.day} ${_getMonthName(date.month)}';
    } else {
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return months[month - 1];
  }
}
