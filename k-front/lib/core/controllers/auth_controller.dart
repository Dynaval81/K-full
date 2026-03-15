import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:knoty/services/api_service.dart';
import 'package:knoty/data/models/user_model.dart';
import 'package:knoty/core/enums/user_role.dart';
import 'package:knoty/core/enums/verification_level.dart';

/// Результат попытки логина
class AuthResult {
  final bool success;
  final String? error;
  final bool isEmailNotVerified;

  const AuthResult({
    required this.success,
    this.error,
    this.isEmailNotVerified = false,
  });

  factory AuthResult.ok() => const AuthResult(success: true);

  factory AuthResult.fail(String error, {bool isEmailNotVerified = false}) =>
      AuthResult(success: false, error: error, isEmailNotVerified: isEmailNotVerified);
}

/// HAI3 Core: Auth controller — единственный источник правды об авторизации.
///
/// Жизненный цикл:
/// 1. [tryRestoreSession] — вызывается при старте приложения.
/// 2. [loginWithCredentials] — реальный логин через POST /auth/login.
/// 3. [logout] — удаляем токен, сбрасываем состояние.
class AuthController extends ChangeNotifier {
  // ── Dependencies ──────────────────────────────────────────────────
  final ApiService _api;
  final FlutterSecureStorage _storage;

  final void Function(User user)? onUserLoaded;
  final void Function(String matrixUserId)? onMatrixUserIdLoaded;
  final Future<void> Function()? onLogout;

  AuthController({
    ApiService? api,
    FlutterSecureStorage? storage,
    this.onUserLoaded,
    this.onMatrixUserIdLoaded,
    this.onLogout,
  })  : _api = api ?? ApiService(),
        _storage = storage ?? const FlutterSecureStorage();

  // ── State ─────────────────────────────────────────────────────────
  bool _isAuthenticated = false;
  bool _isRestoringSession = true;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isRestoringSession => _isRestoringSession;
  User? get currentUser => _currentUser;

  // ── Session restore ───────────────────────────────────────────────

  /// Вызвать один раз при старте приложения в main().
  Future<void> tryRestoreSession() async {
    _isRestoringSession = true;
    notifyListeners();

    try {
      final hasToken = await _api.hasToken();
      if (!hasToken) {
        _setUnauthenticated();
        return;
      }

      final result = await _api.getUserData();
      if (result['success'] == true && result['user'] != null) {
        final user = User.fromJson(result['user'] as Map<String, dynamic>);
        _setAuthenticated(user);
        if (user.matrixUserId != null) {
          onMatrixUserIdLoaded?.call(user.matrixUserId!);
        }
      } else {
        _setUnauthenticated();
      }
    } catch (_) {
      _setUnauthenticated();
    } finally {
      _isRestoringSession = false;
      notifyListeners();
    }
  }

  // ── Login ─────────────────────────────────────────────────────────

