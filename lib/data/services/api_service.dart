import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/rate_limiter.dart';

class ApiService {
  late final Dio _dio;
  String? _authToken;
  final RateLimiter _rateLimiter = RateLimiter();
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Interceptors для логирования и обработки ошибок
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Проверка rate limiting
        final key = '${options.method}:${options.path}';
        if (!_rateLimiter.canMakeRequest(key)) {
          final waitTime = _rateLimiter.getTimeUntilNextRequest(key);
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.unknown,
              error: 'Слишком много запросов. Подождите ${waitTime?.inSeconds ?? 0} секунд',
            ),
          );
        }
        
        // Добавляем токен если есть
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        print('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('ERROR[${error.response?.statusCode}] => MESSAGE: ${error.message}');
        return handler.next(error);
      },
    ));
  }
  
  // Сеттер для токена
  void setAuthToken(String? token) {
    _authToken = token;
  }
  
  // Геттер для токена (нужен для WebSocket авторизации)
  Future<String?> getAuthToken() async {
    return _authToken;
  }
  
  // GET запрос
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // POST запрос
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PUT запрос
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // PATCH запрос
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // DELETE запрос
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Обработка ошибок
  Exception _handleError(DioException error) {
    String errorMessage = 'Произошла ошибка';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Превышено время ожидания. Проверьте подключение к интернету';
        break;
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null) {
          switch (statusCode) {
            case 400:
              errorMessage = error.response?.data['message'] ?? 'Неверный запрос';
              break;
            case 401:
              errorMessage = 'Необходима авторизация';
              break;
            case 403:
              errorMessage = 'Доступ запрещён';
              break;
            case 404:
              errorMessage = 'Ресурс не найден';
              break;
            case 429:
              errorMessage = 'Слишком много запросов. Попробуйте позже';
              break;
            case 500:
            case 502:
            case 503:
              errorMessage = 'Ошибка сервера. Попробуйте позже';
              break;
            default:
              errorMessage = error.response?.data['message'] ?? 'Ошибка сервера';
          }
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Запрос отменён';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Нет подключения к интернету';
        break;
      case DioExceptionType.unknown:
        if (error.error.toString().contains('SocketException')) {
          errorMessage = 'Не удалось подключиться к серверу';
        } else {
          errorMessage = error.error?.toString() ?? 'Неизвестная ошибка';
        }
        break;
      default:
        errorMessage = 'Неизвестная ошибка';
    }

    return Exception(errorMessage);
  }
}
