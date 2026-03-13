import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../providers/user_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/main_app.dart';

void main() {
  runApp(const VtalkFullDemo());
}

class VtalkFullDemo extends StatelessWidget {
  const VtalkFullDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer2<ThemeProvider, UserProvider>(
        builder: (context, themeProvider, userProvider, child) {
          return MaterialApp(
            title: 'VTalk Full Demo',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: userProvider.user != null 
                ? MainApp(initialTab: 0)
                : const AuthScreen(),
          );
        },
      ),
    );
  }
}
