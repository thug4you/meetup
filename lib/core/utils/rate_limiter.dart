class RateLimiter {
  final Map<String, List<DateTime>> _requestTimestamps = {};
  final int maxRequests;
  final Duration window;

  // Singleton pattern
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal()
      : maxRequests = 10,
        window = const Duration(minutes: 1);

  // Проверить, можно ли выполнить запрос
  bool canMakeRequest(String key) {
    final now = DateTime.now();
    final timestamps = _requestTimestamps[key] ?? [];

    // Удаляем старые записи за пределами окна
    timestamps.removeWhere((timestamp) => now.difference(timestamp) > window);

    // Проверяем лимит
    if (timestamps.length >= maxRequests) {
      return false;
    }

    // Добавляем новую запись
    timestamps.add(now);
    _requestTimestamps[key] = timestamps;

    return true;
  }

  // Получить время до следующего доступного запроса
  Duration? getTimeUntilNextRequest(String key) {
    final timestamps = _requestTimestamps[key];
    if (timestamps == null || timestamps.isEmpty) {
      return null;
    }

    final now = DateTime.now();
    final oldestTimestamp = timestamps.first;
    final elapsed = now.difference(oldestTimestamp);

    if (elapsed < window) {
      return window - elapsed;
    }

    return null;
  }

  // Очистить записи для ключа
  void clearKey(String key) {
    _requestTimestamps.remove(key);
  }

  // Очистить все записи
  void clearAll() {
    _requestTimestamps.clear();
  }
}
