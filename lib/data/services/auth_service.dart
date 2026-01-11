import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthService {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthService({
    required ApiService apiService,
    required SharedPreferences prefs,
  })  : _apiService = apiService,
        _prefs = prefs;

  // Получить токен
  String? get token => _prefs.getString(AppConstants.tokenKey);

  // Проверить авторизацию
  bool get isAuthenticated => token != null;

  // Сохранить токен
  Future<void> _saveToken(String token) async {
    await _prefs.setString(AppConstants.tokenKey, token);
    _apiService.setAuthToken(token);
  }

  // Сохранить refresh token
  Future<void> _saveRefreshToken(String refreshToken) async {
    await _prefs.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  // Сохранить данные пользователя
  Future<void> _saveUserData(User user) async {
    await _prefs.setString(AppConstants.userIdKey, user.id);
    await _prefs.setString(AppConstants.userDataKey, user.toJson().toString());
  }

  // Регистрация
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    List<String>? interests,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
          if (interests != null) 'interests': interests,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Сохраняем токены
        if (data.containsKey('token')) {
          await _saveToken(data['token'] as String);
        }
        if (data.containsKey('refreshToken')) {
          await _saveRefreshToken(data['refreshToken'] as String);
        }

        // Сохраняем пользователя
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await _saveUserData(user);

        return user;
      } else {
        throw Exception('Ошибка регистрации: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Ошибка регистрации: $e');
    }
  }

  // Вход
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Сохраняем токены
        if (data.containsKey('token')) {
          await _saveToken(data['token'] as String);
        }
        if (data.containsKey('refreshToken')) {
          await _saveRefreshToken(data['refreshToken'] as String);
        }

        // Сохраняем пользователя
        final user = User.fromJson(data['user'] as Map<String, dynamic>);
        await _saveUserData(user);

        return user;
      } else {
        throw Exception('Неверный email или пароль');
      }
    } catch (e) {
      throw Exception('Ошибка входа: $e');
    }
  }

  // Выход
  Future<void> logout() async {
    try {
      // Отправляем запрос на сервер для инвалидации токена
      if (token != null) {
        await _apiService.post('/auth/logout');
      }
    } catch (e) {
      // Игнорируем ошибки при выходе
    } finally {
      // Очищаем локальные данные
      await _prefs.remove(AppConstants.tokenKey);
      await _prefs.remove(AppConstants.refreshTokenKey);
      await _prefs.remove(AppConstants.userIdKey);
      await _prefs.remove(AppConstants.userDataKey);
      _apiService.setAuthToken(null);
    }
  }

  // Обновить токен
  Future<void> refreshToken() async {
    try {
      final refreshToken = _prefs.getString(AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        throw Exception('Нет refresh токена');
      }

      final response = await _apiService.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('token')) {
          await _saveToken(data['token'] as String);
        }
      } else {
        throw Exception('Не удалось обновить токен');
      }
    } catch (e) {
      // Если не удалось обновить токен, выходим
      await logout();
      throw Exception('Сессия истекла. Войдите снова.');
    }
  }

  // Получить текущего пользователя
  Future<User?> getCurrentUser() async {
    try {
      final userId = _prefs.getString(AppConstants.userIdKey);
      if (userId == null) return null;

      final response = await _apiService.get('/users/$userId');
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data as Map<String, dynamic>);
        await _saveUserData(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Восстановление пароля
  Future<void> resetPassword({required String email}) async {
    try {
      final response = await _apiService.post(
        '/auth/reset-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw Exception('Не удалось отправить письмо для восстановления');
      }
    } catch (e) {
      throw Exception('Ошибка восстановления пароля: $e');
    }
  }

  // Проверка email
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _apiService.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );
      return response.data['exists'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
