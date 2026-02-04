import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/sold_license.dart';

class AdminRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  // ==================== CLIENTES ====================

  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<Customer?> getCustomerByEmail(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<String> createCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.insert('customers', customer.toMap());
    return customer.id;
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await _dbHelper.database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== LICENÇAS ====================

  Future<List<SoldLicense>> getAllLicenses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SoldLicense.fromMap(maps[i]));
  }

  Future<List<SoldLicense>> getLicensesByCustomerId(String customerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SoldLicense.fromMap(maps[i]));
  }

  Future<SoldLicense?> getLicenseById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SoldLicense.fromMap(maps.first);
  }

  Future<List<SoldLicense>> getActiveLicenses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'expiration_date ASC',
    );
    return List.generate(maps.length, (i) => SoldLicense.fromMap(maps[i]));
  }

  Future<List<SoldLicense>> getExpiringLicenses(int days) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      where: 'status = ? AND expiration_date BETWEEN ? AND ?',
      whereArgs: [
        'active',
        now.toIso8601String(),
        futureDate.toIso8601String(),
      ],
      orderBy: 'expiration_date ASC',
    );
    return List.generate(maps.length, (i) => SoldLicense.fromMap(maps[i]));
  }

  String _generateLicenseKey(String username, int days) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$username-$days-$timestamp-sushigen-secret';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString().toUpperCase().substring(0, 32);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<SoldLicense> generateLicense({
    required String customerId,
    required String username,
    required String password,
    required int days,
    double? price,
    String? paymentMethod,
    String? notes,
  }) async {
    final db = await _dbHelper.database;

    final licenseKey = _generateLicenseKey(username, days);
    final passwordHash = _hashPassword(password);
    final now = DateTime.now();
    final expirationDate = now.add(Duration(days: days));

    final license = SoldLicense(
      id: _uuid.v4(),
      customerId: customerId,
      licenseKey: licenseKey,
      username: username,
      passwordHash: passwordHash,
      days: days,
      startDate: now,
      expirationDate: expirationDate,
      status: 'active',
      price: price,
      paymentMethod: paymentMethod,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('sold_licenses', license.toMap());

    // Também criar o usuário na tabela users para que possa fazer login
    await db.insert('users', {
      'id': _uuid.v4(),
      'username': username,
      'password_hash': passwordHash,
      'email': null,
      'role': 'user',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    // Criar a licença na tabela licenses
    await db.insert('licenses', {
      'id': _uuid.v4(),
      'license_key': licenseKey,
      'user_id': null,
      'expiration_date': expirationDate.toIso8601String(),
      'is_active': 1,
      'max_devices': 3,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    return license;
  }

  Future<void> renewLicense(
    String licenseId,
    int additionalDays, {
    double? price,
    String? paymentMethod,
  }) async {
    final db = await _dbHelper.database;
    final license = await getLicenseById(licenseId);
    if (license == null) throw Exception('Licença não encontrada');

    final now = DateTime.now();
    final newExpirationDate = license.expirationDate.add(
      Duration(days: additionalDays),
    );

    await db.update(
      'sold_licenses',
      {
        'expiration_date': newExpirationDate.toIso8601String(),
        'days': license.days + additionalDays,
        'status': 'active',
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [licenseId],
    );

    // Atualizar também a tabela licenses
    await db.update(
      'licenses',
      {
        'expiration_date': newExpirationDate.toIso8601String(),
        'is_active': 1,
        'updated_at': now.toIso8601String(),
      },
      where: 'license_key = ?',
      whereArgs: [license.licenseKey],
    );

    // Registrar pagamento se tiver preço
    if (price != null && price > 0) {
      await registerPayment(
        customerId: license.customerId,
        licenseId: licenseId,
        amount: price,
        paymentMethod: paymentMethod ?? 'Não informado',
        notes: 'Renovação de $additionalDays dias',
      );
    }
  }

  Future<void> revokeLicense(String licenseId, String reason) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    await db.update(
      'sold_licenses',
      {
        'status': 'revoked',
        'notes': reason,
        'updated_at': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [licenseId],
    );

    // Desativar na tabela licenses
    final license = await getLicenseById(licenseId);
    if (license != null) {
      await db.update(
        'licenses',
        {'is_active': 0, 'updated_at': now.toIso8601String()},
        where: 'license_key = ?',
        whereArgs: [license.licenseKey],
      );
    }
  }

  // ==================== PAGAMENTOS ====================

  Future<void> registerPayment({
    required String customerId,
    required String licenseId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    await db.insert('payments', {
      'id': _uuid.v4(),
      'customer_id': customerId,
      'license_id': licenseId,
      'amount': amount,
      'payment_date': now.toIso8601String(),
      'payment_method': paymentMethod,
      'reference': reference,
      'notes': notes,
      'created_at': now.toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPaymentsByCustomer(
    String customerId,
  ) async {
    final db = await _dbHelper.database;
    return await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'payment_date DESC',
    );
  }

  // ==================== ESTATÍSTICAS ====================

  Future<Map<String, dynamic>> getAdminStatistics() async {
    final db = await _dbHelper.database;

    // Total de clientes
    final customersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers WHERE is_active = 1',
    );
    final customersCount = customersResult.first['count'] as int;

    // Total de licenças ativas
    final activeLicensesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sold_licenses WHERE status = ?',
      ['active'],
    );
    final activeLicensesCount = activeLicensesResult.first['count'] as int;

    // Total de licenças expiradas
    final now = DateTime.now().toIso8601String();
    final expiredLicensesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sold_licenses WHERE status = ? AND expiration_date < ?',
      ['active', now],
    );
    final expiredLicensesCount = expiredLicensesResult.first['count'] as int;

    // Licenças a vencer (próximos 7 dias)
    final futureDate = DateTime.now()
        .add(const Duration(days: 7))
        .toIso8601String();
    final expiringLicensesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sold_licenses WHERE status = ? AND expiration_date BETWEEN ? AND ?',
      ['active', now, futureDate],
    );
    final expiringLicensesCount = expiringLicensesResult.first['count'] as int;

    // Faturamento total
    final totalRevenueResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments',
    );
    final totalRevenue = ((totalRevenueResult.first['total'] ?? 0) as num)
        .toDouble();

    // Faturamento do mês atual
    final firstDayOfMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    );
    final monthlyRevenueResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE payment_date >= ?',
      [firstDayOfMonth.toIso8601String()],
    );
    final monthlyRevenue = ((monthlyRevenueResult.first['total'] ?? 0) as num)
        .toDouble();

    return {
      'total_customers': customersCount,
      'active_licenses': activeLicensesCount,
      'expired_licenses': expiredLicensesCount,
      'expiring_soon': expiringLicensesCount,
      'total_revenue': totalRevenue,
      'monthly_revenue': monthlyRevenue,
    };
  }
}
