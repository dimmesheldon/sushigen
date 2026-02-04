# 🔥 Guia Completo: Configuração Firebase para SushiGen

## 📋 Pré-requisitos

- ✅ Conta Google (gmail)
- ✅ Flutter instalado
- ✅ Node.js instalado (para Firebase CLI)

## Parte 1: Configuração no Firebase Console (Web)

### Passo 1: Criar Projeto Firebase

1. Acesse: https://console.firebase.google.com/
2. Clique em **"Adicionar projeto"** ou **"Create a project"**
3. Nome do projeto: **`sushigen`** (ou nome de sua preferência)
4. **Desabilite** o Google Analytics (não é necessário para este projeto)
5. Clique em **"Criar projeto"**
6. Aguarde a criação (1-2 minutos)

### Passo 2: Adicionar App macOS

1. No painel do projeto, clique no ícone **Apple** (iOS+)
2. **Bundle ID**: `com.sushigen.sushigen` (mesmo do Xcode)
   - Para verificar o Bundle ID:
     ```bash
     cat macos/Runner.xcodeproj/project.pbxproj | grep PRODUCT_BUNDLE_IDENTIFIER
     ```
3. **App nickname** (opcional): SushiGen macOS
4. Clique em **"Registrar app"**
5. **Baixar** o arquivo `GoogleService-Info.plist`
6. Clique em **"Próximo"** até finalizar

### Passo 3: Configurar Firestore Database

1. No menu lateral, clique em **"Firestore Database"**
2. Clique em **"Criar banco de dados"**
3. Modo: **"Produção"** (iniciar em modo seguro)
4. Localização: **`southamerica-east1` (São Paulo)** ou mais próximo
5. Clique em **"Ativar"**

### Passo 4: Configurar Regras de Segurança

1. Após criar o Firestore, vá em **"Regras"**
2. Substitua o conteúdo por:

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

### Passo 5: Configurar Authentication (Opcional)

1. No menu lateral, clique em **"Authentication"**
2. Clique em **"Começar"**
3. Habilite o método: **"E-mail/senha"**
4. Clique em **"Salvar"**

## Parte 2: Configuração no macOS App

### Passo 6: Adicionar GoogleService-Info.plist

1. Copie o arquivo `GoogleService-Info.plist` baixado para a pasta do projeto:
   ```bash
   cp ~/Downloads/GoogleService-Info.plist /Users/dimmesheldon/sushigen/macos/Runner/
   ```

2. Abra o Xcode:
   ```bash
   open macos/Runner.xcworkspace
   ```

3. No Xcode:
   - Arraste o arquivo `GoogleService-Info.plist` para dentro da pasta `Runner` (lado esquerdo)
   - **Marque**: ✅ Copy items if needed
   - **Target**: ✅ Runner
   - Clique em **"Finish"**

### Passo 7: Atualizar Entitlements (Permissões)

Edite o arquivo: `macos/Runner/DebugProfile.entitlements`

Adicione as permissões de rede:

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

Repita para: `macos/Runner/Release.entitlements`

## Parte 3: Código Flutter

### Passo 8: Inicializar Firebase no main.dart

O código já está preparado, mas vou adicionar a inicialização:

```dart
// Em lib/main.dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado com sucesso!');
  } catch (e) {
    print('❌ Erro ao inicializar Firebase: $e');
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Passo 9: Criar Serviço de Sincronização

Arquivo: `lib/core/services/sync_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Sincronizar produtos
  Future<void> syncProducts() async {
    try {
      final db = await _dbHelper.database;
      
      // 1. Buscar produtos locais não sincronizados
      final localProducts = await db.query(
        'products',
        where: 'synced = ?',
        whereArgs: [0],
      );
      
      // 2. Upload para Firestore
      for (var product in localProducts) {
        await _firestore
            .collection('products')
            .doc(product['id'] as String)
            .set(product);
        
        // 3. Marcar como sincronizado
        await db.update(
          'products',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [product['id']],
        );
      }
      
      print('✅ Produtos sincronizados: ${localProducts.length}');
    } catch (e) {
      print('❌ Erro ao sincronizar produtos: $e');
      rethrow;
    }
  }

  // Sincronizar vendas
  Future<void> syncSales() async {
    try {
      final db = await _dbHelper.database;
      
      // 1. Buscar vendas não sincronizadas
      final localSales = await db.query(
        'sales',
        where: 'synced = ?',
        whereArgs: [0],
      );
      
      // 2. Upload para Firestore
      for (var sale in localSales) {
        await _firestore
            .collection('sales')
            .doc(sale['id'] as String)
            .set(sale);
        
        // 3. Sincronizar itens da venda
        final saleItems = await db.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [sale['id']],
        );
        
        for (var item in saleItems) {
          await _firestore
              .collection('sale_items')
              .doc(item['id'] as String)
              .set(item);
        }
        
        // 4. Marcar como sincronizado
        await db.update(
          'sales',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [sale['id']],
        );
      }
      
      print('✅ Vendas sincronizadas: ${localSales.length}');
    } catch (e) {
      print('❌ Erro ao sincronizar vendas: $e');
      rethrow;
    }
  }

  // Sincronizar fluxo de caixa
  Future<void> syncCashFlow() async {
    try {
      final db = await _dbHelper.database;
      
      final localEntries = await db.query(
        'cash_flow',
        where: 'synced = ?',
        whereArgs: [0],
      );
      
      for (var entry in localEntries) {
        await _firestore
            .collection('cash_flow')
            .doc(entry['id'] as String)
            .set(entry);
        
        await db.update(
          'cash_flow',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [entry['id']],
        );
      }
      
      print('✅ Fluxo de caixa sincronizado: ${localEntries.length}');
    } catch (e) {
      print('❌ Erro ao sincronizar fluxo de caixa: $e');
      rethrow;
    }
  }

  // Sincronização completa
  Future<void> syncAll() async {
    print('🔄 Iniciando sincronização completa...');
    
    await syncProducts();
    await syncSales();
    await syncCashFlow();
    
    print('✅ Sincronização completa finalizada!');
  }

  // Baixar produtos do servidor
  Future<void> downloadProducts() async {
    try {
      final db = await _dbHelper.database;
      
      final snapshot = await _firestore.collection('products').get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Verificar se já existe localmente
        final existing = await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [doc.id],
        );
        
        if (existing.isEmpty) {
          // Inserir novo produto
          await db.insert('products', data);
        } else {
          // Atualizar produto existente
          await db.update(
            'products',
            data,
            where: 'id = ?',
            whereArgs: [doc.id],
          );
        }
      }
      
      print('✅ Produtos baixados: ${snapshot.docs.length}');
    } catch (e) {
      print('❌ Erro ao baixar produtos: $e');
      rethrow;
    }
  }
}
```

### Passo 10: Criar Provider de Sincronização

Arquivo: `lib/core/providers/sync_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

