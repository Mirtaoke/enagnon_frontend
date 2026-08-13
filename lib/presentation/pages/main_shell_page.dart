import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../business_logic/cubits/auth/auth_event.dart';
import '../../core/constants/app_colors.dart';
import 'audit_page.dart';
import 'home_page.dart';
import 'operations_page.dart';
import 'profile_page.dart';
import 'reports_page.dart';
import 'shop_detail_page.dart';
import 'shops_list_page.dart';
import '../../data/providers/storage_provider.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});
  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int index = 0;
  String? loadedRole;

  Future<void> _restore(String role, int max) async {
    if (loadedRole == role) return;
    loadedRole = role;
    final saved = await StorageProvider().getNavigationIndex(role);
    if (mounted) setState(() => index = saved < max ? saved : 0);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth is! AuthSuccess) return const SizedBox.shrink();
    final isAdmin = auth.user.role == 'admin';
    final shopId = auth.user.shopId;
    final count = 4;
    _restore(auth.user.role, count);
    final pages = isAdmin
        ? <Widget>[
            HomePage(onNavigate: _navigate),
            const ShopsListPage(),
            const ReportsPage(),
            const AuditPage(),
          ]
        : <Widget>[
            HomePage(onNavigate: _navigate),
            if (shopId != null)
              ShopDetailPage(shopId: shopId)
            else
              const _MissingShop(),
            if (shopId != null)
              OperationsPage(shopId: shopId)
            else
              const _MissingShop(),
            const ProfilePage(),
          ];
    final destinations = isAdmin
        ? const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Boutiques',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Rapports',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_history_outlined),
              selectedIcon: Icon(Icons.manage_history),
              label: 'Audit',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Boutique',
            ),
            NavigationDestination(
              icon: Icon(Icons.swap_horiz_outlined),
              selectedIcon: Icon(Icons.swap_horiz),
              label: 'Opérations',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ];
    if (index >= pages.length) index = 0;
    return Scaffold(
      extendBody: false,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey('$isAdmin-$index'),
            child: pages[index],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            height: 68,
            selectedIndex: index,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.secondary.withValues(alpha: .18),
            destinations: destinations,
            onDestinationSelected: _navigate,
          ),
        ),
      ),
    );
  }

  void _navigate(int value) {
    setState(() => index = value);
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthSuccess) {
      StorageProvider().saveNavigationIndex(auth.user.role, value);
    }
  }
}

class _MissingShop extends StatelessWidget {
  const _MissingShop();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Text('Aucune boutique liée à ce compte.')),
  );
}
