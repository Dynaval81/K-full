import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

/// Widget that shows child with visual premium hints instead of hard blocking
class PremiumGuard extends StatefulWidget {
  final Widget child;

  const PremiumGuard({Key? key, required this.child}) : super(key: key);

  @override
  _PremiumGuardState createState() => _PremiumGuardState();
}

class _PremiumGuardState extends State<PremiumGuard> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showUpgradeDialog = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate(UserProvider userProvider) async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Please enter a code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ApiService().activatePremium(code);
    setState(() => _loading = false);
    if (result['success'] == true) {
      userProvider.activatePremium(code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Activated')),
      );
      setState(() => _showUpgradeDialog = false);
    } else {
      setState(() => _error = result['error'] ?? 'Activation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isPremium = userProvider.isPremium;
        
        return Stack(
          children: [
            // 🚨 НОВОЕ: Всегда показываем child (без жесткого блока)
            widget.child,
            
            // 🚨 НОВОЕ: Визуальная подсказка если не premium
            if (!isPremium)
              Positioned(
                top: 60,
                right: 16,
                child: GestureDetector(
                  onTap: () => setState(() => _showUpgradeDialog = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'FREE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // 🚨 НОВОЕ: Диалог апгрейда вместо блокировки
            if (_showUpgradeDialog)
              Dialog(
                backgroundColor: isDark ? Colors.grey[900] : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock Premium Features',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get unlimited access to all features',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _codeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Activation Code',
                          errorText: _error,
                          filled: true,
                          fillColor: isDark ? Colors.white12 : Colors.black12,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => setState(() => _showUpgradeDialog = false),
                              child: Text('Maybe Later'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _loading ? null : () => _activate(userProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Activate'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
