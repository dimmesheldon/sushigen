import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(reportsProvider.notifier).loadReports(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de período
          _buildPeriodSelector(context, ref, reportsState),

          // Conteúdo
          Expanded(
            child: reportsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reportsState.error != null
                ? _buildError(context, ref, reportsState.error!)
                : RefreshIndicator(
                    onRefresh: () =>
                        ref.read(reportsProvider.notifier).loadReports(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resumo
                          _buildSummaryCards(context, reportsState),
                          const SizedBox(height: 24),

                          // Comparação com período anterior
                          if (reportsState.comparison != null) ...[
                            _buildComparisonCard(
                              context,
                              reportsState.comparison!,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 🎯 CARDS INTELIGENTES

                          // Análise de Custos e Lucro
                          if (reportsState.costAnalysis != null) ...[
                            _buildCostAnalysisCard(
                              context,
                              reportsState.costAnalysis!,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Vendas por Canal (iFood vs Local)
                          if (reportsState.channelAnalysis != null) ...[
                            _buildChannelAnalysisCard(
                              context,
                              reportsState.channelAnalysis!,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Análise de Entregas
                          if (reportsState.deliveryAnalysis != null) ...[
                            _buildDeliveryAnalysisCard(
                              context,
                              reportsState.deliveryAnalysis!,
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Produtos mais vendidos
                          _buildTopProducts(context, reportsState),
                          const SizedBox(height: 24),

                          // Produtos menos vendidos
                          if (reportsState.leastProducts.isNotEmpty) ...[
                            _buildLeastProducts(context, reportsState),
                            const SizedBox(height: 24),
                          ],

                          // Vendas por categoria
                          _buildSalesByCategory(context, reportsState),
                          const SizedBox(height: 24),

                          // Vendas por período do dia
                          _buildSalesByDayPeriod(context, reportsState),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    WidgetRef ref,
    ReportsState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<ReportPeriod>(
          segments: const [
            ButtonSegment(
              value: ReportPeriod.today,
              label: Text('Hoje', style: TextStyle(fontSize: 12)),
              icon: Icon(Icons.today, size: 14),
            ),
            ButtonSegment(
              value: ReportPeriod.week,
              label: Text('7 dias', style: TextStyle(fontSize: 12)),
              icon: Icon(Icons.date_range, size: 14),
            ),
            ButtonSegment(
              value: ReportPeriod.month,
              label: Text('30 dias', style: TextStyle(fontSize: 12)),
              icon: Icon(Icons.calendar_month, size: 14),
            ),
          ],
          selected: {state.period},
          onSelectionChanged: (Set<ReportPeriod> newSelection) {
            ref.read(reportsProvider.notifier).setPeriod(newSelection.first);
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, ReportsState state) {
    final summary = state.summary;
    if (summary == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo do Período',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Vendas',
                summary['total_sales'].toString(),
                Icons.shopping_cart,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Faturamento',
                'R\$ ${(summary['total_revenue'] as double).toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Ticket Médio',
                'R\$ ${(summary['average_ticket'] as double).toStringAsFixed(2)}',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Maior Venda',
                'R\$ ${(summary['max_sale'] as double).toStringAsFixed(2)}',
                Icons.star,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context,
    Map<String, dynamic> comparison,
  ) {
    final countChange = comparison['count_change_percent'] as double;
    final totalChange = comparison['total_change_percent'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: Colors.blue.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Comparação',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonItem(
                    'Vendas',
                    countChange,
                    comparison['previous_count'] as int,
                    comparison['current_count'] as int,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildComparisonItem(
                    'Faturamento',
                    totalChange,
                    (comparison['previous_total'] as double).toStringAsFixed(2),
                    (comparison['current_total'] as double).toStringAsFixed(2),
                    isMonetary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(
    String label,
    double changePercent,
    dynamic previousValue,
    dynamic currentValue, {
    bool isMonetary = false,
  }) {
    final isPositive = changePercent >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              '${changePercent.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isMonetary
              ? 'R\$ $previousValue → R\$ $currentValue'
              : '$previousValue → $currentValue',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTopProducts(BuildContext context, ReportsState state) {
    if (state.topProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produtos Mais Vendidos',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.topProducts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = state.topProducts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  product['product_name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${product['total_quantity']} unidades • ${product['category']}',
                ),
                trailing: Text(
                  'R\$ ${(product['total_revenue'] as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSalesByCategory(BuildContext context, ReportsState state) {
    if (state.salesByCategory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendas por Categoria',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: state.salesByCategory.map((category) {
                final total = category['total_revenue'] as double;
                final maxTotal =
                    state.salesByCategory.first['total_revenue'] as double;
                final percentage = (total / maxTotal * 100).toInt();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category['category'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'R\$ ${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${category['total_items']} itens em ${category['sales_count']} vendas',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesByDayPeriod(BuildContext context, ReportsState state) {
    if (state.salesByDayPeriod.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vendas por Período do Dia',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: state.salesByDayPeriod.map((period) {
                IconData icon;
                Color color;
                switch (period['period'] as String) {
                  case 'Manhã':
                    icon = Icons.wb_sunny;
                    color = Colors.orange;
                    break;
                  case 'Tarde':
                    icon = Icons.wb_cloudy;
                    color = Colors.blue;
                    break;
                  case 'Noite':
                    icon = Icons.nightlight;
                    color = Colors.indigo;
                    break;
                  default:
                    icon = Icons.bedtime;
                    color = Colors.purple;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, color: color),
                  title: Text(
                    period['period'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${period['count']} vendas'),
                  trailing: Text(
                    'R\$ ${(period['total'] as double).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 🎯 CARD: Análise de Custos e Lucro
  Widget _buildCostAnalysisCard(
    BuildContext context,
    Map<String, dynamic> costData,
  ) {
    final totalRevenue = (costData['total_revenue'] ?? 0.0) as double;
    final totalCost = (costData['total_cost'] ?? 0.0) as double;
    final netProfit = (costData['net_profit'] ?? 0.0) as double;
    final profitMargin = (costData['profit_margin'] ?? 0.0) as double;
    final deliveryCost = (costData['total_delivery_cost'] ?? 0.0) as double;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.green.shade700,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Análise de Custos e Lucro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    'Faturamento',
                    'R\$ ${totalRevenue.toStringAsFixed(2)}',
                    Colors.blue,
                    Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Custo Total',
                    'R\$ ${totalCost.toStringAsFixed(2)}',
                    Colors.orange,
                    Icons.inventory_2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    'Lucro Líquido',
                    'R\$ ${netProfit.toStringAsFixed(2)}',
                    netProfit >= 0 ? Colors.green : Colors.red,
                    Icons.savings,
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Margem',
                    '${profitMargin.toStringAsFixed(1)}%',
                    profitMargin >= 30
                        ? Colors.green
                        : profitMargin >= 15
                        ? Colors.orange
                        : Colors.red,
                    Icons.percent,
                  ),
                ),
              ],
            ),
            if (deliveryCost > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.delivery_dining, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Custo de entregas: R\$ ${deliveryCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🎯 CARD: Vendas por Canal (iFood vs Local)
  Widget _buildChannelAnalysisCard(
    BuildContext context,
    Map<String, dynamic> channelData,
  ) {
    final localData = channelData['Local'] as Map<String, dynamic>;
    final ifoodData = channelData['iFood'] as Map<String, dynamic>;

    final localSales = (localData['total_sales'] ?? 0) as int;
    final localRevenue = (localData['total_revenue'] ?? 0.0) as double;
    final ifoodSales = (ifoodData['total_sales'] ?? 0) as int;
    final ifoodRevenue = (ifoodData['total_revenue'] ?? 0.0) as double;

    final totalSales = localSales + ifoodSales;
    final totalRevenue = localRevenue + ifoodRevenue;
    final ifoodPercent = totalRevenue > 0
        ? (ifoodRevenue / totalRevenue) * 100
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Colors.purple.shade700, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Vendas por Canal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.store,
                          color: Colors.blue.shade700,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Local',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$localSales vendas',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${localRevenue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Colors.red.shade700,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'iFood',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$ifoodSales vendas',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${ifoodRevenue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Total Vendas',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '$totalSales',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(height: 40, width: 1, color: Colors.grey.shade300),
                  Column(
                    children: [
                      const Text(
                        '% iFood',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${ifoodPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 CARD: Análise de Entregas
  Widget _buildDeliveryAnalysisCard(
    BuildContext context,
    Map<String, dynamic> deliveryData,
  ) {
    final retiradaData = deliveryData['Retirada'] as Map<String, dynamic>;
    final entregaData = deliveryData['Entrega'] as Map<String, dynamic>;

    final retiradaCount = (retiradaData['total'] ?? 0) as int;
    final retiradaRevenue = (retiradaData['revenue'] ?? 0.0) as double;
    final entregaCount = (entregaData['total'] ?? 0) as int;
    final entregaRevenue = (entregaData['revenue'] ?? 0.0) as double;
    final deliveryCost = (entregaData['total_delivery_cost'] ?? 0.0) as double;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Análise de Entregas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    'Retiradas',
                    '$retiradaCount pedidos',
                    Colors.green,
                    Icons.shopping_bag,
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Entregas',
                    '$entregaCount pedidos',
                    Colors.orange,
                    Icons.two_wheeler,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricColumn(
                    'Faturamento Retirada',
                    'R\$ ${retiradaRevenue.toStringAsFixed(2)}',
                    Colors.green,
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildMetricColumn(
                    'Faturamento Entrega',
                    'R\$ ${entregaRevenue.toStringAsFixed(2)}',
                    Colors.orange,
                    Icons.attach_money,
                  ),
                ),
              ],
            ),
            if (deliveryCost > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.motorcycle, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Custo total de entregas',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      'R\$ ${deliveryCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🎯 CARD: Produtos Menos Vendidos
  Widget _buildLeastProducts(BuildContext context, ReportsState state) {
    if (state.leastProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_down, color: Colors.red.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Produtos Menos Vendidos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...state.leastProducts.map((product) {
              final name = product['name'] as String;
              final category = product['category'] as String;
              final quantity = (product['total_quantity'] ?? 0.0) as double;
              final revenue = (product['total_revenue'] ?? 0.0) as double;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.warning,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${quantity.toInt()} vendidos',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'R\$ ${revenue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            if (state.leastProducts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Considere promover estes produtos ou revisar o cardápio',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper: Coluna de métrica
  Widget _buildMetricColumn(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar relatórios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(reportsProvider.notifier).loadReports(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
