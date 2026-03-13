import 'dart:async';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Валидация email или KN-номера
  bool isValidEmail(String email) {
    // Поддержка KN-номера (формат KN-XXXXXX)
    if (RegExp(r'^KN-\d{6}$', caseSensitive: false).hasMatch(email)) {
      return true;
    }
    // Стандартная валидация email
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Валидация пароля
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Получение данных пользователя (getMe)
  Future<Map<String, dynamic>> getMe() async {
    try {
      return await _apiService.getUserData();
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to get user data: ${e.toString()}',
      };
    }
  }

  // Глобальный поиск пользователей
  Future<Map<String, dynamic>> searchUsers(String query) async {
    try {
      final result = await _apiService.searchUsers(query);
      if (result['success'] == true) {
        final users = result['users'];
        return {
          'success': true,
          'users': users is List ? users : [],
        };
      }
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to search users: ${e.toString()}',
      };
    }
  }
}
