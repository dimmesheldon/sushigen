import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import 'generate_license_screen.dart';

class LicensesScreen extends ConsumerStatefulWidget {
  const LicensesScreen({super.key});

  @override
  ConsumerState<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends ConsumerState<LicensesScreen> {
  String _filterStatus = 'all'; // all, active, expired, revoked

  @override
  Widget build(BuildContext context) {
    final licensesState = ref.watch(licensesProvider);
    final customersState = ref.watch(customersProvider);

    var filteredLicenses = licensesState.licenses;
    if (_filterStatus == 'active') {
      filteredLicenses = licensesState.activeLicenses;
    } else if (_filterStatus == 'expired') {
      filteredLicenses = licensesState.expiredLicenses;
    } else if (_filterStatus == 'revoked') {
      filteredLicenses = licensesState.revokedLicenses;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Licenças'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Todas', 'all', filteredLicenses.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Ativas',
                  'active',
                  licensesState.activeLicenses.length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Expiradas',
                  'expired',
                  licensesState.expiredLicenses.length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Revogadas',
                  'revoked',
                  licensesState.revokedLicenses.length,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GenerateLicenseScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Gerar Licença'),
      ),
      body: licensesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : licensesState.error != null
          ? Center(child: Text('Erro: ${licensesState.error}'))
          : filteredLicenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.vpn_key_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterStatus == 'all'
                        ? 'Nenhuma licença cadastrada'
                        : 'Nenhuma licença ${_getFilterLabel()}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredLicenses.length,
              itemBuilder: (context, index) {
                final license = filteredLicenses[index];
                final customer = customersState.customers
                    .where((c) => c.id == license.customerId)
                    .firstOrNull;
                return _buildLicenseCard(context, license, customer?.name);
              },
            ),
    );
  }

  String _getFilterLabel() {
    switch (_filterStatus) {
      case 'active':
        return 'ativa';
      case 'expired':
        return 'expirada';
      case 'revoked':
        return 'revogada';
      default:
        return '';
    }
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildLicenseCard(
    BuildContext context,
    license,
    String? customerName,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isExpired = license.isExpired;
    final isRevoked = license.status == 'revoked';

    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    if (isRevoked) {
      statusColor = Colors.red;
      statusIcon = Icons.block;
    } else if (isExpired) {
      statusColor = Colors.orange;
      statusIcon = Icons.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(statusIcon, color: statusColor, size: 32),
        title: Text(
          license.username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customerName != null) Text('Cliente: $customerName'),
            const SizedBox(height: 4),
            Text(
              'Status: ${license.statusDisplay}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Usuário:', license.username),
                _buildInfoRow('Dias:', '${license.days} dias'),
                _buildInfoRow('Início:', dateFormat.format(license.startDate)),
                _buildInfoRow(
                  'Expiração:',
                  dateFormat.format(license.expirationDate),
                ),
                if (!isExpired && !isRevoked)
                  _buildInfoRow(
                    'Dias restantes:',
                    '${license.daysRemaining} dias',
                    color: license.daysRemaining <= 7 ? Colors.orange : null,
                  ),
                if (license.price != null)
                  _buildInfoRow(
                    'Valor:',
                    NumberFormat.currency(
                      locale: 'pt_BR',
                      symbol: 'R\$',
                    ).format(license.price),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chave de Licença:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: license.licenseKey),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chave copiada!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      tooltip: 'Copiar chave',
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    license.licenseKey,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    if (!isRevoked && !isExpired)
                      ElevatedButton.icon(
                        onPressed: () => _showRenewDialog(context, license),
                        icon: const Icon(Icons.update, size: 18),
                        label: const Text('Renovar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (!isRevoked)
                      OutlinedButton.icon(
                        onPressed: () => _showRevokeDialog(context, license),
                        icon: const Icon(Icons.block, size: 18),
                        label: const Text('Revogar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  void _showRenewDialog(BuildContext context, license) {
    final daysController = TextEditingController(text: '30');
    final priceController = TextEditingController();
    String paymentMethod = 'PIX';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renovar Licença'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysController,
              decoration: const InputDecoration(
                labelText: 'Dias adicionais',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Valor pago (R\$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Forma de Pagamento',
                border: OutlineInputBorder(),
              ),
              items: [
                'PIX',
                'Dinheiro',
                'Cartão',
                'Transferência',
              ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (value) => paymentMethod = value!,
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
              final days = int.tryParse(daysController.text) ?? 0;
              final price = double.tryParse(priceController.text);

              if (days <= 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Dias inválido')));
                return;
              }

              final success = await ref
                  .read(licensesProvider.notifier)
                  .renewLicense(
                    license.id,
                    days,
                    price: price,
                    paymentMethod: paymentMethod,
                  );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Licença renovada com sucesso!'
                          : 'Erro ao renovar licença',
                    ),
                  ),
                );
              }
            },
            child: const Text('Renovar'),
          ),
        ],
      ),
    );
  }

  void _showRevokeDialog(BuildContext context, license) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revogar Licença'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tem certeza que deseja revogar esta licença?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final reason = reasonController.text.isEmpty
                  ? 'Sem motivo especificado'
                  : reasonController.text;

              final success = await ref
                  .read(licensesProvider.notifier)
                  .revokeLicense(license.id, reason);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Licença revogada com sucesso!'
                          : 'Erro ao revogar licença',
                    ),
                  ),
                );
              }
            },
            child: const Text('Revogar'),
          ),
        ],
      ),
    );
  }
}
