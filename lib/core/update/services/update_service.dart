import 'dart:io';
import 'package:dio/dio.dart';
import '../models/release_info.dart';

/// Serviço para verificar e baixar atualizações do GitHub
class UpdateService {
  final Dio _dio;
  final String owner;
  final String repo;

  UpdateService({
    required this.owner,
    required this.repo,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// URL base da API do GitHub
  String get _apiBaseUrl => 'https://api.github.com/repos/$owner/$repo';

  /// Buscar última versão disponível no GitHub Releases
  Future<ReleaseInfo?> getLatestRelease() async {
    try {
      final response = await _dio.get(
        '$_apiBaseUrl/releases/latest',
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return ReleaseInfo.fromJson(response.data);
      } else if (response.statusCode == 404) {
        // Nenhum release encontrado
        print('⚠️ Nenhum release encontrado no GitHub');
        return null;
      } else {
        print('❌ Erro ao buscar release: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao verificar atualizações: $e');
      return null;
    }
  }

  /// Verificar se há atualização disponível
  Future<bool> hasUpdate(String currentVersion) async {
    try {
      final latestRelease = await getLatestRelease();
      if (latestRelease == null) return false;

      final latest = _parseVersion(latestRelease.version);
      final current = _parseVersion(currentVersion);

      return _isNewerVersion(latest, current);
    } catch (e) {
      print('❌ Erro ao verificar se há atualização: $e');
      return false;
    }
  }

  /// Baixar atualização (retorna progresso)
  Future<void> downloadUpdate(
    String downloadUrl,
    String savePath,
    Function(int received, int total)? onProgress,
  ) async {
    try {
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total != -1) {
            onProgress(received, total);
          }
        },
      );
    } catch (e) {
      print('❌ Erro ao baixar atualização: $e');
      rethrow;
    }
  }

  /// Parse de versão (1.2.3 -> [1, 2, 3])
  List<int> _parseVersion(String version) {
    // Remove 'v' se tiver
    version = version.startsWith('v') ? version.substring(1) : version;

    // Remove build number (+1, +2, etc)
    if (version.contains('+')) {
      version = version.split('+')[0];
    }

    return version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }

  /// Comparar versões (retorna true se v1 > v2)
  bool _isNewerVersion(List<int> v1, List<int> v2) {
    for (int i = 0; i < 3; i++) {
      final n1 = i < v1.length ? v1[i] : 0;
      final n2 = i < v2.length ? v2[i] : 0;

      if (n1 > n2) return true;
      if (n1 < n2) return false;
    }
    return false; // Versões iguais
  }

  /// Obter informações da plataforma atual
  String getCurrentPlatform() {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Verificar se o asset é compatível com a plataforma atual
  bool isCompatibleAsset(String assetName) {
    final platform = getCurrentPlatform();
    final name = assetName.toLowerCase();

    switch (platform) {
      case 'macos':
        return name.contains('macos') ||
            name.contains('darwin') ||
            name.endsWith('.dmg');
      case 'windows':
        return name.contains('windows') ||
            name.contains('win') ||
            name.endsWith('.exe') ||
            name.endsWith('.msi');
      case 'linux':
        return name.contains('linux') ||
            name.endsWith('.deb') ||
            name.endsWith('.rpm') ||
            name.endsWith('.appimage');
      default:
        return false;
    }
  }
}
