import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/services/api_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String knotyNumber;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.knotyNumber,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  bool _isLoading = false;
  bool _isResending = false;
  bool _resendDone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await ApiService().getUserData();
      if (!mounted) return;
      final user = result['user'] as Map<String, dynamic>?;
      final verified = user?['emailVerified'] == true;
      if (result['success'] == true && verified) {
        context.go('/register-success', extra: {
          'knotyNumber': widget.knotyNumber,
        });
      } else {
        _showError(AppLocalizations.of(context)!.verifyEmailNotVerified);
      }
    } catch (_) {
      if (mounted) _showError(AppLocalizations.of(context)!.verifyEmailNotVerified);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendEmail() async {
    if (_isResending) return;
    setState(() {
      _isResending = true;
      _resendDone = false;
    });
    try {
      await ApiService().resendVerification(widget.email);
      if (mounted) setState(() => _resendDone = true);
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _resendDone = false);
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    64,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // ── Icon ──────────────────────────────────────────
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Title ─────────────────────────────────────────
                    Text(
                      l10n.verifyEmailTitle,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.verifyEmailSentTo,
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.verifyEmailSpamHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),
                    const SizedBox(height: 24),

                    // ── Confirm button ─────────────────────────────────
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
                          onTap: _isLoading ? null : _checkVerification,
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    l10n.verifyEmailButton,
                                    style: TextStyle(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Resend button ──────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _resendDone
                          ? Padding(
                              key: const ValueKey('done'),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      l10n.verifyEmailResendDone,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              key: const ValueKey('resend'),
                              onTap: _isResending ? null : _resendEmail,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: _isResending
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: cs.onSurfaceVariant),
                                      )
                                    : Text(
                                        l10n.verifyEmailResend,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: cs.onSurfaceVariant,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                              ),
                            ),
                    ),

                    // ── Back to login ──────────────────────────────────
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.auth),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.verifyEmailBackToLogin,
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
