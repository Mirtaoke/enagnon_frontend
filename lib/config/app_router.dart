import 'package:flutter/material.dart';
import '../presentation/pages/auth_gate.dart';
import '../presentation/pages/attendance_page.dart';
import '../presentation/pages/daily_closure_page.dart';
import '../presentation/pages/operations_page.dart';
import '../presentation/pages/forgot_password_page.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/main_shell_page.dart';
import '../presentation/pages/reports_page.dart';
import '../presentation/pages/report_detail_page.dart';
import '../presentation/pages/profile_page.dart';
import '../presentation/pages/shop_detail_page.dart';
import '../presentation/pages/shops_list_page.dart';
import '../presentation/pages/audit_page.dart';

class AppRouter {
  AppRouter._();
  static const root = '/';
  static const login = '/login';
  static const home = '/home';
  static const shops = '/shops';
  static const reports = '/reports';
  static const reportDetail = '/report-detail';
  static const shopDetail = '/shop-detail';
  static const dailyClosure = '/daily-closure';
  static const profile = '/profile';
  static const attendance = '/attendance';
  static const operations = '/operations';
  static const forgotPassword = '/forgot-password';
  static const attendanceOverview = '/attendance-overview';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return _route(const AuthGate());
      case login:
        return _route(const LoginPage());
      case home:
        return _route(const MainShellPage());
      case shops:
        return _route(const ShopsListPage());
      case reports:
        return _route(const ReportsPage());
      case reportDetail:
        final args = settings.arguments as Map<String, int>;
        return _route(
          ReportDetailPage(
            shopId: args['shopId']!,
            reportId: args['reportId']!,
          ),
        );
      case shopDetail:
        return _route(ShopDetailPage(shopId: settings.arguments as int));
      case dailyClosure:
        return _route(DailyClosurePage(shopId: settings.arguments as int));
      case profile:
        return _route(const ProfilePage());
      case attendance:
        return _route(const AttendancePage());
      case operations:
        final args = Map<String, dynamic>.from(settings.arguments as Map);
        return _route(
          OperationsPage(
            shopId: args['shopId'] as int,
            initialService: args['service'] as String?,
          ),
        );
      case forgotPassword:
        return _route(const ForgotPasswordPage());
      case attendanceOverview:
        return _route(const AuditPage(initialTab: 1, todayOnly: true));
      default:
        return _route(const AuthGate());
    }
  }

  static MaterialPageRoute<dynamic> _route(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
