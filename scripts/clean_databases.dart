import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Script de Limpeza Completa dos Bancos de Dados
///
/// ATENÇÃO: Este script apaga TODOS os bancos de dados do sistema!
/// Use apenas para desenvolvimento/testes.
///
/// O que será apagado:
/// - sushigen_admin.db (banco administrativo)
/// - sushigen_db_*.db (todos os bancos de clientes)
///
/// Após executar, será necessário:
/// 1. Criar novo cliente no admin
/// 2. Gerar nova licença
/// 3. Criar usuários para o cliente
/// 4. Fazer login como usuário do cliente

void main() async {
  print('🗑️  LIMPEZA COMPLETA DOS BANCOS DE DADOS');
  print('=' * 50);
  print('⚠️  ATENÇÃO: Isso apagará TODOS os dados!');
  print('=' * 50);

  // Inicializar FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    // Obter diretório de bancos
    final databasesPath = await databaseFactory.getDatabasesPath();
    print('\n📁 Diretório: $databasesPath');

    final directory = Directory(databasesPath);
    if (!directory.existsSync()) {
      print('❌ Diretório não existe!');
      return;
    }

    // Listar todos os arquivos .db
    final files = directory
        .listSync()
        .where((file) => file.path.endsWith('.db'))
        .toList();

    if (files.isEmpty) {
      print('✅ Nenhum banco de dados encontrado.');
      return;
    }

    print('\n🔍 Bancos encontrados:');
    for (var file in files) {
      print('   - ${path.basename(file.path)}');
    }

    print('\n⏳ Apagando bancos...');

    int deletedCount = 0;
    for (var file in files) {
      try {
        final fileName = path.basename(file.path);

        // Fechar banco se estiver aberto
        try {
          await databaseFactory.deleteDatabase(file.path);
        } catch (e) {
          // Se não conseguir deletar pelo factory, força exclusão
          File(file.path).deleteSync();
        }

        print('   ✅ $fileName apagado');
        deletedCount++;
      } catch (e) {
        print('   ❌ Erro ao apagar ${path.basename(file.path)}: $e');
      }
    }

    print('\n' + '=' * 50);
    print('✅ Limpeza concluída!');
    print('📊 Total de bancos apagados: $deletedCount');
    print('=' * 50);

    print('\n📝 Próximos passos:');
    print('1. Reinicie o aplicativo');
    print('2. Acesse o Admin com senha padrão');
    print('3. Crie novo cliente');
    print('4. Gere nova licença');
    print('5. Crie usuários para o cliente');
    print('6. Faça login como usuário do cliente');
  } catch (e) {
    print('\n❌ Erro: $e');
  }
}
