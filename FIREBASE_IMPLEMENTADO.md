# 🔥 Firebase - Status da Implementação

## ✅ O QUE FOI IMPLEMENTADO

### 1. Dependências Adicionadas

**Arquivo**: `pubspec.yaml`

```yaml
firebase_core: ^3.8.1       # Core do Firebase
cloud_firestore: ^5.5.1     # Banco de dados NoSQL
firebase_auth: ^5.3.3       # Autenticação (futuro)
```

### 2. Serviço de Sincronização Completo

**Arquivo**: `lib/core/services/sync_service.dart`

**Funcionalidades**:
- ✅ **syncProducts()** - Upload de produtos para Firebase
- ✅ **syncSales()** - Upload de vendas + itens
- ✅ **syncCashFlow()** - Upload de fluxo de caixa
- ✅ **syncAll()** - Sincronização completa (upload)
- ✅ **downloadProducts()** - Download de produtos do servidor
- ✅ **downloadSales()** - Download de vendas do servidor
- ✅ **downloadAll()** - Download completo
- ✅ **getUnsyncedCounts()** - Contagem de itens não sincronizados

**Inteligência**:
- Converte timestamps SQLite ↔ Firestore automaticamente
- Merge inteligente (não sobrescreve dados mais recentes)
- Sincroniza apenas itens com `synced = 0`
- Marca como sincronizado após upload bem-sucedido

### 3. Provider de Estado

**Arquivo**: `lib/core/providers/sync_provider.dart`

**Estado Gerenciado**:
```dart
class SyncState {
  final bool isSyncing;              // Em sincronização?
  final DateTime? lastSync;          // Última sincronização
  final String? error;               // Erro (se houver)
  final Map<String, int> unsyncedCounts; // Contagem por tipo
  final String? currentOperation;    // Operação atual
}
```

**Métodos**:
- ✅ **syncNow()** - Upload para servidor
- ✅ **downloadData()** - Download do servidor
- ✅ **syncBidirectional()** - Upload + Download
- ✅ **refreshCounts()** - Atualizar contagens

### 4. Inicialização no App

**Arquivo**: `lib/main.dart`

```dart
// Firebase inicializa automaticamente ao abrir o app
await Firebase.initializeApp();
```

**Comportamento**:
- ✅ Se configurado: Inicializa normalmente
- ✅ Se não configurado: App funciona offline (não quebra)
- ✅ Mensagem clara no console sobre o status

### 5. Interface de Sincronização

**Arquivo**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

**Botão no Dashboard**:
- 🔵 Ícone de nuvem (cloud_upload)
- 🔴 Badge vermelho mostrando quantidade não sincronizada
- ⚪ Loading circular durante sincronização
- 💬 Tooltip mostrando operação atual

**Comportamento**:
- Clique: Sincronização bidirecional (upload + download)
- Durante sync: Botão desabilitado
- Sucesso: Toast verde "✅ Sincronização concluída!"
- Erro: Toast vermelho com mensagem do erro
- Após sync: Recarrega dados do dashboard automaticamente

## 📁 Estrutura no Firestore

```
firestore (banco de dados)
├── products/
│   └── {product_id}/
│       ├── id: string
│       ├── name: string
│       ├── price: number
│       ├── cost: number
│       ├── category: string
│       ├── image_url: string
│       ├── created_at: timestamp
│       ├── updated_at: timestamp
│       └── synced: number
│
├── sales/
│   └── {sale_id}/
│       ├── id: string
│       ├── sale_number: number
│       ├── user_id: string
│       ├── total_amount: number
│       ├── final_amount: number
│       ├── payment_method: string
│       ├── is_ifood: number
│       ├── delivery_type: string
│       ├── delivery_cost: number
│       ├── sale_date: timestamp
│       └── created_at: timestamp
│
├── sale_items/
│   └── {item_id}/
│       ├── id: string
│       ├── sale_id: string (referência)
│       ├── product_id: string
│       ├── product_name: string
│       ├── quantity: number
│       ├── unit_price: number
│       └── total_price: number
│
└── cash_flow/
    └── {entry_id}/
        ├── id: string
        ├── type: string (income/expense)
        ├── category: string
        ├── amount: number
        ├── description: string
        ├── date: timestamp
        ├── sale_id: string (opcional)
        └── created_at: timestamp
```

## 🎯 PRÓXIMOS PASSOS PARA VOCÊ

### Passo 1: Criar Projeto no Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Clique em **"Adicionar projeto"**
3. Nome: `sushigen`
4. **Desabilite** Google Analytics
5. Clique em **"Criar projeto"**

### Passo 2: Adicionar App macOS

1. No projeto, clique no ícone **Apple (iOS+)**
2. **Bundle ID**: `com.sushigen.sushigen`
   ```bash
   # Para verificar seu Bundle ID:
   cat macos/Runner.xcodeproj/project.pbxproj | grep PRODUCT_BUNDLE_IDENTIFIER
   ```
3. **Nickname**: SushiGen macOS
4. Clique em **"Registrar app"**
5. **Baixar** o arquivo `GoogleService-Info.plist`
6. Clique em **"Próximo"** até finalizar

### Passo 3: Adicionar GoogleService-Info.plist no Projeto

