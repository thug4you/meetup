import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/admin_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/user.dart';
import '../../../data/models/meeting.dart';
import '../../providers/auth_provider.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminService _adminService;
  
  // Статистика
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;
  
  // Пользователи
  List<User> _users = [];
  bool _isLoadingUsers = true;
  int _usersTotal = 0;
  int _usersPage = 1;
  final TextEditingController _userSearchController = TextEditingController();
  
  // Встречи
  List<Meeting> _meetings = [];
  bool _isLoadingMeetings = true;
  int _meetingsTotal = 0;
  int _meetingsPage = 1;
  String _meetingsStatusFilter = '';
  final TextEditingController _meetingSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adminService = AdminService(context.read<ApiService>());
    _loadStats();
    _loadUsers();
    _loadMeetings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    _meetingSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _adminService.getStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      // При ошибке показываем нулевую статистику
      setState(() {
        _stats = {
          'users': {'total': 0, 'admins': 0},
          'meetings': {'total': 0, 'active': 0},
          'messages': 0,
          'pendingReports': 0,
        };
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _usersPage = 1;
        _users = [];
      });
    }
    setState(() => _isLoadingUsers = true);
    try {
      final result = await _adminService.getUsers(
        page: _usersPage,
        search: _userSearchController.text,
      );
      setState(() {
        _users = result['users'] as List<User>;
        _usersTotal = result['total'] as int;
        _isLoadingUsers = false;
      });
    } catch (e) {
      // При ошибке показываем пустой список
      setState(() {
        _users = [];
        _usersTotal = 0;
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _loadMeetings({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _meetingsPage = 1;
        _meetings = [];
      });
    }
    setState(() => _isLoadingMeetings = true);
    try {
      final result = await _adminService.getMeetings(
        page: _meetingsPage,
        status: _meetingsStatusFilter,
        search: _meetingSearchController.text,
      );
      setState(() {
        _meetings = result['meetings'] as List<Meeting>;
        _meetingsTotal = result['total'] as int;
        _isLoadingMeetings = false;
      });
    } catch (e) {
      // При ошибке показываем пустой список
      setState(() {
        _meetings = [];
        _meetingsTotal = 0;
        _isLoadingMeetings = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _changeUserRole(User user) async {
    final newRole = user.role == 'admin' ? 'user' : 'admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменить роль'),
        content: Text(
          newRole == 'admin'
              ? 'Назначить ${user.name} администратором?'
              : 'Снять права администратора у ${user.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.updateUserRole(user.id, newRole);
        _showSuccess('Роль пользователя изменена');
        _loadUsers(refresh: true);
        _loadStats();
      } catch (e) {
        _showError('Ошибка: $e');
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить пользователя'),
        content: Text('Вы уверены, что хотите удалить ${user.name}? Это действие необратимо.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteUser(user.id);
        _showSuccess('Пользователь удалён');
        _loadUsers(refresh: true);
        _loadStats();
      } catch (e) {
        _showError('Ошибка: $e');
      }
    }
  }

  Future<void> _changeMeetingStatus(Meeting meeting) async {
    final statuses = ['active', 'cancelled', 'completed', 'pending'];
    final newStatus = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите статус'),
        children: statuses.map((status) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, status),
            child: Row(
              children: [
                Icon(
                  meeting.status == status ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _getStatusColor(status),
                ),
                const SizedBox(width: 12),
                Text(_getStatusText(status)),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (newStatus != null && newStatus != meeting.status) {
      try {
        await _adminService.updateMeetingStatus(meeting.id, newStatus);
        _showSuccess('Статус встречи изменён');
        _loadMeetings(refresh: true);
        _loadStats();
      } catch (e) {
        _showError('Ошибка: $e');
      }
    }
  }

  Future<void> _deleteMeeting(Meeting meeting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить встречу'),
        content: Text('Вы уверены, что хотите удалить "${meeting.title}"? Это действие необратимо.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteMeeting(meeting.id);
        _showSuccess('Встреча удалена');
        _loadMeetings(refresh: true);
        _loadStats();
      } catch (e) {
        _showError('Ошибка: $e');
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Активная';
      case 'cancelled':
        return 'Отменена';
      case 'completed':
        return 'Завершена';
      case 'pending':
        return 'Ожидает';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Обзор'),
            Tab(icon: Icon(Icons.people), text: 'Пользователи'),
            Tab(icon: Icon(Icons.event), text: 'Встречи'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildUsersTab(),
          _buildMeetingsTab(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    final users = _stats?['users'] as Map<String, dynamic>? ?? {'total': 0, 'admins': 0};
    final meetings = _stats?['meetings'] as Map<String, dynamic>? ?? {'total': 0, 'active': 0};

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Пользователей',
                    value: '${users['total']}',
                    subtitle: 'Админов: ${users['admins']}',
                    icon: Icons.people,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Встреч',
                    value: '${meetings['total']}',
                    subtitle: 'Активных: ${meetings['active']}',
                    icon: Icons.event,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Сообщений',
                    value: '${_stats?['messages'] ?? 0}',
                    icon: Icons.message,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Жалобы',
                    value: '${_stats?['pendingReports'] ?? 0}',
                    subtitle: 'На рассмотрении',
                    icon: Icons.report,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Поиск пользователей...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _userSearchController.clear();
                  _loadUsers(refresh: true);
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _loadUsers(refresh: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Всего: $_usersTotal',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadUsers(refresh: true),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Пользователей нет',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _loadUsers(refresh: true),
                            child: const Text('Обновить'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadUsers(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user.isAdmin ? Colors.purple : Colors.blue,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(user.name),
                              if (user.isAdmin) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(user.email),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'role':
                                  _changeUserRole(user);
                                  break;
                                case 'delete':
                                  _deleteUser(user);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'role',
                                child: Row(
                                  children: [
                                    Icon(
                                      user.isAdmin ? Icons.person : Icons.admin_panel_settings,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(user.isAdmin ? 'Снять админа' : 'Назначить админом'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Удалить', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMeetingsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _meetingSearchController,
                  decoration: InputDecoration(
                    hintText: 'Поиск встреч...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _loadMeetings(refresh: true),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                onSelected: (value) {
                  setState(() => _meetingsStatusFilter = value);
                  _loadMeetings(refresh: true);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: '', child: Text('Все')),
                  const PopupMenuItem(value: 'active', child: Text('Активные')),
                  const PopupMenuItem(value: 'completed', child: Text('Завершённые')),
                  const PopupMenuItem(value: 'cancelled', child: Text('Отменённые')),
                  const PopupMenuItem(value: 'pending', child: Text('Ожидающие')),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Всего: $_meetingsTotal${_meetingsStatusFilter.isNotEmpty ? ' (${_getStatusText(_meetingsStatusFilter)})' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadMeetings(refresh: true),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingMeetings
              ? const Center(child: CircularProgressIndicator())
              : _meetings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Встреч нет',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _loadMeetings(refresh: true),
                            child: const Text('Обновить'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadMeetings(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _meetings.length,
                        itemBuilder: (context, index) {
                          final meeting = _meetings[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(meeting.status.name),
                                child: const Icon(Icons.event, color: Colors.white),
                              ),
                              title: Text(meeting.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Статус: ${_getStatusText(meeting.status.name)}',
                                    style: TextStyle(color: _getStatusColor(meeting.status.name)),
                                  ),
                                  if (meeting.organizerName != null)
                                    Text('Организатор: ${meeting.organizerName}'),
                                ],
                              ),
                              isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'status':
                                  _changeMeetingStatus(meeting);
                                  break;
                                case 'delete':
                                  _deleteMeeting(meeting);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'status',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Изменить статус'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Удалить', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
