/// 📋 VTalk Beta Constants
/// HAI3 compliant constants and configuration

class AppConstants {
  // 📱 App Information
  static const String appName = 'VTalk';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // 🌐 API Configuration
  static const String baseUrl = 'https://hypermax.duckdns.org/api/v1';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 10);
  
  // 🔐 Authentication
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userProfileKey = 'user_profile';
  
  // 🎨 Assets
  static const String logoPath = 'assets/images/app_logo_classic.png';
  static const String defaultAvatarUrl = 'https://api.dicebear.com/7.x/avataaars/svg?seed=default';
  
  // 📏 Dimensions
  static const double defaultButtonHeight = 48.0;
  static const double defaultInputHeight = 48.0;
  static const double avatarSize = 40.0;
  static const double messageMaxWidth = 300.0;
  
  // ⏱️ Durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDelay = Duration(milliseconds: 2500);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration typingIndicatorDelay = Duration(milliseconds: 1000);
  
  // 📝 Validation
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxMessageLength = 1000;
  static const int maxBioLength = 200;
  
  // 🎯 UI Constants
  static const int maxRecentChats = 10;
  static const int maxSearchResults = 20;
  static const int messagesPerPage = 50;
  static const int contactsPerPage = 30;
  
  // 🚨 Error Messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String authErrorMessage = 'Authentication failed. Please check your credentials.';
  static const String validationErrorMessage = 'Please check your input and try again.';
  
  // 🎉 Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registerSuccessMessage = 'Account created successfully!';
  static const String profileUpdateSuccessMessage = 'Profile updated successfully!';
  static const String messageSentSuccessMessage = 'Message sent successfully!';
  
  // 🔄 Loading Messages
  static const String loadingMessage = 'Loading...';
  static const String sendingMessage = 'Sending...';
  static const String connectingMessage = 'Connecting...';
  static const String authenticatingMessage = 'Authenticating...';
  
  // 🎨 Theme Configuration
  static const bool useDarkThemeByDefault = true;
  static const bool enableSystemTheme = true;
  static const bool enableCustomAnimations = true;
  
  // 🔔 Notification Settings
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableInAppNotifications = true;
  
  // 🔒 Security Settings
  static const bool enableTwoFactorAuth = true;
  static const bool enableSessionTimeout = true;
  static const Duration sessionTimeout = Duration(hours: 24);
  
  // 📊 Analytics
  static const bool enableAnalytics = false; // Privacy-focused
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = false;
  
  // 🎯 Feature Flags
  static const bool enableVoiceMessages = true;
  static const bool enableVideoCalls = false; // Coming soon
  static const bool enableFileSharing = true;
  static const bool enableLocationSharing = false; // Privacy-focused
  static const bool enableEndToEndEncryption = true;
  
  // 🌍 Localization
  static const String defaultLocale = 'en';
  static const List<String> supportedLocales = ['en', 'es', 'fr', 'de', 'it', 'pt', 'ru'];
  
  // 📱 Platform Specific
  static const bool enableBiometricAuth = true;
  static const bool enableHapticFeedback = true;
  static const bool enableSystemUI = true;
  
  // 🎨 Brand Colors (HAI3 Compliance)
  static const int primaryColorValue = 0xFF00A3FF;
  static const int backgroundColorValue = 0xFF000000;
  static const int surfaceColorValue = 0xFF1A1A1A;
  static const int onSurfaceColorValue = 0xFFFFFFFF;
  
  // 📏 Spacing Constants (HAI3 8px Grid)
  static const double spacingUnit = 8.0;
  static const double borderRadiusUnit = 4.0;
  
  // 🎯 Animation Constants
  static const double defaultOpacity = 1.0;
  static const double disabledOpacity = 0.6;
  static const double hoverOpacity = 0.8;
  static const double pressedOpacity = 0.4;
}

/// 🎯 Route Names
class AppRoutes {
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';
  static const String chats = '/chats';
  static const String chat = '/chat';
  static const String ai = '/ai';
  static const String vpn = '/vpn';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String onboarding = '/onboarding';
}

/// 🎯 Screen Names
class AppScreens {
  static const String splash = 'SplashScreen';
  static const String auth = 'AuthScreen';
  static const String login = 'LoginScreen';
  static const String register = 'RegisterScreen';
  static const String home = 'HomeScreen';
  static const String chats = 'ChatsScreen';
  static const String chat = 'ChatRoomScreen';
  static const String ai = 'AiScreen';
  static const String vpn = 'VpnScreen';
  static const String profile = 'ProfileScreen';
  static const String settings = 'SettingsScreen';
  static const String onboarding = 'OnboardingScreen';
}

/// 🎯 Storage Keys
class StorageKeys {
  static const String firstLaunch = 'first_launch';
  static const String theme = 'theme';
  static const String language = 'language';
  static const String notifications = 'notifications';
  static const String biometric = 'biometric';
  static const String analytics = 'analytics';
  static const String crashReporting = 'crash_reporting';
}
