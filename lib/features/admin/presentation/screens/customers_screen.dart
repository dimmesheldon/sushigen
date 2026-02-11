import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/customer.dart';
import '../providers/admin_provider.dart';
import 'company_users_screen.dart';
import 'generate_license_screen.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Clientes'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomerDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Novo Cliente'),
      ),
      body: customersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : customersState.error != null
          ? Center(child: Text('Erro: ${customersState.error}'))
          : customersState.customers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum cliente cadastrado',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clique no botão + para adicionar',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customersState.customers.length,
              itemBuilder: (context, index) {
                final customer = customersState.customers[index];
                return _buildCustomerCard(context, ref, customer);
              },
            ),
    );
  }

  Widget _buildCustomerCard(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    final licensesState = ref.watch(licensesProvider);
    final customerLicenses = licensesState.licenses
        .where((l) => l.customerId == customer.id)
        .toList();
    final activeLicenses = customerLicenses
        .where((l) => l.status == 'active' && !l.isExpired)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(customer.email),
              ],
            ),
            if (customer.phone != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(customer.phone!),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('$activeLicenses licenças ativas'),
                  labelStyle: const TextStyle(fontSize: 12),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: activeLicenses > 0
                      ? Colors.green[100]
                      : Colors.grey[200],
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showCustomerDialog(context, ref, customer);
                break;
              case 'manage_users':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CompanyUsersScreen(customer: customer),
                  ),
                );
                break;
              case 'generate_license':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GenerateLicenseScreen(customer: customer),
                  ),
                );
                break;
              case 'delete':
                _showDeleteDialog(context, ref, customer);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'manage_users',
              child: Row(
                children: [
                  Icon(Icons.manage_accounts, size: 20),
                  SizedBox(width: 8),
                  Text('Gerenciar Usuários'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'generate_license',
              child: Row(
                children: [
                  Icon(Icons.vpn_key, size: 20),
                  SizedBox(width: 8),
                  Text('Gerar Licença'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Excluir', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDialog(
    BuildContext context,
    WidgetRef ref,
    Customer? customer,
  ) {
    final isEditing = customer != null;
    final nameController = TextEditingController(text: customer?.name);
    final emailController = TextEditingController(text: customer?.email);
    final phoneController = TextEditingController(text: customer?.phone);
    final businessNameController = TextEditingController(
      text: customer?.businessName,
    );
    final cnpjController = TextEditingController(text: customer?.cnpj);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Cliente' : 'Novo Cliente'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: businessNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Restaurante',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cnpjController,
                  decoration: const InputDecoration(
                    labelText: 'CNPJ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preencha os campos obrigatórios'),
                  ),
                );
                return;
              }

              final now = DateTime.now();
              final newCustomer = Customer(
                id: customer?.id ?? const Uuid().v4(),
                name: nameController.text,
                email: emailController.text,
                phone: phoneController.text.isEmpty
                    ? null
                    : phoneController.text,
                businessName: businessNameController.text.isEmpty
                    ? null
                    : businessNameController.text,
                cnpj: cnpjController.text.isEmpty ? null : cnpjController.text,
                createdAt: customer?.createdAt ?? now,
                updatedAt: now,
              );

              final success = isEditing
                  ? await ref
                        .read(customersProvider.notifier)
                        .updateCustomer(newCustomer)
                  : await ref
                        .read(customersProvider.notifier)
                        .createCustomer(newCustomer);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? isEditing
                                ? 'Cliente atualizado com sucesso!'
                                : 'Cliente cadastrado com sucesso!'
                          : 'Erro ao salvar cliente: ${ref.read(customersProvider).error ?? 'verifique os dados'}',
                    ),
                  ),
                );
              }
            },
            child: Text(isEditing ? 'Salvar' : 'Cadastrar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o cliente "${customer.name}"?\n\n'
          'Esta ação não pode ser desfeita.',
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
              final success = await ref
                  .read(customersProvider.notifier)
                  .deleteCustomer(customer.id);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Cliente excluído com sucesso!'
                          : 'Erro ao excluir cliente',
                    ),
                  ),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
