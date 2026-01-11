import 'package:flutter/foundation.dart';
import '../../data/models/user.dart';
import '../../data/services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  
  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _errorMessage;

  AuthProvider({required AuthService authService})
      : _authService = authService {
    _checkAuthStatus();
  }

  // Getters
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // Проверка статуса аутентификации при запуске
  Future<void> _checkAuthStatus() async {
    _setStatus(AuthStatus.loading);
    
    try {
      if (_authService.isAuthenticated) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          _currentUser = user;
          _setStatus(AuthStatus.authenticated);
        } else {
          _setStatus(AuthStatus.unauthenticated);
        }
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
      _errorMessage = e.toString();
    }
  }

  // Регистрация
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    List<String>? interests,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        interests: interests,
      );

      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  // Вход
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;

    try {
      final user = await _authService.login(
        email: email,
        password: password,
      );

      _currentUser = user;
      _setStatus(AuthStatus.authenticated);
      return true;
    } catch (e) {
      _setStatus(AuthStatus.unauthenticated);
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    }
  }

  // Выход
  Future<void> logout() async {
    _setStatus(AuthStatus.loading);
    
    try {
      await _authService.logout();
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Обновить данные пользователя
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Восстановление пароля
  Future<bool> resetPassword({required String email}) async {
    _errorMessage = null;
    
    try {
      await _authService.resetPassword(email: email);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Очистить ошибку
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Установить статус
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
