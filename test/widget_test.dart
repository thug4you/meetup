import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/data/services/api_service.dart';
import 'package:flutter_application_1/data/services/auth_service.dart';
import 'package:flutter_application_1/data/services/meeting_service.dart';
import 'package:flutter_application_1/data/services/user_service.dart';
import 'package:flutter_application_1/data/services/notification_service.dart';
import 'package:flutter_application_1/data/models/user.dart';
import 'package:flutter_application_1/data/models/meeting.dart';
import 'package:flutter_application_1/core/utils/input_validator.dart';
import 'package:flutter_application_1/core/utils/responsive.dart';

void main() {
  group('App Tests', () {
    testWidgets('App loads correctly', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      final apiService = ApiService();
      final authService = AuthService(
        apiService: apiService,
        prefs: prefs,
      );
      final meetingService = MeetingService(apiService);
      final userService = UserService(apiService);
      final notificationService = NotificationService(apiService);

      await tester.pumpWidget(MyApp(
        authService: authService,
        meetingService: meetingService,
        userService: userService,
        notificationService: notificationService,
      ));

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Model Tests', () {
    test('User model serialization', () {
      final user = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = user.toJson();
      final userFromJson = User.fromJson(json);

      expect(userFromJson.id, user.id);
      expect(userFromJson.name, user.name);
      expect(userFromJson.email, user.email);
    });

    test('Meeting model serialization', () {
      final meeting = Meeting(
        id: '1',
        title: 'Test Meeting',
        description: 'Test Description',
        category: 'Спорт',
        dateTime: DateTime(2024, 12, 31, 15, 0),
        maxParticipants: 10,
        currentParticipants: 5,
        createdBy: User(
          id: '1',
          name: 'Creator',
          email: 'creator@example.com',
          createdAt: DateTime.now(),
        ),
        createdAt: DateTime.now(),
      );

      final json = meeting.toJson();
      final meetingFromJson = Meeting.fromJson(json);

      expect(meetingFromJson.id, meeting.id);
      expect(meetingFromJson.title, meeting.title);
      expect(meetingFromJson.category, meeting.category);
    });
  });

  group('Validator Tests', () {
    test('Email validation', () {
      expect(InputValidator.isValidEmail('test@example.com'), true);
      expect(InputValidator.isValidEmail('invalid-email'), false);
      expect(InputValidator.isValidEmail('test@'), false);
      expect(InputValidator.isValidEmail('@example.com'), false);
    });

    test('Phone validation', () {
      expect(InputValidator.isValidPhone('+79123456789'), true);
      expect(InputValidator.isValidPhone('79123456789'), true);
      expect(InputValidator.isValidPhone('123'), false);
    });

    test('XSS protection', () {
      final maliciousInput = '<script>alert("XSS")</script>';
      final sanitized = InputValidator.sanitizeInput(maliciousInput);
      expect(sanitized.contains('<script>'), false);
      expect(sanitized.contains('&lt;'), true);
    });

    test('SQL injection detection', () {
      expect(InputValidator.containsSqlInjection("' OR '1'='1"), true);
      expect(InputValidator.containsSqlInjection('SELECT * FROM users'), true);
      expect(InputValidator.containsSqlInjection('Normal text'), false);
    });

    test('Text input validation', () {
      expect(
        InputValidator.validateTextInput(
          'Valid text',
          fieldName: 'Test',
          minLength: 5,
          maxLength: 20,
        ),
        null,
      );

      expect(
        InputValidator.validateTextInput(
          'Hi',
          fieldName: 'Test',
          minLength: 5,
        ),
        isNotNull,
      );
    });
  });

  group('Responsive Tests', () {
    testWidgets('Responsive breakpoints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Simulate mobile width
              return MediaQuery(
                data: const MediaQueryData(size: Size(400, 800)),
                child: Builder(
                  builder: (context) {
                    expect(Responsive.isMobile(context), true);
                    expect(Responsive.isTablet(context), false);
                    expect(Responsive.isDesktop(context), false);
                    return Container();
                  },
                ),
              );
            },
          ),
        ),
      );
    });

    testWidgets('ResponsiveBuilder works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            builder: (context, deviceType) {
              return Text(deviceType.toString());
            },
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('Cache Manager Tests', () {
    test('Cache put and get', () {
      final cache = CacheManager();
      cache.clear();

      cache.put('key1', 'value1');
      expect(cache.get<String>('key1'), 'value1');
      expect(cache.contains('key1'), true);
    });

    test('Cache expiration', () async {
      final cache = CacheManager(defaultTtl: const Duration(milliseconds: 100));
      cache.clear();

      cache.put('key1', 'value1');
      await Future.delayed(const Duration(milliseconds: 150));
      expect(cache.get<String>('key1'), null);
    });

    test('Cache remove', () {
      final cache = CacheManager();
      cache.clear();

      cache.put('key1', 'value1');
      cache.remove('key1');
      expect(cache.contains('key1'), false);
    });
  });
}

