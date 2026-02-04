/// Modelo de informações de release do GitHub
class ReleaseInfo {
  final String version;
  final String tagName;
  final String name;
  final String description;
  final String publishedAt;
  final List<ReleaseAsset> assets;
  final bool isPrerelease;
  final String downloadUrl;

  ReleaseInfo({
    required this.version,
    required this.tagName,
    required this.name,
    required this.description,
    required this.publishedAt,
    required this.assets,
    required this.isPrerelease,
    required this.downloadUrl,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final assets = (json['assets'] as List?)
            ?.map((asset) => ReleaseAsset.fromJson(asset))
            .toList() ??
        [];

    // Detectar plataforma e obter URL correto
    String downloadUrl = '';
    for (var asset in assets) {
      if (_isCurrentPlatformAsset(asset.name)) {
        downloadUrl = asset.browserDownloadUrl;
        break;
      }
    }

    return ReleaseInfo(
      version: _parseVersion(json['tag_name'] ?? ''),
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      description: json['body'] ?? '',
      publishedAt: json['published_at'] ?? '',
      assets: assets,
      isPrerelease: json['prerelease'] ?? false,
      downloadUrl: downloadUrl,
    );
  }

  static String _parseVersion(String tagName) {
    // Remove 'v' do início se tiver (v1.0.0 -> 1.0.0)
    return tagName.startsWith('v') ? tagName.substring(1) : tagName;
  }

  static bool _isCurrentPlatformAsset(String assetName) {
    final name = assetName.toLowerCase();
    
    // macOS
    if (_isMacOS) {
      return name.contains('macos') || name.contains('darwin') || name.endsWith('.dmg');
    }
    
    // Windows
    if (_isWindows) {
      return name.contains('windows') || name.contains('win') || name.endsWith('.exe');
    }
    
    return false;
  }

  static bool get _isMacOS {
    return const bool.fromEnvironment('dart.library.io') &&
        _platformString.contains('macos');
  }

  static bool get _isWindows {
    return const bool.fromEnvironment('dart.library.io') &&
        _platformString.contains('windows');
  }

  static String get _platformString {
    // Implementação simplificada
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'tag_name': tagName,
      'name': name,
      'description': description,
      'published_at': publishedAt,
      'assets': assets.map((a) => a.toJson()).toList(),
      'prerelease': isPrerelease,
      'download_url': downloadUrl,
    };
  }
}

/// Modelo de asset (arquivo) do release
class ReleaseAsset {
  final String name;
  final String browserDownloadUrl;
  final int size;
  final String contentType;

  ReleaseAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
    required this.contentType,
  });

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] ?? '',
      browserDownloadUrl: json['browser_download_url'] ?? '',
      size: json['size'] ?? 0,
      contentType: json['content_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'browser_download_url': browserDownloadUrl,
      'size': size,
      'content_type': contentType,
    };
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
