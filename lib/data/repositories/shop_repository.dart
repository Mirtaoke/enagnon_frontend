import '../models/shop_model.dart';
import '../models/employee_model.dart';
import '../models/report_model.dart';
import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';

class ShopRepository {
  final ApiProvider apiProvider;
  final StorageProvider storageProvider;

  ShopRepository({required this.apiProvider, required this.storageProvider});

  Future<Map<String, dynamic>> getSummary({
    String? month,
    String chartPeriod = 'day',
  }) async {
    final token = await storageProvider.getToken();
    final query = <String>[
      if (month != null) 'month=$month',
      'chart_period=$chartPeriod',
    ].join('&');
    final data = Map<String, dynamic>.from(
      await apiProvider.get(
            '/summary${query.isEmpty ? '' : '?$query'}',
            token: token,
          )
          as Map,
    );
    data['shops'] = (data['shops'] as List? ?? const [])
        .map((item) => Shop.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    return data;
  }

  Future<List<Shop>> getAllShops() async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.get('/shops', token: token);
    final shops = (response['shops'] as List)
        .map((e) => Shop.fromJson(e))
        .toList();
    return shops;
  }

  Future<Shop> addShop(Map<String, dynamic> data) async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.post('/shops', data, token: token);
    return Shop.fromJson(Map<String, dynamic>.from(response['shop'] as Map));
  }

  Future<Shop> updateShop(int shopId, Map<String, dynamic> data) async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.put(
      '/shops/$shopId',
      data,
      token: token,
    );
    return Shop.fromJson(Map<String, dynamic>.from(response['shop'] as Map));
  }

  Future<void> deleteShop(int shopId) async {
    final token = await storageProvider.getToken();
    await apiProvider.delete('/shops/$shopId', token: token);
  }

  Future<Map<String, dynamic>> getShopDetail(int shopId) async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.get('/shops/$shopId', token: token);
    final data = Map<String, dynamic>.from(response as Map);
    data['shop'] = Shop.fromJson(
      Map<String, dynamic>.from(data['shop'] as Map),
    );
    data['service_summary'] = data['service_summary'] is Map
        ? Map<String, dynamic>.from(data['service_summary'] as Map)
        : <String, dynamic>{};
    return data;
  }

  Future<List<Employee>> getShopEmployees(int shopId) async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.get(
      '/shops/$shopId/employees',
      token: token,
    );
    return (response['employees'] as List)
        .map((e) => Employee.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> addEmployee(
    int shopId,
    Map<String, dynamic> data,
  ) async {
    final token = await storageProvider.getToken();
    return Map<String, dynamic>.from(
      await apiProvider.post('/shops/$shopId/employees', data, token: token)
          as Map,
    );
  }

  Future<void> updateEmployee(
    int shopId,
    int employeeId,
    Map<String, dynamic> data,
  ) async {
    final token = await storageProvider.getToken();
    await apiProvider.put(
      '/shops/$shopId/employees/$employeeId',
      data,
      token: token,
    );
  }

  Future<void> deleteEmployee(int shopId, int employeeId) async {
    final token = await storageProvider.getToken();
    await apiProvider.delete(
      '/shops/$shopId/employees/$employeeId',
      token: token,
    );
  }

  Future<Map<String, dynamic>> getShopCash(int shopId) async {
    final token = await storageProvider.getToken();
    return Map<String, dynamic>.from(
      await apiProvider.get('/shops/$shopId/cash', token: token) as Map,
    );
  }

  Future<List<Report>> getShopReports(
    int shopId, {
    String period = 'daily',
  }) async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.get(
      '/shops/$shopId/reports?period=$period',
      token: token,
    );
    return (response['reports'] as List)
        .map((e) => Report.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> getReportDetail(int shopId, int reportId) async {
    final token = await storageProvider.getToken();
    return Map<String, dynamic>.from(
      await apiProvider.get('/shops/$shopId/reports/$reportId', token: token)
          as Map,
    );
  }

  Future<void> deleteReport(int shopId, int reportId) async {
    final token = await storageProvider.getToken();
    await apiProvider.delete('/shops/$shopId/reports/$reportId', token: token);
  }

  Future<void> deleteAllReports(int shopId) async {
    final token = await storageProvider.getToken();
    await apiProvider.delete('/shops/$shopId/reports', token: token);
  }

  Future<void> deleteSelectedReports(int shopId, List<int> ids) async {
    final token = await storageProvider.getToken();
    await apiProvider.post('/shops/$shopId/reports/delete-selection', {
      'report_ids': ids,
    }, token: token);
  }

  Future<Map<String, dynamic>> adjustCash(
    int shopId,
    Map<String, dynamic> data,
  ) async {
    final token = await storageProvider.getToken();
    return Map<String, dynamic>.from(
      await apiProvider.post(
            '/shops/$shopId/cash-adjustments',
            data,
            token: token,
          )
          as Map,
    );
  }
}
