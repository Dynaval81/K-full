import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';

class EmptyChatPlaceholder extends StatelessWidget {
  const EmptyChatPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Center(
      child: Text(
        'Напишите первое сообщение',
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
