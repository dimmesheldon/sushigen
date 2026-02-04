import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../providers/admin_provider.dart';

class GenerateLicenseScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const GenerateLicenseScreen({super.key, this.customer});

  @override
  ConsumerState<GenerateLicenseScreen> createState() =>
      _GenerateLicenseScreenState();
}

class _GenerateLicenseScreenState extends ConsumerState<GenerateLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  int _selectedDays = 30;
  String _paymentMethod = 'PIX';
  bool _isGenerating = false;
  String? _generatedLicenseKey;

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
    if (_selectedCustomer != null) {
      // Sugerir username baseado no nome do cliente
      final nameParts = _selectedCustomer!.name.toLowerCase().split(' ');
      _usernameController.text = nameParts.first;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerar Nova Licença'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Preencha os dados para gerar uma nova licença',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Seleção de Cliente
              DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: const InputDecoration(
                  labelText: 'Cliente *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                items: customersState.customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer,
                    child: Text(customer.name),
                  );
                }).toList(),
                onChanged: (customer) {
                  setState(() {
                    _selectedCustomer = customer;
                    if (customer != null && _usernameController.text.isEmpty) {
                      final nameParts = customer.name.toLowerCase().split(' ');
                      _usernameController.text = nameParts.first;
                    }
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione um cliente' : null,
              ),
              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuário *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                  helperText: 'Nome de usuário para login no sistema',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite um usuário';
                  }
                  if (value.length < 3) {
                    return 'Mínimo 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Senha
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  helperText: 'Senha para login no sistema',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite uma senha';
                  }
                  if (value.length < 4) {
                    return 'Mínimo 4 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Planos Pré-definidos
              Text(
                'Escolha o plano:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPlanChip('30 dias', 30, 49.90),
                  _buildPlanChip('90 dias', 90, 129.90),
                  _buildPlanChip('365 dias', 365, 497.00),
                ],
              ),
              const SizedBox(height: 24),

              // Valor
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Forma de Pagamento
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Forma de Pagamento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payment),
                ),
                items:
                    [
                      'PIX',
                      'Dinheiro',
                      'Débito',
                      'Crédito',
                      'Transferência',
                      'Boleto',
                    ].map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Observações
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Botão Gerar
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateLicense,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.vpn_key),
                label: Text(_isGenerating ? 'Gerando...' : 'Gerar Licença'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),

              // Licença Gerada
              if (_generatedLicenseKey != null) ...[
                const SizedBox(height: 32),
                _buildGeneratedLicenseCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanChip(String label, int days, double suggestedPrice) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDays = days;
          _priceController.text = suggestedPrice.toStringAsFixed(2);
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildGeneratedLicenseCard() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                const SizedBox(width: 12),
                Text(
                  'Licença Gerada com Sucesso!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Usuário:', _usernameController.text),
            _buildInfoRow('Senha:', _passwordController.text),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chave de Licença:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton.filled(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _generatedLicenseKey!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chave copiada!')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copiar chave',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: SelectableText(
                _generatedLicenseKey!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Concluir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Future<void> _generateLicense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) return;

    setState(() {
      _isGenerating = true;
    });

    final price = double.tryParse(_priceController.text);

    final license = await ref
        .read(licensesProvider.notifier)
        .generateLicense(
          customerId: _selectedCustomer!.id,
          username: _usernameController.text,
          password: _passwordController.text,
          days: _selectedDays,
          price: price,
          paymentMethod: _paymentMethod,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

    setState(() {
      _isGenerating = false;
    });

    if (license != null) {
      setState(() {
        _generatedLicenseKey = license.licenseKey;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Licença gerada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erro ao gerar licença'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
