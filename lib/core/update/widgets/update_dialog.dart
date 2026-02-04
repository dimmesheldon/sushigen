import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/release_info.dart';

/// Dialog para notificar sobre atualização disponível
class UpdateDialog extends StatelessWidget {
  final ReleaseInfo release;
  final String currentVersion;
  final VoidCallback? onRemindLater;
  final VoidCallback? onSkip;

  const UpdateDialog({
    Key? key,
    required this.release,
    required this.currentVersion,
    this.onRemindLater,
    this.onSkip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('🎉 Nova Versão Disponível!'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Versões
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Versão Atual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v$currentVersion',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  Column(
                    children: [
                      const Text(
                        'Nova Versão',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v${release.version}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nome do release
            if (release.name.isNotEmpty) ...[
              Text(
                release.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Descrição (changelog)
            if (release.description.isNotEmpty) ...[
              const Text(
                'Novidades:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    _formatDescription(release.description),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Informações adicionais
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seus dados serão preservados durante a atualização',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Ignorar esta versão
        if (onSkip != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onSkip!();
            },
            child: const Text('Ignorar'),
          ),

        // Lembrar depois
        if (onRemindLater != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRemindLater!();
            },
            child: const Text('Depois'),
          ),

        // Baixar atualização
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            await _downloadUpdate();
          },
          icon: const Icon(Icons.download),
          label: const Text('Baixar Atualização'),
        ),
      ],
    );
  }

  /// Formatar descrição do release
  String _formatDescription(String description) {
    // Limitar a 500 caracteres
    if (description.length > 500) {
      return '${description.substring(0, 500)}...';
    }
    return description;
  }

  /// Abrir página de download
  Future<void> _downloadUpdate() async {
    final url = release.downloadUrl.isNotEmpty
        ? release.downloadUrl
        : 'https://github.com/dimmesheldon/sushigen/releases/latest';

    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('❌ Não foi possível abrir URL: $url');
      }
    } catch (e) {
      print('❌ Erro ao abrir URL: $e');
    }
  }

  /// Mostrar dialog
  static Future<void> show(
    BuildContext context, {
    required ReleaseInfo release,
    required String currentVersion,
    VoidCallback? onRemindLater,
    VoidCallback? onSkip,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateDialog(
        release: release,
        currentVersion: currentVersion,
        onRemindLater: onRemindLater,
        onSkip: onSkip,
      ),
    );
  }
}

/// Dialog simples para verificação em progresso
class CheckingUpdateDialog extends StatelessWidget {
  const CheckingUpdateDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Verificando atualizações...'),
        ],
      ),
    );
  }

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CheckingUpdateDialog(),
    );
  }
}

/// Dialog de sucesso
class UpdateSuccessDialog extends StatelessWidget {
  final String message;

  const UpdateSuccessDialog({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text('✅ Tudo Certo!'),
        ],
      ),
      content: Text(message),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) => UpdateSuccessDialog(message: message),
    );
  }
}
