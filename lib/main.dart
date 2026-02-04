import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/database/database_helper.dart';
import 'core/update/widgets/update_checker.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/sales/presentation/screens/quick_sale_screen.dart';
import 'features/auth/data/repositories/auth_repository.dart';
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

  // Criar usuário de teste automaticamente
  await _setupTestUser();

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _setupTestUser() async {
  try {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final authRepo = AuthRepository();

    // Verificar se usuário admin já existe
    final existingUsers = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );

    if (existingUsers.isNotEmpty) {
      print('ℹ️ Usuário admin já existe. Pulando criação...');
      return;
    }

    // Criar usuário admin
    final user = await authRepo.createUser(
      username: 'admin',
      password: 'admin123',
      email: 'admin@sushigen.com',
      role: 'admin',
    );

    // Criar licença vitalícia
    final expirationDate = DateTime.now().add(
      const Duration(days: 36500),
    ); // 100 anos
    await authRepo.createLicense(
      userId: user.id,
      licenseKey: '1A56-0FD1-4814-E762',
      expirationDate: expirationDate,
      maxDevices: 10,
    );

    print('✅ Usuário criado: admin / admin123');
    print('✅ Chave: 1A56-0FD1-4814-E762');
    print('✅ Licença válida até: ${expirationDate.year}');
  } catch (e) {
    print('⚠️ Erro ao configurar usuário de teste: $e');
  }
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
