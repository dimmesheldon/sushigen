# ✅ Correção: Erro ao Gerar Licença (username e password_hash obrigatórios)

## 🐛 Problema Identificado

### Erro ao Gerar Nova Licença
```
SqliteException(sqlite_error: 1299), SqliteException(1299): while executing statement, 
NOT NULL constraint failed (code 1299)
Causing statement: INSERT INTO sold_licenses (id, customer_id, license_key, days, start_date,
expiration_date, status, price, payment_method, notes, created_at, updated_at) 
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?, ?) args [...]
```

**Local do Erro**: Painel Administrativo → Gerenciar Clientes → Gerar Nova Licença

## 🔍 Diagnóstico

### Causa Raiz
A tabela `sold_licenses` foi criada com os campos `username` e `password_hash` como **NOT NULL**:

```sql
-- Schema INCORRETO (antes)
CREATE TABLE sold_licenses (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  license_key TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL UNIQUE,      ❌ NOT NULL
  password_hash TEXT NOT NULL,        ❌ NOT NULL
  days INTEGER NOT NULL,
  ...
);
```

**MAS**: A entidade `SoldLicense` e o método `generateLicense()` não incluem esses campos:

```dart
// lib/features/admin/data/repositories/admin_repository.dart
Future<SoldLicense> generateLicense({
  required String customerId,
  required int days,
  double? price,
  String? paymentMethod,
  String? notes,
}) async {
  final license = SoldLicense(
    id: _uuid.v4(),
    customerId: customerId,
    licenseKey: licenseKey,
    days: days,
    // ❌ SEM username e password_hash!
    startDate: now,
    expirationDate: expirationDate,
    status: 'active',
    price: price,
    paymentMethod: paymentMethod,
    notes: notes,
    createdAt: now,
    updatedAt: now,
  );

  await db.insert('sold_licenses', license.toMap());
}
```

### Por que isso aconteceu?
No sistema antigo, cada licença criava automaticamente um usuário com username e senha. 

Agora, com a tabela `company_users`, os usuários são gerenciados separadamente da licença, mas o schema da tabela `sold_licenses` ainda exigia esses campos.

## 🛠️ Solução Implementada

### 1. Alterada Tabela `sold_licenses` no Banco Atual

Tornados `username` e `password_hash` **OPCIONAIS**:

```sql
BEGIN TRANSACTION;

-- Salvar dados existentes
CREATE TABLE sold_licenses_backup AS SELECT * FROM sold_licenses;

-- Dropar tabela antiga
DROP TABLE sold_licenses;

-- Recriar com username e password_hash opcionais
CREATE TABLE sold_licenses (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  license_key TEXT NOT NULL UNIQUE,
  username TEXT,              -- ✅ OPCIONAL
  password_hash TEXT,         -- ✅ OPCIONAL
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
);

-- Restaurar dados
INSERT INTO sold_licenses SELECT * FROM sold_licenses_backup;

-- Limpar backup
DROP TABLE sold_licenses_backup;

COMMIT;
```

### 2. Atualizado Schema no `DatabaseHelper`

**Arquivo**: `lib/core/database/database_helper.dart`

```dart
// Tabela de Licenças Vendidas
await db.execute('''
  CREATE TABLE sold_licenses (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    license_key TEXT NOT NULL UNIQUE,
    username TEXT,              -- ✅ OPCIONAL
    password_hash TEXT,         -- ✅ OPCIONAL
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
```

### 3. Migração Automática para Bancos Existentes

Adicionada lógica no `_onUpgradeAdmin` para recriar a tabela automaticamente:

```dart
Future<void> _onUpgradeAdmin(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  // ... código anterior ...

  // Tornar username e password_hash opcionais em sold_licenses
  final licenseColumns = await db.rawQuery("PRAGMA table_info(sold_licenses)");
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
    
    // Recriar índices
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
```

## ✅ Verificação

