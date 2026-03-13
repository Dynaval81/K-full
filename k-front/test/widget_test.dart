import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vtalk_app/theme_provider.dart';

void main() {
  testWidgets('ThemeProvider basic test', (WidgetTester tester) async {
    // Create ThemeProvider instance
    final themeProvider = ThemeProvider();
    
    // Test initial state
    expect(themeProvider.isDarkMode, true);
    
    // Test theme toggle
    themeProvider.toggleTheme();
    expect(themeProvider.isDarkMode, false);
    
    // Test simple widget
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: MaterialApp(
          home: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                body: Text('Dark: ${provider.isDarkMode}'),
              );
            },
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Dark: false'), findsOneWidget);
  });
}
