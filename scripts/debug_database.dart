import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  print('🔍 DEBUG: Verificando bancos de dados do SushiGen\n');

  // Inicializar FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Obter diretório de documentos
  final Directory appDocumentsDir = Platform.isMacOS
      ? Directory(
          '${Platform.environment['HOME']}/Library/Application Support/com.sushigen.app',
        )
      : await getApplicationDocumentsDirectory();

  print('📁 Diretório: ${appDocumentsDir.path}\n');

  // Verificar banco administrativo
  final String adminDbPath = join(appDocumentsDir.path, 'sushigen_admin.db');
  print('🗄️  Banco Administrativo: $adminDbPath');

  if (File(adminDbPath).existsSync()) {
    print('   ✅ Arquivo existe (${File(adminDbPath).lengthSync()} bytes)');

    try {
      final adminDb = await openDatabase(adminDbPath);

      // Listar usuários
      print('\n👥 USUÁRIOS:');
      final users = await adminDb.query('users');
      if (users.isEmpty) {
        print('   ❌ Nenhum usuário cadastrado');
      } else {
        for (var user in users) {
          print('   • ${user['username']} (ID: ${user['id']})');
        }
      }

      // Listar licenças
      print('\n🔑 LICENÇAS:');
      final licenses = await adminDb.query('licenses');
      if (licenses.isEmpty) {
        print('   ❌ Nenhuma licença cadastrada');
      } else {
        for (var license in licenses) {
          print('   • ${license['license_key']}');
          print(
            '     Status: ${license['is_active'] == 1 ? 'ATIVA' : 'INATIVA'}',
          );
          print('     Expira: ${license['expiry_date']}');
          print('     Username: ${license['username']}');
        }
      }

      // Listar clientes (se houver tabela)
      try {
        print('\n👤 CLIENTES (Banco Admin):');
        final clients = await adminDb.query('clients');
        if (clients.isEmpty) {
          print('   ℹ️  Nenhum cliente cadastrado');
        } else {
          for (var client in clients) {
            print('   • ${client['name']} (Username: ${client['username']})');
          }
        }
      } catch (e) {
        print('   ℹ️  Tabela clients não existe no banco admin');
      }

      await adminDb.close();
    } catch (e) {
      print('   ❌ Erro ao abrir banco: $e');
    }
  } else {
    print('   ❌ Arquivo não existe!');
  }

  // Listar bancos de usuários
  print('\n\n🗄️  BANCOS DE USUÁRIOS:');
  final files = appDocumentsDir.listSync();
  final userDbs = files
      .where(
        (f) =>
            f.path.endsWith('.db') &&
            !f.path.contains('admin') &&
            f.path.contains('sushigen_'),
      )
      .toList();

  if (userDbs.isEmpty) {
    print('   ℹ️  Nenhum banco de usuário criado ainda');
  } else {
    for (var dbFile in userDbs) {
      final dbName = basename(dbFile.path);
      final username = dbName.replaceAll('sushigen_', '').replaceAll('.db', '');
      print('\n   📊 $dbName (Usuário: $username)');
      print('      Tamanho: ${File(dbFile.path).lengthSync()} bytes');

      try {
        final userDb = await openDatabase(dbFile.path);

        // Contar produtos
        final products = await userDb.query('products');
        print('      Produtos: ${products.length}');

        // Contar vendas
        final sales = await userDb.query('sales');
        print('      Vendas: ${sales.length}');

        await userDb.close();
      } catch (e) {
        print('      ❌ Erro ao ler: $e');
      }
    }
  }

  print('\n\n✅ Análise concluída!');
  print('═' * 60);
}
