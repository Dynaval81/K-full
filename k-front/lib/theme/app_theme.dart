import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      cardColor: AppColors.cardBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText),
        titleTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardBackground,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.primaryText),
        bodyMedium: TextStyle(color: AppColors.primaryText),
        displayLarge: TextStyle(color: AppColors.primaryText),
        displayMedium: TextStyle(color: AppColors.primaryText),
        headlineLarge: TextStyle(color: AppColors.primaryText),
        headlineMedium: TextStyle(color: AppColors.primaryText),
        titleLarge: TextStyle(color: AppColors.primaryText),
        titleMedium: TextStyle(color: AppColors.primaryText),
      ),
      iconTheme: IconThemeData(color: AppColors.primaryText),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: AppColors.lightPrimaryBackground,
      cardColor: AppColors.lightCardBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightCardBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.lightPrimaryText),
        titleTextStyle: TextStyle(
          color: AppColors.lightPrimaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCardBackground,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.lightSecondaryText,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightPrimaryText),
        bodyMedium: TextStyle(color: AppColors.lightPrimaryText),
        displayLarge: TextStyle(color: AppColors.lightPrimaryText),
        displayMedium: TextStyle(color: AppColors.lightPrimaryText),
        headlineLarge: TextStyle(color: AppColors.lightPrimaryText),
        headlineMedium: TextStyle(color: AppColors.lightPrimaryText),
        titleLarge: TextStyle(color: AppColors.lightPrimaryText),
        titleMedium: TextStyle(color: AppColors.lightPrimaryText),
      ),
      iconTheme: IconThemeData(color: AppColors.lightPrimaryText),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
