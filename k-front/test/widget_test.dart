import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:knoty/theme_provider.dart';

void main() {
  testWidgets('ThemeProvider basic test', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();

    expect(themeProvider.isDarkMode, isNotNull);

    themeProvider.toggleTheme();

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

    expect(find.textContaining('Dark:'), findsOneWidget);
  });
}
