class CacheManager {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final Duration defaultTtl;

  // Сохранить в кеш
  void put(String key, dynamic value, {Duration? ttl}) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  // Получить из кеша
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;

    final timestamp = _timestamps[key];
    if (timestamp != null) {
      final age = DateTime.now().difference(timestamp);
      if (age > defaultTtl) {
        remove(key);
        return null;
      }
    }

    return _cache[key] as T?;
  }

  // Проверить наличие в кеше
  bool contains(String key) {
    return _cache.containsKey(key) && get(key) != null;
  }

  // Удалить из кеша
  void remove(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
  }

  // Очистить весь кеш
  void clear() {
    _cache.clear();
    _timestamps.clear();
  }

  // Очистить устаревшие записи
  void clearExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _timestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > defaultTtl) {
        expiredKeys.add(key);
      }
    });

    for (var key in expiredKeys) {
      remove(key);
    }
  }

  // Получить размер кеша
  int get size => _cache.length;

  // Singleton pattern
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal() : defaultTtl = const Duration(minutes: 5);
}
