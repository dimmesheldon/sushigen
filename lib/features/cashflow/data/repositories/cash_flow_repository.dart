import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../models/cash_flow_entry.dart';
import 'package:uuid/uuid.dart';

class CashFlowRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Adicionar entrada de fluxo de caixa
  Future<CashFlowEntry> addEntry(CashFlowEntry entry) async {
    final db = await _dbHelper.database;
    final uuid = const Uuid();

    final entryWithId = entry.copyWith(id: uuid.v4());

    await db.insert(
      'cash_flow',
      entryWithId.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return entryWithId;
  }

  // Buscar todas as entradas
  Future<List<CashFlowEntry>> getAllEntries() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cash_flow',
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => CashFlowEntry.fromMap(map)).toList();
  }

  // Buscar entradas por período
  Future<List<CashFlowEntry>> getEntriesByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cash_flow',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => CashFlowEntry.fromMap(map)).toList();
  }

  // Buscar por tipo (income/expense)
  Future<List<CashFlowEntry>> getEntriesByType(String type) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cash_flow',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => CashFlowEntry.fromMap(map)).toList();
  }

  // Buscar por categoria
  Future<List<CashFlowEntry>> getEntriesByCategory(String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cash_flow',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => CashFlowEntry.fromMap(map)).toList();
  }

  // Calcular saldo por período
  Future<Map<String, double>> getBalanceByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;

    try {
      // Total de receitas
      final incomeResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM cash_flow
        WHERE type = 'income'
        AND date >= ? AND date <= ?
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      // Total de despesas
      final expenseResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) as total
        FROM cash_flow
        WHERE type = 'expense'
        AND date >= ? AND date <= ?
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      final income = (incomeResult.first['total'] as num).toDouble();
      final expense = (expenseResult.first['total'] as num).toDouble();

      return {
        'income': income,
        'expense': expense,
        'balance': income - expense,
      };
    } catch (e) {
      print('❌ Erro ao calcular saldo: $e');
      return {'income': 0.0, 'expense': 0.0, 'balance': 0.0};
    }
  }

  // Estatísticas por categoria
  Future<List<Map<String, dynamic>>> getExpensesByCategory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _dbHelper.database;

    try {
      final result = await db.rawQuery(
        '''
        SELECT 
          category,
          COALESCE(SUM(amount), 0) as total,
          COUNT(*) as count
        FROM cash_flow
        WHERE type = 'expense'
        AND date >= ? AND date <= ?
        GROUP BY category
        ORDER BY total DESC
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return result.map((row) {
        return {
          'category': row['category'] as String,
          'total': (row['total'] as num).toDouble(),
          'count': row['count'] as int,
        };
      }).toList();
    } catch (e) {
      print('❌ Erro ao buscar despesas por categoria: $e');
      return [];
    }
  }

  // Atualizar entrada
  Future<void> updateEntry(CashFlowEntry entry) async {
    final db = await _dbHelper.database;

    final updatedEntry = entry.copyWith(
      updatedAt: DateTime.now(),
      synced: false,
    );

    await db.update(
      'cash_flow',
      updatedEntry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Deletar entrada
  Future<void> deleteEntry(String id) async {
    final db = await _dbHelper.database;
    await db.delete('cash_flow', where: 'id = ?', whereArgs: [id]);
  }

  // Buscar entrada por ID
  Future<CashFlowEntry?> getEntryById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cash_flow',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return CashFlowEntry.fromMap(maps.first);
  }

  // Saldo total (todas as entradas)
  Future<double> getTotalBalance() async {
    final db = await _dbHelper.database;

    try {
      final result = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) -
          COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0) as balance
        FROM cash_flow
      ''');

      return (result.first['balance'] as num).toDouble();
    } catch (e) {
      print('❌ Erro ao calcular saldo total: $e');
      return 0.0;
    }
  }
}
