import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

void main() async {
  print('🚀 Inicializando banco administrativo...');

  // Inicializar FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Caminho do banco admin
  final appSupportDir =
      Platform.environment['HOME']! +
      '/Library/Containers/com.sushigen.sushigen/Data/Library/Application Support/com.sushigen.sushigen';

  // Criar diretório se não existir
  final dir = Directory(appSupportDir);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
    print('📁 Diretório criado: $appSupportDir');
  }

  final dbPath = join(appSupportDir, 'sushigen_admin.db');
  print('📁 Caminho do banco: $dbPath');

  // Deletar banco antigo se existir
  final file = File(dbPath);
  if (file.existsSync()) {
    file.deleteSync();
    print('🗑️  Banco antigo deletado');
  }

  // Criar banco
  final db = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) async {
      print('📋 Criando tabelas...');

      // Tabela customers (empresas)
      await db.execute('''
        CREATE TABLE customers (
          id TEXT PRIMARY KEY,
          company_name TEXT NOT NULL,
          contact_name TEXT,
          email TEXT,
          phone TEXT,
          address TEXT,
          city TEXT,
          state TEXT,
          zip_code TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_active INTEGER DEFAULT 1
        )
      ''');

      // Tabela sold_licenses
      await db.execute('''
        CREATE TABLE sold_licenses (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          license_key TEXT UNIQUE NOT NULL,
          purchase_date TEXT NOT NULL,
          expiration_date TEXT NOT NULL,
          max_devices INTEGER DEFAULT 1,
          status TEXT DEFAULT 'active',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers (id)
        )
      ''');

      // Tabela company_users (usuários das empresas)
      await db.execute('''
        CREATE TABLE company_users (
          id TEXT PRIMARY KEY,
          customer_id TEXT NOT NULL,
          username TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          email TEXT,
          role TEXT DEFAULT 'user',
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          UNIQUE(customer_id, username),
          FOREIGN KEY (customer_id) REFERENCES customers (id)
        )
      ''');

      print('✅ Tabelas criadas!');
    },
  );

  print('');
  print('👤 Criando Super Admin...');

  final uuid = Uuid();
  final now = DateTime.now().toIso8601String();

  // 1. Criar customer "Sistema"
  final customerId = uuid.v4();
  await db.insert('customers', {
    'id': customerId,
    'company_name': 'Administração Sistema',
    'contact_name': 'Super Admin',
    'email': 'admin@sushigen.com',
    'phone': '',
    'address': '',
    'city': '',
    'state': '',
    'zip_code': '',
    'created_at': now,
    'updated_at': now,
    'is_active': 1,
  });
  print('✅ Cliente "Administração Sistema" criado: $customerId');

  // 2. Criar licença vitalícia
  final licenseKey = '1A56-0FD1-4814-E762';
  final licenseId = uuid.v4();
  final expirationDate = DateTime.now().add(Duration(days: 36500)); // 100 anos

  await db.insert('sold_licenses', {
    'id': licenseId,
    'customer_id': customerId,
    'license_key': licenseKey,
    'purchase_date': now,
    'expiration_date': expirationDate.toIso8601String(),
    'max_devices': 10,
    'status': 'active',
    'created_at': now,
    'updated_at': now,
  });
  print('✅ Licença vitalícia criada: $licenseKey');

  // 3. Criar usuário superadmin
  final adminId = uuid.v4();
  final password = 'admin#7435';
  final passwordHash = sha256.convert(utf8.encode(password)).toString();

  await db.insert('company_users', {
    'id': adminId,
    'customer_id': customerId,
    'username': 'superadmin',
    'password_hash': passwordHash,
    'email': 'admin@sushigen.com',
    'role': 'admin',
    'is_active': 1,
    'created_at': now,
    'updated_at': now,
  });
  print('✅ Usuário superadmin criado!');

  await db.close();

  print('');
  print('═══════════════════════════════════════════════════════');
  print('🎉 BANCO ADMINISTRATIVO CRIADO COM SUCESSO!');
  print('═══════════════════════════════════════════════════════');
  print('');
  print('🔑 CREDENCIAIS:');
  print('   Usuário: superadmin');
  print('   Senha: admin#7435');
  print('   Chave de Licença: $licenseKey');
  print('');
  print('📋 Customer ID: $customerId');
  print('');
  print('🚀 Agora você pode fazer login no aplicativo!');
  print('═══════════════════════════════════════════════════════');
}
