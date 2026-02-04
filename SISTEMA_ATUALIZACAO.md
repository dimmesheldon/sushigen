# 🔄 Sistema de Atualização Automática - SushiGen

**Problema**: Como atualizar o app nos clientes sem perder dados?  
**Solução**: Sistema de atualização automática com migrações de banco de dados

---

## 🎯 COMO FUNCIONA

### 1. **Versionamento Semântico**
```
v1.0.0 → Versão inicial
v1.1.0 → Nova funcionalidade (compatível)
v1.1.1 → Correção de bug (compatível)
v2.0.0 → Mudança grande (pode ter breaking changes)
```

### 2. **Sistema de Atualização**
```
Cliente inicia app
  ↓
Verifica versão atual (salva no banco)
  ↓
Consulta servidor: "Tem versão nova?"
  ↓
Se SIM: Baixa e instala (background)
  ↓
Aplica migrações no banco (se necessário)
  ↓
Reinicia app com nova versão
  ↓
✅ Dados preservados!
```

---

## 🗄️ PRESERVAÇÃO DE DADOS

### **Importante**: Os dados do cliente **NUNCA são apagados**!

### Onde ficam os dados:
```
macOS:
~/Library/Application Support/com.sushigen.app/
├── sushigen_admin.db          ← Dados administrativos
├── sushigen_usuario1.db       ← Banco do usuário 1
├── sushigen_usuario2.db       ← Banco do usuário 2
└── sushigen_usuario3.db       ← Banco do usuário 3

Windows:
C:\Users\Usuario\AppData\Roaming\com.sushigen.app\
├── sushigen_admin.db
├── sushigen_usuario1.db
└── ...
```

### **O app só acessa os bancos, NÃO apaga!**

Quando você instala uma nova versão:
- ✅ Binário do app é substituído (código novo)
- ✅ Bancos de dados permanecem intactos
- ✅ Migrações aplicam mudanças no schema (se necessário)

---

## 🔧 IMPLEMENTAÇÃO

### **Opção 1: Update Checker (Simples - RECOMENDADO)**

#### Como funciona:
1. Você lança nova versão no GitHub Releases
2. App verifica se tem versão nova ao iniciar
3. Mostra popup: "Nova versão disponível! Baixar?"
4. Cliente clica → Download automático → Instala
5. App reinicia com nova versão

#### Vantagens:
- ✅ Simples de implementar
- ✅ Cliente controla quando atualizar
- ✅ Funciona offline (só não atualiza)
- ✅ Não precisa de servidor backend

#### Código (já vou criar):
```dart
// Verifica versão ao iniciar
Future<void> checkForUpdates() async {
  final response = await http.get(
    'https://api.github.com/repos/dimmesheldon/sushigen/releases/latest'
  );
  
  final latestVersion = response['tag_name']; // Ex: "v1.2.0"
  final currentVersion = "v1.0.0"; // Versão atual do app
  
  if (latestVersion != currentVersion) {
    showUpdateDialog(); // "Nova versão disponível!"
  }
}
```

---

### **Opção 2: Auto-Update (Avançado)**

#### Como funciona:
1. App baixa atualização em background
2. Instala automaticamente
3. Reinicia app

#### Vantagens:
- ✅ Totalmente automático
- ✅ Cliente sempre na última versão

#### Desvantagens:
- ❌ Mais complexo
- ❌ Precisa de permissões especiais
- ❌ Pode assustar cliente (atualização sem aviso)

---

## 🗃️ MIGRAÇÕES DE BANCO DE DADOS

### **Problema**: E se a nova versão precisar de colunas novas?

### **Solução**: Sistema de Migrações

#### Exemplo:
```dart
// Versão 1.0.0: Schema inicial
CREATE TABLE products (
  id INTEGER PRIMARY KEY,
  name TEXT,
  price REAL
);

// Versão 1.1.0: Adicionar campo "description"
// MIGRAÇÃO:
ALTER TABLE products ADD COLUMN description TEXT;

// Versão 1.2.0: Adicionar tabela "categories"
// MIGRAÇÃO:
CREATE TABLE categories (
  id INTEGER PRIMARY KEY,
  name TEXT
);
```

