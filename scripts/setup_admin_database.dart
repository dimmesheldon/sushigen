import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Script para criar banco administrativo manualmente
void main() async {
  print('🔧 Criando banco administrativo do SushiGen...\n');

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
  print('🗄️  Caminho do banco: $dbPath\n');

  // Verificar se já existe
  if (File(dbPath).existsSync()) {
    print('⚠️  Banco administrativo já existe!');
    print('   Deseja sobrescrever? (s/N)');
    final response = stdin.readLineSync();
    if (response?.toLowerCase() != 's') {
      print('❌ Operação cancelada.');
      return;
    }
    File(dbPath).deleteSync();
    print('🗑️  Banco antigo removido.\n');
  }

  // Criar usuário admin
  final username = 'admin';
  final password = 'admin123';
  final passwordHash = _hashPassword(password);

  // Criar licença válida por 1 ano
  final now = DateTime.now();
  final expiryDate = now.add(const Duration(days: 365));
  final licenseKey = '1A56-0FD1-4814-E762';

  print('👤 Criando usuário admin...');
  print('   Username: $username');
  print('   Senha: $password');
  print('   Hash: $passwordHash\n');

  print('🔑 Criando licença...');
  print('   Chave: $licenseKey');
  print('   Validade: ${expiryDate.toString().split(' ')[0]}\n');

  // SQL para criar estrutura
  final sqlCommands =
      '''
-- Criar banco
.open $dbPath

-- Tabela de usuários
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT NOT NULL,
  license_key TEXT
);

-- Tabela de licenças
CREATE TABLE IF NOT EXISTS licenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  license_key TEXT UNIQUE NOT NULL,
  username TEXT NOT NULL,
  expiry_date TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

-- Tabela de clientes (para área administrativa)
CREATE TABLE IF NOT EXISTS clients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  license_key TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL
);

-- Inserir usuário admin
INSERT INTO users (username, password_hash, created_at, license_key)
VALUES ('$username', '$passwordHash', '${now.toIso8601String()}', '$licenseKey');

-- Inserir licença
INSERT INTO licenses (license_key, username, expiry_date, is_active, created_at)
VALUES ('$licenseKey', '$username', '${expiryDate.toIso8601String()}', 1, '${now.toIso8601String()}');

.exit
''';

  // Salvar script SQL
  final sqlFile = File('/tmp/setup_sushigen.sql');
  sqlFile.writeAsStringSync(sqlCommands);

  print('💾 Script SQL criado em: ${sqlFile.path}\n');
  print('📝 Executando comandos SQL...\n');

  // Executar com sqlite3
  final result = await Process.run('sqlite3', [
    dbPath,
    '<',
    sqlFile.path,
  ], runInShell: true);

  if (result.exitCode == 0) {
    print('✅ Banco criado com sucesso!\n');
    print('═' * 60);
    print('📊 RESUMO');
    print('═' * 60);
    print('🗄️  Banco: $dbPath');
    print('👤 Usuário: $username');
    print('🔑 Senha: $password');
    print('🎫 Licença: $licenseKey');
    print('📅 Validade: ${expiryDate.toString().split(' ')[0]}');
    print('═' * 60);
    print('\n✨ Pronto! Agora você pode fazer login no app.');
  } else {
    print('❌ Erro ao criar banco:');
    print(result.stderr);
  }
}

String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString();
}
