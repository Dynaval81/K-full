import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/locale_provider.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/presentation/atoms/airy_input_field.dart';
import 'package:knoty/core/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // Step 0 = enter login, Step 1 = enter password
  int _step = 0;

  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _loginFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  int _loginMethodIndex = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _loginError;
  String? _passwordError;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Step transition animation
  late final AnimationController _stepController;
  late final Animation<Offset> _slideOut;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideOut = Tween<Offset>(begin: Offset.zero, end: const Offset(-1, 0))
        .animate(CurvedAnimation(parent: _stepController, curve: Curves.easeInCubic));
    _slideIn = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _stepController, curve: Curves.easeOutCubic));
    _stepFade = CurvedAnimation(parent: _stepController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _loginFocus.dispose();
    _passwordFocus.dispose();
    _fadeController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  void _goToPassword() {
    final identifier = _loginController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _loginError = AppLocalizations.of(context)!.loginErrorEmpty);
      return;
    }
    // Email method: validate format inline
    if (_loginMethodIndex == 2) {
      final err = Validators.email(identifier);
      if (err != null) {
        setState(() => _loginError = err);
        return;
      }
    }
    setState(() { _loginError = null; _step = 1; });
    _stepController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 200), () {
      _passwordFocus.requestFocus();
    });
  }

  void _goBack() {
    setState(() => _step = 0);
    _stepController.reverse();
    Future.delayed(const Duration(milliseconds: 100), () {
      _loginFocus.requestFocus();
    });
  }

  Future<void> _onLogin() async {
    final identifier = _loginController.text.trim();
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _passwordError = AppLocalizations.of(context)!.loginEnterPassword);
      return;
    }
    setState(() => _passwordError = null);

    setState(() => _isLoading = true);
    try {
      final result = await context.read<AuthController>().loginWithCredentials(
        identifier: identifier,
        password: password,
      );
      if (!mounted) return;

      if (result.success) {
        context.go(AppRoutes.home);
      } else if (result.isEmailNotVerified) {
        _showError(AppLocalizations.of(context)!.loginErrorEmailVerification);
        _goBack();
      } else {
        _showError(result.error ?? AppLocalizations.of(context)!.loginErrorGeneric);
        _goBack();
      }
    } catch (e) {
      if (mounted) _showError(AppLocalizations.of(context)!.loginErrorNetwork);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _selectMethod(int index) {
    if (_loginMethodIndex == index) return;
    setState(() => _loginMethodIndex = index);
  }

  String _getLoginHint(AppLocalizations l10n) {
    switch (_loginMethodIndex) {
      case 0: return '@Benutzername';
      case 1: return 'Knoty-ID';
      case 2: return l10n.loginHintEmail;
      default: return '@Benutzername';
    }
  }

  TextInputType _getKeyboardType() {
    switch (_loginMethodIndex) {
      case 0: return TextInputType.name;
      case 1: return TextInputType.visiblePassword;
      case 2: return TextInputType.emailAddress;
      default: return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>(); // rebuild on locale change
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 50;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (_step == 1) {
            _goBack();
          }
        }
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 80 && _step == 1) {
            _goBack();
          }
        },
        child: Scaffold(
        backgroundColor: cs.surface,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // ── Language picker ───────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: _LangPickerRow(),
                        ),
                        const SizedBox(height: 24),

                        // ── Logo ──────────────────────────────────
                        Image.asset(
                          'assets/images/knoty_logo.png',
                          width: 180,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 40),

                        // ── Card ──────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [AppShadows.md],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: ClipRect(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              child: _step == 0
                                  ? _buildStepLogin(l10n)
                                  : _buildStepPassword(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Button always above keyboard ───────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(28, 0, 28,
                      MediaQuery.of(context).viewInsets.bottom > 0
                          ? MediaQuery.of(context).viewInsets.bottom + 16
                          : 16),
                  child: _ZenButton(
                    onPressed: _isLoading
                        ? () {}
                        : (_step == 0 ? _goToPassword : _onLogin),
                    backgroundColor: const Color(0xFFE6B800),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _step == 0
                                ? AppLocalizations.of(context)!.loginPrimaryButton
                                : AppLocalizations.of(context)!.loginButtonLogin,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                // ── Footer — hidden when keyboard open ─────────────
                if (!keyboardVisible)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      border: Border(
                        top: BorderSide(
                            color: cs.outline,
                            width: 1),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: GestureDetector(
                        onTap: () =>
                            context.go('/register'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 14),
                                children: [
                                  TextSpan(text: AppLocalizations.of(context)!.loginNoAccount),
                                  TextSpan(
                                    text: AppLocalizations.of(context)!.loginRegister,
                                    style: TextStyle(
                                      color: const Color(0xFFE6B800),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ), // Scaffold
      ), // GestureDetector
    );
  }

  // ── Step 0: Enter login ───────────────────────────────────────────
  Widget _buildStepLogin(AppLocalizations l10n) {
    return Column(
      key: const ValueKey('step_login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiryInputField(
          controller: _loginController,
          focusNode: _loginFocus,
          label: l10n.loginTitle,
          hint: '',
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) { if (_loginError != null) setState(() => _loginError = null); },
          onSubmitted: (_) => _goToPassword(),
          errorText: _loginError,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginIdentifierHint,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
        ),
      ],
    );
  }

  // ── Step 1: Enter password ────────────────────────────────────────
  Widget _buildStepPassword() {
    return Column(
      key: const ValueKey('step_password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Who you're logging in as
        Row(
          children: [
            GestureDetector(
              onTap: _goBack,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 14, color: AppColors.onSurface),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _loginController.text.trim(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Password field
        AiryInputField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: AppLocalizations.of(context)!.loginPasswordLabel,
          hint: AppLocalizations.of(context)!.loginPasswordHint,
          obscureText: _obscurePassword,
          keyboardType: TextInputType.visiblePassword,
          onChanged: (_) { if (_passwordError != null) setState(() => _passwordError = null); },
          onSubmitted: (_) => _onLogin(),
          errorText: _passwordError,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ],
    );
  }
}

// ── Language picker ───────────────────────────────────────────────────────────

class _LangPickerRow extends StatelessWidget {
  static const _langs = [
    ('de', '🇩🇪', 'Deutsch'),
    ('en', '🇬🇧', 'English'),
    ('ru', '🇷🇺', 'Русский'),
  ];

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final current = localeProvider.locale.languageCode;
    final currentFlag = _langs.firstWhere((e) => e.$1 == current,
        orElse: () => _langs.first).$2;

    return PopupMenuButton<String>(
      onSelected: (code) =>
          context.read<LocaleProvider>().setLocale(Locale(code)),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      itemBuilder: (_) => _langs
          .map((e) => PopupMenuItem<String>(
                value: e.$1,
                child: Row(children: [
                  Text(e.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(e.$3,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: e.$1 == current
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: e.$1 == current
                            ? const Color(0xFFE6B800)
                            : Theme.of(context).colorScheme.onSurface,
                      )),
                  if (e.$1 == current) ...[
                    const Spacer(),
                    const Icon(Icons.check_rounded,
                        size: 16, color: Color(0xFFE6B800)),
                  ],
                ]),
              ))
          .toList(),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(currentFlag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ZenButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Widget child;

  const _ZenButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = backgroundColor == Colors.white;
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: isLight
            ? Border.all(color: AppColors.onSurface.withOpacity(0.08))
            : null,
        boxShadow: [
          isLight
              ? AppShadows.sm
              : BoxShadow(
                  color: backgroundColor.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _MethodSelector extends StatelessWidget {
  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelect;

  const _MethodSelector({
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: active ? [AppShadows.sm] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w600 : FontWeight.w400,
                    color: active
                        ? const Color(0xFFE6B800)
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ZenDivider extends StatelessWidget {
  final String label;
  const _ZenDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.onSurface.withOpacity(0.06))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label,
              style: TextStyle(
                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 12)),
        ),
        Expanded(child: Divider(color: AppColors.onSurface.withOpacity(0.06))),
      ],
    );
  }
}