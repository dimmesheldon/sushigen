import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/release_info.dart';
import '../services/update_service.dart';
import 'update_dialog.dart';

/// Widget que verifica atualizações ao iniciar o app
class UpdateChecker extends ConsumerStatefulWidget {
  final Widget child;

  const UpdateChecker({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends ConsumerState<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    _initializeAndCheck();
  }

  Future<void> _initializeAndCheck() async {
    // Aguardar frame ser renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar se deve checar atualizações (1x por dia)
      if (!_shouldCheckForUpdates(prefs)) {
        print('ℹ️ Verificação de atualização já feita hoje');
        return;
      }

      // Verificar atualizações
      final updateService = UpdateService(
        owner: 'dimmesheldon',
        repo: 'sushigen',
      );

      final release = await updateService.getLatestRelease();
      if (release == null) {
        print('ℹ️ Nenhuma atualização encontrada');
        await _saveLastCheck(prefs);
        return;
      }

      // Obter versão atual
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Verificar se há atualização
      final hasUpdate = await updateService.hasUpdate(currentVersion);

      if (!hasUpdate) {
        print('✅ App está atualizado (v$currentVersion)');
        await _saveLastCheck(prefs);
        return;
      }

      // Verificar se versão foi ignorada
      if (_isVersionSkipped(prefs, release.version)) {
        print('ℹ️ Versão ${release.version} foi ignorada pelo usuário');
        await _saveLastCheck(prefs);
        return;
      }

      // Verificar se deve lembrar
      if (!_shouldRemindUpdate(prefs)) {
        print('ℹ️ Usuário pediu para lembrar depois');
        return;
      }

      // Mostrar dialog
      if (mounted) {
        await _saveLastCheck(prefs);
        _showUpdateDialog(release, currentVersion, prefs);
      }
    } catch (e) {
      print('⚠️ Erro ao verificar atualizações: $e');
    }
  }

  bool _shouldCheckForUpdates(SharedPreferences prefs) {
    final lastCheck = prefs.getInt('last_update_check');
    if (lastCheck == null) return true;

    final lastCheckDate = DateTime.fromMillisecondsSinceEpoch(lastCheck);
    final hoursSince = DateTime.now().difference(lastCheckDate).inHours;

    return hoursSince >= 24; // Verificar a cada 24h
  }

  Future<void> _saveLastCheck(SharedPreferences prefs) async {
    await prefs.setInt('last_update_check', DateTime.now().millisecondsSinceEpoch);
  }

  bool _shouldRemindUpdate(SharedPreferences prefs) {
    final timestamp = prefs.getInt('remind_update_later');
    if (timestamp == null) return true;

    final lastRemind = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hoursSince = DateTime.now().difference(lastRemind).inHours;

    return hoursSince >= 24; // Lembrar após 24h
  }

  bool _isVersionSkipped(SharedPreferences prefs, String version) {
    final skipped = prefs.getString('skipped_version');
    return skipped == version;
  }

  void _showUpdateDialog(
    ReleaseInfo release,
    String currentVersion,
    SharedPreferences prefs,
  ) {
    UpdateDialog.show(
      context,
      release: release,
      currentVersion: currentVersion,
      onRemindLater: () async {
        await prefs.setInt(
          'remind_update_later',
          DateTime.now().millisecondsSinceEpoch,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ok! Vou te lembrar amanhã 👍'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onSkip: () async {
        await prefs.setString('skipped_version', release.version);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Versão ${release.version} ignorada'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Menu de ação manual para verificar atualizações
class CheckUpdateButton extends StatelessWidget {
  const CheckUpdateButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.system_update),
      tooltip: 'Verificar Atualizações',
      onPressed: () => _checkManually(context),
    );
  }

  Future<void> _checkManually(BuildContext context) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CheckingUpdateDialog(),
    );

    try {
      // Verificar atualizações
      final updateService = UpdateService(
        owner: 'dimmesheldon',
        repo: 'sushigen',
      );

      final release = await updateService.getLatestRelease();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fechar loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (release == null) {
        if (context.mounted) {
          UpdateSuccessDialog.show(
            context,
            'Não foi possível verificar atualizações.\n\n'
            'Verifique sua conexão com a internet.',
          );
        }
        return;
      }

      // Verificar se há atualização
      final hasUpdate = await updateService.hasUpdate(currentVersion);

      if (hasUpdate) {
        if (context.mounted) {
          final prefs = await SharedPreferences.getInstance();
          UpdateDialog.show(
            context,
            release: release,
            currentVersion: currentVersion,
            onRemindLater: () async {
              await prefs.setInt(
                'remind_update_later',
                DateTime.now().millisecondsSinceEpoch,
              );
            },
            onSkip: () async {
              await prefs.setString('skipped_version', release.version);
            },
          );
        }
      } else {
        // Nenhuma atualização disponível
        if (context.mounted) {
          UpdateSuccessDialog.show(
            context,
            'Você já está usando a versão mais recente!\n\n'
            'Versão atual: v$currentVersion',
          );
        }
      }
    } catch (e) {
      // Fechar loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar erro
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao verificar atualizações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
