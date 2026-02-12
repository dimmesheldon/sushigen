import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';

/// Serviço de sincronização do banco ADMINISTRATIVO via Firebase Firestore.
/// Sincroniza: customers, company_users, sold_licenses e superadmin.
/// Permite que o SuperAdmin gerencie de qualquer máquina.
class AdminSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Coleção raiz no Firestore para dados administrativos
  static const String _adminCollection = 'admin_data';

  // ==================== SYNC SUPERADMIN (USERS) ====================

  /// Sincroniza a tabela users (superadmin) para o Firestore
  Future<void> syncSuperAdmin() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final users = await db.query('users');

      for (var user in users) {
        final userData = Map<String, dynamic>.from(user);
        final id =
            userData['id']?.toString() ?? userData['username']?.toString();
        if (id == null) continue;

        // Converter datas para Firestore-friendly
        _convertDatesToStrings(userData);

        await _firestore
            .collection(_adminCollection)
            .doc('users')
            .collection('items')
            .doc(id)
            .set(userData, SetOptions(merge: true));
      }

      print('✅ [AdminSync] SuperAdmin sincronizado: ${users.length} registros');
    } catch (e) {
      print('❌ [AdminSync] Erro ao sincronizar superadmin: $e');
      rethrow;
    }
  }

  /// Baixa dados de superadmin do Firestore
  Future<void> downloadSuperAdmin() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final snapshot = await _firestore
          .collection(_adminCollection)
          .doc('users')
          .collection('items')
          .get();

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        _convertTimestampsToStrings(data);

        final existing = await db.query(
          'users',
          where: 'username = ?',
          whereArgs: [data['username']],
          limit: 1,
        );

        if (existing.isEmpty) {
          await db.insert('users', data);
        } else {
          // Atualizar apenas se o servidor tem versão mais recente
          final serverUpdated = data['updated_at'] as String?;
          final localUpdated = existing.first['updated_at'] as String?;

          if (_isNewer(serverUpdated, localUpdated)) {
            await db.update(
              'users',
              data,
              where: 'username = ?',
              whereArgs: [data['username']],
            );
          }
        }
      }

      print(
          '✅ [AdminSync] SuperAdmin baixado: ${snapshot.docs.length} registros');
    } catch (e) {
      print('❌ [AdminSync] Erro ao baixar superadmin: $e');
      rethrow;
    }
  }

  // ==================== SYNC CUSTOMERS ====================

  /// Sincroniza tabela customers para o Firestore
  Future<void> syncCustomers() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final customers = await db.query('customers');

      for (var customer in customers) {
        final data = Map<String, dynamic>.from(customer);
        final id = data['id']?.toString();
        if (id == null) continue;

        _convertDatesToStrings(data);

        await _firestore
            .collection(_adminCollection)
            .doc('customers')
            .collection('items')
            .doc(id)
            .set(data, SetOptions(merge: true));
      }

      print('✅ [AdminSync] Customers sincronizados: ${customers.length}');
    } catch (e) {
      print('❌ [AdminSync] Erro ao sincronizar customers: $e');
      rethrow;
    }
  }

  /// Baixa customers do Firestore para o banco local
  Future<void> downloadCustomers() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final snapshot = await _firestore
          .collection(_adminCollection)
          .doc('customers')
          .collection('items')
          .get();

      int newCount = 0;
      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        _convertTimestampsToStrings(data);

        // Garantir que o id do Firestore seja usado
        final customerId = data['id'] ?? doc.id;
        data['id'] = customerId;

        final existing = await db.query(
          'customers',
          where: 'id = ?',
          whereArgs: [customerId],
          limit: 1,
        );

        if (existing.isEmpty) {
          await db.insert('customers', data);
          newCount++;
        } else {
          final serverUpdated = data['updated_at'] as String?;
          final localUpdated = existing.first['updated_at'] as String?;

          if (_isNewer(serverUpdated, localUpdated)) {
            await db.update(
              'customers',
              data,
              where: 'id = ?',
              whereArgs: [customerId],
            );
            updatedCount++;
          }
        }
      }

      print('✅ [AdminSync] Customers baixados: $newCount novos, $updatedCount atualizados');
    } catch (e) {
      print('❌ [AdminSync] Erro ao baixar customers: $e');
      rethrow;
    }
  }

  // ==================== SYNC COMPANY USERS ====================

  /// Sincroniza tabela company_users para o Firestore
  Future<void> syncCompanyUsers() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final users = await db.query('company_users');

      for (var user in users) {
        final data = Map<String, dynamic>.from(user);
        final id = data['id']?.toString();
        if (id == null) continue;

        _convertDatesToStrings(data);

        await _firestore
            .collection(_adminCollection)
            .doc('company_users')
            .collection('items')
            .doc(id)
            .set(data, SetOptions(merge: true));
      }

      print('✅ [AdminSync] Company users sincronizados: ${users.length}');
    } catch (e) {
      print('❌ [AdminSync] Erro ao sincronizar company_users: $e');
      rethrow;
    }
  }

  /// Baixa company_users do Firestore para o banco local
  Future<void> downloadCompanyUsers() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final snapshot = await _firestore
          .collection(_adminCollection)
          .doc('company_users')
          .collection('items')
          .get();

      int newCount = 0;
      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        _convertTimestampsToStrings(data);

        // Verificar se existe por username (UNIQUE constraint)
        final existingByUsername = await db.query(
          'company_users',
          where: 'username = ?',
          whereArgs: [data['username']],
          limit: 1,
        );

        if (existingByUsername.isEmpty) {
          // Inserir novo usuário
          await db.insert('company_users', data);
          newCount++;
        } else {
          // Atualizar se a versão do servidor for mais recente
          final serverUpdated = data['updated_at'] as String?;
          final localUpdated = existingByUsername.first['updated_at'] as String?;

          if (_isNewer(serverUpdated, localUpdated)) {
            await db.update(
              'company_users',
              data,
              where: 'username = ?',
              whereArgs: [data['username']],
            );
            updatedCount++;
          }
        }
      }

      print('✅ [AdminSync] Company users baixados: $newCount novos, $updatedCount atualizados');
    } catch (e) {
      print('❌ [AdminSync] Erro ao baixar company_users: $e');
      rethrow;
    }
  }

  // ==================== SYNC SOLD LICENSES ====================

  /// Sincroniza tabela sold_licenses para o Firestore
  Future<void> syncLicenses() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final licenses = await db.query('sold_licenses');

      for (var license in licenses) {
        final data = Map<String, dynamic>.from(license);
        final id = data['id']?.toString();
        if (id == null) continue;

        _convertDatesToStrings(data);

        await _firestore
            .collection(_adminCollection)
            .doc('sold_licenses')
            .collection('items')
            .doc(id)
            .set(data, SetOptions(merge: true));
      }

      print('✅ [AdminSync] Licenças sincronizadas: ${licenses.length}');
    } catch (e) {
      print('❌ [AdminSync] Erro ao sincronizar licenças: $e');
      rethrow;
    }
  }

  /// Baixa sold_licenses do Firestore para o banco local
  Future<void> downloadLicenses() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final snapshot = await _firestore
          .collection(_adminCollection)
          .doc('sold_licenses')
          .collection('items')
          .get();

      int newCount = 0;
      int updatedCount = 0;

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        _convertTimestampsToStrings(data);

        // Garantir que o id do Firestore seja usado
        final licenseId = data['id'] ?? doc.id;
        data['id'] = licenseId;

        final existing = await db.query(
          'sold_licenses',
          where: 'id = ?',
          whereArgs: [licenseId],
          limit: 1,
        );

        if (existing.isEmpty) {
          await db.insert('sold_licenses', data);
          newCount++;
        } else {
          final serverUpdated = data['updated_at'] as String?;
          final localUpdated = existing.first['updated_at'] as String?;

          if (_isNewer(serverUpdated, localUpdated)) {
            await db.update(
              'sold_licenses',
              data,
              where: 'id = ?',
              whereArgs: [licenseId],
            );
            updatedCount++;
          }
        }
      }

      print('✅ [AdminSync] Licenças baixadas: $newCount novas, $updatedCount atualizadas');
    } catch (e) {
      print('❌ [AdminSync] Erro ao baixar licenças: $e');
      rethrow;
    }
  }

  // ==================== SYNC COMPLETA ====================

  /// Sincroniza pagamentos para o Firestore
  Future<void> syncPayments() async {
    try {
      final db = await _dbHelper.adminDatabase;

      // Verificar se a tabela payments existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='payments'",
      );
      if (tables.isEmpty) return;

      final payments = await db.query('payments');

      for (var payment in payments) {
        final paymentData = Map<String, dynamic>.from(payment);
        final id = paymentData['id']?.toString();
        if (id == null) continue;

        _convertDatesToStrings(paymentData);

        await _firestore
            .collection(_adminCollection)
            .doc('payments')
            .collection('items')
            .doc(id)
            .set(paymentData, SetOptions(merge: true));
      }

      print(
          '✅ [AdminSync] Payments sincronizados: ${payments.length} registros');
    } catch (e) {
      print('❌ [AdminSync] Erro ao sincronizar payments: $e');
      rethrow;
    }
  }

  /// Baixa pagamentos do Firestore
  Future<void> downloadPayments() async {
    try {
      final db = await _dbHelper.adminDatabase;

      // Verificar se a tabela payments existe
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='payments'",
      );
      if (tables.isEmpty) return;

      final snapshot = await _firestore
          .collection(_adminCollection)
          .doc('payments')
          .collection('items')
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _convertTimestampsToStrings(data);

        // Verificar se já existe localmente
        final existing = await db.query(
          'payments',
          where: 'id = ?',
          whereArgs: [doc.id],
        );

        if (existing.isEmpty) {
          await db.insert('payments', data);
          count++;
        }
      }

      print(
          '✅ [AdminSync] Payments baixados: $count novos de ${snapshot.docs.length} total');
    } catch (e) {
      print('❌ [AdminSync] Erro ao baixar payments: $e');
      rethrow;
    }
  }

  /// Sincroniza TODOS os dados administrativos para o Firestore
  Future<void> syncAll() async {
    print('🔄 [AdminSync] Iniciando sincronização completa do admin...');

    await syncSuperAdmin();
    await syncCustomers();
    await syncCompanyUsers();
    await syncLicenses();
    await syncPayments();

    print('✅ [AdminSync] Sincronização completa finalizada!');
  }

  /// Baixa TODOS os dados administrativos do Firestore
  Future<void> downloadAll() async {
    print('🔄 [AdminSync] Iniciando download completo do admin...');

    await downloadSuperAdmin();
    await downloadCustomers();
    await downloadCompanyUsers();
    await downloadLicenses();
    await downloadPayments();

    print('✅ [AdminSync] Download completo finalizado!');
  }

  /// Sincronização bidirecional: upload + download
  Future<void> fullSync() async {
    print('🔄 [AdminSync] Sincronização bidirecional iniciando...');

    // 1. Upload local -> Firestore
    await syncAll();

    // 2. Download Firestore -> local
    await downloadAll();

    print('✅ [AdminSync] Sincronização bidirecional completa!');
  }

  // ==================== HELPERS ====================

  /// Verifica se a data do servidor é mais recente que a local
  bool _isNewer(String? serverDate, String? localDate) {
    if (serverDate == null) return false;
    if (localDate == null) return true;
    try {
      return DateTime.parse(serverDate).isAfter(DateTime.parse(localDate));
    } catch (_) {
      return false;
    }
  }

  /// Converte campos de data para String (para enviar ao Firestore)
  void _convertDatesToStrings(Map<String, dynamic> data) {
    for (final key in data.keys.toList()) {
      if (data[key] is DateTime) {
        data[key] = (data[key] as DateTime).toIso8601String();
      }
    }
  }

  /// Converte Timestamps do Firestore de volta para Strings ISO
  void _convertTimestampsToStrings(Map<String, dynamic> data) {
    for (final key in data.keys.toList()) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }
  }

  /// Retorna contagem de registros no banco admin local
  Future<Map<String, int>> getAdminCounts() async {
    try {
      final db = await _dbHelper.adminDatabase;

      final customers = await db.query('customers');
      final companyUsers = await db.query('company_users');
      final licenses = await db.query('sold_licenses');

      return {
        'customers': customers.length,
        'company_users': companyUsers.length,
        'licenses': licenses.length,
        'total': customers.length + companyUsers.length + licenses.length,
      };
    } catch (e) {
      print('❌ [AdminSync] Erro ao contar registros: $e');
      return {'customers': 0, 'company_users': 0, 'licenses': 0, 'total': 0};
    }
  }
}
