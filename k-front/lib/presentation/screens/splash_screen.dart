import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideUp = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _navigate();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    final bool isAuthenticated =
        context.read<AuthController>().isAuthenticated;
    context.go(isAuthenticated ? AppRoutes.home : AppRoutes.auth);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Logo center
          Center(
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (context, child) => FadeTransition(
                opacity: _fadeIn,
                child: Transform.translate(
                  offset: Offset(0, _slideUp.value),
                  child: child,
                ),
              ),
              child: ScaleTransition(
                scale: _breathScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/knoty_logo.png',
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.splashTagline,
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 0.3,
                        color: Color(0xFF6B6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // HAI3 badge + label at bottom
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/hai_3_dark.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.splashHai3Label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.4,
                      color: Color(0xFFAAAAAA),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}