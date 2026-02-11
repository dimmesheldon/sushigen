import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/database/database_helper.dart';
import 'core/update/widgets/update_checker.dart';
import 'features/admin/data/repositories/admin_repository.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/sales/presentation/screens/quick_sale_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/auth/presentation/screens/license_renewal_screen.dart';
import 'features/products/presentation/screens/products_list_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/cashflow/presentation/screens/cash_flow_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado com sucesso!');
  } catch (e) {
    print('⚠️  Erro ao inicializar Firebase: $e');
    print('💡 Siga o GUIA_FIREBASE.md para configurar sincronização na nuvem');
  }

  // Inicializar localização PT-BR
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  // Reparar banco administrativo e garantir superadmin
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.adminDatabase;
    // await dbHelper.backupAdminDatabase(); // Temporariamente desabilitado
    final adminRepository = AdminRepository();
    await adminRepository.ensureAdminAccount();
    await adminRepository.cleanupAdminData();
  } catch (e) {
    print('⚠️ Erro ao reparar banco administrativo: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return UpdateChecker(
      child: MaterialApp(
        title: 'SushiGen - Sistema de Gerenciamento',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/home': (context) => const QuickSaleScreen(),
          '/license-renewal': (context) => const LicenseRenewalScreen(),
          '/products': (context) => const ProductsListScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/cashflow': (context) => const CashFlowScreen(),
        },
      ),
    );
  }
}
