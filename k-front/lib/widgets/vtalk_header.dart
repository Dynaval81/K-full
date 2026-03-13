import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/user_provider.dart';
import '../constants/app_constants.dart';
import 'package:provider/provider.dart';

class VtalkHeader extends StatelessWidget {
  final String title;
  final bool showScrollAnimation;
  final List<Widget>? actions;
  
  const VtalkHeader({
    required this.title,
    this.showScrollAnimation = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accentColor = const Color(0xFF00B2FF); // 🚨 Ртутный голубой

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // 🚨 Глубокий блюр
        child: Container(
          height: 100, // 🚨 Увеличили высоту для SafeArea
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.4),
            border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.2), width: 0.5)),
          ),
          padding: const EdgeInsets.only(left: 16, right: 16, top: 40), // 🚨 Отступ под челку
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🚨 ЛОГОТИП
              Image.asset(
                'assets/images/app_logo_classic.png',
                height: 32,
                fit: BoxFit.contain,
                color: isDark ? Colors.white : accentColor,
              ),
              // 🚨 НАЗВАНИЕ
              Text(
                "V-TALK",
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.w900, 
                  color: accentColor, 
                  letterSpacing: 2.0, // 🚨 Добавили воздуха буквам
                ),
              ),
              // 🚨 ЖИВАЯ АВАТАРКА
              GestureDetector(
                onTap: () {
                  // 🚨 Открываем Drawer или экран профиля
                  Scaffold.of(context).openDrawer(); 
                },
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return CircleAvatar(
                          radius: 20, 
                          backgroundColor: accentColor.withOpacity(0.1),
                          backgroundImage: NetworkImage("${AppConstants.defaultAvatarUrl}?u=me"),
                        );
                      },
                    ),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        if (!userProvider.isPremium) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent[700],
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Text(
                              "FREE", 
                              style: TextStyle(
                                fontSize: 8, 
                                color: Colors.white, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
