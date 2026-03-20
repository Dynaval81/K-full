import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:knoty/core/network/dio_client.dart';

/// Central HTTP client for the Knoty backend.
/// Uses [DioClient] (singleton) which auto-injects the Bearer token.
/// Offline fallback: [getUserData] and [getSchools] return cached data
/// from SharedPreferences when the server is unreachable.
class ApiService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _cacheUserKey = 'cache_user_data';
  static const String _cacheSchoolsKey = 'cache_schools';

  final Dio _dio = DioClient().dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // ─── Cache helpers ────────────────────────────────────────────────────────

  Future<void> _cacheJson(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _readCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? role,
    String? activationCode,
    String? schoolId,
    String? classId,
    String? username,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (role != null) 'role': role,
        if (activationCode != null) 'activationCode': activationCode,
        if (schoolId != null) 'schoolId': schoolId,
        if (classId != null) 'classId': classId,
        if (username != null && username.isNotEmpty) 'username': username,
      });
      // Server returns accessToken (not token) in register response
      final token = res.data['data']?['accessToken'] ?? res.data['token'] ?? res.data['data']?['token'];
      final refreshToken = res.data['data']?['refreshToken'] ?? res.data['refreshToken'];
      final userData = res.data['data']?['user'] ?? res.data['user'];
      if (token != null) {
        await _secureStorage.write(key: _tokenKey, value: token);
      }
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      return {'success': true, 'user': userData, 'token': token};
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = res.data['token'] ?? res.data['data']?['token']
          ?? res.data['data']?['accessToken'];
      final refreshToken = res.data['data']?['refreshToken'] ?? res.data['refreshToken'];
      final userData = res.data['user'] ?? res.data['data']?['user'];
      if (token != null) {
        await _secureStorage.write(key: _tokenKey, value: token);
      }
      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }
      return {'success': true, 'user': userData, 'token': token};
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final data = e.response?.data as Map? ?? {};
        if (data['code'] == 'ACCOUNT_BANNED') {
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
      }
      return DioClient.handleError(e, fallback: 'Login failed');
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Login failed');
    }
  }

  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null;
  }

  /// Fetches current user. Falls back to cached data when offline.
  Future<Map<String, dynamic>> getUserData() async {
    try {
      final res = await _dio.get('/auth/me');
      final userJson = res.data['data']?['user'] ?? res.data['user'];
      final result = {'success': true, 'user': userJson};
      await _cacheJson(_cacheUserKey, result);
      return result;
    } catch (e) {
      final err = DioClient.handleError(e, fallback: 'Failed to get user data');
      if (err['isOffline'] == true) {
        final cached = await _readCache(_cacheUserKey);
        if (cached != null) return {...cached, 'fromCache': true};
      }
      return err;
    }
  }

  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      final res = await _dio.get('/users/search',
          queryParameters: {'query': query});
      final usersList =
          res.data['data']?['users'] ?? res.data['users'] ?? [];
      return {'success': true, 'users': usersList};
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Failed to search users');
    }
  }

  Future<void> recoverAccess(String email) async {
    await _dio.post('/auth/recovery', data: {'email': email});
  }

  Future<Map<String, dynamic>> verifyCode({
    required String code,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final res = await _dio.post('/auth/verify-code', data: {
        'code': code,
        'firstName': firstName,
        'lastName': lastName,
      });
      return {
        'success': true,
        'valid': res.data['valid'] ?? false,
        'schoolName': res.data['schoolName'],
        'className': res.data['className'],
        'role': res.data['role'],
        'reason': res.data['reason'],
      };
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Verification failed');
    }
  }

  /// Fetches schools list. Falls back to cached data when offline.
  Future<Map<String, dynamic>> getSchools() async {
    try {
      final res = await _dio.get('/schools');
      final result = {
        'success': true,
        'schools': res.data['schools'] ?? [],
      };
      await _cacheJson(_cacheSchoolsKey, result);
      return result;
    } catch (e) {
      final err = DioClient.handleError(e, fallback: 'Failed to load schools');
      if (err['isOffline'] == true) {
        final cached = await _readCache(_cacheSchoolsKey);
        if (cached != null) return {...cached, 'fromCache': true};
      }
      return err;
    }
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      final res = await _dio.post('/auth/resend-verification', data: {'email': email});
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Failed to resend verification email');
    }
  }

  Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final res = await _dio.get('/auth/check-username', queryParameters: {'username': username});
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Failed to check username');
    }
  }

  Future<Map<String, dynamic>> suggestUsername({String? hint}) async {
    try {
      final res = await _dio.get('/auth/suggest-username', queryParameters: hint != null ? {'hint': hint} : null);
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Failed to suggest username');
    }
  }

  Future<Map<String, dynamic>> createChat(String userId) async {
    try {
      final res = await _dio.post('/chats/create', data: {'userId': userId});
      return {
        'success': true,
        'roomId': res.data['roomId'] ?? res.data['data']?['roomId'],
      };
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Failed to create chat');
    }
  }

  Future<Map<String, dynamic>> listChats() async {
    try {
      final res = await _dio.get('/chats/list');
      return {
        'success': true,
        'rooms': res.data['rooms'] ?? res.data['data']?['rooms'] ?? [],
      };
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Failed to load chats');
    }
  }

  // ─── Admin API ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _adminGet(String path,
      {Map<String, String>? query}) async {
    try {
      final res =
          await _dio.get('/admin/$path', queryParameters: query);
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Request failed');
    }
  }

  Future<Map<String, dynamic>> _adminPost(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/admin/$path', data: body);
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Request failed');
    }
  }

  Future<Map<String, dynamic>> _adminPut(
      String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.put('/admin/$path', data: body);
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Request failed');
    }
  }

  Future<Map<String, dynamic>> _adminDelete(String path) async {
    try {
      final res = await _dio.delete('/admin/$path');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return DioClient.handleError(e, fallback: 'Request failed');
    }
  }

  Future<Map<String, dynamic>> adminGetStats() => _adminGet('stats');
  Future<Map<String, dynamic>> adminListSchools() => _adminGet('schools');

  Future<Map<String, dynamic>> adminCreateSchool({
    required String name,
    required String city,
    String? address,
  }) =>
      _adminPost('schools', {
        'name': name,
        'city': city,
        if (address != null) 'address': address,
      });

  Future<Map<String, dynamic>> adminUpdateSchool(String id,
          {String? name, String? city, String? address}) =>
      _adminPut('schools/$id', {
        if (name != null) 'name': name,
        if (city != null) 'city': city,
        if (address != null) 'address': address,
      });

  Future<Map<String, dynamic>> adminListCodes(
          {String? schoolId, String? status, String? classId}) =>
      _adminGet('codes', query: {
        if (schoolId != null) 'schoolId': schoolId!,
        if (status != null) 'status': status!,
        if (classId != null) 'classId': classId!,
      });

  Future<Map<String, dynamic>> adminGenerateCodes({
    required String schoolId,
    required String classId,
    required List<Map<String, String>> entries,
    String role = 'student',
    int expiresInDays = 30,
  }) =>
      _adminPost('codes/generate', {
        'schoolId': schoolId,
        'classId': classId,
        'role': role,
        'entries': entries,
        'expiresInDays': expiresInDays,
      });

  Future<Map<String, dynamic>> adminDeleteCode(String code) =>
      _adminDelete('codes/$code');

  Future<Map<String, dynamic>> adminListUsers({
    String? schoolId,
    String? status,
    String? role,
    bool? pending,
    String? search,
    int page = 1,
    int limit = 50,
  }) =>
      _adminGet('users', query: {
        if (schoolId != null) 'schoolId': schoolId!,
        if (status != null) 'status': status!,
        if (role != null) 'role': role!,
        if (pending != null) 'pending': pending.toString(),
        if (search != null) 'search': search!,
        'page': page.toString(),
        'limit': limit.toString(),
      });

  Future<Map<String, dynamic>> adminApproveUser(String id) =>
      _adminPost('users/$id/approve', {});

  Future<Map<String, dynamic>> adminBanUser(String id, {String? reason}) =>
      _adminPost('users/$id/ban', {if (reason != null) 'reason': reason!});

  Future<Map<String, dynamic>> adminUnbanUser(String id) =>
      _adminPost('users/$id/unban', {});

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