  /// Принимает email / VT-ID / никнейм — бэкенд различает сам.
  // ── Demo accounts ─────────────────────────────────────────────────
  // Временные демо-входы для тестирования UI по ролям.
  // TODO: удалить перед продакшном.
  static final _demoUsers = <String, User>{
    '1': User(
      id: 'demo-student',
      username: 'max.mustermann',
      email: 'student@demo.knoty',
      knotyNumber: 'KN-00000001',
      role: UserRole.student,
      verificationLevel: VerificationLevel.verified,
      schoolId: 'demo-school',
    ),
    '2': User(
      id: 'demo-parent',
      username: 'anna.mueller',
      email: 'parent@demo.knoty',
      knotyNumber: 'KN-00000002',
      role: UserRole.parent,
      verificationLevel: VerificationLevel.verified,
      linkedChildId: 'KN-00000001',
    ),
    '3': User(
      id: 'demo-teacher',
      username: 'herr.schmidt',
      email: 'teacher@demo.knoty',
      knotyNumber: 'KN-00000003',
      role: UserRole.teacher,
      verificationLevel: VerificationLevel.verified,
      schoolId: 'demo-school',
    ),
    '4': User(
      id: 'demo-admin',
      username: 'schuladmin',
      email: 'admin@demo.knoty',
      knotyNumber: 'KN-00000004',
      role: UserRole.schoolAdmin,
      verificationLevel: VerificationLevel.verified,
      schoolId: 'demo-school',
    ),
    // ── Unverified demo accounts ───────────────────────────────────
    '11': User(
      id: 'demo-student-unverified',
      username: 'lena.bauer',
      email: 'student2@demo.knoty',
      knotyNumber: 'KN-00000011',
      role: UserRole.student,
      verificationLevel: VerificationLevel.none,
    ),
    '12': User(
      id: 'demo-parent-unverified',
      username: 'thomas.weber',
      email: 'parent2@demo.knoty',
      knotyNumber: 'KN-00000012',
      role: UserRole.parent,
      verificationLevel: VerificationLevel.none,
    ),
    '13': User(
      id: 'demo-teacher-unverified',
      username: 'frau.klein',
      email: 'teacher2@demo.knoty',
      knotyNumber: 'KN-00000013',
      role: UserRole.teacher,
      verificationLevel: VerificationLevel.none,
    ),
    '14': User(
      id: 'demo-admin-unverified',
      username: 'schuladmin2',
      email: 'admin2@demo.knoty',
      knotyNumber: 'KN-00000014',
      role: UserRole.schoolAdmin,
      verificationLevel: VerificationLevel.none,
    ),
  };

  Future<AuthResult> loginWithCredentials({
    required String identifier,
    required String password,
  }) async {
    // Demo shortcut: логин 1-4, пароль 123456
    if (password == '123456' && _demoUsers.containsKey(identifier.trim())) {
      _setAuthenticated(_demoUsers[identifier.trim()]!);
      return AuthResult.ok();
    }

    try {
      final response = await _api.login(email: identifier, password: password);

      if (response['success'] == true) {
        final userJson = response['user'];
        if (userJson != null) {
          final user = User.fromJson(userJson as Map<String, dynamic>);
          _setAuthenticated(user);
          // Sync Matrix user ID to ChatController
          final matrixUserId = response['matrixUserId']?.toString()
              ?? user.matrixUserId;
          if (matrixUserId != null) {
            onMatrixUserIdLoaded?.call(matrixUserId);
          }
        }
        return AuthResult.ok();
      }

      final isNotVerified = response['isEmailNotVerified'] == true;
      final errorMsg = response['error']?.toString() ?? 'Anmeldung fehlgeschlagen';
      return AuthResult.fail(errorMsg, isEmailNotVerified: isNotVerified);
    } on SocketException {
      return AuthResult.fail('Keine Internetverbindung');
    } on TimeoutException {
      return AuthResult.fail('Verbindung zeitüberschritten');
    } catch (e) {
      return AuthResult.fail('Fehler: ${e.toString()}');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await onLogout?.call();
    } catch (_) {}
    await _api.logout();
    _setUnauthenticated();
  }

  // ── Private ───────────────────────────────────────────────────────

  /// Обновляет текущего пользователя без запроса к серверу (после активации кода).
  void updateUser(User user) {
    _currentUser = user;
    onUserLoaded?.call(user);
    notifyListeners();
  }

  /// Перезапрашивает данные пользователя с сервера.
  Future<void> refreshUser() async {
    try {
      final result = await _api.getUserData();
      if (result['success'] == true && result['user'] != null) {
        final user = User.fromJson(result['user'] as Map<String, dynamic>);
        _setAuthenticated(user);
        if (user.matrixUserId != null) {
          onMatrixUserIdLoaded?.call(user.matrixUserId!);
        }
      }
    } catch (e) {
      debugPrint('[AUTH] refreshUser error: $e');
    }
  }

  void _setAuthenticated(User user) {
    _isAuthenticated = true;
    _currentUser = user;
    onUserLoaded?.call(user);
    notifyListeners();
  }

  void _setUnauthenticated() {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  User _placeholderUser() => User(
        id: 'mock',
        username: 'User',
        email: '',
        knotyNumber: '',
      );
}