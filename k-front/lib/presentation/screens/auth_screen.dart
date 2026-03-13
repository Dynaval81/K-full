import 'package:flutter/material.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/presentation/widgets/airy_input_field.dart';
import 'package:knoty/presentation/widgets/airy_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

/// 🔐 HAI3 Authentication Screen
/// Airy design with generous spacing and bright blue accent
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

enum AuthStep { email, login, register }

enum LoginType { email, username, vtId }

class _AuthScreenState extends State<AuthScreen> {
  AuthStep _currentStep = AuthStep.email;
  LoginType _loginType = LoginType.email;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  static const List<String> _existingEmails = ['user@example.com', 'test@test.com'];

  bool _checkEmail(String email) {
    return _existingEmails.contains(email.trim().toLowerCase());
  }

  String? _getPrefixText() {
    switch (_loginType) {
      case LoginType.vtId:
        return 'VT ';
      case LoginType.username:
        return '@';
      default:
        return null;
    }
  }

  TextInputType _getKeyboardType() {
    switch (_loginType) {
      case LoginType.vtId:
        return TextInputType.number;
      default:
        return TextInputType.emailAddress;
    }
  }

  bool _validateInput() {
    final input = _emailController.text.trim();
    switch (_loginType) {
      case LoginType.email:
        return input.contains('@') && RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(input);
      case LoginType.vtId:
        return RegExp(r'^\d{5,}$').hasMatch(input);
      case LoginType.username:
        return input.length >= 3;
    }
  }

  void _onEmailSubmitted() {
    if (!_validateInput()) return;
    setState(() => _currentStep = AuthStep.login);
  }

  void _onBackToEmail() {
    setState(() {
      _currentStep = AuthStep.email;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _usernameController.clear();
    });
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate login
    setState(() => _isLoading = false);
    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
    }
    if (mounted) context.go('/chats');
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate register
    setState(() => _isLoading = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    if (mounted) context.go('/chats');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              // 🎯 Logo and title
              _buildHeader(),
              
              SizedBox(height: AppSpacing.buttonPadding * 3),
              
              //  Form content
              Expanded(
                child: _currentStep == AuthStep.email
                  ? _buildEmailForm()
                  : _currentStep == AuthStep.login
                    ? _buildLoginForm()
                    : _buildRegisterForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Build header with logo and title
  Widget _buildHeader() {
    return Column(
      children: [
        // 🎯 Logo
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00A3FF), Color(0xFF0066FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppBorderRadius.input),
            boxShadow: [AppShadows.md],
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
            size: 30,
          ),
        ),
        
        SizedBox(height: AppSpacing.inputPadding),
        
        // 📝 App name
        Text(
          AppConstants.appName,
          style: AppTextStyles.h3.copyWith(
            color: Color(0xFF121212),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        
        SizedBox(height: AppSpacing.inputPadding / 2),
        
        // 📝 Tagline
        Text(
          'Secure messaging redefined',
          style: AppTextStyles.body.copyWith(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// 📧 Build email form
  Widget _buildEmailForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Login type selector with custom toggle
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _buildLoginTypeButton(LoginType.email, 'Email', Icons.email_outlined),
                _buildLoginTypeButton(LoginType.username, 'Nickname', Icons.person_outline),
                _buildLoginTypeButton(LoginType.vtId, 'VT-ID', Icons.vpn_key_outlined),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.inputPadding),
          AiryInputField(
            controller: _emailController,
            hintText: _loginType == LoginType.email ? 'Email' : _loginType == LoginType.username ? 'Nickname' : 'VT-ID',
            keyboardType: _getKeyboardType(),
            prefixText: _getPrefixText(),
          ),
          SizedBox(height: AppSpacing.buttonPadding),
          AiryButton(
            text: 'Start',
            onPressed: _onEmailSubmitted,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTypeButton(LoginType type, String label, IconData icon) {
    final isSelected = _loginType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _loginType = type;
            _emailController.clear();
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔐 Build login form
  Widget _buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _onBackToEmail,
              ),
              Spacer(),
            ],
          ),
          // 📧 Email field
          AiryInputField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            enabled: false,
          ),
          
          SizedBox(height: AppSpacing.inputPadding),
          
          // 🔒 Password field
          AiryInputField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: !_isPasswordVisible,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Color(0xFF757575),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          
          SizedBox(height: AppSpacing.inputPadding / 2),
          
          // 📝 Remember me checkbox
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              Text(
                'Remember me',
                style: AppTextStyles.body.copyWith(
                  color: Color(0xFF757575),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                },
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.body.copyWith(
                    color: Color(0xFF00A3FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.buttonPadding),
          
          // 🔐 Login button
          AiryButton(
            text: 'Sign In',
            onPressed: _login,
            isLoading: _isLoading,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  /// � Build register form
  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _onBackToEmail,
              ),
              Spacer(),
            ],
          ),
          // � Username field
          AiryInputField(
            controller: _usernameController,
            label: 'Username',
            hint: 'Choose a username',
            prefixIcon: Icons.person_outline,
          ),
          
          SizedBox(height: AppSpacing.inputPadding),
          
          // � Email field
          AiryInputField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            enabled: false,
          ),
          
          SizedBox(height: AppSpacing.inputPadding),
          
          // 🔒 Password field
          AiryInputField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a password',
            obscureText: !_isPasswordVisible,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Color(0xFF757575),
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          
          SizedBox(height: AppSpacing.inputPadding),
          
          // � Confirm password field
          AiryInputField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
            obscureText: !_isConfirmPasswordVisible,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                color: Color(0xFF757575),
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          
          SizedBox(height: AppSpacing.buttonPadding),
          
          // � Register button
          AiryButton(
            text: 'Sign Up',
            onPressed: _register,
            isLoading: _isLoading,
            fullWidth: true,
          ),
  /// 📝 Build register form
  Widget _buildRegisterForm() {
    return Column(
      children: [
        // 👤 Username field
        AiryInputField(
          controller: _usernameController,
          label: 'Username',
          hint: 'Choose a username',
          prefixIcon: Icons.person_outline,
        ),
        
        SizedBox(height: AppSpacing.inputPadding),
        
        // 📧 Email field
        AiryInputField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
        ),
        
        SizedBox(height: AppSpacing.inputPadding),
        
        // 🔒 Password field
        AiryInputField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Create a password',
          obscureText: !_isPasswordVisible,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFF757575),
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
        
        SizedBox(height: AppSpacing.inputPadding),
        
        // 🔒 Confirm password field
        AiryInputField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Confirm your password',
          obscureText: !_isConfirmPasswordVisible,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Color(0xFF757575),
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
        ),
        
        SizedBox(height: AppSpacing.buttonPadding),
        
        // 📝 Register button
        AiryButton(
          text: 'Create Account',
          onPressed: _handleRegister,
          isLoading: _isLoading,
          fullWidth: true,
        ),
      ],
    );
  }

  /// 🔐 Handle login
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement login logic
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // TODO: Navigate to main app
        // context.go('/');
      }
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 📝 Handle registration
  void _handleRegister() async {
    if (_usernameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement registration logic
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        _showSuccess('Account created successfully!');
        // Switch to login tab
        _tabController.animateTo(0);
      }
    } catch (e) {
      _showError('Registration failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 🚨 Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
        ),
      ),
    );
  }

  /// ✅ Show success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF30D158),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
        ),
      ),
    );
  }
}
