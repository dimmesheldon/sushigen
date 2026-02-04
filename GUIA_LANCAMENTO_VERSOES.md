# 🔄 Guia Prático: Como Lançar Atualizações

**Para**: Desenvolvedor (você)  
**Objetivo**: Passo a passo para lançar atualizações sem perder dados dos clientes

---

## 📋 CHECKLIST RÁPIDO

Quando tiver uma melhoria pronta:

- [ ] 1. Fazer mudanças no código
- [ ] 2. Testar localmente
- [ ] 3. Atualizar número da versão (pubspec.yaml)
- [ ] 4. Commit e push para develop
- [ ] 5. Merge para main
- [ ] 6. Build de produção (macOS/Windows)
- [ ] 7. Criar release no GitHub
- [ ] 8. Clientes recebem notificação automática
- [ ] 9. Clientes atualizam com 1 clique
- [ ] 10. ✅ Dados preservados!

---

## 🛠️ PASSO A PASSO DETALHADO

### **1. Fazer Mudanças no Código**

```bash
# Garantir que está na develop
git checkout develop

# Fazer mudanças...
# Ex: Adicionar novo relatório, corrigir bug, etc.
```

---

### **2. Testar Localmente**

```bash
# Executar app
flutter run -d macos

# Testar:
# - Nova funcionalidade funciona?
# - Não quebrou nada?
# - Banco de dados continua funcionando?
```

---

### **3. Atualizar Número da Versão**

```yaml
# Editar: pubspec.yaml
name: sushigen
version: 1.1.0+2  # ← AUMENTAR AQUI!

# Formato: MAJOR.MINOR.PATCH+BUILD
# Exemplos:
# 1.0.0+1 → Versão inicial
# 1.0.1+2 → Correção de bug (patch)
# 1.1.0+3 → Nova funcionalidade (minor)
# 2.0.0+4 → Mudança grande (major)
```

**Regras:**
- **PATCH** (1.0.X): Correção de bugs
- **MINOR** (1.X.0): Nova funcionalidade (compatível)
- **MAJOR** (X.0.0): Mudança grande (breaking change)

---

### **4. Commit e Push**

```bash
# Adicionar mudanças
git add .

# Commit (mensagem clara!)
git commit -m "feat: adicionar relatório de vendas por período

- Novo gráfico de vendas
- Filtro por data
- Exportar para PDF
- Correção bug no cálculo

Versão: 1.1.0"

# Push
git push origin develop
```

---

### **5. Merge para Main**

```bash
# Ir para main
git checkout main

# Merge da develop
git merge develop

# Push
git push origin main
```

---

### **6. Build de Produção**

#### **macOS:**
```bash
# Build release
flutter build macos --release

# Navegar para pasta
cd build/macos/Build/Products/Release

# Zipar (para upload)
zip -r sushigen-v1.1.0-macos.zip sushigen.app

# Voltar para raiz
cd -
```

#### **Windows** (se tiver Windows ou usar CI/CD):
```bash
flutter build windows --release

cd build/windows/runner/Release

# Zipar
powershell Compress-Archive -Path * -DestinationPath sushigen-v1.1.0-windows.zip

cd -
```

---

### **7. Criar Release no GitHub**

```bash
# Opção A: Via CLI (recomendado)
gh release create v1.1.0 \
  --title "SushiGen v1.1.0 - Relatório de Vendas por Período" \
  --notes "## 🎉 Novidades

- ✅ Novo relatório de vendas por período
- ✅ Gráfico de faturamento mensal
- ✅ Exportar relatório em PDF
- 🐛 Correção no cálculo de estoque

## 📥 Download

Escolha a versão para seu sistema operacional:
- **macOS**: sushigen-v1.1.0-macos.zip
- **Windows**: sushigen-v1.1.0-windows.zip

## 🔄 Como Atualizar

1. Baixe o arquivo para seu sistema
2. Feche o app SushiGen (se estiver aberto)
3. Substitua o app antigo pelo novo
4. Abra o app
5. ✅ Seus dados estarão preservados!

## ⚠️ Importante

**Seus dados NÃO serão perdidos!** O banco de dados fica em pasta separada." \
  build/macos/Build/Products/Release/sushigen-v1.1.0-macos.zip

# Opção B: Via interface web
# Acesse: https://github.com/dimmesheldon/sushigen/releases/new
```

