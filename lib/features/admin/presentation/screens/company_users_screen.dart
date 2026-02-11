import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/company_user.dart';
import '../providers/admin_provider.dart';

class CompanyUsersScreen extends ConsumerStatefulWidget {
  final Customer customer;

  const CompanyUsersScreen({super.key, required this.customer});

  @override
  ConsumerState<CompanyUsersScreen> createState() => _CompanyUsersScreenState();
}

class _CompanyUsersScreenState extends ConsumerState<CompanyUsersScreen> {
  @override
  void initState() {
    super.initState();
    // Carregar usuários desta empresa
    Future.microtask(() {
      ref
          .read(companyUsersProvider.notifier)
          .loadUsersByCustomer(widget.customer.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(companyUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Usuários - ${widget.customer.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(companyUsersProvider.notifier)
                  .loadUsersByCustomer(widget.customer.id);
            },
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: usersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : usersState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar usuários',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(usersState.error!),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(companyUsersProvider.notifier)
                          .loadUsersByCustomer(widget.customer.id);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            )
          : usersState.users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum usuário cadastrado',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Adicione o primeiro usuário para esta empresa',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nome')),
                    DataColumn(label: Text('Usuário')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Cargo')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: usersState.users.map((user) {
                    return DataRow(
                      cells: [
                        DataCell(Text(user.fullName)),
                        DataCell(
                          Text(
                            user.username,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        DataCell(Text(user.email ?? '-')),
                        DataCell(
                          Chip(
                            label: Text(user.roleDisplay),
                            backgroundColor: _getRoleColor(user.role),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        ),
                        DataCell(
                          Icon(
                            user.isActive ? Icons.check_circle : Icons.cancel,
                            color: user.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showEditUserDialog(user),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.lock_reset,
                                  size: 20,
                                  color: Colors.orange,
                                ),
                                onPressed: () => _showResetPasswordDialog(user),
                                tooltip: 'Redefinir Senha',
                              ),
                              if (user.role != 'owner')
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDeleteUser(user),
                                  tooltip: 'Excluir',
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Usuário'),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      case 'operator':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'operator';
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Adicionar Usuário'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Digite o nome completo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Usuário *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_circle),
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Digite o usuário' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Senha *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (v) => (v?.isEmpty ?? true)
                        ? 'Digite a senha'
                        : (v!.length < 4 ? 'Mínimo 4 caracteres' : null),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Cargo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'owner',
                        child: Text('Proprietário'),
                      ),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text('Gerente'),
                      ),
                      DropdownMenuItem(
                        value: 'operator',
                        child: Text('Operador'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Usuário Ativo'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
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
                if (!formKey.currentState!.validate()) return;

                final newUser = CompanyUser(
                  id: '', // Será gerado pelo repository
                  customerId: widget.customer.id,
                  username: usernameController.text,
                  passwordHash:
                      passwordController.text, // Será hasheado no repo
                  fullName: fullNameController.text,
                  email: emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  role: selectedRole,
                  isActive: isActive,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final success = await ref
                    .read(companyUsersProvider.notifier)
                    .createUser(newUser);

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Usuário criado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(CompanyUser user) {
    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email ?? '');
    String selectedRole = user.role;
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Editar Usuário: ${user.username}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Digite o nome completo' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Cargo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'owner',
                        child: Text('Proprietário'),
                      ),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text('Gerente'),
                      ),
                      DropdownMenuItem(
                        value: 'operator',
                        child: Text('Operador'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Usuário Ativo'),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
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
                if (!formKey.currentState!.validate()) return;

                final updatedUser = user.copyWith(
                  fullName: fullNameController.text,
                  email: emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  role: selectedRole,
                  isActive: isActive,
                );

                final success = await ref
                    .read(companyUsersProvider.notifier)
                    .updateUser(updatedUser);

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Usuário atualizado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(CompanyUser user) {
    final formKey = GlobalKey<FormState>();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redefinir Senha: ${user.username}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: newPasswordController,
            decoration: const InputDecoration(
              labelText: 'Nova Senha *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (v) => (v?.isEmpty ?? true)
                ? 'Digite a nova senha'
                : (v!.length < 4 ? 'Mínimo 4 caracteres' : null),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final success = await ref
                  .read(companyUsersProvider.notifier)
                  .updateUserPassword(
                    user.id,
                    newPasswordController.text,
                    widget.customer.id,
                  );

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Senha atualizada!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(CompanyUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o usuário "${user.fullName}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await ref
                  .read(companyUsersProvider.notifier)
                  .deleteUser(user.id, widget.customer.id);

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Usuário excluído!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
