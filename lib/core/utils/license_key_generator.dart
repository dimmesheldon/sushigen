import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

/// Classe utilitária para gerar e validar chaves de licença
class LicenseKeyGenerator {
  static const _uuid = Uuid();

  /// Gera uma chave de licença no formato: XXXX-XXXX-XXXX-XXXX
  static String generate() {
    final uuid = _uuid.v4();
    final hash = sha256.convert(utf8.encode(uuid)).toString();

    // Pega os primeiros 16 caracteres e formata
    final key = hash.substring(0, 16).toUpperCase();

    return '${key.substring(0, 4)}-${key.substring(4, 8)}-${key.substring(8, 12)}-${key.substring(12, 16)}';
  }

  /// Gera múltiplas chaves de licença
  static List<String> generateMultiple(int count) {
    return List.generate(count, (index) => generate());
  }

  /// Valida o formato de uma chave de licença
  static bool isValidFormat(String key) {
    final pattern = RegExp(
      r'^[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}$',
    );
    return pattern.hasMatch(key);
  }

  /// Gera uma chave de licença personalizada com prefixo
  static String generateWithPrefix(String prefix) {
    final uuid = _uuid.v4();
    final hash = sha256.convert(utf8.encode('$prefix-$uuid')).toString();

    final key = hash.substring(0, 16).toUpperCase();

    return '${key.substring(0, 4)}-${key.substring(4, 8)}-${key.substring(8, 12)}-${key.substring(12, 16)}';
  }

  /// Gera chave com informações incorporadas (tipo de licença)
  static String generateTyped(LicenseType type) {
    String prefix;
    switch (type) {
      case LicenseType.trial:
        prefix = 'TRIAL';
        break;
      case LicenseType.monthly:
        prefix = 'MONTH';
        break;
      case LicenseType.yearly:
        prefix = 'YEAR';
        break;
      case LicenseType.lifetime:
        prefix = 'LIFE';
        break;
    }

    return generateWithPrefix(prefix);
  }
}

enum LicenseType {
  trial, // 7-30 dias
  monthly, // 30 dias
  yearly, // 365 dias
  lifetime, // Sem expiração
}

// Função auxiliar para calcular data de expiração
DateTime calculateExpirationDate(LicenseType type) {
  final now = DateTime.now();
  switch (type) {
    case LicenseType.trial:
      return now.add(const Duration(days: 30));
    case LicenseType.monthly:
      return now.add(const Duration(days: 30));
    case LicenseType.yearly:
      return now.add(const Duration(days: 365));
    case LicenseType.lifetime:
      return now.add(const Duration(days: 365 * 100)); // 100 anos
  }
}
