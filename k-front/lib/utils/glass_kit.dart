import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme_provider.dart';
import 'package:provider/provider.dart';

class GlassKit {
  static Widget liquidGlass({
    required Widget child, 
    double radius = 20, 
    double? opacity,
    bool isDark = true,
    bool useBlur = true,  // ✅ Новый параметр для контроля блюра
    BuildContext? context, // Добавляем context для доступа к ThemeProvider
  }) {
    // Получаем debug mode если есть context
    final debugMode = context?.read<ThemeProvider>().debugGlassMode ?? false;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: useBlur 
        ? BackdropFilter(
            // Если блюр включен — нагружаем GPU для красоты (шапки, меню)
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: _buildGlassContainer(child, radius, isDark, opacity, debugMode, useBlur),
          )
        : _buildGlassContainer(child, radius, isDark, opacity, debugMode, useBlur), 
          // Если выключен — просто рисуем прозрачную подложку (высокий FPS)
    );
  }

  // Выносим стиль контейнера в отдельный приватный метод для чистоты кода
  static Widget _buildGlassContainer(
    Widget child, 
    double radius, 
    bool isDark, 
    double? opacity, 
    bool debugMode, 
    bool useBlur
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(opacity ?? 0.2)
            : Colors.white.withOpacity(opacity ?? 0.2),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: debugMode 
            ? (useBlur ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5))
            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
          width: debugMode ? 2.0 : 1.0,
        ),
      ),
      child: child,
    );
  }

  static BoxDecoration mainBackground(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark 
          ? [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)]
          : [Color(0xFFE0EAFC), Color(0xFFCFDEF3)], // Светлая "ледяная" тема
      ),
    );
  }
}
