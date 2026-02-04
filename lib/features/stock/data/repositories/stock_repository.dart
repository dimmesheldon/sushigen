import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../models/stock_entry.dart';

class StockRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // Buscar todas as entradas de estoque
  Future<List<StockEntry>> getAllStock() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT s.*, p.name as product_name
      FROM stock s
      INNER JOIN products p ON s.product_id = p.id
      WHERE p.is_active = 1
      ORDER BY p.name ASC
    ''');
    return result.map((map) => StockEntry.fromMap(map)).toList();
  }

  // Buscar estoque por produto
  Future<StockEntry?> getStockByProduct(String productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      '''
      SELECT s.*, p.name as product_name
      FROM stock s
      INNER JOIN products p ON s.product_id = p.id
      WHERE s.product_id = ?
    ''',
      [productId],
    );

    if (result.isEmpty) return null;
    return StockEntry.fromMap(result.first);
  }

  // Buscar produtos com estoque baixo
  Future<List<StockEntry>> getLowStockProducts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT s.*, p.name as product_name
      FROM stock s
      INNER JOIN products p ON s.product_id = p.id
      WHERE p.is_active = 1 AND s.quantity <= s.min_quantity
      ORDER BY s.quantity ASC
    ''');
    return result.map((map) => StockEntry.fromMap(map)).toList();
  }

  // Buscar produtos sem estoque
  Future<List<StockEntry>> getOutOfStockProducts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT s.*, p.name as product_name
      FROM stock s
      INNER JOIN products p ON s.product_id = p.id
      WHERE p.is_active = 1 AND s.quantity <= 0
      ORDER BY p.name ASC
    ''');
    return result.map((map) => StockEntry.fromMap(map)).toList();
  }

  // Criar entrada de estoque inicial para produto
  Future<void> createStockEntry(
    String productId, {
    double quantity = 0,
    String unit = 'un',
    double minQuantity = 0,
    double? maxQuantity,
  }) async {
    final db = await _dbHelper.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert('stock', {
      'id': id,
      'product_id': productId,
      'quantity': quantity,
      'unit': unit,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'updated_at': now,
    });
  }

  // Atualizar quantidade do estoque
  Future<void> updateStock(String productId, double newQuantity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'stock',
      {'quantity': newQuantity, 'updated_at': now, 'synced': 0},
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  // Adicionar quantidade ao estoque (entrada)
  Future<void> addStock(
    String productId,
    double quantity, {
    double? purchasePrice,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final current = await getStockByProduct(productId);
    if (current == null) {
      // Criar entrada se não existir
      await createStockEntry(productId, quantity: quantity);
      return;
    }

    final newQuantity = current.quantity + quantity;
    final updates = <String, dynamic>{
      'quantity': newQuantity,
      'updated_at': now,
      'synced': 0,
    };

    if (purchasePrice != null) {
      updates['last_purchase_date'] = now;
      updates['last_purchase_price'] = purchasePrice;
    }

    await db.update(
      'stock',
      updates,
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  // Remover quantidade do estoque (saída/venda)
  Future<bool> removeStock(String productId, double quantity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final current = await getStockByProduct(productId);
    if (current == null) return false;

    final newQuantity = current.quantity - quantity;
    if (newQuantity < 0) return false; // Não permite estoque negativo

    await db.update(
      'stock',
      {'quantity': newQuantity, 'updated_at': now, 'synced': 0},
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    return true;
  }

  // Atualizar configurações de estoque (mín, máx, unidade)
  Future<void> updateStockSettings(
    String productId, {
    String? unit,
    double? minQuantity,
    double? maxQuantity,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final updates = <String, dynamic>{'updated_at': now, 'synced': 0};

    if (unit != null) updates['unit'] = unit;
    if (minQuantity != null) updates['min_quantity'] = minQuantity;
    if (maxQuantity != null) updates['max_quantity'] = maxQuantity;

    await db.update(
      'stock',
      updates,
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  // Deletar entrada de estoque
  Future<void> deleteStock(String productId) async {
    final db = await _dbHelper.database;
    await db.delete('stock', where: 'product_id = ?', whereArgs: [productId]);
  }

  // Buscar histórico de movimentações (pode ser expandido)
  Future<int> getStockMovementsCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM stock');
    final count = result.first['count'] as int?;
    return count ?? 0;
  }
}