final syncServiceProvider = Provider((ref) => SyncService());

class SyncState {
  final bool isSyncing;
  final DateTime? lastSync;
  final String? error;

  SyncState({
    this.isSyncing = false,
    this.lastSync,
    this.error,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSync,
    String? error,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSync: lastSync ?? this.lastSync,
      error: error,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(SyncState());

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true, error: null);

    try {
      await _syncService.syncAll();
      state = state.copyWith(
        isSyncing: false,
        lastSync: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> downloadData() async {
    state = state.copyWith(isSyncing: true, error: null);

    try {
      await _syncService.downloadProducts();
      state = state.copyWith(
        isSyncing: false,
        lastSync: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
      );
    }
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.read(syncServiceProvider);
  return SyncNotifier(syncService);
});
```

## Parte 4: Interface de Sincronização

### Passo 11: Adicionar Botão de Sincronização no Dashboard

Em `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, adicione:

```dart
// No AppBar actions
actions: [
  Consumer(
    builder: (context, ref, child) {
      final syncState = ref.watch(syncProvider);
      
      return IconButton(
        icon: syncState.isSyncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload),
        onPressed: syncState.isSyncing
            ? null
            : () async {
                await ref.read(syncProvider.notifier).syncNow();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Sincronização concluída!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
        tooltip: 'Sincronizar com Firebase',
      );
    },
  ),
],
```

## Parte 5: Testar

### Passo 12: Comandos de Teste

```bash
# 1. Parar app atual
pkill -9 -f "sushigen"

# 2. Limpar build
flutter clean

# 3. Instalar dependências
flutter pub get

# 4. Rodar app
flutter run -d macos
```

### Passo 13: Verificar no Firebase Console

1. Abra: https://console.firebase.google.com/
2. Vá em **Firestore Database**
3. Clique em **"Sincronizar agora"** no app
4. Veja os dados aparecendo em tempo real!

## 📊 Estrutura no Firestore

```
sushigen (projeto)
└── firestore
    ├── products/
    │   └── {product_id}
    │       ├── id
    │       ├── name
    │       ├── price
    │       ├── cost
    │       └── ...
    ├── sales/
    │   └── {sale_id}
    │       ├── id
    │       ├── sale_number
    │       ├── total_amount
    │       └── ...
    ├── sale_items/
    │   └── {item_id}
    │       └── ...
    └── cash_flow/
        └── {entry_id}
            └── ...
```

## ⚠️ Problemas Comuns

### Erro: "No Firebase App"
**Solução**: Verifique se o `GoogleService-Info.plist` está no lugar certo e adicionado no Xcode.

### Erro: "Network error"
**Solução**: Verifique os entitlements (permissões de rede).

### Erro: "Permission denied"
**Solução**: Revise as regras do Firestore.

### App não compila
**Solução**:
```bash
flutter clean
rm -rf macos/Pods
rm macos/Podfile.lock
cd macos && pod install
cd .. && flutter pub get
```

## 🎯 Próximos Passos

Depois de configurar:
1. ✅ Fazer algumas vendas
2. ✅ Clicar em "Sincronizar"
3. ✅ Ver dados no Firebase Console
4. ✅ Instalar em outro Mac
5. ✅ Baixar dados sincronizados

## 📝 Notas Importantes

- Dados são **adicionais** ao banco local (não substitui)
- Sincronização é **manual** (botão)
- Conflitos: **último ganha** (last-write-wins)
- Sem internet: App continua funcionando offline

---

**Pronto para começar? Siga o Passo 1!** 🚀
