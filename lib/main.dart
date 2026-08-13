import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'business_logic/cubits/auth/auth_cubit.dart';
import 'business_logic/cubits/closure/closure_cubit.dart';
import 'business_logic/cubits/report/report_cubit.dart';
import 'business_logic/cubits/shop/shop_cubit.dart';
import 'core/theme/app_theme.dart';
import 'config/app_router.dart';
import 'data/providers/api_provider.dart';
import 'data/providers/storage_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/closure_repository.dart';
import 'data/repositories/shop_repository.dart';
import 'services/offline_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  final syncStorage = StorageProvider();
  runApp(const MyApp());
  unawaited(
    OfflineSyncService(
      apiProvider: ApiProvider(),
      storageProvider: syncStorage,
    ).start(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiProvider = ApiProvider();
    final storageProvider = StorageProvider();
    final authRepository = AuthRepository(
      apiProvider: apiProvider,
      storageProvider: storageProvider,
    );
    final shopRepository = ShopRepository(
      apiProvider: apiProvider,
      storageProvider: storageProvider,
    );
    final closureRepository = ClosureRepository(
      apiProvider: apiProvider,
      storageProvider: storageProvider,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(authRepository: authRepository),
        ),
        BlocProvider(
          create: (context) => ShopCubit(shopRepository: shopRepository),
        ),
        BlocProvider(
          create: (context) => ReportCubit(shopRepository: shopRepository),
        ),
        BlocProvider(create: (context) => ClosureCubit(closureRepository)),
      ],
      child: MaterialApp(
        title: 'ENAGNON LEADER',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppRouter.root,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
