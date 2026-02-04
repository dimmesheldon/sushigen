import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/license.dart';
import '../providers/auth_provider.dart';

class LicenseRenewalScreen extends ConsumerStatefulWidget {
  const LicenseRenewalScreen({super.key});

  @override
  ConsumerState<LicenseRenewalScreen> createState() =>
      _LicenseRenewalScreenState();
}

class _LicenseRenewalScreenState extends ConsumerState<LicenseRenewalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseKeyController = TextEditingController();
  final _authRepo = AuthRepository();

  bool _isLoading = false;
  License? _currentLicense;

  @override
  void initState() {
    super.initState();
    _loadCurrentLicense();
  }

  Future<void> _loadCurrentLicense() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    try {
      final license = await _authRepo.getActiveLicense(user.username);
      setState(() {
        _currentLicense = license;
      });
    } catch (e) {
      // Sem licença ativa
    }
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleRenewal() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepo.updateUserLicense(
        username: user.username,
        licenseKey: _licenseKeyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Licença renovada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
    if (_currentLicense == null) return 'Sem licença ativa';

    final daysRemaining = _currentLicense!.daysRemaining;

    if (daysRemaining < 0) {
      return 'Licença expirada há ${-daysRemaining} dias';
    } else if (daysRemaining == 0) {
      return 'Licença expira hoje!';
    } else if (daysRemaining == 1) {
      return 'Expira em 1 dia';
    } else {
      return 'Expira em $daysRemaining dias';
    }
  }

  Color _getStatusColor() {
    if (_currentLicense == null) return Colors.grey;

    final daysRemaining = _currentLicense!.daysRemaining;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renovar Licença'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card de status atual
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Status da Licença Atual',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      if (_currentLicense != null) ...[
                        _buildInfoRow(
                          'Chave',
                          _currentLicense!.licenseKey,
                          Icons.vpn_key,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Expira em',
                          _currentLicense!.expirationDate.toString().split(
                            ' ',
                          )[0],
                          Icons.calendar_today,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _currentLicense!.daysRemaining <= 0
                                    ? Icons.error_outline
                                    : Icons.access_time,
                                color: _getStatusColor(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getDaysRemainingText(),
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 48,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhuma licença ativa encontrada',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Instruções
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Digite a nova chave de licença para renovar ou estender o período de uso do sistema.',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Campo para nova licença
              TextFormField(
                controller: _licenseKeyController,
                decoration: InputDecoration(
                  labelText: 'Nova Chave de Licença',
                  hintText: 'XXXX-XXXX-XXXX-XXXX',
                  prefixIcon: const Icon(Icons.vpn_key),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite a nova chave de licença';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Botão de renovação
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleRenewal,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text(
                    'RENOVAR LICENÇA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
