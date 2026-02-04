# 🏢 Solução Multi-Tenant - SushiGen

**Data**: 2026-02-03  
**Problema**: Todos os usuários compartilham o mesmo banco de dados

---

## 🔍 Problema Atual

```
Estrutura Atual:
~/Documents/sushigen.db  ← TODOS os usuários usam este arquivo

Cliente A (usuário: restaurante_a) ──┐
Cliente B (usuário: sushi_bar)      ├─→ sushigen.db (compartilhado)
Cliente C (usuário: delivery_sushi)──┘

❌ Problema:
- Todos veem os mesmos produtos
- Todos veem as mesmas vendas
- Sem isolamento de dados
```

---

## ✅ Solução 1: Banco Separado por Username (RECOMENDADO)

### Conceito
Cada usuário tem seu próprio arquivo de banco de dados:

```
~/Documents/
  ├── sushigen_restaurante_a.db     ← Cliente A
  ├── sushigen_sushi_bar.db         ← Cliente B
  ├── sushigen_delivery_sushi.db    ← Cliente C
  └── sushigen_admin.db             ← Banco administrativo (clientes, licenças)
```

### Vantagens
✅ Isolamento total de dados  
✅ Simples de implementar  
✅ Backup individual por cliente  
✅ Performance (bancos menores)  
✅ Privacidade garantida  

### Implementação

#### 1. Modificar DatabaseHelper

```dart
class DatabaseHelper {
  static final Map<String, Database> _databases = {};
  static Database? _adminDatabase;
  static String? _currentUsername;

  // Banco administrativo (sempre o mesmo)
  Future<Database> getAdminDatabase() async {
    if (_adminDatabase != null) return _adminDatabase!;
    
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocumentsDir.path, 'sushigen_admin.db');
    
    _adminDatabase = await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreateAdmin,
    );
    
    return _adminDatabase!;
  }

  // Banco do usuário (separado por username)
  Future<Database> getUserDatabase(String username) async {
    if (_databases.containsKey(username)) {
      return _databases[username]!;
    }
    
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocumentsDir.path, 'sushigen_$username.db');
    
    final db = await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreateUser,
      onUpgrade: _onUpgradeUser,
    );
    
    _databases[username] = db;
    _currentUsername = username;
    
    return db;
  }

  Future<void> _onCreateAdmin(Database db, int version) async {
    // Apenas tabelas administrativas
    await db.execute('''CREATE TABLE customers (...)''');
    await db.execute('''CREATE TABLE sold_licenses (...)''');
    await db.execute('''CREATE TABLE payments (...)''');
  }

  Future<void> _onCreateUser(Database db, int version) async {
    // Tabelas operacionais do restaurante
    await db.execute('''CREATE TABLE products (...)''');
    await db.execute('''CREATE TABLE sales (...)''');
    await db.execute('''CREATE TABLE sale_items (...)''');
    await db.execute('''CREATE TABLE cash_flow (...)''');
    await db.execute('''CREATE TABLE stock (...)''');
    
    // NÃO cria tabelas de users, licenses, customers (são do admin)
  }
}
```

#### 2. Modificar AuthRepository

```dart
class AuthRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<User?> authenticate({
    required String username,
    required String password,
    required String licenseKey,
  }) async {
    // 1. Validar credenciais no banco ADMIN
    final adminDb = await _db.getAdminDatabase();
    
    final userResult = await adminDb.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    
    if (userResult.isEmpty) throw Exception('Usuário não encontrado');
    
    final user = User.fromMap(userResult.first);
    final passwordHash = _hashPassword(password);
    
    if (user.passwordHash != passwordHash) {
      throw Exception('Senha incorreta');
    }
    
    // 2. Validar licença no banco ADMIN
    final licenseResult = await adminDb.query(
      'licenses',
      where: 'username = ? AND license_key = ? AND status = ?',
      whereArgs: [username, licenseKey, 'active'],
    );
    
    if (licenseResult.isEmpty) throw Exception('Licença inválida');
    
    final license = License.fromMap(licenseResult.first);
    
    if (license.isExpired) {
      await adminDb.update(
        'licenses',
        {'status': 'expired'},
        where: 'id = ?',
        whereArgs: [license.id],
      );
      throw Exception('Licença expirada');
    }
    
    // 3. INICIALIZAR banco do usuário
    await _db.getUserDatabase(username);
    
    return user;
  }
}
```

#### 3. Modificar Providers

