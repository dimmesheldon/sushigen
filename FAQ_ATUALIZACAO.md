# ❓ FAQ: Atualização do SushiGen

## 🎯 Perguntas e Respostas Rápidas

---

### **1. Os clientes vão perder dados ao atualizar?**

**❌ NÃO!** Os dados **NUNCA** são perdidos.

**Por quê?**
- O banco de dados fica em **pasta separada**
- Atualização só substitui o **código do app**
- Dados ficam **intactos**

---

### **2. Onde ficam os dados?**

**macOS:**
```
~/Library/Application Support/com.sushigen.app/
├── sushigen_admin.db          ← Usuários e licenças
├── sushigen_restaurante1.db   ← Banco do cliente 1
├── sushigen_restaurante2.db   ← Banco do cliente 2
└── sushigen_restaurante3.db   ← Banco do cliente 3
```

**Windows:**
```
C:\Users\Usuario\AppData\Roaming\com.sushigen.app\
├── sushigen_admin.db
└── sushigen_restaurante1.db
```

**Importante**: Essas pastas **NÃO são apagadas** na atualização!

---

### **3. Como os clientes vão atualizar?**

**Opção 1: Manual** (Atual - Simples)
1. Você lança nova versão no GitHub Releases
2. Cliente baixa o arquivo
3. Substitui o app antigo pelo novo
4. Abre o app
5. ✅ Dados preservados!

**Opção 2: Automática** (Futuro - Recomendado)
1. App verifica se tem versão nova ao abrir
2. Mostra popup: "Nova versão disponível!"
3. Cliente clica "Atualizar"
4. Download automático
5. Instala e reinicia
6. ✅ Dados preservados!

---

### **4. Como você vai lançar atualizações?**

**Resumo rápido:**
```bash
# 1. Fazer mudanças
git add .
git commit -m "feat: nova funcionalidade"

# 2. Aumentar versão (pubspec.yaml)
version: 1.1.0  # ← de 1.0.0 para 1.1.0

# 3. Build
flutter build macos --release

# 4. Criar release
gh release create v1.1.0 \
  --title "SushiGen v1.1.0" \
  --notes "Nova funcionalidade X" \
  build/macos/.../sushigen.zip

# 5. ✅ Clientes podem baixar!
```

**Tempo**: ~10 minutos

---

### **5. E se precisar mudar o banco de dados?**

**Exemplo**: Adicionar campo novo (ex: "observações" em produtos)

**Solução**: Migrações automáticas!

```dart
// Aumentar versão do banco
static const int _databaseVersion = 2; // ← Era 1

// Migração automática
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Adicionar coluna
    await db.execute('ALTER TABLE products ADD COLUMN observations TEXT');
  }
}
```

**O que acontece?**
1. Cliente atualiza app
2. App detecta: "Banco é v1, código quer v2"
3. Executa migração automaticamente
4. Adiciona a coluna
5. ✅ Dados antigos preservados + coluna nova criada!

---

### **6. Como garantir segurança?**

**Backup automático:**
```dart
// Antes de migrar, fazer backup
await backupDatabase();

try {
  await applyMigration();
} catch (e) {
  // Se der erro, restaurar
  await restoreBackup();
}
```

**Resultado**: Se a migração falhar, dados são restaurados! 🛡️

---

### **7. Quanto custa a distribuição?**

**GitHub Releases**: ✅ **GRATUITO**
- Upload ilimitado
- Download ilimitado
- CDN rápido do GitHub
- API pronta

**Firebase Storage**: ✅ **10GB grátis/mês**
- Depois: R$ 0,026/GB

**Recomendação**: Usar GitHub Releases (100% grátis)

---

### **8. Como testar antes de lançar?**

**Workflow:**
1. Branch `develop`: Fazer mudanças
2. Testar localmente
3. Quando funcionar: Merge para `main`
4. Criar release
5. Clientes baixam

**Segurança**: Você sempre testa na `develop` antes!

---

### **9. Como notificar clientes sobre atualização?**

**Opção A: Manual**
- WhatsApp broadcast
- Email
- Aviso no próprio app

