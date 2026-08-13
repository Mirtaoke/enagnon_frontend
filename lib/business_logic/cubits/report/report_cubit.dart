import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/report/report_state.dart';
import '../../../data/repositories/shop_repository.dart';

class ReportCubit extends Cubit<ReportState> {
  final ShopRepository shopRepository;

  ReportCubit({required this.shopRepository}) : super(const ReportInitial());

  Future<void> loadReports(int shopId, {String period = 'daily'}) async {
    emit(const ReportLoading());
    try {
      final reports = await shopRepository.getShopReports(
        shopId,
        period: period,
      );
      emit(ReportLoaded(reports: reports));
    } catch (e) {
      emit(ReportError(message: e.toString()));
    }
  }

  Future<void> loadAllReports(
    List<int> shopIds, {
    String period = 'daily',
  }) async {
    emit(const ReportLoading());
    try {
      final batches = await Future.wait(
        shopIds.map((id) => shopRepository.getShopReports(id, period: period)),
      );
      final reports = batches.expand((items) => items).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      emit(ReportLoaded(reports: reports));
    } catch (e) {
      emit(ReportError(message: e.toString()));
    }
  }
}
