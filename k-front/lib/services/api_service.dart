import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://hypermax.duckdns.org/api/v1',
  );
  static const String _tokenKey = 'auth_token';
  static const Duration _timeout = Duration(seconds: 30);

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Регистрация пользователя
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? role,            // 'student' | 'parent' | 'teacher'
    String? activationCode,  // KNOTY-XXXX-XXXX
    String? schoolId,
    String? classId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (firstName != null)      'firstName': firstName,
          if (lastName != null)       'lastName': lastName,
          if (role != null)           'role': role,
          if (activationCode != null) 'activationCode': activationCode,
          if (schoolId != null)       'schoolId': schoolId,
          if (classId != null)        'classId': classId,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final token = data['token'] ?? data['data']?['token'];
        final userData = data['user'] ?? data['data']?['user'];
        if (token != null) {
          await _secureStorage.write(key: _tokenKey, value: token);
        }
        return {'success': true, 'user': userData, 'token': token};
      } else {
        return {'success': false, 'error': data['error'] ?? data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Вход пользователя
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'] ?? data['data']?['token'];
        final userData = data['user'] ?? data['data']?['user'];
        if (token != null) {
          await _secureStorage.write(key: _tokenKey, value: token);
        }
        return {
          'success': true,
          'user': userData,
          'token': token,
        };
      } else if (response.statusCode == 403) {
        final errorCode = data['code'];
        if (errorCode == 'ACCOUNT_BANNED') {
          return {
            'success': false,
            'error': data['error'] ?? 'Account banned',
            'isBanned': true,
            'banReason': data['banReason'],
          };
        }
        return {
          'success': false,
          'error': data['error'] ?? data['message'] ?? 'Access denied',
        };
      } else {
        return {'success': false, 'error': data['message'] ?? data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Проверка наличия токена
  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null;
  }

  // Получение данных текущего пользователя
  Future<Map<String, dynamic>> getUserData() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) return {'success': false, 'error': 'No token found'};

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final userJson = data['data']?['user'] ?? data['user'];
        return {'success': true, 'user': userJson};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get user data'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Глобальный поиск пользователей
  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) return {'success': false, 'error': 'No token found'};

      final uri = Uri.parse('$_baseUrl/users/search').replace(
        queryParameters: {'query': query},
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final usersList = data['data']?['users'] ?? data['users'] ?? [];
        return {'success': true, 'users': usersList};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to search users'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Восстановление доступа
  Future<void> recoverAccess(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/recovery'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) throw Exception('Recovery failed');
  }

  // Проверка активационного кода (до регистрации)
  Future<Map<String, dynamic>> verifyCode({
    required String code,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'firstName': firstName,
          'lastName': lastName,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'valid': data['valid'] ?? false,
          'schoolName': data['schoolName'],
          'className': data['className'],
          'role': data['role'],
          'reason': data['reason'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Verification failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Публичный список школ (для регистрации)
  Future<Map<String, dynamic>> getSchools() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/schools'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'schools': data['schools'] ?? []};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to load schools'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Создание чата
  Future<Map<String, dynamic>> createChat(String userId) async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) return {'success': false, 'error': 'No token'};

      final response = await http.post(
        Uri.parse('$_baseUrl/chats/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId}),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'roomId': data['roomId'] ?? data['data']?['roomId']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to create chat'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Получение списка чатов
  Future<Map<String, dynamic>> listChats() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token == null) return {'success': false, 'error': 'No token'};

      final response = await http.get(
        Uri.parse('$_baseUrl/chats/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'rooms': data['rooms'] ?? data['data']?['rooms'] ?? []};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to load chats'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Выход
  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
