import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/sold_license.dart';
import '../../domain/entities/company_user.dart';

class AdminRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  static const String _superAdminUsername = 'superadmin';
  static const String _defaultAdminPassword = 'admin#7435';

  Future<void> _ensureSuperAdminExists() async {
    final db = await _dbHelper.adminDatabase;
    final now = DateTime.now().toIso8601String();
    final columns = await db.rawQuery("PRAGMA table_info(users)");
    final hasRole = columns.any((row) => row['name'] == 'role');
    final hasUpdatedAt = columns.any((row) => row['name'] == 'updated_at');

    final superAdmin = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [_superAdminUsername],
      limit: 1,
    );

    if (superAdmin.isNotEmpty) {
      final role = superAdmin.first['role']?.toString();
      final passwordHash = superAdmin.first['password_hash']?.toString();
      if (hasRole && role != 'superadmin') {
        final values = <String, Object?>{'role': 'superadmin'};
        if (hasUpdatedAt) {
          values['updated_at'] = now;
        }
        await db.update(
          'users',
          values,
          where: 'username = ?',
          whereArgs: [_superAdminUsername],
        );
      }
      if (passwordHash == null || passwordHash.isEmpty) {
        final values = <String, Object?>{
          'password_hash': _hashPassword(_defaultAdminPassword),
        };
        if (hasUpdatedAt) {
          values['updated_at'] = now;
        }
        await db.update(
          'users',
          values,
          where: 'username = ?',
          whereArgs: [_superAdminUsername],
        );
      }
      return;
    }

    final legacyAdmin = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
      limit: 1,
    );

    if (legacyAdmin.isNotEmpty) {
      final values = <String, Object?>{'username': _superAdminUsername};
      if (hasRole) {
        values['role'] = 'superadmin';
      }
      if (hasUpdatedAt) {
        values['updated_at'] = now;
      }
      await db.update(
        'users',
        values,
        where: 'username = ?',
        whereArgs: ['admin'],
      );
      return;
    }

    final values = <String, Object?>{
      'id': _uuid.v4(),
      'username': _superAdminUsername,
      'password_hash': _hashPassword(_defaultAdminPassword),
      'email': null,
      'created_at': now,
    };
    if (hasRole) {
      values['role'] = 'superadmin';
    }
    if (hasUpdatedAt) {
      values['updated_at'] = now;
    }
    await db.insert('users', values);
  }

  Future<bool> authenticateAdmin({
    required String username,
    required String password,
  }) async {
    final db = await _dbHelper.adminDatabase;
    await _ensureSuperAdminExists();

    final passwordHash = _hashPassword(password);
    final columns = await db.rawQuery("PRAGMA table_info(users)");
    final hasRole = columns.any((row) => row['name'] == 'role');

    final userResult = await db.query(
      'users',
      where: hasRole
          ? 'username = ? AND password_hash = ? AND role = ?'
          : 'username = ? AND password_hash = ?',
      whereArgs: hasRole
          ? [username, passwordHash, 'superadmin']
          : [username, passwordHash],
      limit: 1,
    );

    return userResult.isNotEmpty;
  }

  Future<void> ensureAdminAccount() async {
    await _ensureSuperAdminExists();
  }

  Future<void> resetAdminPassword({
    required String newPassword,
    String username = _superAdminUsername,
  }) async {
    final db = await _dbHelper.adminDatabase;
    await _ensureSuperAdminExists();

    final newPasswordHash = _hashPassword(newPassword);
    final updatedRows = await db.update(
      'users',
      {
        'password_hash': newPasswordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'username = ?',
      whereArgs: [username],
    );

    if (updatedRows == 0 && username != 'admin') {
      await db.update(
        'users',
        {
          'password_hash': newPasswordHash,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'username = ?',
        whereArgs: ['admin'],
      );
    }
  }

  Future<void> cleanupAdminData() async {
    final db = await _dbHelper.adminDatabase;
    final now = DateTime.now().toIso8601String();

    await db.delete(
      'users',
      where: 'username IS NULL OR TRIM(username) = ?',
      whereArgs: [''],
    );

    await db.execute('''
      DELETE FROM sold_licenses
      WHERE customer_id NOT IN (SELECT id FROM customers)
    ''');

    await db.execute(
      '''
      UPDATE licenses
      SET is_active = 0
      WHERE expiration_date < ?
    ''',
      [now],
    );

    await db.execute('''
      DELETE FROM licenses
      WHERE user_id IS NOT NULL
        AND user_id NOT IN (SELECT id FROM users)
        AND license_key NOT IN (SELECT license_key FROM sold_licenses)
    ''');
  }

  // ==================== CLIENTES ====================

  Future<List<Customer>> getAllCustomers() async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<Customer?> getCustomerByEmail(String email) async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  Future<String> createCustomer(Customer customer) async {
    final db = await _dbHelper.adminDatabase;
    final normalizedEmail = customer.email.trim().toLowerCase();
    final existing = await db.query(
      'customers',
      where: 'LOWER(email) = ? AND is_active = 1',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception('Já existe um cliente ativo com este e-mail.');
    }

    await db.insert(
      'customers',
      customer.copyWith(email: normalizedEmail).toMap(),
    );
    return customer.id;
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await _dbHelper.adminDatabase;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> deleteCustomer(String id) async {
    final db = await _dbHelper.adminDatabase;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== LICENÇAS ====================

  Future<List<SoldLicense>> getAllLicenses() async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SoldLicense.fromMap(maps[i]));
  }

  Future<List<SoldLicense>> getLicensesByCustomerId(String customerId) async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SoldLicense.fromMap(maps[i]));
  }

  Future<SoldLicense?> getLicenseById(String id) async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return SoldLicense.fromMap(maps.first);
  }

  Future<List<SoldLicense>> getActiveLicenses() async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'sold_licenses',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'expiration_date ASC',
    );
    return List.generate(maps.length, (i) => SoldLicense.fromMap(maps[i]));
  }

  Future<List<SoldLicense>> getExpiringLicenses(int days) async {
    final db = await _dbHelper.adminDatabase;
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

  // ==================== COMPANY USERS (MULTI-TENANT) ====================

  Future<List<CompanyUser>> getCompanyUsersByCustomerId(
    String customerId,
  ) async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'company_users',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => CompanyUser.fromMap(maps[i]));
  }

  Future<CompanyUser?> getCompanyUserByUsername(String username) async {
    final db = await _dbHelper.adminDatabase;
    final List<Map<String, dynamic>> maps = await db.query(
      'company_users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CompanyUser.fromMap(maps.first);
  }

  Future<String> createCompanyUser(CompanyUser user) async {
    final db = await _dbHelper.adminDatabase;

    // Verificar se username já existe
    final existingUser = await db.query(
      'company_users',
      where: 'username = ?',
      whereArgs: [user.username],
      limit: 1,
    );

    if (existingUser.isNotEmpty) {
      throw Exception(
        'Já existe um usuário com o username "${user.username}".',
      );
    }

    // Gerar novo UUID se o ID estiver vazio
    final userId = user.id.isEmpty ? _uuid.v4() : user.id;

    // Hashear a senha antes de salvar
    final passwordHash = _hashPassword(user.passwordHash);

    // Criar usuário com ID e senha hash gerados
    final newUser = user.copyWith(id: userId, passwordHash: passwordHash);

    await db.insert('company_users', newUser.toMap());
    return userId;
  }

  Future<void> updateCompanyUser(CompanyUser user) async {
    final db = await _dbHelper.adminDatabase;
    await db.update(
      'company_users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> updateCompanyUserPassword(
    String userId,
    String newPassword,
  ) async {
    final db = await _dbHelper.adminDatabase;
    final passwordHash = _hashPassword(newPassword);

    await db.update(
      'company_users',
      {
        'password_hash': passwordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteCompanyUser(String userId) async {
    final db = await _dbHelper.adminDatabase;
    await db.delete('company_users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<bool> validateCompanyUserCredentials({
    required String username,
    required String password,
  }) async {
    final db = await _dbHelper.adminDatabase;
    final passwordHash = _hashPassword(password);

    final userResult = await db.query(
      'company_users',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, passwordHash],
      limit: 1,
    );

    return userResult.isNotEmpty;
  }

  // ==================== LICENÇAS ====================

  Future<SoldLicense> generateLicense({
    required String customerId,
    required int days,
    double? price,
    String? paymentMethod,
    String? notes,
  }) async {
    final db = await _dbHelper.adminDatabase;

    // Verificar se já existe uma licença ativa para este cliente
    final existingLicense = await db.query(
      'sold_licenses',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [customerId, 'active'],
      limit: 1,
    );

    if (existingLicense.isNotEmpty) {
      throw Exception(
        'Já existe uma licença ativa para este cliente.\n'
        'Renove a licença existente ou revogue antes de criar uma nova.',
      );
    }

    final licenseKey = _generateLicenseKey(customerId, days);
    final now = DateTime.now();
    final expirationDate = now.add(Duration(days: days));

    final license = SoldLicense(
      id: _uuid.v4(),
      customerId: customerId,
      licenseKey: licenseKey,
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

    return license;
  }

  Future<void> renewLicense(
    String licenseId,
    int additionalDays, {
    double? price,
    String? paymentMethod,
  }) async {
    final db = await _dbHelper.adminDatabase;
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
    final db = await _dbHelper.adminDatabase;
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
    final db = await _dbHelper.adminDatabase;
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
    final db = await _dbHelper.adminDatabase;
    return await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'payment_date DESC',
    );
  }

  // ==================== ESTATÍSTICAS ====================

  Future<Map<String, dynamic>> getAdminStatistics() async {
    final db = await _dbHelper.adminDatabase;

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

  // ==================== ADMIN SETTINGS ====================

  Future<void> changeAdminPassword({
    required String currentPassword,
    required String newPassword,
    String username = _superAdminUsername,
  }) async {
    final db = await _dbHelper.adminDatabase;
    await _ensureSuperAdminExists();

    // Verificar senha atual
    final currentPasswordHash = _hashPassword(currentPassword);

    final userResult = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, currentPasswordHash],
    );

    if (userResult.isEmpty) {
      throw Exception('Senha atual incorreta');
    }

    // Atualizar para nova senha
    final newPasswordHash = _hashPassword(newPassword);
    final updatedRows = await db.update(
      'users',
      {
        'password_hash': newPasswordHash,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'username = ?',
      whereArgs: [username],
    );

    if (updatedRows == 0 && username != 'admin') {
      await db.update(
        'users',
        {
          'password_hash': newPasswordHash,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'username = ?',
        whereArgs: ['admin'],
      );
    }
  }
}
