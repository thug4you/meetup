import 'package:flutter/foundation.dart';
import '../../data/models/meeting.dart';
import '../../data/services/meeting_service.dart';

class MeetingProvider extends ChangeNotifier {
  final MeetingService _meetingService;

  MeetingProvider(this._meetingService);

  final List<Meeting> _meetings = [];
  List<Meeting> get meetings => _meetings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Фильтры
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  double? _radius;
  double? get radius => _radius;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // Загрузка встреч
  Future<void> loadMeetings({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _meetings.clear();
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newMeetings = await _meetingService.getMeetings(
        category: _selectedCategory,
        startDate: _startDate,
        endDate: _endDate,
        radius: _radius,
        page: _currentPage,
      );

      if (newMeetings.isEmpty) {
        _hasMore = false;
      } else {
        _meetings.addAll(newMeetings);
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Установить фильтр по категории
  void setCategory(String? category) {
    _selectedCategory = category;
    loadMeetings(refresh: true);
  }

  // Установить фильтр по дате
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    loadMeetings(refresh: true);
  }

  // Установить радиус поиска
  void setRadius(double? radius) {
    _radius = radius;
    loadMeetings(refresh: true);
  }

  // Очистить все фильтры
  void clearFilters() {
    _selectedCategory = null;
    _startDate = null;
    _endDate = null;
    _radius = null;
    loadMeetings(refresh: true);
  }

  // Присоединиться к встрече
  Future<bool> joinMeeting(String meetingId) async {
    try {
      final updatedMeeting = await _meetingService.joinMeeting(meetingId);
      
      // Обновить встречу в списке
      final index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        _meetings[index] = updatedMeeting;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Покинуть встречу
  Future<bool> leaveMeeting(String meetingId) async {
    try {
      final updatedMeeting = await _meetingService.leaveMeeting(meetingId);
      
      // Обновить встречу в списке
      final index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        _meetings[index] = updatedMeeting;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Сохранить в избранное
  Future<bool> saveMeeting(String meetingId) async {
    try {
      await _meetingService.saveMeeting(meetingId);
      
      // Обновить состояние встречи
      final index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        // В реальном API должен возвращаться обновлённый объект
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Удалить встречу
  Future<bool> deleteMeeting(String meetingId) async {
    try {
      await _meetingService.deleteMeeting(meetingId);
      
      // Удалить из списка
      _meetings.removeWhere((m) => m.id == meetingId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
