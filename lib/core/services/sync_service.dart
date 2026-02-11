import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Sincronizar produtos
  Future<void> syncProducts() async {
    try {
      // Obter customer_id atual
      final customerId = _dbHelper.getCurrentCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID não definido. Faça login primeiro.');
      }

      final db = await _dbHelper.database;

      // 1. Buscar produtos locais não sincronizados
      final localProducts = await db.query(
        'products',
        where: 'synced = ?',
        whereArgs: [0],
      );

      // 2. Upload para Firestore (subcoleção do cliente)
      for (var product in localProducts) {
        final productData = Map<String, dynamic>.from(product);

        // Converter timestamps para Firestore Timestamp
        if (productData['created_at'] is String) {
          productData['created_at'] = Timestamp.fromDate(
            DateTime.parse(productData['created_at']),
          );
        }
        if (productData['updated_at'] is String) {
          productData['updated_at'] = Timestamp.fromDate(
            DateTime.parse(productData['updated_at']),
          );
        }

        // Salvar em subcoleção do cliente
        await _firestore
            .collection('customers')
            .doc(customerId)
            .collection('products')
            .doc(product['id'] as String)
            .set(productData, SetOptions(merge: true));

        // 3. Marcar como sincronizado
        await db.update(
          'products',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [product['id']],
        );
      }

      print('✅ Produtos sincronizados: ${localProducts.length}');
    } catch (e) {
      print('❌ Erro ao sincronizar produtos: $e');
      rethrow;
    }
  }

  // Sincronizar vendas
  Future<void> syncSales() async {
    try {
      // Obter customer_id atual
      final customerId = _dbHelper.getCurrentCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID não definido. Faça login primeiro.');
      }

      final db = await _dbHelper.database;

      // 1. Buscar vendas não sincronizadas
      final localSales = await db.query(
        'sales',
        where: 'synced = ?',
        whereArgs: [0],
      );

      // 2. Upload para Firestore (subcoleção do cliente)
      for (var sale in localSales) {
        final saleData = Map<String, dynamic>.from(sale);

        // Converter timestamps
        if (saleData['sale_date'] is String) {
          saleData['sale_date'] = Timestamp.fromDate(
            DateTime.parse(saleData['sale_date']),
          );
        }
        if (saleData['created_at'] is String) {
          saleData['created_at'] = Timestamp.fromDate(
            DateTime.parse(saleData['created_at']),
          );
        }

        // Salvar em subcoleção do cliente
        await _firestore
            .collection('customers')
            .doc(customerId)
            .collection('sales')
            .doc(sale['id'] as String)
            .set(saleData, SetOptions(merge: true));

        // 3. Sincronizar itens da venda
        final saleItems = await db.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );

        for (var item in saleItems) {
          final itemData = Map<String, dynamic>.from(item);

          if (itemData['created_at'] is String) {
            itemData['created_at'] = Timestamp.fromDate(
              DateTime.parse(itemData['created_at']),
            );
          }

          await _firestore
              .collection('customers')
              .doc(customerId)
              .collection('sale_items')
              .doc(item['id'] as String)
              .set(itemData, SetOptions(merge: true));
        }

        // 4. Marcar como sincronizado
        await db.update(
          'sales',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [sale['id']],
        );
      }

      print('✅ Vendas sincronizadas: ${localSales.length}');
    } catch (e) {
      print('❌ Erro ao sincronizar vendas: $e');
      rethrow;
    }
  }

  // Sincronizar fluxo de caixa
  Future<void> syncCashFlow() async {
    try {
      // Obter customer_id atual
      final customerId = _dbHelper.getCurrentCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID não definido. Faça login primeiro.');
      }

      final db = await _dbHelper.database;

      final localEntries = await db.query(
        'cash_flow',
        where: 'synced = ?',
        whereArgs: [0],
      );

      for (var entry in localEntries) {
        final entryData = Map<String, dynamic>.from(entry);

        // Converter timestamps
        if (entryData['date'] is String) {
          entryData['date'] = Timestamp.fromDate(
            DateTime.parse(entryData['date']),
          );
        }
        if (entryData['created_at'] is String) {
          entryData['created_at'] = Timestamp.fromDate(
            DateTime.parse(entryData['created_at']),
          );
        }
        if (entryData['updated_at'] is String) {
          entryData['updated_at'] = Timestamp.fromDate(
            DateTime.parse(entryData['updated_at']),
          );
        }

        // Salvar em subcoleção do cliente
        await _firestore
            .collection('customers')
            .doc(customerId)
            .collection('cash_flow')
            .doc(entry['id'] as String)
            .set(entryData, SetOptions(merge: true));

        await db.update(
          'cash_flow',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }

      print('✅ Fluxo de caixa sincronizado: ${localEntries.length}');
    } catch (e) {
      print('❌ Erro ao sincronizar fluxo de caixa: $e');
      rethrow;
    }
  }

  // Sincronização completa
  Future<void> syncAll() async {
    print('🔄 Iniciando sincronização completa...');

    await syncProducts();
    await syncSales();
    await syncCashFlow();

    print('✅ Sincronização completa finalizada!');
  }

  // Baixar produtos do servidor
  Future<void> downloadProducts() async {
    try {
      // Obter customer_id atual
      final customerId = _dbHelper.getCurrentCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID não definido. Faça login primeiro.');
      }

      final db = await _dbHelper.database;

      // Buscar produtos da subcoleção do cliente
      final snapshot = await _firestore
          .collection('customers')
          .doc(customerId)
          .collection('products')
          .get();

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());

        // Converter Timestamps de volta para String
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['updated_at'] is Timestamp) {
          data['updated_at'] = (data['updated_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }

        // Verificar se já existe localmente
        final existing = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          // Inserir novo produto
          await db.insert('products', data);
        } else {
          // Atualizar produto existente (merge)
          final existingData = existing.first;
          final existingUpdatedAt = existingData['updated_at'] as String?;
          final newUpdatedAt = data['updated_at'] as String?;

          // Atualizar apenas se o servidor tem versão mais recente
          if (newUpdatedAt != null &&
              existingUpdatedAt != null &&
              DateTime.parse(
                newUpdatedAt,
              ).isAfter(DateTime.parse(existingUpdatedAt))) {
            await db.update(
              'products',
              data,
              where: 'id = ?',
              whereArgs: [doc.id],
            );
          }
        }
      }

      print('✅ Produtos baixados: ${snapshot.docs.length}');
    } catch (e) {
      print('❌ Erro ao baixar produtos: $e');
      rethrow;
    }
  }

  // Baixar vendas do servidor
  Future<void> downloadSales({DateTime? since}) async {
    try {
      // Obter customer_id atual
      final customerId = _dbHelper.getCurrentCustomerId();
      if (customerId == null) {
        throw Exception('Customer ID não definido. Faça login primeiro.');
      }

      final db = await _dbHelper.database;

      Query<Map<String, dynamic>> query = _firestore
          .collection('customers')
          .doc(customerId)
          .collection('sales');

      // Se especificado, baixar apenas vendas após uma data
      if (since != null) {
        query = query.where(
          'sale_date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        );
      }

      final snapshot = await query.get();

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());

        // Converter Timestamps
        if (data['sale_date'] is Timestamp) {
          data['sale_date'] = (data['sale_date'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['created_at'] is Timestamp) {
          data['created_at'] = (data['created_at'] as Timestamp)
              .toDate()
              .toIso8601String();
        }

        // Verificar se já existe
        final existing = await db.query(
          'sales',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          await db.insert('sales', data);

          // Baixar itens da venda da subcoleção do cliente
          final itemsSnapshot = await _firestore
              .collection('customers')
              .doc(customerId)
              .collection('sale_items')
              .where('sale_id', isEqualTo: doc.id)
              .get();

          for (var itemDoc in itemsSnapshot.docs) {
            final itemData = Map<String, dynamic>.from(itemDoc.data());

            if (itemData['created_at'] is Timestamp) {
              itemData['created_at'] = (itemData['created_at'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            }

            await db.insert('sale_items', itemData);
          }
        }
      }

      print('✅ Vendas baixadas: ${snapshot.docs.length}');
    } catch (e) {
      print('❌ Erro ao baixar vendas: $e');
      rethrow;
    }
  }

  // Download completo
  Future<void> downloadAll() async {
    print('🔄 Iniciando download completo...');

    await downloadProducts();
    await downloadSales();

    print('✅ Download completo finalizado!');
  }

  // Obter contagem de itens não sincronizados
  Future<Map<String, int>> getUnsyncedCounts() async {
    try {
      final db = await _dbHelper.database;

      final products = await db.query(
        'products',
        where: 'synced = ?',
        whereArgs: [0],
      );

      final sales = await db.query(
        'sales',
        where: 'synced = ?',
        whereArgs: [0],
      );

      final cashFlow = await db.query(
        'cash_flow',
        where: 'synced = ?',
        whereArgs: [0],
      );

      return {
        'products': products.length,
        'sales': sales.length,
        'cash_flow': cashFlow.length,
        'total': products.length + sales.length + cashFlow.length,
      };
    } catch (e) {
      print('❌ Erro ao contar itens não sincronizados: $e');
      return {'products': 0, 'sales': 0, 'cash_flow': 0, 'total': 0};
    }
  }
}
