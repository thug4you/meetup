import '../models/report.dart';
import 'api_service.dart';

class ReportService {
  final ApiService _apiService;

  ReportService(this._apiService);

  // Отправить жалобу
  Future<void> submitReport({
    required ReportType type,
    required ReportReason reason,
    required String description,
    required String targetId,
  }) async {
    try {
      await _apiService.post(
        '/reports',
        data: {
          'type': type.toString().split('.').last,
          'reason': reason.toString().split('.').last,
          'description': description,
          'targetId': targetId,
        },
      );
    } catch (e) {
      print('Ошибка отправки жалобы: $e');
      rethrow;
    }
  }

  // Получить историю жалоб пользователя
  Future<List<Report>> getUserReports({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get(
        '/reports/my-reports',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.data != null && response.data is List) {
        return (response.data as List)
            .map((json) => Report.fromJson(json))
            .toList();
      }

      return [];
    } catch (e) {
      print('Ошибка загрузки жалоб: $e');
      rethrow;
    }
  }

  // Отменить жалобу
  Future<void> cancelReport(String reportId) async {
    try {
      await _apiService.delete('/reports/$reportId');
    } catch (e) {
      print('Ошибка отмены жалобы: $e');
      rethrow;
    }
  }
}
