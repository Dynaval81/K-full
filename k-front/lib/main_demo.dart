// Demo file stub - not used in production
void main() {}

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Генератор VT-ID
  String generateVTID() {
    final random = Random();
    int number = random.nextInt(90000) + 10000;
    return "VT-$number";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ФОНОВОЕ ИЗОБРАЖЕНИЕ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF252541),
                    const Color(0xFF2D2D44),
                  ]
                  : [
                    const Color(0xFF6A11CB),
                    const Color(0xFF2575FC),
                    const Color(0xFF3B82F6),
                  ],
              ),
            ),
          ),
          
          // ОСНОВНОЕ СОДЕРЖИМОЕ
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ПУЛЬСИРУЮЩАЯ СФЕРА
                    ScaleTransition(
                      scale: _animation,
                      child: Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: isDark 
                            ? [
                                BoxShadow(
                                  color: Colors.purpleAccent.withOpacity(0.4),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.08),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.sphere,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // ЗАГОЛОВОК - СЛОГАН
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14, 
                          letterSpacing: 2, 
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black54
                        ),
                        children: [
                          TextSpan(text: "VPN "),
                          TextSpan(text: "• ", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.normal)),
                          TextSpan(text: "CHAT "),
                          TextSpan(text: "• ", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.normal)),
                          TextSpan(text: "AI"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),

                    // ПОЛЯ ВВОДА (Стеклянные)
                    _isLogin ? _buildLoginFields(isDark) : _buildRegisterFields(isDark),
                    
                    const SizedBox(height: 40),

                    // КНОПКА ВХОДА ИЛИ ЗАГРУЗКА
                    _isLoading 
                        ? _buildLoadingIndicator(isDark)
                        : _buildMercuryButton(_isLogin ? "START SESSION" : "GENERATE IDENTITY"),
                    
                    const SizedBox(height: 30),
                    
                    // ПЕРЕКЛЮЧАТЕЛЬ ВХОД/РЕГИСТРАЦИЯ
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 1,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          children: [
                            TextSpan(text: _isLogin ? "New here? " : "Already have account? "),
                            TextSpan(
                              text: _isLogin ? "Create Identity" : "Sign In",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Виджет полей регистрации
  Widget _buildRegisterFields(bool isDark) {
    return Column(
      children: [
        _buildAuthField(
          icon: Icons.face_rounded, 
          hint: "Username / Nickname", 
          isDark: isDark,
          controller: _usernameController,
        ),
        const SizedBox(height: 16),
        _buildAuthField(
          icon: Icons.alternate_email_rounded, 
          hint: "Email Address", 
          isDark: isDark,
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        _buildAuthField(
          icon: Icons.lock_outline_rounded, 
          hint: "Create Access Key", 
          isDark: isDark, 
          isPassword: true,
          controller: _passwordController,
        ),
        const SizedBox(height: 16),
        _buildAuthField(
          icon: Icons.verified_user_outlined, 
          hint: "Confirm Access Key", 
          isDark: isDark, 
          isPassword: true,
          controller: _confirmPasswordController,
        ),
      ],
    );
  }

  // Виджет полей входа
  Widget _buildLoginFields(bool isDark) {
    return Column(
      children: [
        _buildAuthField(
          icon: Icons.alternate_email_rounded, 
          hint: "Email / Identifier", 
          isDark: isDark,
          controller: _emailController,
        ),
        const SizedBox(height: 16),
        _buildAuthField(
          icon: Icons.lock_outline_rounded, 
          hint: "Access Key", 
          isDark: isDark, 
          isPassword: true,
          controller: _passwordController,
        ),
      ],
    );
  }

  // Вспомогательный виджет для стеклянных полей
  Widget _buildAuthField({
    required IconData icon, 
    required String hint, 
    required bool isDark, 
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black54),
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // Кнопка в стиле Mercury
  Widget _buildMercuryButton(String text) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () async {
            setState(() => _isLoading = true);
            
            // Имитация задержки
            await Future.delayed(const Duration(seconds: 2));
            
            if (mounted) {
              final vtId = generateVTID();
              _showSuccessDialog(vtId);
            }
            
            setState(() => _isLoading = false);
          },
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Индикатор загрузки
  Widget _buildLoadingIndicator(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: const Center(
        child: SizedBox(
          width:24,
          height:24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        ),
      ),
    );
  }

  // Показать успешную регистрацию
  void _showSuccessDialog(String vtId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Зеленая галочка
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              // Заголовок
              const Text(
                'IDENTITY CREATED',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              
              // Текст
              Text(
                'Your unique VTalk identifier:',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              
              // VT-ID
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vtId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        // TODO: Добавить копирование в буфер
                      },
                      icon: const Icon(Icons.copy, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Кнопка
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Закрываем диалог
                    Navigator.pushReplacement(
                      context, 
                      PageRouteBuilder(
                        pageBuilder: (context, anim1, anim2) => MainApp(initialTab: 0),
                        transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
                        transitionDuration: const Duration(milliseconds: 800),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'FINALIZE SETUP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
