# Correções Críticas - 11/02/2026 (Multi-Tenant + PDF)

## 🔴 PROBLEMAS IDENTIFICADOS

### 1. PDF - Erro de Permissão ✅ CORRIGIDO
**Problema**: Tentativa de criar pasta fora do sandbox do macOS
```
🔴 ERRO: PathAccessException: Creation failed, path = 
'/Users/dimmesheldon/Library/Containers/com.sushigen.sushigen/Documents' 
(OS Error: Operation not permitted, errno = 1)
```

**Causa**: Código tentava sair do sandbox: `appDocDir.parent.parent.path`

**Solução**: Usar pasta DENTRO do sandbox
```dart
// ANTES (ERRADO):
directory = Directory('${appDocDir.parent.parent.path}/Documents/SushiGen/PDFs');

// DEPOIS (CORRETO):
directory = Directory('${appDocDir.path}/PDFs');
```

**Resultado**: PDFs salvos em `~/Library/Containers/com.sushigen.sushigen/Data/Documents/PDFs/`

---

### 2. Menu "Fluxo de Caixa" Faltando ✅ CORRIGIDO
**Problema**: Item de menu ausente no drawer lateral

**Solução**: Adicionado após "Relatórios"
```dart
ListTile(
  leading: const Icon(Icons.account_balance_wallet),
  title: const Text('Fluxo de Caixa'),
  onTap: () {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/cash-flow');
  },
),
```

**Arquivo**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

---

### 3. 🔥 MULTI-TENANT QUEBRADO - Produtos Compartilhados ✅ CORRIGIDO

**PROBLEMA CRÍTICO**: 
- **asu_admin** (cliente Asu): 9 produtos
- **delceni** (cliente Asu): 2 produtos
- **ESPERADO**: MESMOS produtos (mesmo `customer_id`)

**CAUSA RAIZ**: Firebase salvando em coleção global sem separação por cliente

```dart
// CÓDIGO ERRADO:
await _firestore
    .collection('products')  // ❌ Global!
    .doc(product['id'])
    .set(productData);
```

**ARQUITETURA CORRIGIDA**:

```
Firestore Structure:
└─ customers/
   └─ {customerId}/
      ├─ products/
      │  └─ {productId}
      ├─ sales/
      │  └─ {saleId}
      ├─ sale_items/
      │  └─ {itemId}
      └─ cash_flow/
         └─ {entryId}
```

**CORREÇÕES APLICADAS**:

#### 3.1. DatabaseHelper - Novo Método
```dart
// Método público para obter customer_id
String? getCurrentCustomerId() {
  return _currentCustomerId;
}
```

#### 3.2. SyncService - Upload com Multi-Tenant

**syncProducts()**:
```dart
final customerId = _dbHelper.getCurrentCustomerId();
if (customerId == null) {
  throw Exception('Customer ID não definido');
}

await _firestore
    .collection('customers')
    .doc(customerId)
    .collection('products')
    .doc(product['id'])
    .set(productData, SetOptions(merge: true));
```

**syncSales()**:
```dart
await _firestore
    .collection('customers')
    .doc(customerId)
    .collection('sales')
    .doc(sale['id'])
    .set(saleData, SetOptions(merge: true));

// Itens também separados por cliente:
await _firestore
    .collection('customers')
    .doc(customerId)
    .collection('sale_items')
    .doc(item['id'])
    .set(itemData, SetOptions(merge: true));
```

**syncCashFlow()**:
```dart
await _firestore
    .collection('customers')
    .doc(customerId)
    .collection('cash_flow')
    .doc(entry['id'])
    .set(entryData, SetOptions(merge: true));
```

#### 3.3. SyncService - Download com Multi-Tenant

**downloadProducts()**:
```dart
final snapshot = await _firestore
    .collection('customers')
    .doc(customerId)
    .collection('products')
    .get();
```

