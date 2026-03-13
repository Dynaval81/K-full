import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:knoty/data/models/user_model.dart';
import 'package:knoty/services/api_service.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _chatRooms = []; // 🚨 НОВОЕ: Храним список чатов
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _user?.isPremium ?? false;
  List<Map<String, dynamic>> get rooms => _chatRooms; // 🚨 НОВОЕ: Getter для списка чатов

  void setUser(User user) {
    _user = user;
    _error = null;
    
    // 🚨 НОВОЕ: Автоматическое создание чата с самим собой при первой авторизации
    _createSavedMessagesChat(user);
    
    notifyListeners();
  }

  // 🚨 НОВОЕ: Создание чата "Saved Messages"
  Future<void> _createSavedMessagesChat(User user) async {
    try {
      final api = ApiService();
      // 🚨 ИСПРАВЛЕНО: createChat принимает только userId
      final result = await api.createChat(user.id);
      
      if (result['success'] != true) {
        print('Failed to create Saved Messages chat: ${result['error']}');
      } else {
        // 🚨 НОВОЕ: После создания чата обновляем список
        await _fetchRooms();
        notifyListeners();
      }
    } catch (e) {
      print('Error creating Saved Messages chat: $e');
    }
  }

  // 🚨 НОВОЕ: Публичный метод создания чата
  Future<void> createChat(String targetUserId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final api = ApiService();
      await api.createChat(targetUserId);
      
      // 🚨 Ждем 500мс, чтобы бэкенд точно обновился, и тянем список
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 🚨 КРИТИЧЕСКО: Загружаем обновленный список и уведомляем UI
      await _fetchRooms(); 
      _isLoading = false;
      notifyListeners(); 
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Create chat error: $e");
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void activatePremium(String activationCode) {
    if (_user != null) {
      _user = _user!.copyWith(
        isPremium: true,

      );
      notifyListeners();
    }
  }

  // ⭐ СМЕНА ИМЕНИ ПОЛЬЗОВАТЕЛЯ
  Future<void> updateUsername(String newName, BuildContext context) async {
    try {
      final updatedData = await _apiService.changeUsername(newName);
      
      if (updatedData['success']) {
        _user = _user?.copyWith(username: updatedData['username']);
        notifyListeners(); // Мгновенно обновляем ник во всем приложении
      } else {
        showUsernameError(updatedData['error'], updatedData['nextChangeDate'], context);
      }
    } catch (e) {
      showUsernameError('Ошибка сети: ${e.toString()}', null, context);
    }
  }

  // ⭐ ПОКАЗ ОШИБКИ СМЕНЫ ИМЕНИ
  void showUsernameError(String error, String? nextChangeDate, BuildContext context) {
    if (nextChangeDate != null) {
      // ⭐ 429 ОШИБКА - ЛИМИТ ВРЕМЕНИ
      try {
        final nextDate = DateTime.parse(nextChangeDate);
        final now = DateTime.now();
        final difference = nextDate.difference(now);
        final days = difference.inDays;
        
        _showUsernameSpecialError(
          'Вы сможете сменить имя через $days дней (${_formatDate(nextDate)})',
          null,
          context,
        );
      } catch (e) {
        _showUsernameSpecialError('Ошибка парсинга даты', null, context);
      }
    } else {
      // ⭐ 400 ОШИБКА - СТОП-СЛОВА
      _showUsernameSpecialError(
        'Это имя зарезервировано системой. Пожалуйста, выберите другое',
        null,
        context,
      );
    }
  }

  // ⭐ ПОКАЗ СПЕЦИАЛЬНОГО ОКНА ОШИБКИ
  void _showUsernameSpecialError(String error, String? nextChangeDate, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                nextChangeDate != null ? Icons.schedule : Icons.block,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white
                      : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Понятно'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ⭐ ФОРМАТИРОВАНИЕ ДАТЫ
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Removes all user-related data and stored token. Used during logout.
  Future<void> clearUser() async {
    _user = null;
    _token = null;
    _error = null;
    _isLoading = false;
    
    // 🚨 Стираем токен при logout
    await _storage.delete(key: 'auth_token');
    
    notifyListeners();
  }

  /// Convenience method named explicitly for logout semantics.
  Future<void> logout({BuildContext? context}) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _storage.delete(key: 'auth_token');
      _token = null;
      _user = null;
      _error = null;
      _isLoading = false;
      
      // 🚨 НОВОЕ: Это заставит UI перестроиться и увидеть, что юзера нет
      notifyListeners(); 
      
      // 🚨 НОВОЕ: Принудительный переход на экран логина
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      _isLoading = false;
      _token = null;
      _user = null;
      _error = null;
      notifyListeners();
      print("Logout error: $e");
      
      // 🚨 НОВОЕ: Принудительный переход даже при ошибке
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  // 🚨 НОВОЕ: Метод для принудительного обновления чатов
  Future<void> refreshData() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 🚨 Вызываем функцию загрузки чатов (пусть проверит название своей функции)
      await _fetchRooms(); 
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Refresh data error: $e");
    }
  }

  // 🚨 НОВОЕ: Приватный метод для загрузки комнат
  Future<void> _fetchRooms() async {
    try {
      final api = ApiService();
      final result = await api.listChats();
      
      // 🚨 НОВОЕ: Сохраняем список чатов
      if (result['success'] == true && result['data'] != null) {
        _chatRooms = List<Map<String, dynamic>>.from(result['data']);
        print('Fetched ${_chatRooms.length} rooms');
      } else {
        _chatRooms = [];
        print('Failed to fetch rooms: ${result['error']}');
      }
    } catch (e) {
      _chatRooms = [];
      print('Fetch rooms error: $e');
    }
  }

  // ⭐ ОБНОВЛЕНИЕ ДАННЫХ ПОЛЬЗОВАТЕЛЯ
  Future<void> refreshUserData() async {
    try {
      setLoading(true);
      final result = await _apiService.getUserData();
      
      if (result['success']) {
        _user = User.fromJson(result['user']);
        _error = null;
      } else {
        _error = result['error'] ?? 'Failed to refresh user data';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    } finally {
      setLoading(false);
    }
  }
}