#### Como implementar:
```dart
class DatabaseHelper {
  static const int DATABASE_VERSION = 3; // Aumenta a cada mudança
  
  Future<Database> _initDatabase() async {
    return await openDatabase(
      'sushigen.db',
      version: DATABASE_VERSION,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // ← AQUI!
    );
  }
  
  // Executado quando instala versão nova
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Se cliente tinha v1, aplicar migrações até v3
    if (oldVersion < 2) {
      // Migração v1 → v2
      await db.execute('ALTER TABLE products ADD COLUMN description TEXT');
    }
    
    if (oldVersion < 3) {
      // Migração v2 → v3
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY,
          name TEXT
        )
      ''');
    }
    
    // Sempre preserva dados existentes!
  }
}
```

---

## 📦 DISTRIBUIÇÃO DE ATUALIZAÇÕES

### **Opção A: GitHub Releases (GRATUITO - RECOMENDADO)**

#### Como funciona:
1. Você compila nova versão:
```bash
flutter build macos --release
flutter build windows --release
```

2. Cria release no GitHub:
```bash
gh release create v1.1.0 \
  --title "SushiGen v1.1.0 - Melhorias no Relatório" \
  --notes "- Novo relatório de vendas\n- Correção de bugs" \
  build/macos/Build/Products/Release/sushigen.app.zip \
  build/windows/runner/Release/sushigen.exe
```

3. App do cliente verifica:
```dart
// URL: https://api.github.com/repos/dimmesheldon/sushigen/releases/latest
// Retorna: { "tag_name": "v1.1.0", "assets": [...] }
```

4. Cliente baixa e instala automaticamente

#### Vantagens:
- ✅ 100% gratuito
- ✅ Ilimitado
- ✅ CDN rápido do GitHub
- ✅ API pronta

---

### **Opção B: Firebase Storage (GRATUITO até 10GB)**

#### Como funciona:
1. Upload da nova versão:
```bash
gsutil cp sushigen.dmg gs://sushigen.appspot.com/releases/v1.1.0/
```

2. App verifica Firestore:
```dart
final latestVersion = await FirebaseFirestore.instance
  .collection('releases')
  .doc('latest')
  .get();
```

3. Baixa e instala

#### Vantagens:
- ✅ Controle total
- ✅ Analytics integrado
- ✅ 10GB grátis/mês

#### Desvantagens:
- ❌ Mais complexo
- ❌ Limite de 10GB

---

### **Opção C: Servidor Próprio**

Só se você tiver servidor web próprio. **Não recomendado** para começar.

---

## 🔐 SEGURANÇA

### **Importante**: Como garantir que a atualização é legítima?

### 1. **Assinatura Digital**
```bash
# macOS (Certificado Apple Developer)
codesign --sign "Developer ID Application: Seu Nome" sushigen.app

# Windows (Certificado Code Signing)
signtool sign /f certificado.pfx /p senha sushigen.exe
```

### 2. **Checksum (SHA256)**
```bash
# Gerar hash
shasum -a 256 sushigen.dmg > checksum.txt

# App verifica antes de instalar
if (downloadedHash != expectedHash) {
  throw "Arquivo corrompido!";
}
```

---

## 🎯 IMPLEMENTAÇÃO RECOMENDADA

### **Para SushiGen, recomendo:**

1. **GitHub Releases** (distribuição)
2. **Update Checker** (verificação manual)
3. **Migrações de Banco** (schema changes)

### **Por quê?**
- ✅ 100% gratuito
- ✅ Simples de implementar
- ✅ Confiável (infraestrutura do GitHub)
- ✅ Cliente controla quando atualizar
- ✅ Dados sempre preservados

---

## 📝 CHECKLIST DE ATUALIZAÇÃO

Quando lançar nova versão, você vai:

### 1. **Desenvolvimento**
```bash
# Fazer mudanças no código
git add .
git commit -m "feat: nova funcionalidade"
git push origin develop
```

### 2. **Testar**
```bash
# Testar no seu Mac
flutter run -d macos

# Verificar banco de dados (não apaga dados?)
# Testar migrações (se tiver)
```

### 3. **Merge para Main**
```bash
git checkout main
git merge develop
```

### 4. **Atualizar Versão**
```yaml
# pubspec.yaml
version: 1.1.0+2  # ← Aumentar
```

### 5. **Build de Produção**
```bash
# macOS
flutter build macos --release

# Windows (se tiver)
flutter build windows --release
```

### 6. **Criar Release no GitHub**
```bash
# Zipar (macOS)
cd build/macos/Build/Products/Release
zip -r sushigen-v1.1.0-macos.zip sushigen.app

# Upload
gh release create v1.1.0 \
  --title "SushiGen v1.1.0" \
  --notes "- Nova funcionalidade X\n- Correção bug Y" \
  sushigen-v1.1.0-macos.zip
```

