import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';

class ClosureRepository {
  final ApiProvider apiProvider;
  final StorageProvider storageProvider;

  ClosureRepository({required this.apiProvider, required this.storageProvider});

  Future<Map<String, dynamic>> getDraft(int shopId, String date) async {
    final token = await storageProvider.getToken();
    return Map<String, dynamic>.from(
      await apiProvider.get(
            '/shops/$shopId/closures/today?date=$date',
            token: token,
          )
          as Map,
    );
  }

  Future<Map<String, dynamic>> create(
    int shopId,
    Map<String, dynamic> data,
  ) async {
    final token = await storageProvider.getToken();
    final endpoint = '/shops/$shopId/closures';
    try {
      return Map<String, dynamic>.from(
        await apiProvider.post(endpoint, data, token: token) as Map,
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      await storageProvider.queueOperation(endpoint, data);
      return {'queued': true, 'published': false};
    }
  }
}
