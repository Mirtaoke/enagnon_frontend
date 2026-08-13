import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';

class AttendanceRepository {
  final ApiProvider apiProvider;
  final StorageProvider storageProvider;
  AttendanceRepository({
    ApiProvider? apiProvider,
    StorageProvider? storageProvider,
  }) : apiProvider = apiProvider ?? ApiProvider(),
       storageProvider = storageProvider ?? StorageProvider();

  Future<Map<String, dynamic>> today() => _get('/attendance/today');
  Future<Map<String, dynamic>> checkIn() => _post('/attendance/check-in');
  Future<Map<String, dynamic>> checkOut() => _post('/attendance/check-out');

  Future<Map<String, dynamic>> _get(String endpoint) async {
    final token = await storageProvider.getToken();
    return Map<String, dynamic>.from(
      await apiProvider.get(endpoint, token: token) as Map,
    );
  }

  Future<Map<String, dynamic>> _post(String endpoint) async {
    final token = await storageProvider.getToken();
    return Map<String, dynamic>.from(
      await apiProvider.post(endpoint, {}, token: token) as Map,
    );
  }
}
