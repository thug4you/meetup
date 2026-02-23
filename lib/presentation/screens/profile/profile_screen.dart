import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user.dart';
import '../../../data/models/meeting.dart';
import '../../../data/services/user_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/meeting_card.dart';
import '../meeting/meeting_detail_screen.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late UserService _userService;
  
  User? _user;
  List<Meeting> _createdMeetings = [];
  List<Meeting> _joinedMeetings = [];
  
  bool _isLoading = true;
  bool _isLoadingCreated = false;
  bool _isLoadingJoined = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _userService = UserService(context.read());
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем данные каждый раз при возврате на экран
    if (mounted && !_isLoading) {
      _refreshProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
      
      // Загружаем встречи
      _loadCreatedMeetings();
      _loadJoinedMeetings();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCreatedMeetings() async {
    if (_user == null) return;
    
    setState(() => _isLoadingCreated = true);
    
    try {
      final meetings = await _userService.getCreatedMeetings(_user!.id);
      setState(() {
        _createdMeetings = meetings;
        _isLoadingCreated = false;
      });
    } catch (e) {
      setState(() => _isLoadingCreated = false);
    }
  }

  Future<void> _loadJoinedMeetings() async {
    if (_user == null) return;
    
    setState(() => _isLoadingJoined = true);
    
    try {
      final meetings = await _userService.getJoinedMeetings(_user!.id);
      setState(() {
        _joinedMeetings = meetings;
        _isLoadingJoined = false;
      });
    } catch (e) {
      setState(() => _isLoadingJoined = false);
    }
  }

  Future<void> _refreshProfile() async {
    // Тихое обновление без показа загрузки
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) {
        setState(() => _user = user);
      }
      _loadCreatedMeetings();
      _loadJoinedMeetings();
    } catch (e) {
      // Игнорируем ошибки при фоновом обновлении
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Для AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: Открыть экран настроек
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Настройки - в разработке')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _user != null
                  ? _buildProfile()
                  : const SizedBox(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки профиля',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Column(
      children: [
        // Информация о пользователе
        Container(
          color: AppTheme.surfaceColor,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Аватар
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: _user!.avatarUrl != null
                    ? NetworkImage(_user!.avatarUrl!)
                    : null,
                child: _user!.avatarUrl == null
                    ? Text(
                        _user!.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              
              const SizedBox(height: 16),
              
              // Имя
              Text(
                _user!.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              
              const SizedBox(height: 4),
              
              // Email
              Text(
                _user!.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
              
              if (_user!.phone != null && _user!.phone!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _user!.phone!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Кнопка редактирования
              OutlinedButton.icon(
                onPressed: () async {
                  final updatedUser = await Navigator.push<User>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(user: _user!),
                    ),
                  );
                  
                  if (updatedUser != null) {
                    setState(() {
                      _user = updatedUser;
                    });
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Редактировать профиль'),
              ),
              
              // Интересы
              if (_user!.interests.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Интересы',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _user!.interests.map((interest) {
                    return Chip(
                      label: Text(interest),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      labelStyle: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        
        // Табы
        Container(
          color: AppTheme.surfaceColor,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondaryColor,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Созданные'),
              Tab(text: 'Участвую'),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Содержимое табов
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCreatedMeetings(),
              _buildJoinedMeetings(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreatedMeetings() {
    if (_isLoadingCreated) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_createdMeetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет созданных встреч',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте свою первую встречу',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCreatedMeetings,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _createdMeetings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final meeting = _createdMeetings[index];
          return MeetingCard(
            meeting: meeting,
            currentUserId: _user?.id,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingDetailScreen(
                    meetingId: meeting.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJoinedMeetings() {
    if (_isLoadingJoined) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_joinedMeetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Вы не участвуете во встречах',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Найдите интересные встречи в ленте',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJoinedMeetings,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _joinedMeetings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final meeting = _joinedMeetings[index];
          return MeetingCard(
            meeting: meeting,
            currentUserId: _user?.id,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingDetailScreen(
                    meetingId: meeting.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
