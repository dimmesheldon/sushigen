import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cash_flow_entry.dart';
import '../providers/cash_flow_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/currency_input_formatter.dart';

class CashFlowFormScreen extends ConsumerStatefulWidget {
  final String type; // 'income' ou 'expense'
  final CashFlowEntry? entry; // Para edição

  const CashFlowFormScreen({super.key, required this.type, this.entry});

  @override
  ConsumerState<CashFlowFormScreen> createState() => _CashFlowFormScreenState();
}

class _CashFlowFormScreenState extends ConsumerState<CashFlowFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.entry != null) {
      _descriptionController.text = widget.entry!.description;
      _amountController.text = CurrencyParser.format(widget.entry!.amount);
      _selectedCategory = widget.entry!.category;
      _selectedDate = widget.entry!.date;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    return widget.type == 'income'
        ? CashFlowCategories.incomeCategories
        : CashFlowCategories.expenseCategories;
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;
    final title = widget.entry != null
        ? 'Editar ${isIncome ? 'Receita' : 'Despesa'}'
        : 'Nova ${isIncome ? 'Receita' : 'Despesa'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Descrição
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descrição *',
                hintText: 'Ex: Pagamento de fornecedor',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 100,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite uma descrição';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Categoria
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoria *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecione uma categoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Valor
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Valor *',
                prefixText: 'R\$ ',
                hintText: '0,00',
                prefixIcon: Icon(
                  isIncome ? Icons.add_circle : Icons.remove_circle,
                  color: color,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite o valor';
                }
                final amount = CurrencyParser.parse(value);
                if (amount <= 0) {
                  return 'Valor deve ser maior que zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Data
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.id ?? '';

      final entry = CashFlowEntry.create(
        type: widget.type,
        category: _selectedCategory!,
        amount: CurrencyParser.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        userId: userId,
      );

      if (widget.entry != null) {
        // Editar
        final updatedEntry = entry.copyWith(
          id: widget.entry!.id,
          createdAt: widget.entry!.createdAt,
        );
        await ref.read(cashFlowProvider.notifier).updateEntry(updatedEntry);
      } else {
        // Criar novo
        await ref.read(cashFlowProvider.notifier).addEntry(entry);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entry != null
                  ? 'Entrada atualizada com sucesso!'
                  : 'Entrada adicionada com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
