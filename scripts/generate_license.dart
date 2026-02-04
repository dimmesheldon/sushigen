import 'package:sushigen/core/utils/license_key_generator.dart';

/// Script simples para gerar chaves de licença
void main(List<String> args) {
  print('');
  print('🔑 ═══════════════════════════════════════════════');
  print('   SushiGen - Gerador de Chaves de Licença');
  print('═══════════════════════════════════════════════\n');

  if (args.isEmpty) {
    // Gera uma chave padrão
    print('📝 Gerando chave de licença padrão...\n');
    final key = LicenseKeyGenerator.generate();
    print('✅ Chave gerada:');
    print('   $key\n');

    print('📋 Use esta chave no login do sistema.');
    print('💡 Validade: configure ao criar a licença no banco.\n');
  } else if (args[0] == '--multiple' && args.length > 1) {
    // Gera múltiplas chaves
    final count = int.tryParse(args[1]) ?? 1;
    print('📝 Gerando $count chaves de licença...\n');

    final keys = LicenseKeyGenerator.generateMultiple(count);
    for (int i = 0; i < keys.length; i++) {
      print('${i + 1}. ${keys[i]}');
    }
    print('');
  } else if (args[0] == '--typed') {
    // Gera chaves por tipo
    print('📝 Gerando chaves por tipo de licença...\n');

    final trialKey = LicenseKeyGenerator.generateTyped(LicenseType.trial);
    final monthlyKey = LicenseKeyGenerator.generateTyped(LicenseType.monthly);
    final yearlyKey = LicenseKeyGenerator.generateTyped(LicenseType.yearly);
    final lifetimeKey = LicenseKeyGenerator.generateTyped(LicenseType.lifetime);

    print('🆓 Trial (30 dias):');
    print('   $trialKey\n');

    print('📅 Mensal (30 dias):');
    print('   $monthlyKey\n');

    print('📆 Anual (365 dias):');
    print('   $yearlyKey\n');

    print('♾️  Vitalícia (sem expiração):');
    print('   $lifetimeKey\n');
  } else {
    print('❌ Comando não reconhecido.\n');
    _printHelp();
  }

  print('═══════════════════════════════════════════════\n');
}

void _printHelp() {
  print('📚 Uso:');
  print(
    '   dart run scripts/generate_license.dart                # Gera 1 chave',
  );
  print(
    '   dart run scripts/generate_license.dart --multiple 5   # Gera 5 chaves',
  );
  print(
    '   dart run scripts/generate_license.dart --typed        # Gera por tipo',
  );
}
