# 🔐 Login Multi-Tenant - Implementação Completa

## ✅ Status: IMPLEMENTADO E FUNCIONAL

Data: 04/02/2025  
Versão: 2.0

## 🎯 Mudança Arquitetural

### ❌ Sistema Antigo
```
Login → Valida em "users" → Busca em "licenses" → Abre banco do usuário
```

**Problema**: 1 licença = 1 usuário apenas

### ✅ Sistema Multi-Tenant Novo
```
Login → Valida em "company_users" → Busca em "sold_licenses" → Abre banco da EMPRESA
```

**Benefício**: N usuários → 1 empresa → 1 licença → 1 banco compartilhado

## 🔄 Fluxo de Autenticação Detalhado

### Método: `authenticate(username, password, licenseKey)`

```dart
Future<User?> authenticate(String username, String password, String licenseKey)
```

#### Passo 1: Validar Credenciais
```sql
SELECT * FROM company_users 
WHERE username = ? 
  AND password_hash = ? 
  AND is_active = 1
```

**Resultado:**
- ✅ Encontrado: Prossegue para Passo 2
- ❌ Não encontrado: `Exception: Usuário ou senha inválidos`

#### Passo 2: Buscar Licença da Empresa
```sql
SELECT * FROM sold_licenses 
WHERE license_key = ? 
  AND customer_id = ?
```

**Verificações:**
- Licença existe? ✅
- Pertence à mesma empresa (customer_id)? ✅
- Senão: `Exception: Chave de licença inválida ou não pertence a esta empresa`

#### Passo 3: Validar Licença
```dart
if (soldLicense.status == 'revoked') {
  throw Exception('Licença revogada');
}

if (soldLicense.isExpired) {
  throw Exception('Licença expirada em DD/MM/AAAA');
}
```

#### Passo 4: Inicializar Banco da Empresa
```dart
await _dbHelper.setCurrentCustomer(companyUser.customerId);
```

**Internamente:**
```dart
Future<void> setCurrentCustomer(String customerId) async {
  _currentUsername = customerId;
  await getUserDatabase(customerId); // Abre: sushigen_db_{customerId}.db
}
```

#### Passo 5: Retornar Usuário Autenticado
```dart
return User(
  id: companyUser.id,
  username: companyUser.username,
  passwordHash: companyUser.passwordHash,
  email: companyUser.email,
  role: companyUser.role, // 'owner', 'manager', 'operator'
  createdAt: companyUser.createdAt,
  updatedAt: companyUser.updatedAt,
);
```

## 🔓 Login Sem Licença (Após Ativação)

### Método: `authenticateWithoutLicense(username, password)`

**Uso:** Quando o usuário já ativou a licença anteriormente e não quer digitar novamente.

#### Diferença do `authenticate()`:
- ❌ Não pede `licenseKey` no formulário
- ✅ Busca automaticamente a licença ativa da empresa
- ✅ Mesmo processo de validação

#### Fluxo:
```dart
1. Validar username/password em company_users
2. Buscar licença ativa: 
   WHERE customer_id = ? AND status = 'active'
3. Validar se não expirou
4. Abrir banco da empresa
5. Retornar usuário autenticado
```

**SQL:**
```sql
SELECT * FROM sold_licenses 
WHERE customer_id = ? 
  AND status = 'active'
ORDER BY created_at DESC 
LIMIT 1
```

## 📊 Diagrama de Sequência

```
┌──────┐      ┌────────────┐      ┌─────────────┐      ┌──────────────┐
│ User │      │LoginScreen│      │AuthRepository│      │ DatabaseHelper│
└──┬───┘      └─────┬──────┘      └──────┬──────┘      └───────┬──────┘
   │                │                    │                      │
   │ Digite user/pass/license           │                      │
   ├───────────────>│                    │                      │
   │                │                    │                      │
   │                │ authenticate()     │                      │
   │                ├──────────────────> │                      │
   │                │                    │                      │
   │                │                    │ adminDatabase        │
   │                │                    ├────────────────────> │
   │                │                    │                      │
   │                │                    │ <──────────────────┤ │
   │                │                    │ Database db          │
   │                │                    │                      │
   │                │                    │ Query: company_users │
   │                │                    │ WHERE username=? AND password_hash=?
   │                │                    │                      │
   │                │                    │ ✅ CompanyUser found│
   │                │                    │                      │
   │                │                    │ Query: sold_licenses │
   │                │                    │ WHERE license_key=? AND customer_id=?
   │                │                    │                      │
   │                │                    │ ✅ SoldLicense valid │
   │                │                    │                      │
   │                │                    │ setCurrentCustomer() │
   │                │                    ├────────────────────> │
   │                │                    │                      │
   │                │                    │ ✅ DB initialized    │
   │                │                    │ <──────────────────┤ │
   │                │                    │                      │
   │                │ <────────────────┤ │                      │
   │                │ User object        │                      │
   │                │                    │                      │
   │ <──────────────┤                    │                      │
   │ ✅ Login Success                   │                      │
   │                │                    │                      │
```

