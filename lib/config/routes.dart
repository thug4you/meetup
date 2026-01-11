import 'package:flutter/material.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String meetingDetail = '/meeting/detail';
  static const String createMeeting = '/meeting/create';
  static const String editMeeting = '/meeting/edit';
  static const String meetingChat = '/meeting/chat';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String search = '/search';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  
  // Route generator (будет реализован позже)
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // case splash:
      //   return MaterialPageRoute(builder: (_) => SplashScreen());
      // case login:
      //   return MaterialPageRoute(builder: (_) => LoginScreen());
      // ... другие роуты
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} не найден'),
            ),
          ),
        );
    }
  }
}
