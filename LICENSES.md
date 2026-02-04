# 🔑 Chaves de Licença do SushiGen

## Chaves Geradas para Testes

### 🆓 Licença Trial (30 dias)
```
Chave: 8288-EFEE-9D08-5AF5
Validade: 30 dias
Dispositivos: 3
```

### 📅 Licença Mensal
```
Chave: A76C-4BAE-241D-E16F
Validade: 30 dias
Dispositivos: 3
```

### 📆 Licença Anual (Recomendada)
```
Chave: 6319-35B3-FD24-1BC8
Validade: 365 dias
Dispositivos: 5
```

### ♾️ Licença Vitalícia
```
Chave: 1A56-0FD1-4814-E762
Validade: 100 anos
Dispositivos: 10
```

---

## 🚀 Como Usar

### Opção 1: Configuração Automática (Recomendada)

Execute o script de setup que cria automaticamente:
- ✅ Banco de dados
- ✅ Usuário admin
- ✅ Licença anual
- ✅ 20 produtos de exemplo

```bash
dart run scripts/setup_database.dart
```

Após executar, use as credenciais geradas no terminal para fazer login.

---

### Opção 2: Configuração Manual

#### 1. Gerar Nova Chave de Licença

**Gerar uma chave:**
```bash
dart run scripts/generate_license.dart
```

**Gerar 5 chaves:**
```bash
dart run scripts/generate_license.dart --multiple 5
```

**Gerar chaves por tipo:**
```bash
dart run scripts/generate_license.dart --typed
```

#### 2. Criar Usuário e Licença no Banco

Use o código abaixo ou adapte conforme necessário:

```dart
import 'package:sushigen/core/database/database_helper.dart';
import 'package:sushigen/features/auth/data/repositories/auth_repository.dart';

void main() async {
  final authRepo = AuthRepository();
  
  // Criar usuário
  final user = await authRepo.createUser(
    username: 'admin',
    password: 'admin123',
    email: 'admin@sushigen.com',
    role: 'admin',
  );
  
  // Criar licença
  final expirationDate = DateTime.now().add(Duration(days: 365));
  await authRepo.createLicense(
    userId: user.id,
    licenseKey: '6319-35B3-FD24-1BC8', // Use a chave gerada
    expirationDate: expirationDate,
    maxDevices: 5,
  );
  
  print('✅ Configuração concluída!');
}
```

---

## 📋 Credenciais de Teste Padrão

Após executar o `setup_database.dart`:

```
Usuário: admin
Senha: admin123
Chave de Licença: [exibida no terminal após o setup]
```

---

## 🔐 Formato das Chaves

Todas as chaves seguem o formato:
```
XXXX-XXXX-XXXX-XXXX
```

Onde cada `X` é um caractere hexadecimal (0-9, A-F).

**Exemplo válido:** `6319-35B3-FD24-1BC8`

---

## 🛠️ Gerando Chaves Programaticamente

Use a classe `LicenseKeyGenerator`:

```dart
import 'package:sushigen/core/utils/license_key_generator.dart';

// Chave simples
final key = LicenseKeyGenerator.generate();

// Chave por tipo
final yearlyKey = LicenseKeyGenerator.generateTyped(LicenseType.yearly);

// Múltiplas chaves
final keys = LicenseKeyGenerator.generateMultiple(10);

// Validar formato
bool isValid = LicenseKeyGenerator.isValidFormat('6319-35B3-FD24-1BC8');
```

---

## 📊 Tipos de Licença

| Tipo | Duração | Dispositivos | Uso Recomendado |
|------|---------|--------------|-----------------|
| 🆓 Trial | 30 dias | 3 | Testes e demonstrações |
| 📅 Mensal | 30 dias | 3 | Assinatura mensal |
| 📆 Anual | 365 dias | 5 | Assinatura anual (recomendado) |
| ♾️ Vitalícia | 100 anos | 10 | Licença perpétua |

---

## ⚠️ Importante

- As chaves são geradas usando SHA-256 + UUID
- Cada chave é única e não pode ser duplicada
- O sistema valida automaticamente a expiração no login
- Licenças expiradas bloqueiam o acesso
- O limite de dispositivos é controlado por licença

---

## 🔄 Renovação de Licença

Para renovar uma licença:

1. Gere uma nova chave
2. Atualize no banco de dados:
   ```sql
   UPDATE licenses 
   SET license_key = 'NOVA-CHAVE-AQUI',
       expiration_date = '2027-02-03T00:00:00',
       is_active = 1
   WHERE user_id = 'ID_DO_USUARIO';
   ```

---

## 📞 Suporte

Para qualquer dúvida sobre licenciamento:
- Verifique o código em `lib/core/utils/license_key_generator.dart`
- Consulte o repositório em `lib/features/auth/data/repositories/auth_repository.dart`
- Execute os scripts de teste em `scripts/`

---

**Última atualização:** 03/02/2026
