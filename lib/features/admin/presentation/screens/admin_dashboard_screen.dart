import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/customer.dart';
import '../providers/admin_provider.dart';
import 'customers_screen.dart';
import 'licenses_screen.dart';
import 'admin_settings_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(adminStatisticsProvider);
    final licensesState = ref.watch(licensesProvider);
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminSettingsScreen(),
                ),
              );
            },
            tooltip: 'Configurações',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminStatisticsProvider);
              ref.read(customersProvider.notifier).loadCustomers();
              ref.read(licensesProvider.notifier).loadLicenses();
            },
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminStatisticsProvider);
          await ref.read(customersProvider.notifier).loadCustomers();
          await ref.read(licensesProvider.notifier).loadLicenses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Dashboard Administrativo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gerencie seus clientes e licenças',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              // Cards de Estatísticas
              statisticsAsync.when(
                data: (stats) => _buildStatisticsCards(context, stats),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(child: Text('Erro: $error')),
              ),

              const SizedBox(height: 32),

              // Licenças a Vencer
              if (licensesState.expiringSoon.isNotEmpty) ...[
                _buildExpiringLicensesCard(
                  context,
                  licensesState,
                  customersState,
                ),
                const SizedBox(height: 32),
              ],

              // Ações Rápidas
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context: context,
          title: 'Clientes',
          value: stats['total_customers'].toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          context: context,
          title: 'Licenças Ativas',
          value: stats['active_licenses'].toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatCard(
          context: context,
          title: 'Licenças Expiradas',
          value: stats['expired_licenses'].toString(),
          icon: Icons.error,
          color: Colors.red,
        ),
        _buildStatCard(
          context: context,
          title: 'Vencem em 7 dias',
          value: stats['expiring_soon'].toString(),
          icon: Icons.warning,
          color: Colors.orange,
        ),
        _buildStatCard(
          context: context,
          title: 'Faturamento Total',
          value: currencyFormat.format(stats['total_revenue']),
          icon: Icons.attach_money,
          color: Colors.purple,
          isCompact: true,
        ),
        _buildStatCard(
          context: context,
          title: 'Faturamento Mensal',
          value: currencyFormat.format(stats['monthly_revenue']),
          icon: Icons.calendar_today,
          color: Colors.teal,
          isCompact: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isCompact = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiringLicensesCard(
    BuildContext context,
    LicensesState state,
    CustomersState customersState,
  ) {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Licenças a Vencer (próximos 7 dias)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...state.expiringSoon.take(5).map((license) {
              // Buscar cliente da licença
              final customer = customersState.customers.firstWhere(
                (c) => c.id == license.customerId,
                orElse: () => Customer(
                  id: '',
                  name: 'Cliente Desconhecido',
                  email: '',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.businessName ?? customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${license.daysRemaining} ${license.daysRemaining == 1 ? 'dia' : 'dias'}',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (state.expiringSoon.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${state.expiringSoon.length - 5} mais',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(
              context: context,
              title: 'Gerenciar Clientes',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomersScreen(),
                  ),
                );
              },
            ),
            _buildActionCard(
              context: context,
              title: 'Gerenciar Licenças',
              icon: Icons.vpn_key,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LicensesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
