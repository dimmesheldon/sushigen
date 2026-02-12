import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Script para resetar e criar banco administrativo
void main() async {
  print('🔧 RESET DO BANCO ADMINISTRATIVO\n');

  // Inicializar FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Definir caminho do banco
  final appSupportDir = Directory(
    '${Platform.environment['HOME']}/Library/Application Support/com.sushigen.app',
  );

  // Criar diretório se não existir
  if (!appSupportDir.existsSync()) {
    print('📁 Criando diretório: ${appSupportDir.path}');
    appSupportDir.createSync(recursive: true);
  }

  final dbPath = '${appSupportDir.path}/sushigen_admin.db';
  print('🗄️  Banco: $dbPath\n');

  // Remover banco antigo se existir
  if (File(dbPath).existsSync()) {
    print('🗑️  Removendo banco antigo...');
    File(dbPath).deleteSync();
  }

  print('✨ Criando novo banco...\n');

  // Criar banco
  final db = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) async {
      // Criar tabelas
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TEXT NOT NULL,
          license_key TEXT
        )
      ''');

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

      print('✅ Tabelas criadas!\n');
    },
  );

  // Criar usuário admin
  final username = 'admin';
  final password = 'admin#7435';
  final passwordHash = _hashPassword(password);
  final licenseKey = '1A56-0FD1-4814-E762';
  final now = DateTime.now();
  final expiryDate = now.add(const Duration(days: 365));

  print('👤 Criando usuário admin...');
  await db.insert('users', {
    'username': username,
    'password_hash': passwordHash,
    'created_at': now.toIso8601String(),
    'license_key': licenseKey,
  });
  print('   ✅ Usuário criado: $username\n');

  print('🔑 Criando licença...');
  await db.insert('licenses', {
    'license_key': licenseKey,
    'username': username,
    'expiry_date': expiryDate.toIso8601String(),
    'is_active': 1,
    'created_at': now.toIso8601String(),
  });
  print('   ✅ Licença criada: $licenseKey\n');

  // Verificar dados
  final users = await db.query('users');
  final licenses = await db.query('licenses');

  await db.close();

  print('═' * 60);
  print('✅ BANCO CRIADO COM SUCESSO!');
  print('═' * 60);
  print('📊 Resumo:');
  print('   • Usuários: ${users.length}');
  print('   • Licenças: ${licenses.length}');
  print('\n🔐 Credenciais de Login:');
  print('   • Usuário: $username');
  print('   • Senha: $password');
  print('   • Licença: $licenseKey');
  print('   • Validade: ${expiryDate.toString().split(' ')[0]}');
  print('═' * 60);
  print('\n✨ Pronto! Feche e abra o app novamente para fazer login.');
}

String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
