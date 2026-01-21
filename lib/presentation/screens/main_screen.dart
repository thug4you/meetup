import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import 'feed/meetings_feed_screen.dart';
import 'package:flutter_application_1/presentation/screens/meeting/create_meeting_screen.dart';
import 'search/search_screen.dart';
import 'profile/profile_screen.dart';
import 'notifications/notifications_screen.dart';
import '../providers/notification_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Экраны приложения (без CreateMeetingScreen)
  final List<Widget> _screens = [
    const MeetingsFeedScreen(),
    const SearchScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    // Если нажата кнопка "Создать" (индекс 2)
    if (index == 2) {
      _openCreateMeeting();
      return;
    }
    
    // Корректируем индекс после удаления CreateMeetingScreen
    final screenIndex = index > 2 ? index - 1 : index;
    setState(() {
      _currentIndex = screenIndex;
    });
  }

  Future<void> _openCreateMeeting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateMeetingScreen(),
      ),
    );
    
    // Если встреча была создана, обновляем список и переключаемся на главный экран
    if (result == true && mounted) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 1 ? _currentIndex + 1 : _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.event),
            activeIcon: Icon(Icons.event),
            label: 'Встречи',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Поиск',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 32),
            activeIcon: Icon(Icons.add_circle, size: 32),
            label: 'Создать',
          ),
          BottomNavigationBarItem(
            icon: _buildNotificationIcon(false),
            activeIcon: _buildNotificationIcon(true),
            label: 'Уведомления',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(bool isActive) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final unreadCount = provider.unreadCount;
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isActive ? Icons.notifications : Icons.notifications_outlined,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
