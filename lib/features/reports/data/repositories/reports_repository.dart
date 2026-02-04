import '../../../../core/database/database_helper.dart';

class ReportsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Vendas por período
  Future<Map<String, dynamic>> getSalesByPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as total_sales,
          COALESCE(SUM(total_amount), 0) as total_revenue,
          COALESCE(AVG(total_amount), 0) as average_ticket,
          COALESCE(MIN(total_amount), 0) as min_sale,
          COALESCE(MAX(total_amount), 0) as max_sale
        FROM sales
        WHERE sale_date BETWEEN ? AND ?
        AND status != 'cancelled'
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      if (result.isEmpty) {
        return {
          'total_sales': 0,
          'total_revenue': 0.0,
          'average_ticket': 0.0,
          'min_sale': 0.0,
          'max_sale': 0.0,
        };
      }

      final data = result.first;
      return {
        'total_sales': data['total_sales'] ?? 0,
        'total_revenue': (data['total_revenue'] ?? 0.0) as double,
        'average_ticket': (data['average_ticket'] ?? 0.0) as double,
        'min_sale': (data['min_sale'] ?? 0.0) as double,
        'max_sale': (data['max_sale'] ?? 0.0) as double,
      };
    } catch (e) {
      print('❌ Erro em getSalesByPeriod: $e');
      return {
        'total_sales': 0,
        'total_revenue': 0.0,
        'average_ticket': 0.0,
        'min_sale': 0.0,
        'max_sale': 0.0,
      };
    }
  }

  // Vendas por dia do período
  Future<List<Map<String, dynamic>>> getDailySales({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          DATE(sale_date) as date,
          COUNT(*) as count,
          SUM(total_amount) as total
        FROM sales
        WHERE sale_date BETWEEN ? AND ?
        AND status != 'cancelled'
        GROUP BY DATE(sale_date)
        ORDER BY date
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return result
          .map(
            (row) => {
              'date': DateTime.parse(row['date'] as String),
              'count': row['count'] as int,
              'total': (row['total'] ?? 0.0) as double,
            },
          )
          .toList();
    } catch (e) {
      print('❌ Erro em getDailySales: $e');
      return [];
    }
  }

  // Produtos mais vendidos
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Verificar se existem vendas no período
      final checkResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE sale_date BETWEEN ? AND ? AND status != ?',
        [startDate.toIso8601String(), endDate.toIso8601String(), 'cancelled'],
      );

      if ((checkResult.first['count'] as int) == 0) {
        return [];
      }

      final result = await db.rawQuery(
        '''
        SELECT 
          si.product_id,
          p.name as product_name,
          p.category,
          p.price,
          p.cost,
          p.image_url,
          SUM(si.quantity) as total_quantity,
          SUM(si.total_price) as total_revenue,
          SUM(si.quantity * p.cost) as total_cost,
          SUM(si.quantity * (si.unit_price - p.cost)) as total_profit,
          COUNT(DISTINCT s.id) as num_orders
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        INNER JOIN products p ON si.product_id = p.id
        WHERE s.sale_date BETWEEN ? AND ?
        AND s.status != 'cancelled'
        GROUP BY si.product_id, p.name, p.category, p.price, p.cost, p.image_url
        ORDER BY total_quantity DESC
        LIMIT ?
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String(), limit],
      );

      return result
          .map(
            (row) => {
              'product_id': row['product_id'] as String,
              'product_name': row['product_name'] as String,
              'category': row['category'] as String,
              'price': (row['price'] ?? 0.0) as double,
              'cost': (row['cost'] ?? 0.0) as double,
              'image_url': row['image_url'] as String?,
              'total_quantity': ((row['total_quantity'] ?? 0) as num).toInt(),
              'total_revenue': (row['total_revenue'] ?? 0.0) as double,
              'total_cost': (row['total_cost'] ?? 0.0) as double,
              'total_profit': (row['total_profit'] ?? 0.0) as double,
              'num_orders': ((row['num_orders'] ?? 0) as num).toInt(),
            },
          )
          .toList();
    } catch (e) {
      print('❌ Erro em getTopSellingProducts: $e');
      return [];
    }
  }

  // Vendas por categoria
  Future<List<Map<String, dynamic>>> getSalesByCategory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Verificar se existem vendas no período
      final checkResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE sale_date BETWEEN ? AND ? AND status != ?',
        [startDate.toIso8601String(), endDate.toIso8601String(), 'cancelled'],
      );

      if ((checkResult.first['count'] as int) == 0) {
        return [];
      }

      final result = await db.rawQuery(
        '''
        SELECT 
          p.category,
          COUNT(DISTINCT s.id) as sales_count,
          SUM(si.quantity) as total_items,
          SUM(si.total_price) as total_revenue
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        INNER JOIN products p ON si.product_id = p.id
        WHERE s.sale_date BETWEEN ? AND ?
        AND s.status != 'cancelled'
        GROUP BY p.category
        ORDER BY total_revenue DESC
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return result
          .map(
            (row) => {
              'category': row['category'] as String,
              'sales_count': ((row['sales_count'] ?? 0) as num).toInt(),
              'total_items': ((row['total_items'] ?? 0) as num).toInt(),
              'total_revenue': (row['total_revenue'] ?? 0.0) as double,
            },
          )
          .toList();
    } catch (e) {
      print('❌ Erro em getSalesByCategory: $e');
      return [];
    }
  }

  // Vendas por período do dia
  Future<List<Map<String, dynamic>>> getSalesByDayPeriod({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          CASE 
            WHEN CAST(strftime('%H', sale_date) AS INTEGER) BETWEEN 6 AND 11 THEN 'Manhã'
            WHEN CAST(strftime('%H', sale_date) AS INTEGER) BETWEEN 12 AND 17 THEN 'Tarde'
            WHEN CAST(strftime('%H', sale_date) AS INTEGER) BETWEEN 18 AND 23 THEN 'Noite'
            ELSE 'Madrugada'
          END as period,
          COUNT(*) as count,
          SUM(total_amount) as total
        FROM sales
        WHERE sale_date BETWEEN ? AND ?
        AND status != 'cancelled'
        GROUP BY period
        ORDER BY 
          CASE period
            WHEN 'Manhã' THEN 1
            WHEN 'Tarde' THEN 2
            WHEN 'Noite' THEN 3
            ELSE 4
          END
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return result
          .map(
            (row) => {
              'period': row['period'] as String,
              'count': row['count'] as int,
              'total': (row['total'] ?? 0.0) as double,
            },
          )
          .toList();
    } catch (e) {
      print('❌ Erro em getSalesByDayPeriod: $e');
      return [];
    }
  }

  // Comparação com período anterior
  Future<Map<String, dynamic>> getComparison({
    required DateTime currentStart,
    required DateTime currentEnd,
  }) async {
    try {
      final db = await _dbHelper.database;

      // Calcular período anterior (mesma duração)
      final duration = currentEnd.difference(currentStart);
      final previousStart = currentStart.subtract(duration);
      final previousEnd = currentStart;

      // Período atual
      final currentResult = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(total_amount), 0) as total
        FROM sales
        WHERE sale_date BETWEEN ? AND ?
        AND status != 'cancelled'
      ''',
        [currentStart.toIso8601String(), currentEnd.toIso8601String()],
      );

      // Período anterior
      final previousResult = await db.rawQuery(
        '''
        SELECT 
          COUNT(*) as count,
          COALESCE(SUM(total_amount), 0) as total
        FROM sales
        WHERE sale_date BETWEEN ? AND ?
        AND status != 'cancelled'
      ''',
        [previousStart.toIso8601String(), previousEnd.toIso8601String()],
      );

      final currentData = currentResult.first;
      final previousData = previousResult.first;

      final currentCount = currentData['count'] as int;
      final currentTotalRaw = currentData['total'];
      final currentTotal = (currentTotalRaw is int)
          ? currentTotalRaw.toDouble()
          : (currentTotalRaw ?? 0.0) as double;

      final previousCount = previousData['count'] as int;
      final previousTotalRaw = previousData['total'];
      final previousTotal = (previousTotalRaw is int)
          ? previousTotalRaw.toDouble()
          : (previousTotalRaw ?? 0.0) as double;

      double countChange = 0.0;
      double totalChange = 0.0;

      if (previousCount > 0) {
        countChange = ((currentCount - previousCount) / previousCount) * 100;
      } else if (currentCount > 0) {
        countChange = 100.0; // 100% de crescimento se antes era zero
      }

      if (previousTotal > 0) {
        totalChange = ((currentTotal - previousTotal) / previousTotal) * 100;
      } else if (currentTotal > 0) {
        totalChange = 100.0; // 100% de crescimento se antes era zero
      }

      return {
        'current_count': currentCount,
        'current_total': currentTotal,
        'previous_count': previousCount,
        'previous_total': previousTotal,
        'count_change_percent': countChange,
        'total_change_percent': totalChange,
      };
    } catch (e) {
      print('❌ Erro em getComparison: $e');
      return {
        'current_count': 0,
        'current_total': 0.0,
        'previous_count': 0,
        'previous_total': 0.0,
        'count_change_percent': 0.0,
        'total_change_percent': 0.0,
      };
    }
  }

  // Métodos de pagamento mais usados
  Future<List<Map<String, dynamic>>> getPaymentMethods({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          payment_method,
          COUNT(*) as count,
          COALESCE(SUM(total_amount), 0) as total
        FROM sales
        WHERE sale_date BETWEEN ? AND ?
        AND status != 'cancelled'
        GROUP BY payment_method
        ORDER BY count DESC
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      return result
          .map(
            (row) => {
              'payment_method': row['payment_method'] as String,
              'count': row['count'] as int,
              'total': (row['total'] ?? 0.0) as double,
            },
          )
          .toList();
    } catch (e) {
      print('❌ Erro em getPaymentMethods: $e');
      return [];
    }
  }

  // Vendas por Canal (iFood vs Local)
  Future<Map<String, dynamic>> getSalesByChannel({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          CASE WHEN is_ifood = 1 THEN 'iFood' ELSE 'Local' END as channel,
          COUNT(*) as total_sales,
          COALESCE(SUM(final_amount), 0) as total_revenue,
          COALESCE(AVG(final_amount), 0) as avg_ticket
        FROM sales
        WHERE sale_date BETWEEN ? AND ?
        AND status != 'cancelled'
        GROUP BY is_ifood
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      Map<String, dynamic> channelData = {
        'Local': {'total_sales': 0, 'total_revenue': 0.0, 'avg_ticket': 0.0},
        'iFood': {'total_sales': 0, 'total_revenue': 0.0, 'avg_ticket': 0.0},
      };

      for (var row in result) {
        final channel = row['channel'] as String;
        channelData[channel] = {
          'total_sales': row['total_sales'] ?? 0,
          'total_revenue': (row['total_revenue'] ?? 0.0) as double,
          'avg_ticket': (row['avg_ticket'] ?? 0.0) as double,
        };
      }

      return channelData;
    } catch (e) {
      print('❌ Erro em getSalesByChannel: $e');
      return {
        'Local': {'total_sales': 0, 'total_revenue': 0.0, 'avg_ticket': 0.0},
        'iFood': {'total_sales': 0, 'total_revenue': 0.0, 'avg_ticket': 0.0},
      };
    }
  }

  // Análise de Entregas
  Future<Map<String, dynamic>> getDeliveryAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          delivery_type,
          COUNT(*) as total,
          COALESCE(SUM(final_amount), 0) as revenue,
          COALESCE(SUM(delivery_cost), 0) as total_delivery_cost,
          COALESCE(AVG(final_amount), 0) as avg_ticket
        FROM sales
        WHERE sale_date BETWEEN ? AND ?
        AND status != 'cancelled'
        GROUP BY delivery_type
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      Map<String, dynamic> deliveryData = {
        'Retirada': {
          'total': 0,
          'revenue': 0.0,
          'total_delivery_cost': 0.0,
          'avg_ticket': 0.0,
        },
        'Entrega': {
          'total': 0,
          'revenue': 0.0,
          'total_delivery_cost': 0.0,
          'avg_ticket': 0.0,
        },
      };

      for (var row in result) {
        final type = row['delivery_type'] as String;
        deliveryData[type] = {
          'total': row['total'] ?? 0,
          'revenue': (row['revenue'] ?? 0.0) as double,
          'total_delivery_cost': (row['total_delivery_cost'] ?? 0.0) as double,
          'avg_ticket': (row['avg_ticket'] ?? 0.0) as double,
        };
      }

      return deliveryData;
    } catch (e) {
      print('❌ Erro em getDeliveryAnalysis: $e');
      return {
        'Retirada': {
          'total': 0,
          'revenue': 0.0,
          'total_delivery_cost': 0.0,
          'avg_ticket': 0.0,
        },
        'Entrega': {
          'total': 0,
          'revenue': 0.0,
          'total_delivery_cost': 0.0,
          'avg_ticket': 0.0,
        },
      };
    }
  }

  // Análise de Custos e Lucro
  Future<Map<String, dynamic>> getCostAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          COALESCE(SUM(si.quantity * si.unit_price), 0) as total_revenue,
          COALESCE(SUM(si.quantity * p.cost), 0) as total_cost,
          COALESCE(SUM(si.quantity * (si.unit_price - p.cost)), 0) as total_profit,
          COALESCE(SUM(s.delivery_cost), 0) as total_delivery_cost
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        JOIN products p ON si.product_id = p.id
        WHERE s.sale_date BETWEEN ? AND ?
        AND s.status != 'cancelled'
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String()],
      );

      if (result.isEmpty) {
        return {
          'total_revenue': 0.0,
          'total_cost': 0.0,
          'total_profit': 0.0,
          'total_delivery_cost': 0.0,
          'profit_margin': 0.0,
          'net_profit': 0.0,
        };
      }

      final data = result.first;
      final totalRevenue = (data['total_revenue'] ?? 0.0) as double;
      final totalCost = (data['total_cost'] ?? 0.0) as double;
      final totalProfit = (data['total_profit'] ?? 0.0) as double;
      final totalDeliveryCost = (data['total_delivery_cost'] ?? 0.0) as double;
      final netProfit = totalProfit - totalDeliveryCost;
      final profitMargin = totalRevenue > 0
          ? (netProfit / totalRevenue) * 100
          : 0.0;

      return {
        'total_revenue': totalRevenue,
        'total_cost': totalCost,
        'total_profit': totalProfit,
        'total_delivery_cost': totalDeliveryCost,
        'net_profit': netProfit,
        'profit_margin': profitMargin,
      };
    } catch (e) {
      print('❌ Erro em getCostAnalysis: $e');
      return {
        'total_revenue': 0.0,
        'total_cost': 0.0,
        'total_profit': 0.0,
        'total_delivery_cost': 0.0,
        'profit_margin': 0.0,
        'net_profit': 0.0,
      };
    }
  }

  // Top Produtos Menos Vendidos
  Future<List<Map<String, dynamic>>> getLeastSellingProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 5,
  }) async {
    try {
      final db = await _dbHelper.database;

      final result = await db.rawQuery(
        '''
        SELECT 
          p.name,
          p.category,
          p.image_url,
          COALESCE(SUM(si.quantity), 0) as total_quantity,
          COALESCE(SUM(si.quantity * si.unit_price), 0) as total_revenue,
          COUNT(DISTINCT s.id) as num_orders
        FROM products p
        LEFT JOIN sale_items si ON p.id = si.product_id
        LEFT JOIN sales s ON si.sale_id = s.id 
          AND s.sale_date BETWEEN ? AND ?
          AND s.status != 'cancelled'
        WHERE p.is_active = 1
        GROUP BY p.id
        ORDER BY total_quantity ASC
        LIMIT ?
      ''',
        [startDate.toIso8601String(), endDate.toIso8601String(), limit],
      );

      return result
          .map(
            (row) => {
              'name': row['name'] as String,
              'category': row['category'] as String,
              'image_url': row['image_url'] as String?,
              'total_quantity': ((row['total_quantity'] ?? 0) as num)
                  .toDouble(),
              'total_revenue': ((row['total_revenue'] ?? 0) as num).toDouble(),
              'num_orders': ((row['num_orders'] ?? 0) as num).toInt(),
            },
          )
          .toList();
    } catch (e) {
      print('❌ Erro em getLeastSellingProducts: $e');
      return [];
    }
  }
}