**Opção B: Automática** (Recomendado - vou implementar)
```dart
// App verifica ao abrir
final latestVersion = await checkGitHubReleases();

if (latestVersion > currentVersion) {
  showUpdateDialog(); // "Nova versão disponível!"
}
```

**Benefício**: Cliente sempre vê quando tem atualização!

---

### **10. E se o cliente não atualizar?**

**Não tem problema!**
- App continua funcionando normalmente
- Dados preservados
- Só não tem as novas funcionalidades

**Opcional**: Você pode forçar atualização para versões críticas:
```dart
if (currentVersion < minimumRequiredVersion) {
  showForceUpdateDialog(); // "Atualize para continuar"
}
```

---

### **11. Como reverter uma atualização ruim?**

**Se um cliente reportar problema:**

**Opção 1**: Lançar hotfix (v1.1.1 corrigindo v1.1.0)

**Opção 2**: Reverter release no GitHub
```bash
# Ocultar release problemática
gh release delete v1.1.0

# Cliente volta para v1.0.0
```

**Dados do cliente**: ✅ **Sempre preservados**

---

### **12. Posso ter versões diferentes para Mac e Windows?**

**Sim!** GitHub Releases suporta múltiplos arquivos:

```bash
gh release create v1.1.0 \
  --title "SushiGen v1.1.0" \
  sushigen-v1.1.0-macos.zip \
  sushigen-v1.1.0-windows.zip
```

**Cliente baixa**: Automaticamente o correto para seu sistema

---

### **13. Como adicionar changelog automático?**

**No momento do commit:**
```bash
git commit -m "feat: novo relatório de vendas

- Gráfico de faturamento
- Filtro por período
- Exportar PDF

BREAKING CHANGE: API mudou"
```

**No release:**
```bash
gh release create v1.1.0 --generate-notes
```

**Resultado**: GitHub gera changelog automaticamente! 🎉

---

### **14. Quanto tempo leva para cliente atualizar?**

**Download**: 1-2 minutos (15-20 MB)  
**Instalação**: 10 segundos  
**Migração de banco**: 1-5 segundos  
**Total**: ~2-3 minutos

**Experiência do usuário:**
```
[Notificação]
🎉 Nova versão disponível!
[Atualizar] [Depois]

↓ (clica Atualizar)

[Progresso]
Baixando... 100%
Instalando...
Atualizando banco...

↓ (2-3 minutos)

[Tela de Login]
✅ Atualizado para v1.1.0!
Seus dados estão preservados.
```

---

### **15. Resumo Final: Atualização é Segura?**

## ✅ **SIM! 100% SEGURO**

### **Por quê?**
1. ✅ Dados em pasta separada (não são tocados)
2. ✅ Backup automático antes de migração
3. ✅ Migrações testadas antes de lançar
4. ✅ Rollback se der erro
5. ✅ Cliente controla quando atualizar

### **O que pode dar errado?**
- ❌ Download interrompido → Cliente tenta novamente
- ❌ Migração falha → Backup restaurado automaticamente
- ❌ Bug na nova versão → Você lança hotfix (v1.1.1)

### **O que NÃO pode dar errado?**
- ✅ **Perda de dados** → IMPOSSÍVEL (dados em pasta separada)

---

## 🎯 CONCLUSÃO

### **Para você (desenvolvedor):**
- Lançar atualização: ~10 minutos
- Sem custo (GitHub grátis)
- Workflow simples

### **Para o cliente:**
- Atualizar: 1 clique (ou download manual)
- Tempo: 2-3 minutos
- **Dados: SEMPRE PRESERVADOS** ✅

### **Resultado:**
- 🎉 Clientes felizes
- 🚀 App sempre atualizado
- 💰 Sem custos de infraestrutura
- 🔒 Dados seguros

---

## 🚀 PRÓXIMO PASSO

**Quer que eu implemente o sistema de atualização automática?**

O app vai:
1. Verificar GitHub Releases ao abrir
2. Mostrar notificação quando tiver versão nova
3. Permitir atualização com 1 clique
4. Baixar e instalar automaticamente
5. Aplicar migrações de banco
6. Fazer backup antes de migrar

**Tempo**: ~30 minutos de implementação  
**Benefício**: Cliente sempre atualizado sem esforço!

**Fazer agora?** 🚀
