import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/glass_kit.dart';

class GracePeriodBanner extends StatelessWidget {
  const GracePeriodBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;
        if (user == null) return const SizedBox.shrink();

        // ⭐ ПРОВЕРКА GRACE PERIOD
        final now = DateTime.now();
        final isGracePeriod = user.premiumExpiresAt != null &&
            now.isAfter(user.premiumExpiresAt!) &&
            now.isBefore(user.premiumExpiresAt!.add(const Duration(hours: 24)));

        if (!isGracePeriod) return const SizedBox.shrink();

        // ⭐ ВЫЧИСЛЯЕМ ОСТАВШЕЕСЯ ВРЕМЯ
        final gracePeriodEnd = user.premiumExpiresAt!.add(const Duration(hours: 24));
        final remaining = gracePeriodEnd.difference(now);
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes % 60;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // ⭐ ИКОНКА ПРЕДУПРЕЖДЕНИЯ
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              
              // ⭐ ТЕКСТ ПРЕДУПРЕЖДЕНИЯ
              Expanded(
                child: Text(
                  'Льготный период: доступ истекает через $hours ч $minutes мин',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // ⭐ КНОПКА АКТИВАЦИИ
              GestureDetector(
                onTap: () {
                  _showActivationDialog(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Активировать',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ⭐ ДИАЛОГ АКТИВАЦИИ
  void _showActivationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassKit.liquidGlass(
          radius: 20,
          isDark: Theme.of(context).brightness == Brightness.dark,
          opacity: 0.15,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.vpn_key,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Активация Premium',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Введите код активации для продления Premium доступа',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Код активации',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.orange.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Активировать',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
