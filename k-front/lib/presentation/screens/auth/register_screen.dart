import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/l10n/app_localizations.dart';
import 'package:knoty/services/api_service.dart';
import 'package:knoty/presentation/atoms/airy_input_field.dart';
import 'package:knoty/constants/app_colors.dart';

// Роль выбирается на шаге 0, данные вводятся на шаге 1
enum _RegRole { student, parent, teacher }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ── Шаги ─────────────────────────────────────────────────────────────────
  int _step = 0; // 0 = выбор роли, 1 = форма
  _RegRole _selectedRole = _RegRole.student;

  // ── Контроллеры ───────────────────────────────────────────────────────────
  final _usernameCtrl        = TextEditingController();
  final _firstNameCtrl       = TextEditingController();
  final _lastNameCtrl        = TextEditingController();
  final _emailCtrl           = TextEditingController();
  bool _usernameTouched = false; // true = пользователь вручную изменил ник

  // Генерирует ник из email: max.mustermann@... → max.mustermann
  void _suggestUsernameFromEmail(String email) {
    if (_usernameTouched) return;
    final local = email.split('@').first;
    if (local.length >= 3) {
      _usernameCtrl.text = local.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');
    }
  }
  final _passwordCtrl        = TextEditingController();
  final _schoolSearchCtrl    = TextEditingController();
  final _knChildCtrl         = TextEditingController(); // родитель: KN ребёнка
  final _subjectCtrl         = TextEditingController(); // учитель: предмет
  final _schoolCodeCtrl      = TextEditingController(); // код SCH-XXXX

  bool _isLoading        = false;
  bool _obscurePassword  = true;
  bool _hasSchoolCode    = false;

  // ── Школа (autocomplete) ──────────────────────────────────────────────────
  String? _selectedSchool;
  String? _selectedClass;
  List<String> _filteredSchools = [];
  List<String> _schoolClasses   = [];
  bool _showSchoolDropdown      = false;
  Timer? _debounce;

  // Demo — придёт с бэкенда
  static const _allSchools = [
    'Goethe-Gymnasium München',
    'Schiller-Realschule Berlin',
    'Humboldt-Gesamtschule Hamburg',
    'Einstein-Gymnasium Frankfurt',
    'Kant-Gymnasium Köln',
  ];
  static const _classMap = {
    'Goethe-Gymnasium München':     ['5a','5b','6a','6b','7a','7b','8a','8b','9a','9b','10a','10b','11','12'],
    'Schiller-Realschule Berlin':   ['5a','5b','6a','6b','7a','7b','8a','8b','9a','9b','10a','10b'],
    'Humboldt-Gesamtschule Hamburg':['5a','5b','5c','6a','6b','7a','7b','8a','9a','10a','11','12','13'],
    'Einstein-Gymnasium Frankfurt': ['5a','5b','6a','7a','8a','9a','10a','11','12'],
    'Kant-Gymnasium Köln':          ['5a','6a','7a','8a','9a','10a','11','12'],
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();   _lastNameCtrl.dispose();
    _emailCtrl.dispose();        _passwordCtrl.dispose();
    _schoolSearchCtrl.dispose(); _knChildCtrl.dispose();
    _subjectCtrl.dispose();      _schoolCodeCtrl.dispose();
    super.dispose();
  }

  // ── School search with debounce ───────────────────────────────────────────
  void _onSchoolSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _filteredSchools = query.length < 2 ? [] : _allSchools
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();
        _showSchoolDropdown = _filteredSchools.isNotEmpty;
      });
    });
  }

  void _selectSchool(String school) {
    setState(() {
      _selectedSchool       = school;
      _selectedClass        = null;
      _schoolClasses        = List<String>.from(_classMap[school] ?? []);
      _schoolSearchCtrl.text = school;
      _showSchoolDropdown   = false;
      _filteredSchools      = [];
    });
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;

    if (_usernameCtrl.text.trim().length < 5) { _err('Benutzername mind. 5 Zeichen'); return; }
    if (!RegExp(r'^[a-zA-Z0-9._]+\$').hasMatch(_usernameCtrl.text.trim())) { _err('Nur Buchstaben, Zahlen, . und _'); return; }
    if (_firstNameCtrl.text.trim().isEmpty) { _err('Bitte Vornamen eingeben'); return; }
    if (_lastNameCtrl.text.trim().isEmpty)  { _err('Bitte Nachnamen eingeben'); return; }
    if (_emailCtrl.text.trim().isEmpty)     { _err(l10n.loginErrorEmpty); return; }
    if (_passwordCtrl.text.length < AppConstants.minPasswordLength) {
      _err(l10n.registerPasswordHint); return;
    }

    // Role-specific validation
    switch (_selectedRole) {
      case _RegRole.student:
        if (!_hasSchoolCode && _selectedSchool == null) {
          _err('Bitte Schule auswählen'); return;
        }
        if (_hasSchoolCode && _schoolCodeCtrl.text.trim().isEmpty) {
          _err('Bitte Schulcode eingeben'); return;
        }
      case _RegRole.parent:
        if (_knChildCtrl.text.trim().isEmpty) {
          _err('Bitte KN-Nummer des Kindes eingeben'); return;
        }
      case _RegRole.teacher:
        if (!_hasSchoolCode && _selectedSchool == null) {
          _err('Bitte Schule auswählen'); return;
        }
        if (_hasSchoolCode && _schoolCodeCtrl.text.trim().isEmpty) {
          _err('Bitte Schulcode eingeben'); return;
        }
    }

    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final result = await api.register(
        email:        _emailCtrl.text.trim(),
        password:     _passwordCtrl.text,
        username:     _usernameCtrl.text.trim(),
        firstName:    _firstNameCtrl.text.trim(),
        lastName:     _lastNameCtrl.text.trim(),
        role:         _selectedRole.name, // 'student' | 'parent' | 'teacher'
        schoolCode:   _schoolCodeCtrl.text.trim().isNotEmpty
                          ? _schoolCodeCtrl.text.trim() : null,
        linkedChildKn: _selectedRole == _RegRole.parent
                          ? _knChildCtrl.text.trim() : null,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        final knotyNumber = result['user']?['knotyNumber']?.toString()
            ?? result['user']?['vtNumber']?.toString() ?? '';
        context.go('/verify-email', extra: {
          'email':       _emailCtrl.text.trim(),
          'nickname':    _usernameCtrl.text.trim(),
          'knotyNumber': knotyNumber,
        });
      } else {
        _err(result['error']?.toString() ?? l10n.errorUnknown);
      }
    } on SocketException {
      if (mounted) _err('Keine Internetverbindung');
    } catch (e) {
      if (mounted) _err(l10n.errorUnknown);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: ThemeData.light().copyWith(scaffoldBackgroundColor: Colors.white),
      child: GestureDetector(
        // Свайп вправо: на шаге 1 → шаг 0, на шаге 0 → назад (логин)
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 300) {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              context.go(AppRoutes.auth);
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            bottom: false,
            child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Header
                      Row(children: [
                        if (_step == 1)
                          GestureDetector(
                            onTap: () => setState(() => _step = 0),
                            child: Container(
                              width: 36, height: 36,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 16, color: Color(0xFF1A1A1A)),
                            ),
                          ),
                        Image.asset('assets/images/knoty_logo_nt.png',
                            width: 36, height: 36, fit: BoxFit.contain),
                        const SizedBox(width: 12),
                        Text(
                          _step == 0 ? 'Wer bist du?' : l10n.registerTitle,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(
                        _step == 0
                            ? 'Wähle deine Rolle, um fortzufahren'
                            : _roleSubtitle(_selectedRole),
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF9E9E9E)),
                      ),
                      const SizedBox(height: 24),

                      // Step 0: Role selection
                      if (_step == 0) ...[
                        _RoleSelector(
                          selected: _selectedRole,
                          onChanged: (r) {
                            setState(() => _selectedRole = r);
                            // Сбрасываем поля предыдущей роли
                            _schoolSearchCtrl.clear();
                            _knChildCtrl.clear();
                            _subjectCtrl.clear();
                            _schoolCodeCtrl.clear();
                            _selectedSchool = null;
                            _hasSchoolCode = false;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => setState(() => _step = 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE6B800),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Weiter',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],

                      // Step 1: Form
                      if (_step == 1) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20, offset: const Offset(0, 4),
                            )],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Role badge
                              _RoleBadge(role: _selectedRole),
                              const SizedBox(height: 16),

                              // Nickname
                              _UsernameField(
                                controller: _usernameCtrl,
                                onChanged: (_) => _usernameTouched = true,
                                onSuggest: () {
                                  setState(() {
                                    _usernameCtrl.text = _generateNicknameSuggestion();
                                    _usernameTouched = true;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),

                              // Common: Vorname + Nachname
                              AiryInputField(controller: _firstNameCtrl,
                                  label: 'Vorname', hint: 'Max',
                                  keyboardType: TextInputType.name),
                              const SizedBox(height: 16),
                              AiryInputField(controller: _lastNameCtrl,
                                  label: 'Nachname', hint: 'Mustermann',
                                  keyboardType: TextInputType.name),
                              const SizedBox(height: 16),

                              // Role-specific fields
                              ..._buildRoleFields(),

                              // Common: Email + Password
                              AiryInputField(controller: _emailCtrl,
                                  label: l10n.registerEmailLabel,
                                  hint: l10n.registerEmailHint,
                                  keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: 16),
                              AiryInputField(
                                controller: _passwordCtrl,
                                label: l10n.registerPasswordLabel,
                                hint: l10n.registerPasswordHint,
                                obscureText: _obscurePassword,
                                keyboardType: TextInputType.visiblePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.greyText, size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE6B800),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(l10n.registerButton,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  border: Border(top: BorderSide(
                      color: Colors.black.withOpacity(0.06))),
                ),
                child: SafeArea(
                  top: false,
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.auth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            children: [
                              TextSpan(text: l10n.registerHaveAccount),
                              TextSpan(
                                text: l10n.registerLogin,
                                style: const TextStyle(
                                    color: Color(0xFFE6B800),
                                    fontWeight: FontWeight.bold),
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
      ),
    );
  }

  // ── Role-specific form fields ─────────────────────────────────────────────
  List<Widget> _buildRoleFields() {
    switch (_selectedRole) {
      case _RegRole.student:
        return _buildStudentFields();
      case _RegRole.parent:
        return _buildParentFields();
      case _RegRole.teacher:
        return _buildTeacherFields();
    }
  }

  List<Widget> _buildStudentFields() => [
    // School search with debounce
    _SchoolSearchField(
      controller: _schoolSearchCtrl,
      filteredSchools: _showSchoolDropdown ? _filteredSchools : [],
      onSearch: _onSchoolSearch,
      onSelect: _selectSchool,
      enabled: !_hasSchoolCode,
    ),
    if (_selectedSchool != null && !_hasSchoolCode) ...[
      const SizedBox(height: 16),
      _ClassDropdown(
        classes: _schoolClasses,
        selected: _selectedClass,
        onChanged: (v) => setState(() => _selectedClass = v),
      ),
    ],
    const SizedBox(height: 16),
    _InfoBox(text: 'Dein Konto wird vom Schuladministrator geprüft.'),
    const SizedBox(height: 16),
    _SchoolCodeToggle(
      hasCode: _hasSchoolCode,
      controller: _schoolCodeCtrl,
      onToggle: (v) => setState(() {
        _hasSchoolCode = v;
        if (v) {
          _selectedSchool = null;
          _selectedClass = null;
          _schoolSearchCtrl.clear();
        }
      }),
    ),
    const SizedBox(height: 16),
  ];

  List<Widget> _buildParentFields() => [
    AiryInputField(
      controller: _knChildCtrl,
      label: 'KN-Nummer des Kindes',
      hint: 'KN-XXXXXXXX',
      keyboardType: TextInputType.number,
      inputFormatters: [_KnNumberFormatter()],
    ),
    const SizedBox(height: 16),
    _InfoBox(text: 'Gib die KN-Nummer deines Kindes ein. Du findest sie in der Knoty-App deines Kindes.'),
    const SizedBox(height: 16),
  ];

  List<Widget> _buildTeacherFields() => [
    _SchoolSearchField(
      controller: _schoolSearchCtrl,
      filteredSchools: _showSchoolDropdown ? _filteredSchools : [],
      onSearch: _onSchoolSearch,
      onSelect: _selectSchool,
      enabled: !_hasSchoolCode,
    ),
    const SizedBox(height: 16),
    AiryInputField(
      controller: _subjectCtrl,
      label: 'Fach / Fächer',
      hint: 'z.B. Mathematik, Physik',
      keyboardType: TextInputType.text,
    ),
    const SizedBox(height: 16),
    _InfoBox(text: 'Dein Konto wird vom Schuladministrator verifiziert.'),
    const SizedBox(height: 16),
    _SchoolCodeToggle(
      hasCode: _hasSchoolCode,
      controller: _schoolCodeCtrl,
      onToggle: (v) => setState(() {
        _hasSchoolCode = v;
        if (v) { _selectedSchool = null; _schoolSearchCtrl.clear(); }
      }),
    ),
    const SizedBox(height: 16),
  ];

  String _generateNicknameSuggestion() {
    final email = _emailCtrl.text.trim();
    final firstName = _firstNameCtrl.text.trim().toLowerCase();
    final lastName = _lastNameCtrl.text.trim().toLowerCase();

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName}.${lastName}';
    }
    if (email.contains('@')) {
      return email.split('@').first.toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9._]'), '');
    }
    // Random suffix fallback
    final suffix = (1000 + DateTime.now().millisecond % 9000).toString();
    return 'user\$suffix';
  }

  String _roleSubtitle(_RegRole r) {
    switch (r) {
      case _RegRole.student:  return 'Schüler-Konto erstellen';
      case _RegRole.parent:   return 'Elternteil-Konto erstellen';
      case _RegRole.teacher:  return 'Lehrer-Konto erstellen';
    }
  }
}

// ── Role Selector ─────────────────────────────────────────────────────────────

class _RoleSelector extends StatelessWidget {
  final _RegRole selected;
  final ValueChanged<_RegRole> onChanged;
  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RoleTile(
          role: _RegRole.student,
          icon: Icons.school_rounded,
          title: 'Schüler',
          subtitle: 'Ich bin Schüler oder Schülerin',
          selected: selected == _RegRole.student,
          onTap: () => onChanged(_RegRole.student),
        ),
        const SizedBox(height: 12),
        _RoleTile(
          role: _RegRole.parent,
          icon: Icons.family_restroom_rounded,
          title: 'Elternteil',
          subtitle: 'Ich bin Mutter oder Vater',
          selected: selected == _RegRole.parent,
          onTap: () => onChanged(_RegRole.parent),
        ),
        const SizedBox(height: 12),
        _RoleTile(
          role: _RegRole.teacher,
          icon: Icons.person_rounded,
          title: 'Lehrer',
          subtitle: 'Ich bin Lehrer oder Lehrerin',
          selected: selected == _RegRole.teacher,
          onTap: () => onChanged(_RegRole.teacher),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  final _RegRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile({
    required this.role, required this.icon, required this.title,
    required this.subtitle, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF8E1) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? const Color(0xFFE6B800)
                : Colors.black.withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: const Color(0xFFE6B800).withOpacity(0.15),
              blurRadius: 12, offset: const Offset(0, 4),
            )
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFE6B800).withOpacity(0.15)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon,
                color: selected
                    ? const Color(0xFFE6B800)
                    : const Color(0xFF9E9E9E),
                size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: selected
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFF1A1A1A))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(
                  fontSize: 13, color: Color(0xFF9E9E9E))),
            ],
          )),
          if (selected)
            Container(
              width: 22, height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFE6B800),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14),
            )
          else
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.black.withOpacity(0.15), width: 2),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Role Badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final _RegRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (role) {
      _RegRole.student => (Icons.school_rounded, 'Schüler'),
      _RegRole.parent  => (Icons.family_restroom_rounded, 'Elternteil'),
      _RegRole.teacher => (Icons.person_rounded, 'Lehrer'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFE6B800).withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: const Color(0xFFE6B800)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: Color(0xFFE6B800))),
      ]),
    );
  }
}