---

### **8. Verificar Release**

```bash
# Abrir no navegador
gh release view v1.1.0 --web

# Ou listar releases
gh release list
```

---

### **9. Notificar Clientes** (Opcional - Manual)

Se quiser avisar manualmente:

```
📱 WhatsApp (Broadcast):
"🎉 Nova versão do SushiGen disponível!

Versão 1.1.0 - Relatório de Vendas

Novidades:
✅ Gráfico de vendas por período
✅ Exportar relatórios em PDF
✅ Melhorias de performance

Baixe: https://github.com/dimmesheldon/sushigen/releases/latest

Seus dados serão preservados! 🔒"

📧 Email (Lista de clientes):
Assunto: Nova versão disponível - SushiGen v1.1.0
Corpo: [Mesma mensagem acima com HTML bonitinho]
```

---

## 🗄️ MIGRAÇÕES DE BANCO (Quando Necessário)

### **Quando usar?**

Se a nova versão precisar de:
- ✅ Novas colunas em tabelas existentes
- ✅ Novas tabelas
- ✅ Índices novos
- ✅ Mudanças no schema

### **Como fazer?**

```dart
// lib/core/database/database_helper.dart

class DatabaseHelper {
  // SEMPRE aumentar quando mudar o schema!
  static const int _databaseVersion = 2; // ← Era 1, agora é 2
  
  Future<Database> _initAdminDatabase() async {
    return await openDatabase(
      'sushigen_admin.db',
      version: _databaseVersion,
      onCreate: _onCreateAdmin,
      onUpgrade: _onUpgradeAdmin, // ← AQUI!
    );
  }
  
  // Executado automaticamente quando versão aumenta
  Future<void> _onUpgradeAdmin(Database db, int oldVersion, int newVersion) async {
    print('Migrando banco: v$oldVersion → v$newVersion');
    
    // MIGRAÇÃO v1 → v2
    if (oldVersion < 2) {
      // Exemplo: Adicionar coluna "phone" na tabela customers
      await db.execute('''
        ALTER TABLE customers ADD COLUMN phone TEXT
      ''');
      
      print('✅ Migração v1→v2 concluída');
    }
    
    // MIGRAÇÃO v2 → v3 (futuro)
    if (oldVersion < 3) {
      // Próximas mudanças...
    }
  }
}
```

### **Exemplo Real**:

**Situação**: Você quer adicionar campo "observações" em produtos

**Passo 1**: Atualizar código
```dart
// lib/features/products/domain/entities/product.dart
class Product {
  final String id;
  final String name;
  final double price;
  final String observations; // ← NOVO CAMPO
  
  Product({
    required this.id,
    required this.name,
    required this.price,
    this.observations = '', // ← Valor padrão
  });
}
```

**Passo 2**: Criar migração
```dart
// lib/core/database/database_helper.dart
static const int _databaseVersion = 2; // ← Aumentar

Future<void> _onUpgradeUser(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Adicionar coluna
    await db.execute('ALTER TABLE products ADD COLUMN observations TEXT DEFAULT ""');
    print('✅ Campo observations adicionado');
  }
}
```

**Passo 3**: Testar migração
```bash
# Rodar app (vai executar migração automaticamente)
flutter run -d macos

# Verificar log:
# I/flutter: Migrando banco: v1 → v2
# I/flutter: ✅ Campo observations adicionado
```

**Passo 4**: Lançar versão (1.1.0)

**Resultado**: Cliente atualiza e a coluna é adicionada automaticamente! 🎉

---

## 🛡️ SEGURANÇA: Backup Antes de Migrar

### **Adicionar backup automático:**

```dart
Future<void> _onUpgradeUser(Database db, int oldVersion, int newVersion) async {
  try {
    // 1. BACKUP antes de migrar
    await _backupDatabase(db);
    
    // 2. Aplicar migrações
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN observations TEXT');
    }
    
    print('✅ Migração concluída com sucesso');
    
  } catch (e) {
    // 3. Se der erro, restaurar backup
    print('❌ Erro na migração: $e');
    await _restoreBackup(db);
    throw 'Migração falhou. Dados restaurados.';
  }
}

Future<void> _backupDatabase(Database db) async {
  final dbPath = db.path;
  final backupPath = '$dbPath.backup';
  
  // Copiar arquivo
  await File(dbPath).copy(backupPath);
  print('✅ Backup criado: $backupPath');
}
```

