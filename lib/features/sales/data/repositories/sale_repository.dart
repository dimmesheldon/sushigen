import 'package:uuid/uuid.dart';
import '../models/sale.dart';
import '../../../../core/database/database_helper.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _uuid = const Uuid();

  // Gerar próximo número de venda
  Future<int> _getNextSaleNumber() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(sale_number) as max_number FROM sales',
    );
    final maxNumber = result.first['max_number'] as int?;
    return (maxNumber ?? 0) + 1;
  }

  // Criar venda completa (venda + itens)
  Future<Sale> createSale({
    required String userId,
    required List<SaleItem> items,
    String? customerName,
    String? customerPhone,
    required double totalAmount,
    double discountAmount = 0,
    required String paymentMethod,
    String? notes,
    bool isIfood = false,
    String deliveryType = 'Retirada',
    double deliveryCost = 0,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final saleNumber = await _getNextSaleNumber();
    final finalAmount = totalAmount - discountAmount;

    // Criar venda
    final sale = Sale(
      id: _uuid.v4(),
      saleNumber: saleNumber,
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      paymentMethod: paymentMethod,
      status: 'completed',
      notes: notes,
      saleDate: now,
      createdAt: now,
      isIfood: isIfood,
      deliveryType: deliveryType,
      deliveryCost: deliveryCost,
    );

    // Inserir venda
    await db.insert('sales', sale.toMap());

    // Inserir itens da venda
    for (final item in items) {
      final saleItem = SaleItem(
        id: _uuid.v4(),
        saleId: sale.id,
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.totalPrice,
        notes: item.notes,
        createdAt: now,
      );
      await db.insert('sale_items', saleItem.toMap());
    }

    // Registrar no fluxo de caixa
    await db.insert('cash_flow', {
      'id': _uuid.v4(),
      'user_id': userId,
      'type': 'income',
      'category': 'Venda',
      'amount': finalAmount,
      'description': 'Venda #$saleNumber',
      'sale_id': sale.id,
      'date': now.toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'synced': 0,
    });

    return sale;
  }

  // Buscar venda por ID com itens
  Future<Map<String, dynamic>?> getSaleWithItems(String saleId) async {
    final db = await _dbHelper.database;

    // Buscar venda
    final saleResult = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [saleId],
    );
    if (saleResult.isEmpty) return null;

    final sale = Sale.fromMap(saleResult.first);

    // Buscar itens
    final itemsResult = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    final items = itemsResult.map((map) => SaleItem.fromMap(map)).toList();

    return {'sale': sale, 'items': items};
  }

  // Buscar vendas por data
  Future<List<Sale>> getSalesByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));

    final result = await db.query(
      'sales',
      where: 'sale_date >= ? AND sale_date < ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'sale_date DESC',
    );

    return result.map((map) => Sale.fromMap(map)).toList();
  }

  // Buscar vendas por período
  Future<List<Sale>> getSalesByPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'sale_date >= ? AND sale_date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'sale_date DESC',
    );

    return result.map((map) => Sale.fromMap(map)).toList();
  }

  // Buscar últimas vendas
  Future<List<Sale>> getRecentSales(int limit) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      orderBy: 'sale_date DESC',
      limit: limit,
    );

    return result.map((map) => Sale.fromMap(map)).toList();
  }

  // Calcular total de vendas do dia
  Future<double> getTodayTotal() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final endDate = startDate.add(const Duration(days: 1));

    final result = await db.rawQuery(
      'SELECT SUM(final_amount) as total FROM sales WHERE sale_date >= ? AND sale_date < ? AND status = ?',
      [startDate.toIso8601String(), endDate.toIso8601String(), 'completed'],
    );

    return (result.first['total'] as double?) ?? 0.0;
  }

  // Contar vendas do dia
  Future<int> getTodayCount() async {
    final db = await _dbHelper.database;
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final endDate = startDate.add(const Duration(days: 1));

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sales WHERE sale_date >= ? AND sale_date < ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  // Cancelar venda
  Future<void> cancelSale(String saleId, String reason) async {
    final db = await _dbHelper.database;
    await db.update(
      'sales',
      {'status': 'cancelled', 'notes': reason},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }
}