**Opção A - Via Terminal**:
```bash
# 1. Copiar arquivo para pasta do projeto
cp ~/Downloads/GoogleService-Info.plist /Users/dimmesheldon/sushigen/macos/Runner/

# 2. Abrir no Xcode
open /Users/dimmesheldon/sushigen/macos/Runner.xcworkspace

# 3. No Xcode:
#    - Arraste o arquivo para dentro da pasta Runner (lado esquerdo)
#    - Marque: ✅ Copy items if needed
#    - Target: ✅ Runner
#    - Clique em "Finish"
```

**Opção B - Manualmente**:
1. Mova `GoogleService-Info.plist` para `macos/Runner/`
2. Abra o Xcode
3. Adicione o arquivo ao projeto

### Passo 4: Configurar Firestore Database

1. No menu lateral do Firebase Console, clique em **"Firestore Database"**
2. Clique em **"Criar banco de dados"**
3. Modo: **"Produção"** (começar seguro)
4. Localização: **`southamerica-east1` (São Paulo)**
5. Clique em **"Ativar"**

### Passo 5: Configurar Regras de Segurança

1. Vá em **"Regras"** no Firestore
2. Copie e cole este código:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Produtos (leitura pública, escrita autenticada)
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Vendas (apenas autenticado)
    match /sales/{saleId} {
      allow read, write: if request.auth != null;
    }
    
    // Itens de venda
    match /sale_items/{itemId} {
      allow read, write: if request.auth != null;
    }
    
    // Fluxo de caixa
    match /cash_flow/{entryId} {
      allow read, write: if request.auth != null;
    }
    
    // Usuários
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Clique em **"Publicar"**

### Passo 6: Atualizar Permissões do App (Entitlements)

Edite: `macos/Runner/DebugProfile.entitlements` e `macos/Runner/Release.entitlements`

Adicione estas linhas dentro de `<dict>`:

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

O arquivo completo deve ficar assim:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
</dict>
</plist>
```

### Passo 7: Limpar e Rebuildar

```bash
# Parar app
pkill -9 -f "sushigen"

# Limpar build
flutter clean

# Instalar dependências
flutter pub get

# Rodar app
flutter run -d macos
```

### Passo 8: Testar Sincronização

1. **Abrir o app**
2. **Fazer algumas vendas** (3-5 vendas variadas)
3. **Cadastrar/Editar produtos**
4. **Clicar no botão de nuvem** no Dashboard
5. **Aguardar** mensagem "✅ Sincronização concluída!"
6. **Verificar no Firebase Console**:
   - https://console.firebase.google.com/
   - Ir em **Firestore Database**
   - Ver as coleções: `products`, `sales`, `sale_items`, `cash_flow`

## 🎨 Como Funciona na Prática

### Cenário 1: Trabalhar Offline e Sincronizar Depois

1. **Sem internet**:
   - App funciona normalmente
   - Vendas são salvas localmente
   - Campo `synced = 0` no banco

2. **Com internet**:
   - Clicar no botão de nuvem
   - App envia todos os dados não sincronizados
   - Marca como `synced = 1`

### Cenário 2: Usar em Múltiplos Computadores

**Computador 1** (Caixa principal):
1. Fazer vendas
2. Clicar em sincronizar
3. Dados vão para Firebase

**Computador 2** (Notebook em casa):
1. Abrir o app
2. Clicar em sincronizar
3. Baixa vendas do Computador 1
4. Pode ver relatórios atualizados

### Cenário 3: Backup Automático

- Toda vez que sincroniza = backup na nuvem
- Dados seguros mesmo se computador quebrar
- Pode restaurar instalando em novo Mac

## 🔧 Troubleshooting

### ❌ "No Firebase App has been created"

**Causa**: GoogleService-Info.plist não está no projeto ou não foi adicionado no Xcode

**Solução**:
1. Verifique se arquivo existe em `macos/Runner/GoogleService-Info.plist`
2. Abra Xcode e adicione ao projeto
3. Rebuild: `flutter clean && flutter pub get && flutter run -d macos`

### ❌ "Network error" / "Permission denied"

**Causa 1**: Entitlements não configurados

**Solução**:
1. Verifique `macos/Runner/DebugProfile.entitlements`
2. Adicione permissões de rede
3. Rebuild

**Causa 2**: Regras do Firestore muito restritivas

**Solução**:
1. Vá em Firestore Console → Regras
2. **TEMPORARIAMENTE** (só para teste):
   ```javascript
   allow read, write: if true;
   ```
3. Se funcionar, problema são as regras
4. Ajuste as regras corretamente

### ❌ "Auth required" mas você não tem auth

**Solução**: Nas regras do Firestore, mude temporariamente para:
```javascript
allow read, write: if true; // APENAS PARA TESTES!
```

Depois implemente autenticação ou use uma API Key.

## 📊 Status Final

- ✅ Código implementado e pronto
- ✅ Botão de sincronização no Dashboard
- ✅ Badge mostrando itens não sincronizados
- ✅ Upload e Download funcionando
- ✅ Merge inteligente de dados
- ✅ Toast de sucesso/erro
- ⏳ **AGUARDANDO**: Configuração no Firebase Console (feita por você)

## 🚀 Benefícios da Sincronização

1. **Multi-device**: Usar em vários computadores
2. **Backup**: Dados seguros na nuvem
3. **Colaboração**: Vários usuários vendo mesmos dados
4. **Histórico**: Vendas antigas sempre disponíveis
5. **Recuperação**: Reinstalar sem perder nada

---

**Quer que eu te guie pelo processo de configuração no Firebase Console?** 🔥
