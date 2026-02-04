import '../../../products/data/models/product.dart';
import '../../../../core/database/database_helper.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Criar produto
  Future<Product> createProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.insert('products', product.toMap());
    return product;
  }

  // Buscar todos os produtos
  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Buscar produtos por categoria
  Future<List<Product>> getProductsByCategory(String category) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'category = ? AND is_active = ?',
      whereArgs: [category, 1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Buscar produto por ID
  Future<Product?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  // Buscar produtos por nome
  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? AND is_active = ?',
      whereArgs: ['%$query%', 1],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Atualizar produto
  Future<void> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // Deletar produto (soft delete)
  Future<void> deleteProduct(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Buscar todas as categorias
  Future<List<String>> getAllCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE is_active = 1 ORDER BY category',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  // Contar produtos por categoria
  Future<Map<String, int>> countByCategory() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM products WHERE is_active = 1 GROUP BY category',
    );

    final Map<String, int> counts = {};
    for (final row in result) {
      counts[row['category'] as String] = row['count'] as int;
    }
    return counts;
  }
}
