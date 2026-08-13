import 'package:equatable/equatable.dart';
import '../../../data/models/shop_model.dart';

abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {
  const ShopInitial();
}

class ShopLoading extends ShopState {
  const ShopLoading();
}

class ShopSummaryLoaded extends ShopState {
  final int shopCount;
  final int employeeCount;
  final double cashBalance;
  final List<Shop> shops;
  final double todaySales;
  final double weekSales;
  final double monthSales;
  final int differenceCount;
  final int activeShopCount;
  final int reportCount;
  final int presentEmployeeCount;
  final List<Map<String, dynamic>> salesChart;
  final String chartMonth;

  const ShopSummaryLoaded({
    required this.shopCount,
    required this.employeeCount,
    required this.cashBalance,
    required this.shops,
    this.todaySales = 0,
    this.weekSales = 0,
    this.monthSales = 0,
    this.differenceCount = 0,
    this.activeShopCount = 0,
    this.reportCount = 0,
    this.presentEmployeeCount = 0,
    this.salesChart = const [],
    this.chartMonth = '',
  });

  @override
  List<Object?> get props => [
    shopCount,
    employeeCount,
    cashBalance,
    shops,
    todaySales,
    weekSales,
    monthSales,
    differenceCount,
    activeShopCount,
    reportCount,
    presentEmployeeCount,
    salesChart,
    chartMonth,
  ];
}

class ShopsLoaded extends ShopState {
  final List<Shop> shops;

  const ShopsLoaded({required this.shops});

  @override
  List<Object?> get props => [shops];
}

class ShopDetailLoaded extends ShopState {
  final Shop shop;
  final double cashBalance;
  final double totalIn;
  final double totalOut;
  final double dayBalance;
  final Map<String, dynamic> serviceSummary;

  const ShopDetailLoaded({
    required this.shop,
    required this.cashBalance,
    required this.totalIn,
    required this.totalOut,
    this.dayBalance = 0,
    this.serviceSummary = const {},
  });

  @override
  List<Object?> get props => [
    shop,
    cashBalance,
    totalIn,
    totalOut,
    dayBalance,
    serviceSummary,
  ];
}

class ShopError extends ShopState {
  final String message;

  const ShopError({required this.message});

  @override
  List<Object?> get props => [message];
}
