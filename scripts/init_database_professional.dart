import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Script PROFISSIONAL para inicializar banco administrativo
void main() async {
  print('=' * 70);
  print('🔧 INICIALIZAÇÃO PROFISSIONAL DO BANCO ADMINISTRATIVO');
  print('=' * 70);
  print('');

  // Inicializar FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // USAR O CAMINHO QUE O APP USA (Sandbox do macOS)
  final homeDir = Platform.environment['HOME']!;
  final dbDir =
      '$homeDir/Library/Containers/com.sushigen.sushigen/Data/Library/Application Support/com.sushigen.sushigen';
  final dbPath = '$dbDir/sushigen_admin.db';

  // Criar diretório se não existir
  final dir = Directory(dbDir);
  if (!dir.existsSync()) {
    print('📁 Criando diretório: $dbDir');
    dir.createSync(recursive: true);
  }

  print('📁 Diretório de dados: $dbDir');
  print('🗄️  Caminho do banco: $dbPath');
  print('');

  // Verificar se banco já existe
  final dbFile = File(dbPath);
  if (dbFile.existsSync()) {
    print('⚠️  Banco já existe! Removendo...');
    dbFile.deleteSync();
  }

  print('✨ Criando novo banco...');
  print('');

  // Criar banco
  final db = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) async {
      // Tabela users
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TEXT NOT NULL,
          license_key TEXT
        )
      ''');

      // Tabela licenses
      await db.execute('''
        CREATE TABLE licenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          license_key TEXT UNIQUE NOT NULL,
          username TEXT NOT NULL,
          expiry_date TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      // Tabela clients (clientes/restaurantes)
      await db.execute('''
        CREATE TABLE clients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          username TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          license_key TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      // Tabela customers (para área administrativa)
      await db.execute('''
        CREATE TABLE customers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          email TEXT,
          phone TEXT,
          address TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      // Tabela sold_licenses
      await db.execute('''
        CREATE TABLE sold_licenses (
          id TEXT PRIMARY KEY,
          license_key TEXT UNIQUE NOT NULL,
          customer_id TEXT NOT NULL,
          username TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          issue_date TEXT NOT NULL,
          expiration_date TEXT NOT NULL,
          status TEXT NOT NULL,
          price REAL,
          payment_method TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (customer_id) REFERENCES customers(id)
        )
      ''');

      // Tabela payments
      await db.execute('''
        CREATE TABLE payments (
          id TEXT PRIMARY KEY,
          license_id TEXT NOT NULL,
          amount REAL NOT NULL,
          payment_date TEXT NOT NULL,
          payment_method TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (license_id) REFERENCES sold_licenses(id)
        )
      ''');

      print('✅ Tabelas criadas!');
    },
  );

  // Criar usuário admin
  final username = 'admin';
  final password = 'admin#7435';
  final passwordHash = _hashPassword(password);
  final licenseKey = '1A56-0FD1-4814-E762';
  final now = DateTime.now();
  final expiryDate = now.add(const Duration(days: 365));

  print('');
  print('👤 Criando usuário administrativo...');
  await db.insert('users', {
    'username': username,
    'password_hash': passwordHash,
    'created_at': now.toIso8601String(),
    'license_key': licenseKey,
  });
  print('   ✅ Usuário criado: $username');

  print('');
  print('🔑 Criando licença...');
  await db.insert('licenses', {
    'license_key': licenseKey,
    'username': username,
    'expiry_date': expiryDate.toIso8601String(),
    'is_active': 1,
    'created_at': now.toIso8601String(),
  });
  print('   ✅ Licença criada: $licenseKey');

  // Verificar dados
  final users = await db.query('users');
  final licenses = await db.query('licenses');

  await db.close();

  print('');
  print('=' * 70);
  print('✅ BANCO CRIADO COM SUCESSO!');
  print('=' * 70);
  print('');
  print('📊 Resumo:');
  print('   • Usuários: ${users.length}');
  print('   • Licenças: ${licenses.length}');
  print('');
  print('🔐 Credenciais de Login Administrativo:');
  print('   • Usuário: superadmin');
  print('   • Senha: $password');
  print('   • Licença: Não necessário para admin');
  print(
    '   • Validade da licença do sistema: ${expiryDate.toString().split(' ')[0]}',
  );
  print('');
  print('=' * 70);
  print('');
  print('📝 INSTRUÇÕES:');
  print('   1. FECHE COMPLETAMENTE o app SushiGen (Cmd+Q)');
  print('   2. Abra o app novamente');
  print('   3. Clique em "Área Administrativa"');
  print('   4. Login: superadmin / admin#7435');
  print('   5. Acesse Configurações (⚙️) para trocar a senha');
  print('');
  print('✨ Sistema pronto para uso profissional!');
  print('=' * 70);
}

String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