### Antes
```sql
sqlite> PRAGMA table_info(sold_licenses);
0|id|TEXT|0||1
1|customer_id|TEXT|1||0
2|license_key|TEXT|1||0
3|username|TEXT|1||0         ❌ NOT NULL (notnull=1)
4|password_hash|TEXT|1||0    ❌ NOT NULL (notnull=1)
5|days|INTEGER|1||0
...
```

### Depois
```sql
sqlite> PRAGMA table_info(sold_licenses);
0|id|TEXT|0||1
1|customer_id|TEXT|1||0
2|license_key|TEXT|1||0
3|username|TEXT|0||0         ✅ OPCIONAL (notnull=0)
4|password_hash|TEXT|0||0    ✅ OPCIONAL (notnull=0)
5|days|INTEGER|1||0
...
```

## 📊 Schema Atualizado

### Tabela `sold_licenses` (CORRIGIDA)

| Coluna            | Tipo    | Obrigatório | Descrição                          |
|-------------------|---------|-------------|------------------------------------|
| id                | TEXT    | ✅          | UUID único (PK)                   |
| customer_id       | TEXT    | ✅          | ID do cliente (FK → customers)    |
| license_key       | TEXT    | ✅          | Chave da licença (UNIQUE)         |
| **username**      | **TEXT**| ❌ **OPCIONAL** | **Username (legado)** 🆕      |
| **password_hash** | **TEXT**| ❌ **OPCIONAL** | **Hash senha (legado)** 🆕    |
| days              | INTEGER | ✅          | Duração em dias                   |
| start_date        | TEXT    | ✅          | Data de início (ISO 8601)         |
| expiration_date   | TEXT    | ✅          | Data de expiração (ISO 8601)      |
| status            | TEXT    | ✅          | 'active', 'expired', 'revoked'    |
| price             | REAL    | ❌          | Preço da licença                  |
| payment_method    | TEXT    | ❌          | Forma de pagamento                |
| notes             | TEXT    | ❌          | Observações                       |
| created_at        | TEXT    | ✅          | Data de criação (ISO 8601)        |
| updated_at        | TEXT    | ✅          | Data de atualização (ISO 8601)    |

### Novo Fluxo

**Antes** (sistema antigo):
```
Gerar Licença → Criar username/senha → Inserir em sold_licenses
                                     ↓
                            Usuário não gerenciável
```

**Agora** (novo sistema):
```
Gerar Licença → Inserir em sold_licenses (sem username/senha)
                           ↓
Gerenciar Usuários → Criar em company_users
                           ↓
                  Múltiplos usuários por cliente
```

## 🎯 Funcionalidades Agora Disponíveis

Com os campos opcionais, o sistema pode:

1. ✅ **Gerar licenças** sem criar usuário automaticamente
2. ✅ **Gerenciar usuários separadamente** em `company_users`
3. ✅ **Múltiplos usuários por cliente** (não limitado a 1:1 com licença)
4. ✅ **Usuários com nome completo** (`full_name`)
5. ✅ **Controle granular** (admin, manager, operator)

## 🧪 Como Testar

1. **Login** como superadmin
2. **Navegue**: Painel Admin → Gerenciar Clientes → Asu
3. **Clique**: "Gerar Licença"
4. **Preencha**:
   - Plano: 30 dias
   - Preço: R$ 49,90
   - Forma de pagamento: PIX
5. **Clique**: "Gerar Licença"
6. **Resultado esperado**:
   - ✅ Licença gerada com sucesso!
   - ✅ Sem erro de NOT NULL constraint
   - ✅ Campos username/password_hash podem ficar vazios

## 🔄 Migração Automática

Para bancos futuros:
- ✅ Tabela criada com campos opcionais desde o início
- ✅ Migração automática recria tabela se necessário
- ✅ Dados existentes preservados durante migração

## 📝 Resumo da Correção

| Item                                  | Status |
|---------------------------------------|--------|
| username/password_hash opcionais      | ✅      |
| Schema atualizado                     | ✅      |
| Migração automática implementada      | ✅      |
| Banco atual corrigido                 | ✅      |
| Geração de licença testada            | ⏳      |

---

**Data**: 11/02/2026  
**Versão do Banco**: 4  
**Status**: ✅ Correção completa - teste agora!
