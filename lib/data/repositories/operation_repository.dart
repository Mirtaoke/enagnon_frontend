import '../models/operation_model.dart';
import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';

class OperationRepository {
  final ApiProvider apiProvider;
  final StorageProvider storageProvider;
  OperationRepository({
    ApiProvider? apiProvider,
    StorageProvider? storageProvider,
  }) : apiProvider = apiProvider ?? ApiProvider(),
       storageProvider = storageProvider ?? StorageProvider();

  Future<List<OperationModel>> list(
    int shopId, {
    String? service,
    String? date,
  }) async {
    final query = <String>[
      if (service != null) 'service=$service',
      if (date != null) 'date=$date',
    ].join('&');
    final token = await storageProvider.getToken();
    final response = await apiProvider.get(
      '/shops/$shopId/operations${query.isEmpty ? '' : '?$query'}',
      token: token,
    );
    if (response is! Map || response['operations'] is! List) return const [];
    return (response['operations'] as List)
        .whereType<Map>()
        .map((item) => OperationModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> summary(int shopId, String date) async {
    final token = await storageProvider.getToken();
    return Map<String, dynamic>.from(
      await apiProvider.get(
            '/shops/$shopId/operations-summary?date=$date',
            token: token,
          )
          as Map,
    );
  }

  Future<bool> create(int shopId, Map<String, dynamic> data) async {
    final endpoint = '/shops/$shopId/operations';
    final token = await storageProvider.getToken();
    try {
      await apiProvider.post(endpoint, data, token: token);
      return false;
    } on ApiException {
      rethrow;
    } catch (_) {
      await storageProvider.queueOperation(endpoint, data);
      return true;
    }
  }

  Future<void> update(
    int shopId,
    int operationId,
    Map<String, dynamic> data,
  ) async {
    final token = await storageProvider.getToken();
    await apiProvider.put(
      '/shops/$shopId/operations/$operationId',
      data,
      token: token,
    );
  }

  Future<void> delete(int shopId, int operationId) async {
    final token = await storageProvider.getToken();
    await apiProvider.delete(
      '/shops/$shopId/operations/$operationId',
      token: token,
    );
  }
}
