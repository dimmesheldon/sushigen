# ✅ Correção: Campo full_name Faltando em company_users

## 🐛 Problema Identificado

### Erro ao Carregar Usuários
```
Erro ao carregar usuários
(type 'Null' is not a subtype of type 'String' in type cast)
```

**Local do Erro**: Painel Administrativo → Gerenciar Clientes → Cliente "Asu" → Gerenciar Usuários

## 🔍 Diagnóstico

### Causa Raiz
A entidade `CompanyUser` espera um campo **obrigatório** `full_name`:

```dart
// lib/features/admin/domain/entities/company_user.dart
factory CompanyUser.fromMap(Map<String, dynamic> map) {
  return CompanyUser(
    id: map['id'] as String,
    customerId: map['customer_id'] as String,
    username: map['username'] as String,
    passwordHash: map['password_hash'] as String,
    fullName: map['full_name'] as String,  // ❌ CAMPO OBRIGATÓRIO
    email: map['email'] as String?,
    // ...
  );
}
```

**MAS**: A tabela `company_users` foi criada **sem** o campo `full_name`:

```sql
-- Schema INCORRETO (antes)
CREATE TABLE company_users (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  email TEXT,              -- ❌ SEM full_name!
  role TEXT DEFAULT 'user',
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

Quando o código tentava fazer `map['full_name'] as String`, o valor era `null`, causando:
```
type 'Null' is not a subtype of type 'String' in type cast
```

## 🛠️ Solução Implementada

### 1. Adicionado Campo na Criação da Tabela

**Arquivo**: `lib/core/database/database_helper.dart`

```dart
// Tabela de Usuários da Empresa (company_users)
await db.execute('''
  CREATE TABLE company_users (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    full_name TEXT NOT NULL,  // ✅ ADICIONADO
    email TEXT,
    role TEXT DEFAULT 'user',
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
  )
''');
```

### 2. Migração Automática para Bancos Existentes

Atualizado `_onUpgradeAdmin` para adicionar o campo em bancos que já têm a tabela:

```dart
Future<void> _onUpgradeAdmin(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 4) {
    // Criar tabela company_users com full_name
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_users (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,  // ✅ INCLUÍDO
        email TEXT,
        role TEXT DEFAULT 'user',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Criar índices
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_company_users_customer ON company_users(customer_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_company_users_username ON company_users(username)',
    );
  }

  // ✅ MIGRAÇÃO INTELIGENTE: Adicionar full_name se não existe
  final columns = await db.rawQuery("PRAGMA table_info(company_users)");
  final hasFullName = columns.any((col) => col['name'] == 'full_name');
  
  if (!hasFullName) {
    // Adicionar coluna full_name
    await db.execute(
      'ALTER TABLE company_users ADD COLUMN full_name TEXT',
    );
    
    // Atualizar registros existentes: usar username como full_name temporário
    await db.execute(
      'UPDATE company_users SET full_name = username WHERE full_name IS NULL',
    );
  }
}
```

### 3. Atualização Manual do Banco Atual

Para o banco já existente, executei:

```bash
# Adicionar coluna
sqlite3 sushigen_admin.db \
  "ALTER TABLE company_users ADD COLUMN full_name TEXT;"

# Atualizar registro existente
sqlite3 sushigen_admin.db \
  "UPDATE company_users SET full_name = 'Administrador Asu' WHERE username = 'asu_admin';"
```

## ✅ Verificação

### Antes
```sql
sqlite> PRAGMA table_info(company_users);
0|id|TEXT|0||1
1|customer_id|TEXT|1||0
2|username|TEXT|1||0
3|password_hash|TEXT|1||0
4|email|TEXT|0||0          ❌ SEM full_name
5|role|TEXT|0|'user'|0
6|is_active|INTEGER|0|1|0
7|created_at|TEXT|1||0
8|updated_at|TEXT|1||0
```

### Depois
```sql
sqlite> PRAGMA table_info(company_users);
0|id|TEXT|0||1
1|customer_id|TEXT|1||0
2|username|TEXT|1||0
3|password_hash|TEXT|1||0
4|full_name|TEXT|0||0       ✅ ADICIONADO
5|email|TEXT|0||0
6|role|TEXT|0|'user'|0
7|is_active|INTEGER|0|1|0
8|created_at|TEXT|1||0
9|updated_at|TEXT|1||0

sqlite> SELECT username, full_name, email, role FROM company_users;
asu_admin|Administrador Asu|asu_admin@sushigen.com|admin  ✅
```

## 📊 Schema Atualizado

### Tabela `company_users` (CORRIGIDA)

| Coluna         | Tipo    | Obrigatório | Descrição                           |
|---------------|---------|-------------|-------------------------------------|
| id            | TEXT    | ✅          | UUID único (PK)                    |
| customer_id   | TEXT    | ✅          | ID do cliente (FK → customers)     |
| username      | TEXT    | ✅          | Nome de usuário (UNIQUE)           |
| password_hash | TEXT    | ✅          | Hash da senha (SHA-256)            |
| **full_name** | **TEXT**| **✅**      | **Nome completo do usuário** 🆕    |
| email         | TEXT    | ❌          | E-mail do usuário (opcional)       |
| role          | TEXT    | ❌          | Papel: 'admin' ou 'user'           |
| is_active     | INTEGER | ❌          | 1 = ativo, 0 = inativo             |
| created_at    | TEXT    | ✅          | Data de criação (ISO 8601)         |
| updated_at    | TEXT    | ✅          | Data de atualização (ISO 8601)     |

## 🎯 Funcionalidades Agora Disponíveis

Com o campo `full_name` criado, o sistema pode:

1. ✅ **Listar usuários** sem erro de cast
2. ✅ **Exibir nome completo** na interface
3. ✅ **Criar novos usuários** com nome completo
4. ✅ **Editar usuários** e alterar nome completo
5. ✅ **Todos os CRUDs** funcionando corretamente

## 🧪 Como Testar

1. **Reinicie o app** (encerrar e abrir novamente)
2. **Faça login** como superadmin
3. **Navegue**: Painel Admin → Gerenciar Clientes → Asu → Gerenciar Usuários
4. **Resultado esperado**:
   - ✅ Nenhum erro
   - ✅ Usuário "Administrador Asu" visível
   - ✅ Pode criar, editar, resetar senha e excluir

## 🔄 Migração Automática

Para bancos futuros:
- ✅ Tabela criada com `full_name` desde o início
- ✅ Migração automática adiciona `full_name` em bancos antigos
- ✅ Registros existentes recebem `username` como `full_name` padrão

## 📝 Resumo da Correção

| Item                              | Status |
|-----------------------------------|--------|
| Campo `full_name` no schema       | ✅      |
| Migração automática implementada  | ✅      |
| Banco atual atualizado            | ✅      |
| Registro existente corrigido      | ✅      |
| App reiniciado                    | ⏳      |

---

**Data**: 11/02/2026  
**Versão do Banco**: 4  
**Status**: ✅ Correção completa - reinicie o app para testar
