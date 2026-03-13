/// Роли пользователей в системе Knoty.
/// 
/// Архитектурное решение по мультиролям:
/// - Один аккаунт = одна роль
/// - Учитель-родитель → два отдельных аккаунта, связанных через linkedAccounts
/// - SuperAdmin и SchoolAdmin создаются вручную, не через регистрацию
enum UserRole {
  student,      // Ученик — базовая роль
  parent,       // Родитель — привязывается к ребёнку по KN-номеру
  teacher,      // Учитель — верифицируется школой
  schoolAdmin,  // Администратор школы — назначается при регистрации школы
  superAdmin,   // Суперадмин Knoty — создаётся командой вручную
}

extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.student:    return 'Schüler';
      case UserRole.parent:     return 'Elternteil';
      case UserRole.teacher:    return 'Lehrer';
      case UserRole.schoolAdmin: return 'Schuladmin';
      case UserRole.superAdmin: return 'SuperAdmin';
    }
  }

  String get displayNameEn {
    switch (this) {
      case UserRole.student:    return 'Student';
      case UserRole.parent:     return 'Parent';
      case UserRole.teacher:    return 'Teacher';
      case UserRole.schoolAdmin: return 'School Admin';
      case UserRole.superAdmin: return 'Super Admin';
    }
  }

  /// Регистрируется через приложение — только student/parent/teacher
  bool get isRegisterable =>
      this == UserRole.student ||
      this == UserRole.parent ||
      this == UserRole.teacher;

  /// Имеет доступ к вкладке "Ребёнок"
  bool get hasChildTab => this == UserRole.parent;

  /// Имеет вкладку "Мои классы"
  bool get hasMyClassesTab => this == UserRole.teacher;

  /// Имеет вкладку "Управление"
  bool get hasManagementTab =>
      this == UserRole.schoolAdmin || this == UserRole.superAdmin;

  /// Имеет расширенный доступ к школьным чатам
  bool get hasFullSchoolAccess =>
      this == UserRole.schoolAdmin || this == UserRole.superAdmin;

  /// Парсинг из строки (от бэкенда)
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'student':     return UserRole.student;
      case 'parent':      return UserRole.parent;
      case 'teacher':     return UserRole.teacher;
      case 'schooladmin':
      case 'school_admin': return UserRole.schoolAdmin;
      case 'superadmin':
      case 'super_admin': return UserRole.superAdmin;
      default:            return UserRole.student; // безопасный fallback
    }
  }
}