// ── Info Box ──────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6B800).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.info_outline_rounded,
            size: 16, color: Color(0xFFE6B800)),
        const SizedBox(width: 8),
        Flexible(child: Text(text,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B6B6B)))),
      ]),
    );
  }
}

// ── School Search Field ───────────────────────────────────────────────────────

class _SchoolSearchField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> filteredSchools;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onSelect;
  final bool enabled;
  const _SchoolSearchField({
    required this.controller, required this.filteredSchools,
    required this.onSearch, required this.onSelect, this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Opacity(
        opacity: enabled ? 1.0 : 0.45,
        child: AiryInputField(
          controller: controller,
          label: 'Schule',
          hint: enabled ? 'Schulname eingeben...' : 'Schulcode wird verwendet',
          keyboardType: TextInputType.text,
          onChanged: enabled ? onSearch : null,
        ),
      ),
      if (filteredSchools.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12, offset: const Offset(0, 4),
            )],
          ),
          child: Column(
            children: filteredSchools.map((s) => InkWell(
              onTap: () => onSelect(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.school_outlined,
                      size: 16, color: Color(0xFFE6B800)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s,
                      style: const TextStyle(fontSize: 14))),
                ]),
              ),
            )).toList(),
          ),
        ),
    ]);
  }
}

// ── Class Dropdown ────────────────────────────────────────────────────────────

