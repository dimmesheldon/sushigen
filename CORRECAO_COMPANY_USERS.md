# ✅ Correção: Tabela company_users Não Existia

## 🐛 Problema Identificado

### Erro ao Gerenciar Usuários no Painel Admin
```
SqliteException(1): no such table: company_users, 
SQL logic error while preparing statement, 
SELECT * FROM company_users WHERE customer_id = ? ORDER BY created_at DESC
```

**Local do Erro**: Painel Administrativo → Gerenciar Clientes → Cliente "Asu" → Gerenciar Usuários

## 🔍 Diagnóstico

O sistema tinha toda a lógica implementada para gerenciar usuários de empresas (company_users):
- ✅ Entidade `CompanyUser` criada
- ✅ AdminRepository com todos os métodos (getCompanyUsersByCustomerId, createCompanyUser, etc.)
- ✅ CompanyUsersProvider com state management
- ✅ CompanyUsersScreen com UI completa

**MAS**: A tabela `company_users` **nunca foi criada** no banco de dados!

### Causa Raiz
O método `_onCreateAdmin()` no `DatabaseHelper` criava 6 tabelas:
1. ✅ users
2. ✅ licenses
3. ✅ devices
4. ✅ customers
5. ✅ sold_licenses
6. ✅ payments
7. ❌ **company_users** → FALTAVA!

## 🛠️ Solução Implementada

### 1. Adicionada Criação da Tabela no `_onCreateAdmin`

**Arquivo**: `lib/core/database/database_helper.dart`

```dart
// Tabela de Usuários da Empresa (company_users)
await db.execute('''
  CREATE TABLE company_users (
    id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    email TEXT,
    role TEXT DEFAULT 'user',
    is_active INTEGER DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
  )
''');
```

### 2. Adicionados Índices para Performance

```dart
await db.execute(
  'CREATE INDEX idx_company_users_customer ON company_users(customer_id)',
);
await db.execute(
  'CREATE INDEX idx_company_users_username ON company_users(username)',
);
```

### 3. Migração para Bancos Existentes

Atualizado `_onUpgradeAdmin` para criar a tabela em bancos antigos:

```dart
Future<void> _onUpgradeAdmin(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 4) {
    // Migração da versão 3 para 4: Adicionar tabela company_users
    await db.execute('''
      CREATE TABLE IF NOT EXISTS company_users (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
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
}
```

## ✅ Verificação

### Antes
```bash
$ sqlite3 sushigen_admin.db ".tables"
customers         licenses          sold_licenses
devices           payments          users
```
❌ company_users **não existia**

### Depois
```bash
$ sqlite3 sushigen_admin.db ".tables"
company_users     devices           payments          users
customers         licenses          sold_licenses
```
✅ company_users **criada com sucesso**

## 🚀 Como Aplicar

### Para Novos Bancos
O banco será criado automaticamente com a tabela `company_users` incluída.

### Para Bancos Existentes
**Opção 1: Recriar banco admin** (RECOMENDADO para desenvolvimento)
```bash
rm ~/Library/Containers/com.sushigen.sushigen/Data/Documents/sushigen_admin.db
dart run scripts/init_admin_quick.dart
```

**Opção 2: Migração automática**
O banco será atualizado automaticamente na próxima inicialização devido ao `_onUpgradeAdmin`.

## 📊 Schema da Tabela company_users

| Coluna         | Tipo    | Descrição                           |
|---------------|---------|-------------------------------------|
| id            | TEXT    | UUID único (PK)                    |
| customer_id   | TEXT    | ID do cliente (FK → customers)     |
| username      | TEXT    | Nome de usuário (UNIQUE)           |
| password_hash | TEXT    | Hash da senha (SHA-256)            |
| email         | TEXT    | E-mail do usuário (opcional)       |
| role          | TEXT    | Papel: 'admin' ou 'user'           |
| is_active     | INTEGER | 1 = ativo, 0 = inativo             |
| created_at    | TEXT    | Data de criação (ISO 8601)         |
| updated_at    | TEXT    | Data de atualização (ISO 8601)     |

### Índices
- `idx_company_users_customer`: Busca rápida por cliente
- `idx_company_users_username`: Busca rápida por username

## 🎯 Funcionalidades Agora Disponíveis

Com a tabela `company_users` criada, o sistema pode:

1. ✅ **Listar usuários** de um cliente específico
2. ✅ **Criar novos usuários** para empresas
3. ✅ **Editar usuários** existentes
4. ✅ **Resetar senhas** de usuários
5. ✅ **Desativar/ativar** usuários
6. ✅ **Excluir usuários** de empresas
7. ✅ **Validar credenciais** no login

## 🔒 Multi-Tenant Corrigido

A tabela `company_users` é fundamental para o sistema multi-tenant:

```
Admin DB (sushigen_admin.db)
├── customers (clientes/empresas)
├── sold_licenses (licenças vendidas)
└── company_users (usuários de cada cliente) ← ADICIONADA
    └── FK: customer_id

Cliente DB (sushigen_db_{customer_id}.db)
├── products (produtos do cliente)
├── sales (vendas do cliente)
└── cash_flow (caixa do cliente)
```

## 📝 Resumo da Correção

| Item                        | Status |
|----------------------------|--------|
| Schema atualizado          | ✅      |
| Índices criados            | ✅      |
| Migração implementada      | ✅      |
| Banco recriado             | ✅      |
| App testado                | ⏳      |

## 🧪 Próximos Passos

1. ⏳ Fazer login como superadmin
2. ⏳ Navegar até Gerenciar Clientes → Asu → Gerenciar Usuários
3. ⏳ Criar novo usuário para o cliente Asu
4. ⏳ Testar edição, reset de senha e exclusão

---

**Data**: 11/02/2026  
**Versão do Banco**: 4  
**Status**: ✅ Correção completa - aguardando testes
