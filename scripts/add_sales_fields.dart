import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Script para adicionar novos campos na tabela sales
///
/// Campos adicionados:
/// - is_ifood INTEGER DEFAULT 0 (se a venda é do iFood)
/// - delivery_type TEXT DEFAULT 'Retirada' (Retirada/Entrega)
/// - delivery_cost REAL DEFAULT 0 (Taxa de entrega)

void main() async {
  print('🔧 Iniciando atualização do banco de dados...\n');

  // Inicializar SQLite FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    // Abrir banco de dados
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final path = join(appDocumentsDir.path, 'sushigen.db');

    print('📂 Abrindo banco de dados: $path');
    final db = await openDatabase(path);

    print('\n📊 Verificando estrutura atual da tabela sales...');

    // Verificar se as colunas já existem
    final columns = await db.rawQuery('PRAGMA table_info(sales)');
    final columnNames = columns.map((c) => c['name'] as String).toList();

    print('   Colunas existentes: ${columnNames.join(", ")}');

    // Adicionar coluna is_ifood
    if (!columnNames.contains('is_ifood')) {
      print('\n➕ Adicionando coluna: is_ifood');
      await db.execute(
        'ALTER TABLE sales ADD COLUMN is_ifood INTEGER DEFAULT 0',
      );
      print('   ✅ Coluna is_ifood adicionada');
    } else {
      print('\n✓  Coluna is_ifood já existe');
    }

    // Adicionar coluna delivery_type
    if (!columnNames.contains('delivery_type')) {
      print('\n➕ Adicionando coluna: delivery_type');
      await db.execute(
        'ALTER TABLE sales ADD COLUMN delivery_type TEXT DEFAULT "Retirada"',
      );
      print('   ✅ Coluna delivery_type adicionada');
    } else {
      print('\n✓  Coluna delivery_type já existe');
    }

    // Adicionar coluna delivery_cost
    if (!columnNames.contains('delivery_cost')) {
      print('\n➕ Adicionando coluna: delivery_cost');
      await db.execute(
        'ALTER TABLE sales ADD COLUMN delivery_cost REAL DEFAULT 0',
      );
      print('   ✅ Coluna delivery_cost adicionada');
    } else {
      print('\n✓  Coluna delivery_cost já existe');
    }

    print('\n📊 Verificando estrutura atualizada...');
    final newColumns = await db.rawQuery('PRAGMA table_info(sales)');
    final newColumnNames = newColumns.map((c) => c['name'] as String).toList();
    print('   Colunas atuais: ${newColumnNames.join(", ")}');

    await db.close();

    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║           ATUALIZAÇÃO CONCLUÍDA COM SUCESSO!              ║');
    print('╠════════════════════════════════════════════════════════════╣');
    print('║ Novos campos adicionados à tabela sales:                  ║');
    print('║                                                            ║');
    print('║ ✓ is_ifood       (INTEGER) - Se é venda do iFood          ║');
    print('║ ✓ delivery_type  (TEXT)    - Retirada/Entrega             ║');
    print('║ ✓ delivery_cost  (REAL)    - Taxa de entrega              ║');
    print('╚════════════════════════════════════════════════════════════╝');
  } catch (e) {
    print('\n❌ Erro durante a atualização: $e');
    print('   Stack trace: ${StackTrace.current}');
  }
}