class _ClassDropdown extends StatelessWidget {
  final List<String> classes;
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _ClassDropdown({
    required this.classes, required this.selected, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Klasse', style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: Color(0xFF6B6B6B))),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            hint: const Text('Klasse wählen',
                style: TextStyle(color: Colors.black38, fontSize: 15)),
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6B6B6B)),
            items: classes.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 15)),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }
}

// ── School Code Toggle ────────────────────────────────────────────────────────

class _SchoolCodeToggle extends StatelessWidget {
  final bool hasCode;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  const _SchoolCodeToggle({
    required this.hasCode, required this.controller, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GestureDetector(
        onTap: () => onToggle(!hasCode),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: hasCode
                  ? const Color(0xFFE6B800)
                  : Colors.transparent,
              border: Border.all(
                color: hasCode
                    ? const Color(0xFFE6B800)
                    : Colors.grey.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: hasCode
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          const Flexible(child: Text(
            'Ich habe einen Schulcode (SCH-XXXX)',
            style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          )),
        ]),
      ),
      if (hasCode) ...[
        const SizedBox(height: 12),
        AiryInputField(
          controller: controller,
          label: 'Schulcode',
          hint: 'SCH-XXXX',
          keyboardType: TextInputType.text,
          inputFormatters: [_SchCodeFormatter()],
        ),
      ],
    ]);
  }
}