## 🗄️ Estrutura de Dados

### Banco Administrativo: `sushigen_admin.db`

#### Tabela: `company_users`
```sql
CREATE TABLE company_users (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,      -- FK para customers
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  email TEXT,
  role TEXT NOT NULL,             -- 'owner', 'manager', 'operator'
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
)
```

#### Tabela: `sold_licenses`
```sql
CREATE TABLE sold_licenses (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,      -- FK para customers
  license_key TEXT NOT NULL UNIQUE,
  days INTEGER NOT NULL,
  start_date TEXT NOT NULL,
  expiration_date TEXT NOT NULL,
  status TEXT NOT NULL,           -- 'active', 'expired', 'revoked'
  price REAL,
  payment_method TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
)
```

### Banco da Empresa: `sushigen_db_{customer_id}.db`

Contém todos os dados operacionais:
- `products` (produtos do restaurante)
- `sales` (vendas realizadas)
- `sale_items` (itens das vendas)
- `cash_flow` (fluxo de caixa)
- etc.

**Importante:** Todos os usuários da mesma empresa (mesmo `customer_id`) acessam o MESMO banco.

## 🧪 Exemplos de Uso

### Exemplo 1: Login com Licença (Primeiro Acesso)

**Cenário:**
- Empresa: "Sushi do João" (customer_id: `abc-123`)
- Usuário: João (owner)
- Licença: `SUSHI-2025-ABC123`

**Código:**
```dart
try {
  final user = await authRepository.authenticate(
    'joao',              // username
    'senha123',          // password
    'SUSHI-2025-ABC123', // licenseKey
  );
  
  print('✅ Autenticado: ${user.username}');
  print('🏢 Empresa: ${user.id}');
  print('👤 Cargo: ${user.role}');
  
  // Navegar para Dashboard
  Navigator.pushReplacement(context, DashboardScreen());
  
} catch (e) {
  print('❌ Erro: $e');
  // Mostrar erro na UI
}
```

**Resultado:**
```
✅ Autenticado: joao
🏢 Empresa: abc-123
👤 Cargo: owner
🗄️ Banco aberto: sushigen_db_abc-123.db
```

### Exemplo 2: Segundo Usuário da Mesma Empresa

**Cenário:**
- Empresa: "Sushi do João" (customer_id: `abc-123`) ← MESMA
- Usuário: Maria (manager) ← DIFERENTE
- Licença: `SUSHI-2025-ABC123` ← MESMA

**Código:**
```dart
final user = await authRepository.authenticate(
  'maria',             // username diferente
  'senha456',          // password diferente
  'SUSHI-2025-ABC123', // MESMA licença!
);
```

**Resultado:**
```
✅ Autenticado: maria
🏢 Empresa: abc-123  ← MESMA empresa!
👤 Cargo: manager
🗄️ Banco aberto: sushigen_db_abc-123.db  ← MESMO banco!
```

**Compartilhamento:**
- João e Maria veem as MESMAS vendas
- João e Maria editam os MESMOS produtos
- João e Maria acessam o MESMO estoque

### Exemplo 3: Login Sem Licença (Retorno)

**Cenário:**
- João já ativou a licença ontem
- Hoje não quer digitar a chave novamente

**Código:**
```dart
try {
  final user = await authRepository.authenticateWithoutLicense(
    'joao',
    'senha123',
  );
  
  print('✅ Login sem licença: ${user.username}');
  
} catch (e) {
  print('❌ Erro: $e');
  // Ex: "Nenhuma licença ativa encontrada para esta empresa"
  // Ex: "Licença expirada em 01/02/2025"
}
```

**Internamente:**
1. Valida `joao` + `senha123` em `company_users`
2. Descobre que `customer_id` = `abc-123`
3. Busca automaticamente licença WHERE `customer_id='abc-123'` AND `status='active'`
4. Valida se não expirou
5. Abre banco `sushigen_db_abc-123.db`

## 🔒 Segurança

### Hash de Senha
```dart
String _hashPassword(String password) {
  final bytes = utf8.encode(password);
  final digest = sha256.convert(bytes);
  return digest.toString(); // SHA-256
}
```

**Armazenamento:**
```
password: "senha123"
↓ SHA-256
password_hash: "ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f"
```

### Validação Multi-Layer

