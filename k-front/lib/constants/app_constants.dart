class AppConstants {
  // API и сеть
  static const String defaultAvatarUrl = 'https://i.pravatar.cc/150';
  static const String avatarUrl = 'https://i.pravatar.cc/150'; // Добавляем avatarUrl для совместимости
  static const String mockVpnIp = '45.134.144.10';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Vtalk номера
  static const int vtalkNumberMin = 1000;
  static const int vtalkNumberMax = 9999;
  
  // Валидация
  static const int passwordMinLength = 6;
  static const int nicknameMinLength = 3;
  
  // UI константы
  static const double borderRadius = 8.0;
  static const double avatarRadius = 18.0;
  static const double buttonHeight = 16.0;
  
  // Storage ключи
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNicknameKey = 'user_nickname';
  static const String vtalkNumberKey = 'vtalk_number';
  
  // Email regex
  static const String emailRegexPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // Nickname regex
  static const String nicknameRegexPattern = r'^[a-zA-Z0-9_]+$';
}