// ── Username Field ────────────────────────────────────────────────────────────

class _UsernameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSuggest;
  const _UsernameField({
    required this.controller,
    required this.onChanged,
    required this.onSuggest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('@Benutzername',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: Color(0xFF6B6B6B))),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('@',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600,
                          color: Color(0xFFE6B800))),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'deinname',
                      hintStyle: TextStyle(color: Colors.black26),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 14),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          // Suggest button
          GestureDetector(
            onTap: onSuggest,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFE6B800).withOpacity(0.3)),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 20, color: Color(0xFFE6B800)),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        const Text(
          'Mind. 5 Zeichen · Buchstaben, Zahlen, . und _ · Wird automatisch aus deiner E-Mail vorgeschlagen. Drücke ✨ für einen Vorschlag. Falls vergeben, wird ein freier Name zugewiesen.',
          style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
        ),
      ],
    );
  }
}

// ── Input Formatters ──────────────────────────────────────────────────────────

/// Форматирует ввод как KN-XXXXXXXX (8 цифр после KN-)
/// Пример: 12345678 → KN-12345678
class _KnNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Оставляем только цифры
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final formatted = limited.isEmpty ? '' : 'KN-$limited';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Форматирует ввод как SCH-XXXX (4 буквенно-цифровых символа)
/// Пример: AB12 → SCH-AB12
class _SchCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final chars = newValue.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase();
    final limited = chars.length > 4 ? chars.substring(0, 4) : chars;
    final formatted = limited.isEmpty ? '' : 'SCH-$limited';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}