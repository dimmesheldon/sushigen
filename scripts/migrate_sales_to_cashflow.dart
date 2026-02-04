import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Script para migrar vendas existentes que não foram registradas no fluxo de caixa
///
/// Problema: Vendas antigas usavam nomes de colunas incorretos ao inserir no cash_flow
/// Solução: Este script lê todas as vendas e cria os registros faltantes no fluxo de caixa
///
/// Uso: dart run scripts/migrate_sales_to_cashflow.dart

void main() async {
  print('🔧 Iniciando migração de vendas para fluxo de caixa...\n');

  // Inicializar SQLite FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    // Abrir banco de dados (usar path do app)
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final path = join(appDocumentsDir.path, 'sushigen.db');

    print('📂 Abrindo banco de dados: $path');
    final db = await openDatabase(path);

    // 1. Buscar todas as vendas
    print('\n📊 Buscando todas as vendas...');
    final sales = await db.query(
      'sales',
      where: 'status != ?',
      whereArgs: ['cancelled'],
      orderBy: 'sale_date ASC',
    );
    print('   ✅ Encontradas ${sales.length} vendas');

    // 2. Buscar vendas já registradas no fluxo de caixa
    print('\n💰 Verificando fluxo de caixa...');
    final cashFlowEntries = await db.query(
      'cash_flow',
      where: 'category = ?',
      whereArgs: ['Venda'],
    );

    // Extrair IDs de vendas que já estão no cash_flow
    final registeredSaleIds = <String>{};
    for (final entry in cashFlowEntries) {
      final saleId = entry['sale_id'] as String?;
      if (saleId != null && saleId.isNotEmpty) {
        registeredSaleIds.add(saleId);
      }
    }
    print(
      '   ✅ ${registeredSaleIds.length} vendas já registradas no fluxo de caixa',
    );

    // 3. Identificar vendas faltantes
    final missingSales = sales.where((sale) {
      final saleId = sale['id'] as String;
      return !registeredSaleIds.contains(saleId);
    }).toList();

    if (missingSales.isEmpty) {
      print('\n✅ Todas as vendas já estão registradas no fluxo de caixa!');
      print('   Nenhuma migração necessária.');
      await db.close();
      return;
    }

    print(
      '\n⚠️  Encontradas ${missingSales.length} vendas NÃO registradas no fluxo de caixa:',
    );
    print('   ╔════════════════════════════════════════════════════════════╗');

    double totalMissing = 0;
    for (final sale in missingSales) {
      final saleNumber = sale['sale_number'];
      final finalAmount = sale['final_amount'] as double;
      final saleDate = sale['sale_date'];
      totalMissing += finalAmount;

      print(
        '   ║ Venda #$saleNumber - R\$ ${finalAmount.toStringAsFixed(2)} - $saleDate ║',
      );
    }
    print('   ╚════════════════════════════════════════════════════════════╝');
    print('   Total faltante: R\$ ${totalMissing.toStringAsFixed(2)}');

    // 4. Migrar vendas automaticamente (sem confirmação)
    print('\n🚀 Iniciando migração automática...\n');
    final uuid = const Uuid();
    int successCount = 0;
    int errorCount = 0;

    for (final sale in missingSales) {
      final saleId = sale['id'] as String;
      final saleNumber = sale['sale_number'];
      final userId = sale['user_id'] as String;
      final finalAmount = sale['final_amount'] as double;
      final saleDate = sale['sale_date'] as String;
      final createdAt = sale['created_at'] as String;

      try {
        await db.insert('cash_flow', {
          'id': uuid.v4(),
          'user_id': userId,
          'type': 'income',
          'category': 'Venda',
          'amount': finalAmount,
          'description': 'Venda #$saleNumber (migração)',
          'sale_id': saleId,
          'date': saleDate,
          'created_at': createdAt,
          'updated_at': DateTime.now().toIso8601String(),
          'synced': 0,
        });

        successCount++;
        print('   ✅ Venda #$saleNumber migrada com sucesso');
      } catch (e) {
        errorCount++;
        print('   ❌ Erro ao migrar Venda #$saleNumber: $e');
      }
    }

    // 6. Resumo final
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║                    RESUMO DA MIGRAÇÃO                      ║');
    print('╠════════════════════════════════════════════════════════════╣');
    print(
      '║ Total de vendas analisadas: ${sales.length.toString().padLeft(3)}                        ║',
    );
    print(
      '║ Vendas já registradas:      ${registeredSaleIds.length.toString().padLeft(3)}                        ║',
    );
    print(
      '║ Vendas migradas com sucesso: ${successCount.toString().padLeft(2)}                         ║',
    );
    print(
      '║ Erros durante migração:     ${errorCount.toString().padLeft(3)}                        ║',
    );
    print(
      '║ Valor total migrado:        R\$ ${totalMissing.toStringAsFixed(2).padLeft(10)}          ║',
    );
    print('╚════════════════════════════════════════════════════════════╝');

    if (errorCount == 0) {
      print('\n✅ Migração concluída com sucesso!');
      print('   Todas as vendas estão agora sincronizadas no fluxo de caixa.');
    } else {
      print('\n⚠️  Migração concluída com alguns erros.');
      print('   Verifique os logs acima para detalhes.');
    }

    await db.close();
  } catch (e) {
    print('\n❌ Erro fatal durante a migração: $e');
    print('   Stack trace: ${StackTrace.current}');
  }
}
