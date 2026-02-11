import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../sales/data/repositories/sale_repository.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../../core/providers/sync_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _saleRepo = SaleRepository();
  final _productRepo = ProductRepository();

  double _todayTotal = 0.0;
  int _todayCount = 0;
  int _productsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final todayTotal = await _saleRepo.getTodayTotal();
      final todayCount = await _saleRepo.getTodayCount();
      final products = await _productRepo.getAllProducts();

      setState(() {
        _todayTotal = todayTotal;
        _todayCount = todayCount;
        _productsCount = products.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar formato simples sem necessidade de localização complexa
    final now = DateTime.now();
    final today =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authProvider);
            final userName = authState.user?.username ?? '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard', style: TextStyle(fontSize: 20)),
                if (userName.isNotEmpty)
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            );
          },
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Botão de Sincronização Firebase
          Consumer(
            builder: (context, ref, child) {
              final syncState = ref.watch(syncProvider);

              return IconButton(
                icon: syncState.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Badge(
                        label:
                            syncState.unsyncedCounts['total'] != null &&
                                syncState.unsyncedCounts['total']! > 0
                            ? Text(
                                '${syncState.unsyncedCounts['total']}',
                                style: const TextStyle(fontSize: 10),
                              )
                            : null,
                        isLabelVisible:
                            syncState.unsyncedCounts['total'] != null &&
                            syncState.unsyncedCounts['total']! > 0,
                        child: const Icon(Icons.cloud_upload),
                      ),
                onPressed: syncState.isSyncing
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(syncProvider.notifier)
                              .syncBidirectional();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Sincronização concluída!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );

                            // Recarregar dados do dashboard
                            _loadDashboardData();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Erro: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                tooltip: syncState.isSyncing
                    ? syncState.currentOperation ?? 'Sincronizando...'
                    : 'Sincronizar com Firebase',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho com data
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Hoje, $today',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Cards de resumo
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Vendas Hoje',
                            '$_todayCount',
                            Icons.shopping_cart,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Faturamento Hoje',
                            'R\$ ${_todayTotal.toStringAsFixed(2)}',
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Produtos',
                            '$_productsCount',
                            Icons.inventory,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            'Ticket Médio',
                            _todayCount > 0
                                ? 'R\$ ${(_todayTotal / _todayCount).toStringAsFixed(2)}'
                                : 'R\$ 0,00',
                            Icons.trending_up,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Ações rápidas
                    Text(
                      'Ações Rápidas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildActionCard(
                          'Nova Venda',
                          Icons.point_of_sale,
                          Colors.red.shade700,
                          () => Navigator.pushNamed(context, '/home'),
                        ),
                        _buildActionCard(
                          'Produtos',
                          Icons.restaurant_menu,
                          Colors.blue.shade700,
                          () => Navigator.pushNamed(context, '/products'),
                        ),
                        _buildActionCard(
                          'Relatórios',
                          Icons.assessment,
                          Colors.green.shade700,
                          () => Navigator.pushNamed(context, '/reports'),
                        ),
                        _buildActionCard(
                          'Fluxo de Caixa',
                          Icons.account_balance_wallet,
                          Colors.purple.shade700,
                          () => Navigator.pushNamed(context, '/cashflow'),
                        ),
                        _buildActionCard(
                          'Configurações',
                          Icons.settings,
                          Colors.grey.shade700,
                          () => _showSettingsMenu(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.red.shade700),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, size: 64, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'SushiGen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale),
            title: const Text('Nova Venda'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.restaurant_menu),
            title: const Text('Produtos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/products');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Relatórios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Fluxo de Caixa'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/cashflow');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Renovar Licença'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/license-renewal');
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Sair'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.vpn_key, color: Colors.red),
              title: const Text('Renovar Licença'),
              subtitle: const Text('Atualizar chave de acesso'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/license-renewal');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Sobre o Sistema'),
              subtitle: const Text('Versão 1.0.0'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'SushiGen',
                  applicationVersion: '1.0.0',
                  applicationIcon: Icon(
                    Icons.restaurant,
                    size: 48,
                    color: Colors.red.shade700,
                  ),
                  children: [
                    const Text(
                      'Sistema de Gerenciamento para Restaurante de Sushi',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
