import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/stock_provider.dart';
import '../../data/models/stock_entry.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockState = ref.watch(stockProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Estoque'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(stockProvider.notifier).loadStock(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Cards de resumo
          _buildSummaryCards(stockState, currencyFormat),

          // Filtros
          _buildFilterChips(context, ref, stockState),

          // Lista de produtos
          Expanded(
            child: stockState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stockState.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text('Erro: ${stockState.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(stockProvider.notifier).loadStock(),
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  )
                : stockState.entries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum produto encontrado',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: stockState.entries.length,
                    itemBuilder: (context, index) {
                      final entry = stockState.entries[index];
                      return _buildStockCard(
                        context,
                        ref,
                        entry,
                        currencyFormat,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIngredientInfo(context),
        icon: const Icon(Icons.add),
        label: const Text('Novo Ingrediente'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showAddIngredientInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Adicionar Ingrediente'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como adicionar um novo ingrediente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('1️⃣ Vá em "Gestão de Produtos"'),
            SizedBox(height: 8),
            Text('2️⃣ Clique no botão "+" para adicionar'),
            SizedBox(height: 8),
            Text('3️⃣ Cadastre o ingrediente como um produto'),
            SizedBox(height: 8),
            Text('4️⃣ Ele aparecerá automaticamente aqui'),
            SizedBox(height: 12),
            Text(
              '💡 Dica: Use nomes como "Arroz para Sushi", "Salmão Fresco", etc.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/products');
            },
            child: const Text('Ir para Produtos'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(StockState state, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Produtos',
              state.totalProducts.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Estoque Baixo',
              state.lowStockCount.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Sem Estoque',
              state.outOfStockCount.toString(),
              Icons.error,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    StockState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: state.filter == 'all',
            onSelected: (_) =>
                ref.read(stockProvider.notifier).setFilter('all'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Estoque Baixo'),
            selected: state.filter == 'low_stock',
            onSelected: (_) =>
                ref.read(stockProvider.notifier).setFilter('low_stock'),
            avatar: const Icon(Icons.warning, size: 18),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Sem Estoque'),
            selected: state.filter == 'out_of_stock',
            onSelected: (_) =>
                ref.read(stockProvider.notifier).setFilter('out_of_stock'),
            avatar: const Icon(Icons.error, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(
    BuildContext context,
    WidgetRef ref,
    StockEntry entry,
    NumberFormat currencyFormat,
  ) {
    final statusColor = _getStatusColor(entry.status);
    final statusText = _getStatusText(entry.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.quantity.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                entry.unit,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        title: Text(
          entry.productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Mín: ${entry.minQuantity.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (entry.lastPurchasePrice != null) ...[
              const SizedBox(height: 4),
              Text(
                'Último custo: ${currencyFormat.format(entry.lastPurchasePrice)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add',
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Adicionar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.remove_circle, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Remover'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'adjust',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Ajustar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Configurações'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'add':
                _showAddStockDialog(context, ref, entry);
                break;
              case 'remove':
                _showRemoveStockDialog(context, ref, entry);
                break;
              case 'adjust':
                _showAdjustStockDialog(context, ref, entry);
                break;
              case 'settings':
                _showSettingsDialog(context, ref, entry);
                break;
            }
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'out_of_stock':
        return Colors.red;
      case 'low_stock':
        return Colors.orange;
      case 'overstock':
        return Colors.purple;
      default:
        return Colors.green;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'out_of_stock':
        return 'SEM ESTOQUE';
      case 'low_stock':
        return 'ESTOQUE BAIXO';
      case 'overstock':
        return 'EXCESSO';
      default:
        return 'OK';
    }
  }

  void _showAddStockDialog(
    BuildContext context,
    WidgetRef ref,
    StockEntry entry,
  ) {
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adicionar Estoque - ${entry.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                suffixText: entry.unit,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Preço de Compra (opcional)',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantidade inválida')),
                );
                return;
              }

              final price = double.tryParse(priceController.text);
              final success = await ref
                  .read(stockProvider.notifier)
                  .addStock(entry.productId, quantity, purchasePrice: price);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Estoque adicionado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showRemoveStockDialog(
    BuildContext context,
    WidgetRef ref,
    StockEntry entry,
  ) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remover Estoque - ${entry.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Estoque atual: ${entry.quantity} ${entry.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantidade a remover',
                suffixText: entry.unit,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text);
              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantidade inválida')),
                );
                return;
              }

              if (quantity > entry.quantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Quantidade maior que o estoque disponível'),
                  ),
                );
                return;
              }

              final success = await ref
                  .read(stockProvider.notifier)
                  .removeStock(entry.productId, quantity);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Estoque removido com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(
    BuildContext context,
    WidgetRef ref,
    StockEntry entry,
  ) {
    final quantityController = TextEditingController(
      text: entry.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajustar Estoque - ${entry.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Defina a quantidade exata do estoque:'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                suffixText: entry.unit,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text);
              if (quantity == null || quantity < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantidade inválida')),
                );
                return;
              }

              final success = await ref
                  .read(stockProvider.notifier)
                  .updateStock(entry.productId, quantity);

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Estoque ajustado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    WidgetRef ref,
    StockEntry entry,
  ) {
    final unitController = TextEditingController(text: entry.unit);
    final minController = TextEditingController(
      text: entry.minQuantity.toString(),
    );
    final maxController = TextEditingController(
      text: entry.maxQuantity?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configurações - ${entry.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Unidade',
                hintText: 'un, kg, L, etc',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minController,
              decoration: const InputDecoration(
                labelText: 'Estoque Mínimo',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxController,
              decoration: const InputDecoration(
                labelText: 'Estoque Máximo (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final unit = unitController.text.trim();
              final min = double.tryParse(minController.text);
              final max = double.tryParse(maxController.text);

              if (unit.isEmpty || min == null || min < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dados inválidos')),
                );
                return;
              }

              final success = await ref
                  .read(stockProvider.notifier)
                  .updateSettings(
                    entry.productId,
                    unit: unit,
                    minQuantity: min,
                    maxQuantity: max,
                  );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Configurações salvas com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
