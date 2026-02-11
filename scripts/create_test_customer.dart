import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() async {
  print('🚀 Criando cliente de teste "Asu"...\n');

  // Inicializar FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Obter caminho do banco admin
  final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  final String dbPath = join(appDocumentsDir.path, 'sushigen_admin.db');

  print('📁 Caminho do banco: $dbPath\n');

  // Abrir banco
  final db = await openDatabase(dbPath);

  final uuid = const Uuid();
  final now = DateTime.now();

  // Criar cliente Asu
  final customerId = uuid.v4();
  print('👤 Criando cliente "Asu"...');

  await db.insert('customers', {
    'id': customerId,
    'name': 'Asu',
    'email': 'asu@sushigen.com',
    'phone': '(11) 98765-4321',
    'business_name': 'Asu Sushi Bar',
    'cnpj': '12.345.678/0001-90',
    'address': 'Rua das Flores, 123',
    'city': 'São Paulo',
    'state': 'SP',
    'notes': 'Cliente de teste criado automaticamente',
    'is_active': 1,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });

  print('✅ Cliente "Asu" criado: $customerId\n');

  // Criar licença para o cliente Asu
  final licenseKey = '1234-ABCD-5678-EFGH';
  final username = 'asu';
  final password = 'asu123';
  final passwordHash = sha256.convert(utf8.encode(password)).toString();

  print('🔑 Criando licença para Asu...');

  final expirationDate = now.add(const Duration(days: 365));

  await db.insert('sold_licenses', {
    'id': uuid.v4(),
    'customer_id': customerId,
    'license_key': licenseKey,
    'username': username,
    'password_hash': passwordHash,
    'days': 365,
    'start_date': now.toIso8601String(),
    'expiration_date': expirationDate.toIso8601String(),
    'status': 'active',
    'price': 1200.0,
    'payment_method': 'Pix',
    'notes': 'Licença de teste - 1 ano',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });

  print('✅ Licença criada: $licenseKey\n');

  // Criar usuário na tabela users para login
  await db.insert('users', {
    'id': uuid.v4(),
    'username': username,
    'password_hash': passwordHash,
    'email': 'asu@sushigen.com',
    'role': 'user',
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });

  print('✅ Usuário de login criado!\n');

  // Criar usuário admin na tabela company_users
  await db.insert('company_users', {
    'id': uuid.v4(),
    'customer_id': customerId,
    'username': 'asu_admin',
    'password_hash': passwordHash,
    'email': 'asu_admin@sushigen.com',
    'role': 'admin',
    'is_active': 1,
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });

  print('✅ Usuário admin (company_users) criado!\n');

  await db.close();

  print('═══════════════════════════════════════════════════════════');
  print('🎉 CLIENTE ASU CRIADO COM SUCESSO!');
  print('═══════════════════════════════════════════════════════════\n');
  print('📋 INFORMAÇÕES:');
  print('   Cliente: Asu Sushi Bar');
  print('   Customer ID: $customerId');
  print('   Email: asu@sushigen.com\n');
  print('🔑 CREDENCIAIS DE LOGIN:');
  print('   Usuário: $username');
  print('   Senha: $password');
  print('   Licença: $licenseKey\n');
  print('👥 USUÁRIO ADMIN (COMPANY_USERS):');
  print('   Username: asu_admin');
  print('   Senha: $password');
  print('   Role: admin\n');
  print('🚀 Agora você pode:');
  print('   1. Fazer login como superadmin no Painel Admin');
  print('   2. Gerenciar o cliente "Asu"');
  print('   3. Ver e editar o usuário asu_admin');
  print('═══════════════════════════════════════════════════════════');
}
