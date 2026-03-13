import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../theme_provider.dart';

class ThemeSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return SwitchListTile(
          title: Text(
            'Dark Mode',
            style: TextStyle(
              color: themeProvider.isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            'Switch between light and dark themes',
            style: TextStyle(
              color: themeProvider.isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText,
              fontSize: 12,
            ),
          ),
          value: themeProvider.isDarkMode,
          onChanged: (value) {
            themeProvider.toggleTheme();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(value ? 'Dark mode enabled' : 'Light mode enabled'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          activeColor: AppColors.primaryBlue,
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: themeProvider.isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText,
          ),
        );
      },
    );
  }
}
