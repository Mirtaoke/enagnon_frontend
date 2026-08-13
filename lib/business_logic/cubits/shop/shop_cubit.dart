import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/shop/shop_state.dart';
import '../../../data/repositories/shop_repository.dart';

class ShopCubit extends Cubit<ShopState> {
  final ShopRepository shopRepository;

  ShopCubit({required this.shopRepository}) : super(const ShopInitial());

  Future<void> loadSummary({String? month, String chartPeriod = 'day'}) async {
    emit(const ShopLoading());
    try {
      final response = await shopRepository.getSummary(
        month: month,
        chartPeriod: chartPeriod,
      );
      final summary = response['summary'];
      final shops = response['shops'];

      emit(
        ShopSummaryLoaded(
          shopCount: summary['shop_count'] ?? 0,
          employeeCount: summary['employee_count'] ?? 0,
          cashBalance: double.tryParse('${summary['cash_balance']}') ?? 0,
          shops: shops,
          todaySales: double.tryParse('${summary['today_sales']}') ?? 0,
          weekSales: double.tryParse('${summary['week_sales']}') ?? 0,
          monthSales: double.tryParse('${summary['month_sales']}') ?? 0,
          differenceCount: summary['difference_count'] ?? 0,
          activeShopCount: summary['active_shop_count'] ?? 0,
          reportCount: summary['report_count'] ?? 0,
          presentEmployeeCount: summary['present_employee_count'] ?? 0,
          salesChart: (response['sales_chart'] as List? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
          chartMonth: '${response['chart_month'] ?? ''}',
        ),
      );
    } catch (e) {
      emit(ShopError(message: _message(e)));
    }
  }

  String _message(Object error) {
    final text = error.toString();
    if (text.contains('TimeoutException')) {
      return 'Le serveur ne répond pas. Vérifie que Laravel est démarré sur le port 8000.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  Future<void> loadAllShops() async {
    emit(const ShopLoading());
    try {
      final shops = await shopRepository.getAllShops();
      emit(ShopsLoaded(shops: shops));
    } catch (e) {
      emit(ShopError(message: e.toString()));
    }
  }

  Future<void> loadShopDetail(int shopId) async {
    emit(const ShopLoading());
    try {
      final response = await shopRepository.getShopDetail(shopId);
      final cash = response['cash'];
      emit(
        ShopDetailLoaded(
          shop: response['shop'],
          cashBalance: double.tryParse('${cash['balance']}') ?? 0,
          totalIn: double.tryParse('${cash['total_in']}') ?? 0,
          totalOut: double.tryParse('${cash['total_out']}') ?? 0,
          dayBalance: double.tryParse('${cash['day_balance']}') ?? 0,
          serviceSummary: Map<String, dynamic>.from(
            response['service_summary'] as Map? ?? const {},
          ),
        ),
      );
    } catch (e) {
      emit(ShopError(message: e.toString()));
    }
  }
}
