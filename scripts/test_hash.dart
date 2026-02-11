import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  final password = 'admin123';
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  final hash = digest.toString();

  print('Senha: $password');
  print('Hash gerado: $hash');
  print(
    '\nHash no banco: 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
  );
  print(
    'Hashes são iguais: ${hash == "240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9"}',
  );
}
