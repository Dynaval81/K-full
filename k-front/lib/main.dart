import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:knoty/core/constants.dart';
import 'package:knoty/core/constants/app_constants.dart';
import 'package:knoty/core/controllers/auth_controller.dart';
import 'package:knoty/core/controllers/chat_controller.dart';
import 'package:knoty/core/controllers/tab_visibility_controller.dart';
import 'package:knoty/core/controllers/swipe_lock_controller.dart';
import 'package:knoty/presentation/screens/auth/login_screen.dart';
import 'package:knoty/presentation/screens/auth/register_screen.dart' as reg_screen;
import 'package:knoty/presentation/screens/auth/registration_success_screen.dart';
import 'package:knoty/presentation/screens/auth/email_verification_screen.dart';
import 'package:knoty/presentation/screens/chat/chat_room_screen.dart';
import 'package:knoty/presentation/screens/settings_screen.dart';
import 'package:knoty/presentation/screens/splash_screen.dart';
import 'package:knoty/presentation/widgets/airy_button.dart';
import 'package:knoty/presentation/widgets/organisms/main_nav_shell.dart';
import 'package:knoty/data/models/chat_room.dart';
import 'package:knoty/providers/user_provider.dart';
import 'package:knoty/theme_provider.dart';
import 'package:knoty/theme/app_theme.dart';
import 'package:knoty/locale_provider.dart';
import 'l10n/app_localizations.dart';
import 'package:knoty/core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.instance.init();

  final userProvider = UserProvider();
  final chatController = ChatController();

  final authController = AuthController(
    onUserLoaded: (user) { if (user != null) userProvider.setUser(user); },
    onMatrixUserIdLoaded: (matrixUserId) {
      chatController.updateUserId(matrixUserId);
    },
  );

  await authController.tryRestoreSession();

  final initialLocation = authController.isAuthenticated
      ? AppRoutes.home
      : AppRoutes.splash;

  final themeProvider = ThemeProvider();
  await themeProvider.initializeTheme();

  final localeProvider = LocaleProvider();
  await localeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: chatController),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => TabVisibilityController()..load()),
        ChangeNotifierProvider(create: (_) => SwipeLockController()),
      ],
      child: KnotyApp(initialLocation: initialLocation, authController: authController),
    ),
  );
}

class KnotyApp extends StatefulWidget {
  final String initialLocation;
  final AuthController authController;

  const KnotyApp({super.key, required this.initialLocation, required this.authController});

  @override
  State<KnotyApp> createState() => _KnotyAppState();
}

class _KnotyAppState extends State<KnotyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: widget.initialLocation,
      refreshListenable: widget.authController,
      redirect: (context, state) {
        final auth = widget.authController;
        if (auth.isRestoringSession) return null;
        final isAuth = auth.isAuthenticated;
        const publicPaths = {'/splash', '/auth', '/register', '/verify-email', '/register-success'};
        final isPublic = publicPaths.contains(state.matchedLocation);
        if (!isAuth && !isPublic) return AppRoutes.auth;
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          pageBuilder: (context, state) => const CupertinoPage<void>(child: SplashScreen()),
        ),
        GoRoute(
          path: AppRoutes.auth,
          pageBuilder: (context, state) => const CupertinoPage<void>(child: LoginScreen()),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => CupertinoPage<void>(child: reg_screen.RegisterScreen()),
        ),
        GoRoute(
          path: '/verify-email',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CupertinoPage<void>(child: EmailVerificationScreen(
              email: extra['email']?.toString() ?? '',
              nickname: extra['nickname']?.toString() ?? '',
              knotyNumber: extra['knotyNumber']?.toString() ?? '',
            ));
          },
        ),
        GoRoute(
          path: '/register-success',
          pageBuilder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CupertinoPage<void>(child: RegistrationSuccessScreen(
              nickname: extra['nickname']?.toString() ?? '',
              knotyNumber: extra['knotyNumber']?.toString() ?? '',
            ));
          },
        ),
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => CupertinoPage<void>(child: MainNavShell()),
        ),
        GoRoute(
          path: '${AppRoutes.chat}/:chatId',
          pageBuilder: (context, state) {
            final chatId = state.pathParameters['chatId']!;
            return CupertinoPage<void>(child: _ChatScreen(chatId: chatId));
          },
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => const CupertinoPage<void>(child: SettingsScreen()),
        ),
      ],
      errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp.router(
      routerConfig: _router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Тёмная тема отключена до MVP
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: localeProvider.locale,
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Fehler',
          style: TextStyle(
            color: AppColors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: AppSpacing.buttonPadding),
            Text(
              'Etwas ist schiefgelaufen',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.inputPadding),
            Text(
              error?.toString() ?? 'Unbekannter Fehler',
              style: AppTextStyles.body.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.buttonPadding * 3),
            AiryButton(
              text: 'Zur Anmeldung',
              onPressed: () => context.go(AppRoutes.auth),
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatScreen extends StatelessWidget {
  final String chatId;

  const _ChatScreen({required this.chatId});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ChatController>();
    ChatRoom? room;
    try {
      room = controller.chatRooms.firstWhere((r) => r.id == chatId);
    } catch (_) {}
    if (room == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: AppBar(title: Text('Chat $chatId')),
        body: const Center(child: Text('Chat nicht gefunden')),
      );
    }
    return ChatRoomScreen(chat: room);
  }
}