**downloadSales()**:
```dart
Query<Map<String, dynamic>> query = _firestore
    .collection('customers')
    .doc(customerId)
    .collection('sales');

// Itens da venda:
final itemsSnapshot = await _firestore
    .collection('customers')
    .doc(customerId)
    .collection('sale_items')
    .where('sale_id', isEqualTo: doc.id)
    .get();
```

---

## 📂 ARQUIVOS MODIFICADOS

1. **lib/features/cashflow/presentation/screens/cash_flow_screen.dart**
   - Corrigido caminho de salvamento PDF
   - Removido tentativa de sair do sandbox

2. **lib/features/dashboard/presentation/screens/dashboard_screen.dart**
   - Adicionado menu "Fluxo de Caixa"

3. **lib/core/database/database_helper.dart**
   - Adicionado `getCurrentCustomerId()`

4. **lib/core/services/sync_service.dart**
   - `syncProducts()`: Subcoleção por cliente
   - `syncSales()`: Subcoleção por cliente
   - `syncCashFlow()`: Subcoleção por cliente
   - `downloadProducts()`: Filtro por cliente
   - `downloadSales()`: Filtro por cliente

---

## ✅ VALIDAÇÃO NECESSÁRIA

### Teste 1: PDF Gerado com Sucesso
```
1. Login como qualquer usuário
2. Ir em Fluxo de Caixa
3. Clicar no ícone PDF
4. Verificar mensagem de sucesso
5. Clicar em "ABRIR" → Finder deve abrir pasta
```

**Esperado**: PDF em `~/Library/Containers/com.sushigen.sushigen/Data/Documents/PDFs/`

### Teste 2: Menu Fluxo de Caixa
```
1. Login como qualquer usuário
2. Abrir menu lateral (hamburguer)
3. Verificar item "Fluxo de Caixa" presente
4. Clicar → deve navegar para tela de fluxo
```

### Teste 3: Multi-Tenant - Produtos Compartilhados
```
1. Login como asu_admin (cliente Asu)
2. Criar produto "Sushi Salmão"
3. Sincronizar
4. Logout
5. Login como delceni (cliente Asu)
6. Baixar dados do servidor
7. Verificar "Sushi Salmão" presente
```

**Esperado**: MESMOS produtos para usuários do mesmo cliente

### Teste 4: Multi-Tenant - Isolamento Entre Clientes
```
1. Criar segundo cliente "Cliente B"
2. Login como usuário do "Cliente B"
3. Verificar que NÃO vê produtos do cliente Asu
```

**Esperado**: Produtos ISOLADOS por cliente

---

## 🚀 PRÓXIMOS PASSOS

1. ✅ Hot reload para aplicar correções
2. ⏳ Testar geração de PDF
3. ⏳ Verificar menu Fluxo de Caixa
4. ⏳ Validar multi-tenant (produtos compartilhados)
5. ⏳ Limpar dados antigos do Firebase (coleções globais)
6. ⏳ Documentar estrutura Firebase no README

---

## 🔥 ATENÇÃO: LIMPEZA DE DADOS

Os dados antigos no Firebase estão em coleções globais:
- `products/` (global) ❌
- `sales/` (global) ❌  
- `sale_items/` (global) ❌
- `cash_flow/` (global) ❌

**Após validar o sistema**, execute no Firebase Console:
```javascript
// Firestore → Deletar coleções antigas:
- products
- sales  
- sale_items
- cash_flow
```

A nova estrutura usa subcoleções:
```
customers/{customerId}/products
customers/{customerId}/sales
customers/{customerId}/sale_items
customers/{customerId}/cash_flow
```

---

## 📊 RESUMO

| Problema | Status | Impacto |
|----------|--------|---------|
| PDF - Permissão Negada | ✅ Corrigido | Médio |
| Menu Fluxo de Caixa | ✅ Corrigido | Baixo |
| Multi-Tenant Quebrado | ✅ Corrigido | 🔥 CRÍTICO |

**Total de Arquivos Modificados**: 4
**Total de Métodos Corrigidos**: 7
