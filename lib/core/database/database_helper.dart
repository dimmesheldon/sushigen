import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// ignore: unused_import
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Banco administrativo (único, para gestão de clientes e licenças)
  static Database? _adminDatabase;

  // Bancos de clientes (um por customer_id - MULTI-TENANT)
  static final Map<String, Database> _customerDatabases = {};

  // Customer ID do cliente atualmente logado
  static String? _currentCustomerId;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  // GETTER: Banco administrativo (para área administrativa)
  Future<Database> get adminDatabase async {
    if (_adminDatabase != null) return _adminDatabase!;
    _adminDatabase = await _initAdminDatabase();
    return _adminDatabase!;
  }

  // GETTER: Banco do cliente logado (para operações do restaurante - MULTI-TENANT)
  Future<Database> get database async {
    if (_currentCustomerId == null) {
      throw Exception('Nenhum cliente logado. Faça login primeiro.');
    }
    return await getCustomerDatabase(_currentCustomerId!);
  }

  // MÉTODO: Inicializar banco administrativo
  Future<Database> _initAdminDatabase() async {
    // Inicializa FFI para desktop
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocumentsDir.path, 'sushigen_admin.db');

    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreateAdmin,
      onUpgrade: _onUpgradeAdmin,
    );
  }

  // MÉTODO: Fazer backup do banco administrativo
  Future<void> backupAdminDatabase() async {
    try {
      final Directory appDocumentsDir =
          await getApplicationDocumentsDirectory();
      final String dbPath = join(appDocumentsDir.path, 'sushigen_admin.db');
      final File dbFile = File(dbPath);

      if (!dbFile.existsSync()) return;

      final backupDir = Directory(join(appDocumentsDir.path, 'backups'));
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final backupPath = join(backupDir.path, 'sushigen_admin_$timestamp.db');

      dbFile.copySync(backupPath);
      print('✅ Backup criado: $backupPath');

      // Manter apenas os 5 backups mais recentes
      final backups = backupDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.db'))
          .toList()
        ..sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
        );

      for (final oldBackup in backups.skip(5)) {
        oldBackup.deleteSync();
      }
    } catch (e) {
      print('⚠️  Falha ao criar backup: $e');
    }
  }

  // MÉTODO: Obter/criar banco específico do CLIENTE (MULTI-TENANT)
  Future<Database> getCustomerDatabase(String customerId) async {
    // Se já existe na memória, retorna
    if (_customerDatabases.containsKey(customerId)) {
      print('🔵 Retornando banco do cache para cliente: $customerId');
      return _customerDatabases[customerId]!;
    }

    // Inicializa FFI para desktop (caso ainda não tenha sido)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Cria banco específico para o CLIENTE (não para username!)
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(
      appDocumentsDir.path,
      'sushigen_db_$customerId.db',
    );

    print('🟢 Criando/abrindo banco para cliente: $customerId');
    print('📁 Caminho: $dbPath');

    final db = await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreateUser,
      onUpgrade: _onUpgradeUser,
    );

    // Armazena na memória com customer_id como chave
    _customerDatabases[customerId] = db;
    _currentCustomerId = customerId;

    print('✅ Banco do cliente $customerId pronto!');
    return db;
  }

  // COMPATIBILIDADE: Método antigo redireciona para getCustomerDatabase
  @Deprecated('Use getCustomerDatabase() instead')
  Future<Database> getUserDatabase(String username) async {
    print(
      '⚠️  getUserDatabase() deprecated! Redirecionando para getCustomerDatabase()',
    );
    return await getCustomerDatabase(username);
  }

  // MÉTODO: Definir cliente logado (MULTI-TENANT)
  Future<void> setCurrentCustomer(String customerId) async {
    print('🔵 Definindo cliente atual: $customerId');
    _currentCustomerId = customerId;
    // Garante que o banco do cliente está inicializado
    await getCustomerDatabase(customerId);
  }

  // MÉTODO: Obter cliente atual
  String? getCurrentCustomerId() {
    return _currentCustomerId;
  }

  // COMPATIBILIDADE: Método antigo
  @Deprecated('Use setCurrentCustomer() instead')
  Future<void> setCurrentUser(String username) async {
    print(
      '⚠️  setCurrentUser() deprecated! Redirecionando para setCurrentCustomer()',
    );
    await setCurrentCustomer(username);
  }

  // MÉTODO: Limpar cliente logado (logout)
  void clearCurrentUser() {
    print('🔴 Limpando cliente atual');
    _currentCustomerId = null;
  }

  // ============================================================
  // CRIAÇÃO DE TABELAS - BANCO ADMINISTRATIVO
  // ============================================================

  Future<void> _onCreateAdmin(Database db, int version) async {
    // Tabela de Usuários (credenciais para login)
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        email TEXT,
        role TEXT DEFAULT 'user',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabela de Licenças (validação de acesso)
    await db.execute('''
      CREATE TABLE licenses (
        id TEXT PRIMARY KEY,
        license_key TEXT NOT NULL UNIQUE,
        user_id TEXT,
        expiration_date TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        max_devices INTEGER DEFAULT 3,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Dispositivos
    await db.execute('''
      CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        license_id TEXT NOT NULL,
        device_name TEXT NOT NULL,
        device_id TEXT NOT NULL UNIQUE,
        last_sync TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (license_id) REFERENCES licenses (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Clientes (empresas que compram licenças)
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        business_name TEXT,
        cnpj TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        notes TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabela de Licenças Vendidas
    await db.execute('''
      CREATE TABLE sold_licenses (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        license_key TEXT NOT NULL UNIQUE,
        username TEXT,
        password_hash TEXT,
        days INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        expiration_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        price REAL,
        payment_method TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Pagamentos
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        license_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        reference TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id),
        FOREIGN KEY (license_id) REFERENCES sold_licenses (id)
      )
    ''');

    // Tabela de Usuários da Empresa (company_users)
    await db.execute('''
      CREATE TABLE company_users (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        email TEXT,
        role TEXT DEFAULT 'user',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Criar índices para performance
    await db.execute('CREATE INDEX idx_customers_email ON customers(email)');
    await db.execute(
      'CREATE INDEX idx_sold_licenses_status ON sold_licenses(status)',
    );
    await db.execute(
      'CREATE INDEX idx_sold_licenses_expiration ON sold_licenses(expiration_date)',
    );
    await db.execute(
      'CREATE INDEX idx_payments_date ON payments(payment_date)',
    );
    await db.execute(
      'CREATE INDEX idx_company_users_customer ON company_users(customer_id)',
    );
    await db.execute(
      'CREATE INDEX idx_company_users_username ON company_users(username)',
    );
  }

  // ============================================================
  // CRIAÇÃO DE TABELAS - BANCO DO USUÁRIO (RESTAURANTE)
  // ============================================================

  Future<void> _onCreateUser(Database db, int version) async {
    // IMPORTANTE: Este banco contém APENAS dados operacionais do restaurante
    // Tabelas de users, licenses, customers NÃO ficam aqui (ficam no admin)

    // Tabela de Produtos
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        cost REAL DEFAULT 0,
        image_url TEXT,
        is_active INTEGER DEFAULT 1,
        preparation_time INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');

    // Tabela de Estoque
    await db.execute('''
      CREATE TABLE stock (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        unit TEXT DEFAULT 'un',
        min_quantity REAL DEFAULT 0,
        max_quantity REAL,
        last_purchase_date TEXT,
        last_purchase_price REAL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de Vendas
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        sale_number INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        total_amount REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        final_amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT DEFAULT 'completed',
        notes TEXT,
        sale_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        is_ifood INTEGER DEFAULT 0,
        delivery_type TEXT DEFAULT 'Retirada',
        delivery_cost REAL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Tabela de Fluxo de Caixa
    await db.execute('''
      CREATE TABLE cash_flow (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        sale_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (sale_id) REFERENCES sales (id)
      )
    ''');

    // Tabela de Sincronização
    await db.execute('''
      CREATE TABLE sync_log (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        device_id TEXT NOT NULL,
        sync_date TEXT NOT NULL,
        status TEXT DEFAULT 'pending'
      )
    ''');

    // Criar índices para melhor performance
    await db.execute(
      'CREATE INDEX idx_products_category ON products(category)',
    );
    await db.execute('CREATE INDEX idx_sales_date ON sales(sale_date)');
    await db.execute('CREATE INDEX idx_sales_status ON sales(status)');
    await db.execute('CREATE INDEX idx_cashflow_date ON cash_flow(date)');
    await db.execute('CREATE INDEX idx_cashflow_type ON cash_flow(type)');
    await db.execute('CREATE INDEX idx_sync_status ON sync_log(status)');
  }

  // ============================================================
  // UPGRADE DE TABELAS
  // ============================================================

  Future<void> _onUpgradeAdmin(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 4) {
      // Migração da versão 3 para 4: Adicionar tabela company_users
      await db.execute('''
        CREATE TABLE IF NOT EXISTS company_users (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          username TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          full_name TEXT NOT NULL,
          email TEXT,
          role TEXT DEFAULT 'user',
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
        )
      ''');

      // Criar índices para company_users
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_company_users_customer ON company_users(customer_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_company_users_username ON company_users(username)',
      );
    }

    // Adicionar full_name se a tabela já existe mas não tem o campo
    final columns = await db.rawQuery("PRAGMA table_info(company_users)");
    final hasFullName = columns.any((col) => col['name'] == 'full_name');

    if (!hasFullName) {
      // Adicionar coluna full_name
      await db.execute('ALTER TABLE company_users ADD COLUMN full_name TEXT');

      // Atualizar registros existentes: usar username como full_name temporário
      await db.execute(
        'UPDATE company_users SET full_name = username WHERE full_name IS NULL',
      );
    }

    // Tornar username e password_hash opcionais em sold_licenses
    final licenseColumns = await db.rawQuery(
      "PRAGMA table_info(sold_licenses)",
    );
    final usernameCol = licenseColumns.firstWhere(
      (col) => col['name'] == 'username',
      orElse: () => {},
    );

    // Se username é NOT NULL (notnull == 1), precisa recriar a tabela
    if (usernameCol.isNotEmpty && usernameCol['notnull'] == 1) {
      // Salvar dados
      final existingLicenses = await db.query('sold_licenses');

      // Dropar tabela
      await db.execute('DROP TABLE sold_licenses');

      // Recriar com campos opcionais
      await db.execute('''
        CREATE TABLE sold_licenses (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          license_key TEXT NOT NULL UNIQUE,
          username TEXT,
          password_hash TEXT,
          days INTEGER NOT NULL,
          start_date TEXT NOT NULL,
          expiration_date TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'active',
          price REAL,
          payment_method TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
        )
      ''');

      // Recriar índice
      await db.execute(
        'CREATE INDEX idx_sold_licenses_status ON sold_licenses(status)',
      );
      await db.execute(
        'CREATE INDEX idx_sold_licenses_expiration ON sold_licenses(expiration_date)',
      );

      // Restaurar dados
      for (final license in existingLicenses) {
        await db.insert('sold_licenses', license);
      }
    }
  }

  Future<void> _onUpgradeUser(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Migração da versão 1 para 2: Renomear colunas da tabela cash_flow
      // Como SQLite não suporta ALTER COLUMN, precisamos recriar a tabela

      // 1. Salvar dados existentes (se houver)
      final existingData = await db.query('cash_flow');

      // 2. Dropar tabela antiga
      await db.execute('DROP TABLE IF EXISTS cash_flow');

      // 3. Criar nova tabela com schema correto
      await db.execute('''
        CREATE TABLE cash_flow (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          type TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          date TEXT NOT NULL,
          sale_id TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (sale_id) REFERENCES sales (id)
        )
      ''');

      // 4. Recriar índices
      await db.execute('CREATE INDEX idx_cashflow_date ON cash_flow(date)');
      await db.execute('CREATE INDEX idx_cashflow_type ON cash_flow(type)');

      // 5. Migrar dados antigos (se houver)
      for (final row in existingData) {
        await db.insert('cash_flow', {
          'id': row['id'],
          'user_id': row['user_id'],
          'type': row['transaction_type'], // Renomear campo
          'category': row['category'],
          'amount': row['amount'],
          'description': row['description'] ?? '',
          'date': row['transaction_date'], // Renomear campo
          'sale_id': row['reference_id'],
          'created_at': row['created_at'],
          'updated_at': DateTime.now().toIso8601String(),
          'synced': row['synced'] ?? 0,
        });
      }
    }

    // Migração da versão 2 para 3: Adicionar campos de entrega e iFood na tabela sales
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE sales ADD COLUMN is_ifood INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE sales ADD COLUMN delivery_type TEXT DEFAULT "Retirada"',
      );
      await db.execute(
        'ALTER TABLE sales ADD COLUMN delivery_cost REAL DEFAULT 0',
      );
    }

    // Nota: Versão 4 é apenas para tabelas administrativas (banco admin)
    // Banco do usuário não precisa de migração v4
  }

  // ============================================================
  // MÉTODOS AUXILIARES
  // ============================================================

  Future<void> close() async {
    // Fechar banco administrativo
    if (_adminDatabase != null) {
      await _adminDatabase!.close();
      _adminDatabase = null;
    }

    // Fechar todos os bancos de clientes
    for (var db in _customerDatabases.values) {
      await db.close();
    }
    _customerDatabases.clear();
    _currentCustomerId = null;
    print('🔴 Todos os bancos fechados');
  }
}
