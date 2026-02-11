import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/cash_flow_provider.dart';
import '../../data/models/cash_flow_entry.dart';
import 'cash_flow_form_screen.dart';
import '../../../sales/data/repositories/sale_repository.dart';
import '../../../sales/data/models/sale.dart';

class CashFlowScreen extends ConsumerStatefulWidget {
  const CashFlowScreen({super.key});

  @override
  ConsumerState<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends ConsumerState<CashFlowScreen> {
  final Set<String> _expandedCards = {};
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cashFlowProvider.notifier).loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cashFlowState = ref.watch(cashFlowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluxo de Caixa'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showPeriodSelector(context),
            tooltip: 'Selecionar Período',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              try {
                await _generatePDF(cashFlowState);
              } catch (e) {
                print('ERRO AO GERAR PDF: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao gerar PDF: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              }
            },
            tooltip: 'Gerar PDF',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFiltersDialog(context),
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cashFlowProvider.notifier).loadEntries(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _navigateToForm(context, 'income'),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Receita'),
            heroTag: 'income',
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => _navigateToForm(context, 'expense'),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.remove),
            label: const Text('Despesa'),
            heroTag: 'expense',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cards de Resumo
          _buildSummaryCards(cashFlowState),

          // Indicador de Período
          if (cashFlowState.startDate != null && cashFlowState.endDate != null)
            _buildPeriodIndicator(cashFlowState),

          // Filtros Ativos
          if (cashFlowState.selectedType != null ||
              cashFlowState.selectedCategory != null)
            _buildActiveFilters(cashFlowState),

          // Lista de Entradas
          Expanded(
            child: cashFlowState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : cashFlowState.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar dados',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cashFlowState.error!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ref.read(cashFlowProvider.notifier).loadEntries(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  )
                : cashFlowState.entries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma movimentação',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adicione receitas e despesas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildEntriesList(cashFlowState.entries),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(CashFlowState state) {
    final income = state.balance['income'] ?? 0.0;
    final expense = state.balance['expense'] ?? 0.0;
    final balance = state.balance['balance'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Receitas',
              value: income,
              color: Colors.green,
              icon: Icons.arrow_upward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Despesas',
              value: expense,
              color: Colors.red,
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Saldo',
              value: balance,
              color: balance >= 0 ? Colors.blue : Colors.orange,
              icon: Icons.account_balance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodIndicator(CashFlowState state) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            'Período: ${dateFormat.format(state.startDate!)} - ${dateFormat.format(state.endDate!)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(CashFlowState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (state.selectedType != null)
            Chip(
              label: Text(
                state.selectedType == 'income' ? 'Receitas' : 'Despesas',
              ),
              onDeleted: () =>
                  ref.read(cashFlowProvider.notifier).filterByType(null),
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          if (state.selectedCategory != null)
            Chip(
              label: Text(state.selectedCategory!),
              onDeleted: () =>
                  ref.read(cashFlowProvider.notifier).filterByCategory(null),
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
          if (state.selectedType != null || state.selectedCategory != null)
            TextButton.icon(
              onPressed: () =>
                  ref.read(cashFlowProvider.notifier).clearFilters(),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Limpar Filtros'),
            ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<CashFlowEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildEntryCard(entry);
      },
    );
  }

  Widget _buildEntryCard(CashFlowEntry entry) {
    final isIncome = entry.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isExpanded = _expandedCards.contains(entry.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIncome ? Icons.add_circle : Icons.remove_circle,
                color: color,
                size: 28,
              ),
            ),
            title: Text(
              entry.description,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  entry.category,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(entry.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeFormat.format(entry.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} R\$ ${entry.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.saleId != null)
                      Text(
                        'Venda',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    // Badge iFood
                    if (entry.saleId != null)
                      FutureBuilder<Map<String, dynamic>?>(
                        future: SaleRepository().getSaleWithItems(
                          entry.saleId!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            final sale = snapshot.data!['sale'] as Sale;
                            if (sale.isIfood) {
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'iFood',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                  ],
                ),
              ],
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(entry.id);
                } else {
                  _expandedCards.add(entry.id);
                }
              });
            },
            onLongPress: () => _showEntryOptions(context, entry),
          ),

          // Detalhes expandidos
          if (isExpanded && entry.saleId != null)
            FutureBuilder<Map<String, dynamic>?>(
              future: SaleRepository().getSaleWithItems(entry.saleId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data == null) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Erro ao carregar detalhes da venda',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                final saleData = snapshot.data!;
                final sale = saleData['sale'] as Sale;
                final items = saleData['items'] as List<SaleItem>;
                return _buildSaleDetails(sale, items);
              },
            ),

