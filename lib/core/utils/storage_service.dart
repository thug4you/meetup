import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  late final SharedPreferences _prefs;
  bool _initialized = false;

  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Инициализация
  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Проверка инициализации
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('StorageService не инициализирован. Вызовите init() перед использованием.');
    }
  }

  // Сохранить строку
  Future<bool> setString(String key, String value) async {
    _ensureInitialized();
    return await _prefs.setString(key, value);
  }

  // Получить строку
  String? getString(String key) {
    _ensureInitialized();
    return _prefs.getString(key);
  }

  // Сохранить int
  Future<bool> setInt(String key, int value) async {
    _ensureInitialized();
    return await _prefs.setInt(key, value);
  }

  // Получить int
  int? getInt(String key) {
    _ensureInitialized();
    return _prefs.getInt(key);
  }

  // Сохранить bool
  Future<bool> setBool(String key, bool value) async {
    _ensureInitialized();
    return await _prefs.setBool(key, value);
  }

  // Получить bool
  bool? getBool(String key) {
    _ensureInitialized();
    return _prefs.getBool(key);
  }

  // Сохранить список строк
  Future<bool> setStringList(String key, List<String> value) async {
    _ensureInitialized();
    return await _prefs.setStringList(key, value);
  }

  // Получить список строк
  List<String>? getStringList(String key) {
    _ensureInitialized();
    return _prefs.getStringList(key);
  }

  // Удалить значение
  Future<bool> remove(String key) async {
    _ensureInitialized();
    return await _prefs.remove(key);
  }

  // Очистить всё
  Future<bool> clear() async {
    _ensureInitialized();
    return await _prefs.clear();
  }

  // Проверить наличие ключа
  bool containsKey(String key) {
    _ensureInitialized();
    return _prefs.containsKey(key);
  }

  // Получить все ключи
  Set<String> getKeys() {
    _ensureInitialized();
    return _prefs.getKeys();
  }
}