```dart
// Todos os providers devem usar o banco do usuário logado
class ProductsRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<List<Product>> getAllProducts() async {
    final username = _db._currentUsername;
    if (username == null) throw Exception('Usuário não logado');
    
    final db = await _db.getUserDatabase(username);
    final result = await db.query('products');
    return result.map((e) => Product.fromMap(e)).toList();
  }
}
```

---

## ✅ Solução 2: Campo `owner_id` (Alternativa)

### Conceito
Um único banco, mas cada registro tem o dono:

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  owner_username TEXT NOT NULL,  ← NOVO CAMPO
  name TEXT NOT NULL,
  price REAL NOT NULL,
  ...
);

CREATE INDEX idx_products_owner ON products(owner_username);
```

### Vantagens
✅ Backup simplificado (1 arquivo)  
✅ Queries mais complexas possíveis  

### Desvantagens
❌ Risco de vazamento de dados (bug de filtro)  
❌ Performance pior (banco gigante)  
❌ Todas as queries precisam filtrar por owner  
❌ Mais complexo de manter  

---

## 🎯 Recomendação Final

**Use a Solução 1: Banco Separado por Username**

### Motivos:
1. **Segurança**: Isolamento físico de dados
2. **Simplicidade**: Não precisa modificar 20+ queries
3. **Performance**: Bancos menores = mais rápido
4. **Backup**: Fácil fazer backup individual
5. **LGPD**: Cliente pode deletar todos seus dados facilmente

### Estrutura Final:

```
Aplicação SushiGen
│
├── Banco Admin (sushigen_admin.db)
│   ├── customers (clientes)
│   ├── sold_licenses (licenças vendidas)
│   └── payments (pagamentos)
│
└── Bancos de Usuários
    ├── sushigen_restaurante_a.db
    │   ├── products (produtos do restaurante A)
    │   ├── sales (vendas do restaurante A)
    │   └── cash_flow (fluxo de caixa do restaurante A)
    │
    ├── sushigen_sushi_bar.db
    │   ├── products (produtos do sushi bar)
    │   ├── sales (vendas do sushi bar)
    │   └── cash_flow (fluxo de caixa do sushi bar)
    │
    └── sushigen_delivery_sushi.db
        ├── products (produtos do delivery)
        ├── sales (vendas do delivery)
        └── cash_flow (fluxo de caixa do delivery)
```

---

## 📝 Checklist de Implementação

- [ ] Separar DatabaseHelper em 2 métodos (admin + user)
- [ ] Modificar AuthRepository para inicializar banco do usuário
- [ ] Modificar todos os Repositories para usar getUserDatabase()
- [ ] Remover tabelas administrativas do onCreate de usuário
- [ ] Testar login com 2 usuários diferentes
- [ ] Verificar isolamento de dados
- [ ] Atualizar documentação

---

## 🧪 Como Testar

```bash
# 1. Criar 2 licenças diferentes
Admin → Gerar licença para "restaurante_a"
Admin → Gerar licença para "sushi_bar"

# 2. Login como restaurante_a
Username: restaurante_a
Senha: 1234
Chave: [chave gerada]

# 3. Cadastrar produtos no restaurante A
Produto: Sushi Salmão - R$ 15,00

# 4. Logout e login como sushi_bar
Username: sushi_bar
Senha: 5678
Chave: [chave gerada]

# 5. Verificar que produtos do restaurante A NÃO aparecem
✅ Lista vazia (correto!)

# 6. Cadastrar produtos no sushi bar
Produto: Temaki Atum - R$ 20,00

# 7. Voltar para restaurante_a
✅ Deve ver apenas "Sushi Salmão"
✅ NÃO deve ver "Temaki Atum"
```

---

## 🔧 Impacto da Mudança

### Arquivos a Modificar:
1. `lib/core/database/database_helper.dart` (separar admin/user)
2. `lib/features/auth/data/repositories/auth_repository.dart` (inicializar banco user)
3. `lib/features/products/data/repositories/products_repository.dart` (usar getUserDatabase)
4. `lib/features/sales/data/repositories/sales_repository.dart` (usar getUserDatabase)
5. `lib/features/cashflow/data/repositories/cashflow_repository.dart` (usar getUserDatabase)
6. `lib/features/reports/data/repositories/reports_repository.dart` (usar getUserDatabase)

### Tempo Estimado:
- **Implementação**: 2-3 horas
- **Testes**: 1 hora
- **Total**: 3-4 horas

---

**Status**: 📋 Documentado - Pronto para implementar
