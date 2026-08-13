import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/providers/api_provider.dart';
import '../data/providers/storage_provider.dart';

class OfflineSyncService {
  final ApiProvider apiProvider;
  final StorageProvider storageProvider;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _syncing = false;

  OfflineSyncService({
    required this.apiProvider,
    required this.storageProvider,
  });

  Future<void> start() async {
    _subscription ??= Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) syncNow();
    });
    final current = await Connectivity().checkConnectivity();
    if (!current.contains(ConnectivityResult.none)) await syncNow();
  }

  Future<int> syncNow() async {
    if (_syncing) return 0;
    _syncing = true;
    var synchronized = 0;
    try {
      final token = await storageProvider.getToken();
      if (token == null) return 0;
      final operations = await storageProvider.getPendingOperations();
      for (final operation in operations) {
        try {
          await apiProvider.post(
            operation['endpoint'].toString(),
            Map<String, dynamic>.from(operation['body'] as Map),
            token: token,
          );
          await storageProvider.removePendingOperation(
            operation['id'].toString(),
          );
          synchronized++;
        } catch (_) {
          break;
        }
      }
      return synchronized;
    } finally {
      _syncing = false;
    }
  }

  Future<void> dispose() async => _subscription?.cancel();
}