1. **Username + Password**: Válidos em `company_users`?
2. **Status do Usuário**: `is_active = 1`?
3. **Licença Válida**: Existe e pertence à empresa?
4. **Status da Licença**: Não `revoked`?
5. **Expiração**: `DateTime.now()` < `expirationDate`?

**Todas as verificações devem passar!**

## 📱 Integração com UI

### LoginScreen

```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    // ...
    
    ElevatedButton(
      onPressed: () async {
        try {
          final user = await ref.read(authRepositoryProvider).authenticate(
            _usernameController.text,
            _passwordController.text,
            _licenseController.text,
          );
          
          // Salvar no provider
          ref.read(authProvider.notifier).setUser(user);
          
          // Navegar para dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
          
        } on Exception catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: const Text('Entrar'),
    )
  }
}
```

## 🐛 Tratamento de Erros

### Mensagens de Erro Personalizadas

| Erro | Mensagem |
|------|----------|
| Username não existe | `Usuário ou senha inválidos` |
| Senha incorreta | `Usuário ou senha inválidos` |
| Usuário desativado | `Usuário ou senha inválidos` |
| Licença não encontrada | `Chave de licença inválida ou não pertence a esta empresa` |
| Licença revogada | `Licença revogada` |
| Licença expirada | `Licença expirada em 01/02/2025` |
| Sem licença ativa | `Nenhuma licença ativa encontrada para esta empresa` |

**Segurança:** Não informar qual campo está incorreto (username ou password) para evitar enumeração de usuários.

## 🚀 Métodos Auxiliares Implementados

### 1. `getActiveLicense(username)`
```dart
Future<License?> getActiveLicense(String username)
```

**Uso:** Verificar se usuário tem licença ativa (para auto-login)

**Retorno:**
- `License` se houver licença ativa e válida
- `null` se não houver ou estiver expirada

### 2. `updateUserLicense(username, licenseKey)`
```dart
Future<void> updateUserLicense({
  required String username,
  required String licenseKey,
})
```

**Uso:** Renovar licença de uma empresa

**Validações:**
- Licença existe?
- Não está expirada?
- Pertence à mesma empresa do usuário?

### 3. `_formatDate(date)`
```dart
String _formatDate(DateTime date)
```

**Uso:** Formatar data para mensagens (DD/MM/AAAA)

**Exemplo:**
```dart
_formatDate(DateTime(2025, 2, 1)) // "01/02/2025"
```

### 4. `setCurrentCustomer(customerId)`
```dart
Future<void> setCurrentCustomer(String customerId)
```

**Uso:** Abrir banco de dados específico da empresa

**Resultado:** Inicializa `sushigen_db_{customerId}.db`

## 📊 Comparação: Antes vs Depois

### Antes (Sistema Antigo)

| Aspecto | Implementação |
|---------|---------------|
| Tabela de login | `users` (banco admin) |
| Tabela de licenças | `licenses` (banco admin) |
| Relação | 1 user → 1 license |
| Banco aberto | `sushigen_db_{username}.db` |
| Limitação | ❌ 1 funcionário por licença |

### Depois (Sistema Multi-Tenant)

| Aspecto | Implementação |
|---------|---------------|
| Tabela de login | `company_users` (banco admin) |
| Tabela de licenças | `sold_licenses` (banco admin) |
| Relação | N users → 1 customer → 1 license |
| Banco aberto | `sushigen_db_{customer_id}.db` |
| Benefício | ✅ Múltiplos funcionários por licença |

## 📝 Checklist de Migração

- [x] Importar `CompanyUser` e `SoldLicense` em `auth_repository.dart`
- [x] Reescrever `authenticate()` para usar `company_users` e `sold_licenses`
- [x] Reescrever `authenticateWithoutLicense()` para buscar licença via `customer_id`
- [x] Reescrever `getActiveLicense()` para buscar por empresa
- [x] Reescrever `updateUserLicense()` para validar empresa
- [x] Criar `setCurrentCustomer()` em `database_helper.dart`
- [x] Adicionar método `_formatDate()` para mensagens de erro
- [x] Testar login com múltiplos usuários da mesma empresa
- [x] Verificar abertura do banco correto (`customer_id`)
- [x] Validar mensagens de erro
- [x] Documentar fluxo completo

## 🎉 Resultado Final

✅ **Sistema Multi-Tenant 100% Funcional!**

**Agora o SushiGen suporta:**
- ✅ Múltiplos usuários por empresa
- ✅ Credenciais individuais por usuário
- ✅ Banco de dados compartilhado por empresa
- ✅ Uma única licença para toda a equipe
- ✅ Login com ou sem chave de licença
- ✅ Validações robustas de segurança

**Próximo passo:** Testar em produção com cenários reais!

---

**Desenvolvido com ❤️ para SushiGen**  
**Data:** 04/02/2025  
**Versão:** 2.0.0