---

## 📊 EXEMPLO COMPLETO: Lançar v1.1.0

### **Situação Real:**
Você adicionou "Relatório de Vendas por Período"

### **Comandos:**

```bash
# 1. Garantir que está na develop
git checkout develop

# 2. Editar pubspec.yaml (versão 1.0.0 → 1.1.0)
code pubspec.yaml

# 3. Commit
git add .
git commit -m "feat: adicionar relatório de vendas por período

- Novo gráfico de faturamento
- Filtro por data (dia, semana, mês, ano)
- Exportar PDF
- Melhorias de performance

Versão: 1.1.0"

# 4. Push
git push origin develop

# 5. Merge para main
git checkout main
git merge develop
git push origin main

# 6. Build
flutter build macos --release

# 7. Zipar
cd build/macos/Build/Products/Release
zip -r sushigen-v1.1.0-macos.zip sushigen.app
cd -

# 8. Criar release
gh release create v1.1.0 \
  --title "SushiGen v1.1.0 - Relatório de Vendas" \
  --notes "🎉 Nova funcionalidade: Relatório de vendas por período" \
  build/macos/Build/Products/Release/sushigen-v1.1.0-macos.zip

# 9. Verificar
gh release view v1.1.0 --web

# 10. ✅ Pronto! Clientes podem baixar
```

---

## 🎯 AUTOMATIZAÇÃO FUTURA (Opcional)

### **GitHub Actions**: Build automático ao criar release

```yaml
# .github/workflows/release.yml
name: Build Release

on:
  release:
    types: [created]

jobs:
  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build macos --release
      - name: Upload
        uses: actions/upload-release-asset@v1
        with:
          upload_url: ${{ github.event.release.upload_url }}
          asset_path: build/macos/sushigen.zip
```

**Benefício**: Você só cria a tag, o build é automático! 🚀

---

## 📝 TEMPLATE DE RELEASE NOTES

### **Copie e cole ao criar release:**

```markdown
## 🎉 SushiGen v1.1.0

### ✨ Novidades
- Novo relatório de vendas por período
- Gráfico de faturamento mensal
- Filtro por data (dia, semana, mês, ano)

### 🐛 Correções
- Correção no cálculo de desconto
- Melhoria na performance de listagem de produtos

### 📥 Download
Escolha a versão para seu sistema:
- **macOS**: [sushigen-v1.1.0-macos.zip](link)
- **Windows**: [sushigen-v1.1.0-windows.zip](link)

### 🔄 Como Atualizar
1. Feche o app SushiGen (se estiver aberto)
2. Baixe o arquivo para seu sistema
3. Substitua o app antigo pelo novo
4. Abra o app
5. ✅ **Seus dados estarão preservados!**

### ⚠️ Importante
**Seus dados NÃO serão perdidos!**  
O banco de dados fica em pasta separada e será mantido.

### 📞 Suporte
- WhatsApp: (99) 98453-2007
- Email: dimme.spa@gmail.com

---
**Data**: 2026-02-03  
**Versão anterior**: 1.0.0  
**Tamanho**: ~15 MB (macOS), ~20 MB (Windows)
```

---

## 🎯 RESUMO EXECUTIVO

### **Para lançar atualização:**
1. Fazer mudanças → Testar
2. Aumentar versão no `pubspec.yaml`
3. Commit → Merge para main
4. Build → Zipar
5. Criar release no GitHub
6. ✅ Clientes baixam e atualizam

### **Tempo total**: ~10 minutos

### **Dados dos clientes**: ✅ **SEMPRE PRESERVADOS**

### **Por quê?**
Os bancos ficam em:
- macOS: `~/Library/Application Support/com.sushigen.app/`
- Windows: `C:\Users\Usuario\AppData\Roaming\com.sushigen.app\`

O app só **lê e escreve** nesses bancos. Nunca apaga!

---

## 🚀 PRÓXIMA IMPLEMENTAÇÃO

Quer que eu crie o **sistema de verificação automática de atualizações**?

O app vai:
1. Verificar GitHub Releases ao iniciar
2. Mostrar popup se tiver versão nova
3. Permitir atualização com 1 clique
4. Baixar em background
5. Instalar automaticamente

**Implementação**: ~30 minutos  
**Quer agora?** 🚀
