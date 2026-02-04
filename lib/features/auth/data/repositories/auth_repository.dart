import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/license.dart';
import '../../../../core/database/database_helper.dart';

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
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO para validação
    final db = await _dbHelper.adminDatabase;

    // Verificar licença
    final licenseResult = await db.query(
      'licenses',
      where: 'license_key = ?',
      whereArgs: [licenseKey],
    );

    if (licenseResult.isEmpty) {
      throw Exception('Chave de licença inválida');
    }

    final license = License.fromMap(licenseResult.first);

    if (!license.isValid) {
      throw Exception('Licença expirada ou inativa');
    }

    // Autenticar usuário
    final passwordHash = _hashPassword(password);
    final userResult = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, passwordHash],
    );

    if (userResult.isEmpty) {
      throw Exception('Usuário ou senha inválidos');
    }

    // 🟢 MUDANÇA: Inicializar banco específico do usuário
    await _dbHelper.setCurrentUser(username);

    return User.fromMap(userResult.first);
  }

  /// Autentica sem necessidade de licença (para login após primeira ativação)
  Future<User?> authenticateWithoutLicense(
    String username,
    String password,
  ) async {
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO para validação
    final db = await _dbHelper.adminDatabase;

    // Autenticar usuário
    final passwordHash = _hashPassword(password);
    final userResult = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, passwordHash],
    );

    if (userResult.isEmpty) {
      throw Exception('Usuário ou senha inválidos');
    }

    // 🟢 MUDANÇA: Inicializar banco específico do usuário
    await _dbHelper.setCurrentUser(username);

    return User.fromMap(userResult.first);
  }

  /// Verifica se usuário já possui licença ativa
  Future<License?> getActiveLicense(String username) async {
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO
    final db = await _dbHelper.adminDatabase;

    // Buscar usuário
    final userResult = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (userResult.isEmpty) return null;

    final userId = userResult.first['id'] as String;

    // Buscar licença ativa
    final licenseResult = await db.query(
      'licenses',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (licenseResult.isEmpty) return null;

    final license = License.fromMap(licenseResult.first);

    // Verificar se ainda está válida
    if (!license.isValid) {
      return null;
    }

    return license;
  }

  /// Atualiza a licença de um usuário existente
  Future<void> updateUserLicense({
    required String username,
    required String licenseKey,
  }) async {
    // 🔴 MUDANÇA: Usar banco ADMINISTRATIVO
    final db = await _dbHelper.adminDatabase;

    // Verificar se a licença existe e é válida
    final licenseResult = await db.query(
      'licenses',
      where: 'license_key = ?',
      whereArgs: [licenseKey],
    );

    if (licenseResult.isEmpty) {
      throw Exception('Chave de licença inválida');
    }

    final license = License.fromMap(licenseResult.first);

    if (!license.isValid) {
      throw Exception('Licença expirada ou inativa');
    }

    // Buscar usuário
    final userResult = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (userResult.isEmpty) {
      throw Exception('Usuário não encontrado');
    }

    final userId = userResult.first['id'] as String;

    // Desativar licenças antigas do usuário
    await db.update(
      'licenses',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Associar nova licença ao usuário
    await db.update(
      'licenses',
      {'user_id': userId, 'updated_at': DateTime.now().toIso8601String()},
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
