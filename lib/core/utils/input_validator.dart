class InputValidator {
  // XSS защита - удаление опасных символов и тегов
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
    // Удаляем HTML теги
    String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Экранируем специальные символы
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
    
    return sanitized.trim();
  }

  // Валидация email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Валидация телефона
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  // Валидация URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Проверка на недопустимые слова (базовая реализация)
  static bool containsProfanity(String text) {
    final profanityWords = [
      // Добавьте сюда недопустимые слова для вашего приложения
      // Пример заглушки
    ];
    
    final lowerText = text.toLowerCase();
    return profanityWords.any((word) => lowerText.contains(word));
  }

  // Валидация длины строки
  static bool isValidLength(String text, {int min = 0, int max = 1000}) {
    final length = text.trim().length;
    return length >= min && length <= max;
  }

  // Проверка на SQL injection паттерны
  static bool containsSqlInjection(String input) {
    final sqlPatterns = [
      RegExp(r"('\s*(or|and)\s*')", caseSensitive: false),
      RegExp(r'(\bselect\b|\binsert\b|\bupdate\b|\bdelete\b|\bdrop\b|\bunion\b)', caseSensitive: false),
      RegExp(r'(--|;|/\*|\*/)', caseSensitive: false),
    ];
    
    return sqlPatterns.any((pattern) => pattern.hasMatch(input));
  }

  // Проверка на script injection
  static bool containsScriptInjection(String input) {
    final scriptPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'onerror\s*=', caseSensitive: false),
      RegExp(r'onload\s*=', caseSensitive: false),
    ];
    
    return scriptPatterns.any((pattern) => pattern.hasMatch(input));
  }

  // Комплексная валидация текстового ввода
  static String? validateTextInput(
    String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 1000,
    bool checkXss = true,
    bool checkProfanity = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName не может быть пустым';
    }

    if (!isValidLength(value, min: minLength, max: maxLength)) {
      return '$fieldName должен содержать от $minLength до $maxLength символов';
    }

    if (checkXss) {
      if (containsScriptInjection(value)) {
        return 'Недопустимые символы в поле $fieldName';
      }
      if (containsSqlInjection(value)) {
        return 'Недопустимые символы в поле $fieldName';
      }
    }

    if (checkProfanity && containsProfanity(value)) {
      return '$fieldName содержит недопустимые слова';
    }

    return null;
  }

  // Валидация email поля
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email не может быть пустым';
    }

    if (!isValidEmail(value)) {
      return 'Введите корректный email';
    }

    return null;
  }

  // Валидация пароля
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Пароль не может быть пустым';
    }

    if (value.length < minLength) {
      return 'Пароль должен содержать минимум $minLength символов';
    }

    return null;
  }

  // Валидация телефона
  static String? validatePhone(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Телефон не может быть пустым' : null;
    }

    if (!isValidPhone(value)) {
      return 'Введите корректный номер телефона';
    }

    return null;
  }
}