### 7. **Clientes Atualizam**
```
Cliente abre app
  ↓
App verifica GitHub: "Tem v1.1.0 nova!"
  ↓
Mostra popup: "Atualizar para v1.1.0?"
  ↓
Cliente clica "Sim"
  ↓
Download automático (background)
  ↓
Instala
  ↓
Reinicia app
  ↓
✅ Atualizado! (dados preservados)
```

---

## 🛡️ BACKUP AUTOMÁTICO

### **Extra**: Criar backup antes de atualizar

```dart
Future<void> updateApp() async {
  // 1. Backup do banco
  await backupDatabase();
  
  // 2. Baixar nova versão
  await downloadUpdate();
  
  // 3. Aplicar migrações
  await applyMigrations();
  
  // 4. Se der erro, restaurar backup
  try {
    await installUpdate();
  } catch (e) {
    await restoreBackup();
    throw "Atualização falhou. Dados restaurados.";
  }
}
```

---

## 📊 EXEMPLO REAL

### **Cenário**: Cliente está na v1.0.0, você lança v1.1.0

1. **Cliente abre app (v1.0.0)**
2. **App verifica**: "Última versão é v1.1.0"
3. **Mostra popup**: 
```
🎉 Nova versão disponível!

Versão 1.1.0 - Melhorias no Relatório

- Novo gráfico de vendas por período
- Correção no cálculo de estoque
- Melhor performance

[Atualizar Agora]  [Depois]
```
4. **Cliente clica "Atualizar Agora"**
5. **Download em background**: 
```
Baixando atualização... 45%
```
6. **Instala automaticamente**
7. **App reinicia**
8. **Tela inicial**: "✅ Atualizado para v1.1.0"
9. **Cliente loga normalmente**
10. **Todos os dados estão lá!** (produtos, vendas, usuários)

---

## 🔍 VERSIONAMENTO DO BANCO

### **Como saber qual versão do banco o cliente tem?**

```dart
// Salvar versão no banco
class DatabaseHelper {
  Future<void> _onCreate(Database db, int version) async {
    // Schema inicial...
    
    // Salvar versão
    await db.execute('''
      CREATE TABLE app_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    
    await db.insert('app_metadata', {
      'key': 'database_version',
      'value': version.toString(),
    });
  }
  
  // Verificar versão
  Future<int> getDatabaseVersion() async {
    final db = await database;
    final result = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: ['database_version'],
    );
    return int.parse(result.first['value']);
  }
}
```

---

## 🎯 RESUMO EXECUTIVO

### **Como funciona na prática:**

1. **Você faz melhorias**: Adiciona nova funcionalidade
2. **Compila nova versão**: `flutter build macos --release`
3. **Lança no GitHub**: `gh release create v1.1.0`
4. **Cliente abre app**: Vê notificação de atualização
5. **Cliente atualiza**: Clica um botão
6. **App baixa e instala**: Automático
7. **Dados preservados**: Tudo continua funcionando
8. **Cliente feliz**: Nova funcionalidade + dados intactos

### **O que o cliente vê:**
```
[Notificação]
🎉 Nova versão 1.1.0 disponível!
[Atualizar Agora]

↓ (clica)

[Progresso]
Baixando... 100%
Instalando...

↓ (2-3 segundos)

[Tela de Login]
✅ Atualizado para v1.1.0
Bem-vindo de volta!
```

### **O que acontece por trás:**
1. ✅ Download da nova versão
2. ✅ Backup do banco (segurança)
3. ✅ Aplicação de migrações (se tiver)
4. ✅ Substituição do executável
5. ✅ Reinício do app
6. ✅ Verificação de integridade
7. ✅ Todos os dados preservados

---

## 🚀 PRÓXIMOS PASSOS

Quer que eu implemente o sistema de atualização automática agora?

**Vou criar:**
1. ✅ UpdateService (verifica GitHub Releases)
2. ✅ UpdateDialog (UI para atualização)
3. ✅ MigrationManager (migrações de banco)
4. ✅ BackupService (backup antes de atualizar)
5. ✅ Documentação completa

**Tempo estimado**: 30 minutos

**Quer que eu faça agora?** 🚀

---

**Resumo**: **SEUS CLIENTES NUNCA PERDERÃO DADOS!** Os bancos ficam em pasta separada e são preservados nas atualizações. Apenas o código do app é substituído. 🎉
