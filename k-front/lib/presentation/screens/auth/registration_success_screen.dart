import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/l10n/app_localizations.dart';

class RegistrationSuccessScreen extends StatefulWidget {
  final String nickname;
  final String knotyNumber;

  const RegistrationSuccessScreen({
    super.key,
    required this.nickname,
    required this.knotyNumber,
  });

  @override
  State<RegistrationSuccessScreen> createState() =>
      _RegistrationSuccessScreenState();
}

class _RegistrationSuccessScreenState extends State<RegistrationSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyNumber() async {
    await Clipboard.setData(ClipboardData(text: widget.knotyNumber));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Check icon ────────────────────────────────────
                  ScaleTransition(
                    scale: _scaleIn,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.green,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Title ─────────────────────────────────────────
                  Text(
                    l10n.registerSuccessWelcome,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '@${widget.nickname}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Knoty ID card ─────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [AppShadows.md],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          l10n.registerSuccessKnotyIdLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _copyNumber,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: _copied
                                  ? Colors.green.withOpacity(0.08)
                                  : cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _copied
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'KN-',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: AppColors.onSurfaceVariant
                                        .withOpacity(0.5),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                                Text(
                                  widget.knotyNumber.replaceFirst('KN-', '').replaceFirst('kn-', ''),
                                    style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: _copied
                                        ? Colors.green
                                        : AppColors.onSurface,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  _copied
                                      ? Icons.check_rounded
                                      : Icons.copy_rounded,
                                  color: _copied
                                      ? Colors.green
                                      : AppColors.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.registerSuccessRememberHint,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Continue button ───────────────────────────────
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.go(AppRoutes.home),
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Text(
                            l10n.registerSuccessButton,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
    );
  }
}