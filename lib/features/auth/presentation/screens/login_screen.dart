import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admin/presentation/screens/admin_login_screen.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/license.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseKeyController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  License? _existingLicense;

  @override
  void initState() {
    super.initState();
    _checkForExistingLicense();
  }

  Future<void> _checkForExistingLicense() async {
    // Espera o usuário digitar o username para verificar se já tem licença
    _userIdController.addListener(_onUsernameChanged);
  }

  Future<void> _onUsernameChanged() async {
    final username = _userIdController.text.trim();

    // 🔥 SUPERADMIN não precisa de licença!
    if (username.toLowerCase() == 'superadmin') {
      setState(() {
        _existingLicense = null; // Força a não mostrar campo de licença
      });
      return;
    }

    if (username.isEmpty || username.length < 3) {
      setState(() {
        _existingLicense = null;
      });
      return;
    }

    try {
      final license = await _authRepo.getActiveLicense(username);
      setState(() {
        _existingLicense = license;
        if (license != null) {
          _licenseKeyController.text = license.licenseKey;
        }
      });
    } catch (e) {
      setState(() {
        _existingLicense = null;
      });
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _licenseKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _userIdController.text.trim();
      final password = _passwordController.text;
      final licenseKey = _licenseKeyController.text.trim();

      // 🔥 SUPERADMIN não precisa de licença!
      if (username.toLowerCase() == 'superadmin') {
        await ref
            .read(authProvider.notifier)
            .login(username, password, ''); // Licença vazia para superadmin
      }
      // Se já existe licença ativa, não precisa validar novamente
      else if (_existingLicense != null) {
        await ref
            .read(authProvider.notifier)
            .loginWithoutLicense(username, password);
      } else {
        // Primeiro login ou licença expirada - valida a licença
        await ref
            .read(authProvider.notifier)
            .login(username, password, licenseKey);
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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

  String _getDaysRemainingText() {
    if (_existingLicense == null) return '';

    final daysRemaining = _existingLicense!.daysRemaining;

    if (daysRemaining < 0) {
      return '⚠️ Licença expirada!';
    } else if (daysRemaining == 0) {
      return '⚠️ Licença expira hoje!';
    } else if (daysRemaining == 1) {
      return '⏰ Expira em 1 dia';
    } else if (daysRemaining <= 7) {
      return '⚠️ Expira em $daysRemaining dias';
    } else if (daysRemaining <= 30) {
      return '⏰ Expira em $daysRemaining dias';
    } else {
      return '✅ Ativa - $daysRemaining dias restantes';
    }
  }

  Color _getDaysRemainingColor() {
    if (_existingLicense == null) return Colors.grey;

    final daysRemaining = _existingLicense!.daysRemaining;

    if (daysRemaining <= 0) {
      return Colors.red;
    } else if (daysRemaining <= 7) {
      return Colors.orange;
    } else if (daysRemaining <= 30) {
      return Colors.amber.shade700;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveLicense =
        _existingLicense != null && _existingLicense!.isValid;

    // 🔥 Detectar se é superadmin
    final bool isSuperAdmin =
        _userIdController.text.trim().toLowerCase() == 'superadmin';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red.shade700, Colors.red.shade900],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título
                      Text(
                        'SushiGen',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistema de Gerenciamento',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Campo ID do Usuário
                      TextFormField(
                        controller: _userIdController,
                        decoration: InputDecoration(
                          labelText: 'ID do Usuário',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Digite seu ID de usuário';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Senha
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite sua senha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo Chave de Licença - ESCONDIDO PARA SUPERADMIN!
                      if (!isSuperAdmin) ...[
                        TextFormField(
                          controller: _licenseKeyController,
                          enabled: !hasActiveLicense,
                          decoration: InputDecoration(
                            labelText: 'Chave de Licença',
                            prefixIcon: Icon(
                              hasActiveLicense ? Icons.lock : Icons.vpn_key,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: hasActiveLicense,
                            fillColor: hasActiveLicense
                                ? Colors.grey.shade100
                                : null,
                          ),
                          validator: (value) {
                            if (hasActiveLicense) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'Digite a chave de licença';
                            }
                            return null;
                          },
                        ),

                        // Status da licença
                        if (_existingLicense != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getDaysRemainingColor().withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getDaysRemainingColor(),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: _getDaysRemainingColor(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getDaysRemainingText(),
                                  style: TextStyle(
                                    color: _getDaysRemainingColor(),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // Badge para SUPERADMIN
                      if (isSuperAdmin) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.shade700,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: Colors.purple.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Acesso Administrativo',
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botão de Login
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'ENTRAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botão Área Administrativa
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AdminLoginScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Área Administrativa'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