          // Detalhes expandidos para entradas sem venda
          if (isExpanded && entry.saleId == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Categoria: ${entry.category}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Valor: R\$ ${entry.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaleDetails(Sale sale, List<SaleItem> items) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da venda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Venda #${sale.saleNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dateFormat.format(sale.saleDate),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Divider(height: 20),

          // Items da venda
          if (items.isNotEmpty) ...[
            const Text(
              'Itens:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity.toStringAsFixed(0)}x ${item.productName}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          'R\$ ${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            const Divider(height: 16),
          ],

          // Totais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 12)),
              Text(
                'R\$ ${sale.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          if (sale.discountAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Desconto:', style: TextStyle(fontSize: 12)),
                Text(
                  '- R\$ ${sale.discountAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                'R\$ ${sale.finalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Forma de pagamento
          Row(
            children: [
              Icon(
                _getPaymentIcon(sale.paymentMethod),
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Pagamento: ${_getPaymentMethodName(sale.paymentMethod)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          // Observações
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Obs: ${sale.notes}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'money':
        return Icons.money;
      case 'debit':
        return Icons.credit_card;
      case 'credit':
        return Icons.credit_card;
      case 'pix':
        return Icons.qr_code;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'money':
        return 'Dinheiro';
      case 'debit':
        return 'Débito';
      case 'credit':
        return 'Crédito';
      case 'pix':
        return 'PIX';
      default:
        return method;
    }
  }

  void _showFiltersDialog(BuildContext context) {
    final cashFlowState = ref.read(cashFlowProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tipo de Movimentação',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Todas'),
              leading: const Icon(Icons.all_inclusive),
              onTap: () {
                ref.read(cashFlowProvider.notifier).filterByType(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Apenas Receitas'),
              leading: Icon(Icons.arrow_upward, color: Colors.green.shade600),
              onTap: () {
                ref.read(cashFlowProvider.notifier).filterByType('income');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Apenas Despesas'),
              leading: Icon(Icons.arrow_downward, color: Colors.red.shade600),
              onTap: () {
                ref.read(cashFlowProvider.notifier).filterByType('expense');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Vendas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            CheckboxListTile(
              title: const Text('Somente iFood'),
              secondary: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'iFood',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              value: cashFlowState.onlyIfood,
              onChanged: (value) {
                ref.read(cashFlowProvider.notifier).toggleIfoodFilter();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(cashFlowProvider.notifier).clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Limpar Filtros'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showEntryOptions(BuildContext context, CashFlowEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _navigateToForm(context, entry.type, entry: entry);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade600),
              title: Text(
                'Excluir',
                style: TextStyle(color: Colors.red.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, entry);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CashFlowEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir "${entry.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cashFlowProvider.notifier).deleteEntry(entry.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entrada excluída com sucesso!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showPeriodSelector(BuildContext context) {
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Período'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Hoje'),
              onTap: () {
                final startDate = DateTime(now.year, now.month, now.day);
                final endDate = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  23,
                  59,
                  59,
                );
                ref
                    .read(cashFlowProvider.notifier)
                    .filterByPeriod(startDate, endDate);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_week),
              title: const Text('Esta Semana'),
              onTap: () {
                final weekday = now.weekday;
                final startDate = now.subtract(Duration(days: weekday - 1));
                final endDate = startDate.add(
                  const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
                );
                ref
                    .read(cashFlowProvider.notifier)
                    .filterByPeriod(
                      DateTime(startDate.year, startDate.month, startDate.day),
                      DateTime(
                        endDate.year,
                        endDate.month,
                        endDate.day,
                        23,
                        59,
                        59,
                      ),
                    );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Este Mês'),
              onTap: () {
                final startDate = DateTime(now.year, now.month, 1);
                final endDate = DateTime(
                  now.year,
                  now.month + 1,
                  0,
                  23,
                  59,
                  59,
                );
                ref
                    .read(cashFlowProvider.notifier)
                    .filterByPeriod(startDate, endDate);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Mês Anterior'),
              onTap: () {
                final startDate = DateTime(now.year, now.month - 1, 1);
                final endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
                ref
                    .read(cashFlowProvider.notifier)
                    .filterByPeriod(startDate, endDate);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Período Personalizado'),
              onTap: () {
                Navigator.pop(context);
                _showCustomPeriodPicker(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomPeriodPicker(BuildContext context) async {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    // Selecionar data inicial
    startDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Selecione a data inicial',
    );

    if (startDate == null) return;

    // Selecionar data final
    endDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: startDate,
      lastDate: now,
      helpText: 'Selecione a data final',
    );

    if (endDate == null) return;

    // Aplicar filtro
    ref
        .read(cashFlowProvider.notifier)
        .filterByPeriod(
          DateTime(startDate.year, startDate.month, startDate.day),
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
        );
  }

  Future<void> _generatePDF(CashFlowState state) async {
    print('🔵 INICIANDO GERAÇÃO DE PDF...');
    try {
      print('🔵 Criando documento PDF...');
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');
      final now = DateTime.now();

      print('🔵 Separando receitas e despesas...');
      // Separar receitas e despesas
      final incomeEntries = state.entries
          .where((e) => e.type == 'income')
          .toList();
      final expenseEntries = state.entries
          .where((e) => e.type == 'expense')
          .toList();

      print('🔵 Buscando informações de vendas iFood...');
      // Criar mapa de sale_id -> isIfood
      final saleRepo = SaleRepository();
      final saleIfoodMap = <String, bool>{};

      for (final entry in incomeEntries) {
        if (entry.saleId != null) {
          try {
            final saleData = await saleRepo.getSaleWithItems(entry.saleId!);
            if (saleData != null) {
              saleIfoodMap[entry.saleId!] = saleData['sale'].isIfood;
            }
          } catch (e) {
            // Se não encontrar venda, assume Local
            saleIfoodMap[entry.saleId!] = false;
          }
        }
      }

      print('🔵 Calculando totais...');
      // Calcular totais
      final totalIncome = incomeEntries.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );
      final totalExpense = expenseEntries.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );
      final balance = totalIncome - totalExpense;

      print('🔵 Criando páginas do PDF...');
      // Criar PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Cabeçalho
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FLUXO DE CAIXA',
                    style: const pw.TextStyle(fontSize: 18),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Gerado em: ${dateFormat.format(now)} as ${DateFormat('HH:mm').format(now)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  if (state.startDate != null && state.endDate != null)
                    pw.Text(
                      'Periodo: ${dateFormat.format(state.startDate!)} a ${dateFormat.format(state.endDate!)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  pw.SizedBox(height: 16),
                  pw.Divider(),
                ],
              ),
            ),

            // Resumo
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'RECEITAS',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'R\$ ${totalIncome.toStringAsFixed(2)}',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.green,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'DESPESAS',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'R\$ ${totalExpense.toStringAsFixed(2)}',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('SALDO', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'R\$ ${balance.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: balance >= 0
                              ? PdfColors.blue
                              : PdfColors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Receitas
            if (incomeEntries.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('RECEITAS', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2), // Data
                  1: const pw.FlexColumnWidth(2.5), // Descrição
                  2: const pw.FlexColumnWidth(1.5), // Categoria
                  3: const pw.FlexColumnWidth(1.0), // Origem
                  4: const pw.FlexColumnWidth(1.5), // Valor
                },
                children: [
                  // Cabeçalho
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.green50,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Data',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Descrição',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Categoria',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Origem',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Valor',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  // Dados
                  ...incomeEntries.map((entry) {
                    // Determinar origem (iFood ou Local)
                    final isIfood = entry.saleId != null
                        ? (saleIfoodMap[entry.saleId!] ?? false)
                        : false;
                    final origem = isIfood ? 'iFood' : 'Local';

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            dateFormat.format(entry.date),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            entry.description,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            entry.category,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: isIfood
                                  ? PdfColors.red100
                                  : PdfColors.blue100,
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                            ),
                            child: pw.Text(
                              origem,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: isIfood
                                    ? PdfColors.red900
                                    : PdfColors.blue900,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'R\$ ${entry.amount.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                  // Subtotal
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.green100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'SUBTOTAL',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'R\$ ${totalIncome.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 11),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // Despesas
            if (expenseEntries.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text('DESPESAS', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Cabeçalho
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Data',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Descrição',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Categoria',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Valor',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  // Dados
                  ...expenseEntries.map(
                    (entry) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            dateFormat.format(entry.date),
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            entry.description,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            entry.category,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'R\$ ${entry.amount.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Subtotal
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'SUBTOTAL',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'R\$ ${totalExpense.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 11),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],

            // Total Geral
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: balance >= 0 ? PdfColors.blue50 : PdfColors.orange50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(
                  color: balance >= 0 ? PdfColors.blue : PdfColors.orange,
                  width: 2,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'SALDO FINAL',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.Text(
                    'R\$ ${balance.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: balance >= 0 ? PdfColors.blue : PdfColors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Rodapé
            pw.SizedBox(height: 32),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'SushiGen - Sistema de Gerenciamento',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

      print('🔵 Salvando documento PDF...');
      final pdfBytes = await pdf.save();
      print('🔵 PDF salvo! Tamanho: ${pdfBytes.length} bytes');

      print('🔵 Obtendo diretório de Downloads...');
      print('🟢 Platform.isMacOS = ${Platform.isMacOS}');
      // No macOS, usar o diretório de documentos do app (dentro do sandbox)
      Directory? directory;

      if (Platform.isMacOS || Platform.isWindows) {
        print('🟢 Usando pasta Documents para desktop...');
        // Para desktop, usar pasta de documentos DENTRO DO SANDBOX
        final appDocDir = await getApplicationDocumentsDirectory();
        print('🟢 appDocDir = ${appDocDir.path}');
        // Criar subpasta "PDFs" dentro do diretório de documentos do app
        directory = Directory('${appDocDir.path}/PDFs');
        print('🟢 Pasta final = ${directory.path}');
        if (!directory.existsSync()) {
          print('🟢 Pasta não existe, criando...');
          directory.createSync(recursive: true);
          print('📁 Pasta criada: ${directory.path}');
        } else {
          print('🟢 Pasta já existe!');
        }
      } else {
        print('🔴 Usando getDownloadsDirectory para mobile...');
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Não foi possível acessar a pasta de documentos');
      }

      final fileName =
          'fluxo_caixa_${dateFormat.format(now).replaceAll('/', '_')}.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      print('🔵 Salvando arquivo em: $filePath');
      await file.writeAsBytes(pdfBytes);
      print('🔵 PDF gerado com sucesso!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF salvo em:\n$filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'ABRIR',
              textColor: Colors.white,
              onPressed: () async {
                // Abrir pasta no Finder
                await Process.run('open', [directory!.path]);
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('🔴 ERRO AO GERAR PDF: $e');
      print('🔴 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _navigateToForm(
    BuildContext context,
    String type, {
    CashFlowEntry? entry,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashFlowFormScreen(type: type, entry: entry),
      ),
    );
  }
}
