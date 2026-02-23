import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage_service.dart';
import 'data/services/api_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/meeting_service.dart';
import 'data/services/user_service.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/meeting_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/main_screen.dart';

import 'presentation/screens/admin/admin_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация локализации для дат
  await initializeDateFormatting('ru_RU', null);
  
  // Инициализация storage
  final storageService = StorageService();
  await storageService.init();
  
  // Получаем SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Создаем сервисы
  final apiService = ApiService();
  
  // Восстанавливаем токен из хранилища если есть
  final savedToken = prefs.getString('auth_token');
  if (savedToken != null) {
    apiService.setAuthToken(savedToken);
  }
  
  final authService = AuthService(
    apiService: apiService,
    prefs: prefs,
  );
  final meetingService = MeetingService(apiService);
  final userService = UserService(apiService);
  final notificationService = NotificationService(apiService);
  
  runApp(MyApp(
    apiService: apiService,
    authService: authService,
    meetingService: meetingService,
    userService: userService,
    notificationService: notificationService,
  ));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  final AuthService authService;
  final MeetingService meetingService;
  final UserService userService;
  final NotificationService notificationService;
  
  const MyApp({
    super.key,
    required this.apiService,
    required this.authService,
    required this.meetingService,
    required this.userService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<UserService>.value(value: userService),
        Provider<MeetingService>.value(value: meetingService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProvider(
          create: (_) => MeetingProvider(meetingService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'MeetUp',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: _getInitialScreen(authProvider),
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/main': (context) => const MainScreen(),
              '/admin': (context) => const AdminPanelScreen(),
            },
          );
        },
      ),
    );
  }

  Widget _getInitialScreen(AuthProvider authProvider) {
    switch (authProvider.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        return const SplashScreen();
      case AuthStatus.authenticated:
        // Если пользователь админ - показываем админ-панель
        if (authProvider.currentUser?.isAdmin == true) {
          return const AdminPanelScreen();
        }
        return const MainScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
