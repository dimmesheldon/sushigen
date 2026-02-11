import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/license.dart';
import '../../../../core/database/database_helper.dart';
import '../../../admin/domain/entities/company_user.dart';
import '../../../admin/domain/entities/sold_license.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _uuid = const Uuid();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User?> authenticate(
    String username,
    String password,
    String licenseKey,
  ) async {
    print('🔐 ========================================');
    print('🔐 INICIANDO LOGIN');
    print('🔐 Usuário: $username');
    print('🔐 ========================================');

    // � NOVO SISTEMA MULTI-TENANT
    // 1. Validar credenciais em company_users (banco admin)
    final db = await _dbHelper.adminDatabase;
    final passwordHash = _hashPassword(password);

    print('🔍 Buscando usuário no banco admin...');

    final userResult = await db.query(
      'company_users',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, passwordHash],
    );

    if (userResult.isEmpty) {
      print('❌ Usuário ou senha inválidos');
      throw Exception('Usuário ou senha inválidos');
    }

    final companyUser = CompanyUser.fromMap(userResult.first);
    print('✅ Usuário encontrado!');
    print('📋 Customer ID: ${companyUser.customerId}');
    print('📋 Username: ${companyUser.username}');
    print('📋 Role: ${companyUser.role}');

    // 🔥 SUPERADMIN NÃO PRECISA DE LICENÇA!
    if (username.toLowerCase() == 'superadmin' && companyUser.role == 'admin') {
      print('👑 SUPERADMIN detectado - pulando validação de licença!');
      print('🔄 Inicializando banco do cliente...');

      // Inicializar banco específico da empresa (customer_id)
      await _dbHelper.setCurrentCustomer(companyUser.customerId);

      print('✅ Banco inicializado com sucesso!');
      print('🔐 ========================================');

      // Retornar usuário
      return User(
        id: companyUser.id,
        username: companyUser.username,
        passwordHash: companyUser.passwordHash,
        email: companyUser.email,
        role: companyUser.role,
        createdAt: companyUser.createdAt,
        updatedAt: companyUser.updatedAt,
      );
    }

    // 2. Buscar licença da empresa (sold_licenses) - apenas para usuários normais
    print('🔍 Validando licença...');
    final licenseResult = await db.query(
      'sold_licenses',
      where: 'license_key = ? AND customer_id = ?',
      whereArgs: [licenseKey, companyUser.customerId],
    );

    if (licenseResult.isEmpty) {
      print('❌ Licença inválida');
      throw Exception(
        'Chave de licença inválida ou não pertence a esta empresa',
      );
    }

    final soldLicense = SoldLicense.fromMap(licenseResult.first);

    // 3. Validar licença
    if (soldLicense.status == 'revoked') {
      print('❌ Licença revogada');
      throw Exception('Licença revogada');
    }

    if (soldLicense.isExpired) {
      print('❌ Licença expirada');
      throw Exception(
        'Licença expirada em ${_formatDate(soldLicense.expirationDate)}',
      );
    }

    print('✅ Licença válida!');
    print('🔄 Inicializando banco do cliente...');

    // 4. Inicializar banco específico da empresa (customer_id)
    await _dbHelper.setCurrentCustomer(companyUser.customerId);

    print('✅ Banco inicializado com sucesso!');
    print('🔐 ========================================');

    // 5. Converter CompanyUser para User (entidade do sistema de auth)
    return User(
      id: companyUser.id,
      username: companyUser.username,
      passwordHash: companyUser.passwordHash,
      email: companyUser.email,
      role: companyUser.role,
      createdAt: companyUser.createdAt,
      updatedAt: companyUser.updatedAt,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Autentica sem necessidade de licença (para login após primeira ativação)
  Future<User?> authenticateWithoutLicense(
    String username,
    String password,
  ) async {
    // � NOVO SISTEMA MULTI-TENANT
    final db = await _dbHelper.adminDatabase;
    final passwordHash = _hashPassword(password);

    // Autenticar via company_users
    final userResult = await db.query(
      'company_users',
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username, passwordHash],
    );

    if (userResult.isEmpty) {
      throw Exception('Usuário ou senha inválidos');
    }

    final companyUser = CompanyUser.fromMap(userResult.first);

    // Verificar se a empresa tem licença ativa
    final licenseResult = await db.query(
      'sold_licenses',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [companyUser.customerId, 'active'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (licenseResult.isEmpty) {
      throw Exception('Nenhuma licença ativa encontrada para esta empresa');
    }

    final soldLicense = SoldLicense.fromMap(licenseResult.first);

    if (soldLicense.isExpired) {
      throw Exception(
        'Licença expirada em ${_formatDate(soldLicense.expirationDate)}',
      );
    }

    // Inicializar banco específico da empresa
    await _dbHelper.setCurrentCustomer(companyUser.customerId);

    return User(
      id: companyUser.id,
      username: companyUser.username,
      passwordHash: companyUser.passwordHash,
      email: companyUser.email,
      role: companyUser.role,
      createdAt: companyUser.createdAt,
      updatedAt: companyUser.updatedAt,
    );
  }

  /// Verifica se usuário já possui licença ativa
  Future<License?> getActiveLicense(String username) async {
    // � NOVO SISTEMA MULTI-TENANT
    final db = await _dbHelper.adminDatabase;

    // Buscar usuário em company_users
    final userResult = await db.query(
      'company_users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (userResult.isEmpty) return null;

    final companyUser = CompanyUser.fromMap(userResult.first);

    // Buscar licença ativa da empresa
    final licenseResult = await db.query(
      'sold_licenses',
      where: 'customer_id = ? AND status = ?',
      whereArgs: [companyUser.customerId, 'active'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (licenseResult.isEmpty) return null;

    final soldLicense = SoldLicense.fromMap(licenseResult.first);

    // Verificar se ainda está válida
    if (soldLicense.isExpired) {
      return null;
    }

    // Converter SoldLicense para License (entidade antiga para compatibilidade)
    return License(
      id: soldLicense.id,
      licenseKey: soldLicense.licenseKey,
      userId: companyUser.customerId, // Agora representa o customer_id
      expirationDate: soldLicense.expirationDate,
      isActive: soldLicense.status == 'active',
      maxDevices: 3, // Valor padrão
      createdAt: soldLicense.createdAt,
      updatedAt: soldLicense.updatedAt,
    );
  }

  /// Atualiza a licença de um usuário existente
  Future<void> updateUserLicense({
    required String username,
    required String licenseKey,
  }) async {
    // � NOVO SISTEMA MULTI-TENANT
    final db = await _dbHelper.adminDatabase;

    // Verificar se a licença existe e é válida
    final licenseResult = await db.query(
      'sold_licenses',
      where: 'license_key = ?',
      whereArgs: [licenseKey],
    );

    if (licenseResult.isEmpty) {
      throw Exception('Chave de licença inválida');
    }

    final soldLicense = SoldLicense.fromMap(licenseResult.first);

    if (soldLicense.isExpired) {
      throw Exception('Licença expirada');
    }

    // Buscar usuário em company_users
    final userResult = await db.query(
      'company_users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (userResult.isEmpty) {
      throw Exception('Usuário não encontrado');
    }

    final companyUser = CompanyUser.fromMap(userResult.first);

    // Verificar se a licença pertence à mesma empresa
    if (soldLicense.customerId != companyUser.customerId) {
      throw Exception('Esta licença não pertence à sua empresa');
    }

    // Ativar a licença (caso esteja inativa)
    await db.update(
      'sold_licenses',
      {'status': 'active', 'updated_at': DateTime.now().toIso8601String()},
      where: 'license_key = ?',
      whereArgs: [licenseKey],
    );
  }

  Future<User> createUser({
    required String username,
    required String password,
    String? email,
    String role = 'user',
  }) async {
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO
    final db = await _dbHelper.adminDatabase;
    final now = DateTime.now();

    final user = User(
      id: _uuid.v4(),
      username: username,
      passwordHash: _hashPassword(password),
      email: email,
      role: role,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('users', user.toMap());
    return user;
  }

  Future<License> createLicense({
    required String userId,
    required String licenseKey,
    required DateTime expirationDate,
    int maxDevices = 3,
  }) async {
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO
    final db = await _dbHelper.adminDatabase;
    final now = DateTime.now();

    final license = License(
      id: _uuid.v4(),
      licenseKey: licenseKey,
      userId: userId,
      expirationDate: expirationDate,
      isActive: true,
      maxDevices: maxDevices,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('licenses', license.toMap());
    return license;
  }

  Future<License?> getLicenseByKey(String licenseKey) async {
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO
    final db = await _dbHelper.adminDatabase;
    final result = await db.query(
      'licenses',
      where: 'license_key = ?',
      whereArgs: [licenseKey],
    );

    if (result.isEmpty) return null;
    return License.fromMap(result.first);
  }

  Future<void> deactivateLicense(String licenseKey) async {
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO
    final db = await _dbHelper.adminDatabase;
    await db.update(
      'licenses',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'license_key = ?',
      whereArgs: [licenseKey],
    );
  }

  Future<bool> checkDeviceLimit(String licenseId) async {
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO
    final db = await _dbHelper.adminDatabase;
    final result = await db.query(
      'devices',
      where: 'license_id = ? AND is_active = 1',
      whereArgs: [licenseId],
    );

    final license = await db.query(
      'licenses',
      where: 'id = ?',
      whereArgs: [licenseId],
    );

    if (license.isEmpty) return false;

    final maxDevices = license.first['max_devices'] as int;
    return result.length < maxDevices;
  }
}
