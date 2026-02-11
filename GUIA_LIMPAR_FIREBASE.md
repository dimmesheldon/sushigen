# 🔥 GUIA: Deletar Coleções Globais do Firebase

## ⚠️ PROBLEMA

O sistema estava salvando dados em coleções globais sem separação por cliente:
- `products/` (global) ❌
- `sales/` (global) ❌
- `sale_items/` (global) ❌
- `cash_flow/` (global) ❌

Isso causava compartilhamento indevido de produtos entre TODOS os clientes.

---

## ✅ SOLUÇÃO APLICADA

Código corrigido para usar arquitetura multi-tenant com subcoleções:

```
Firestore:
└─ customers/
   └─ {customerId}/
      ├─ products/
      ├─ sales/
      ├─ sale_items/
      └─ cash_flow/
```

---

## 🗑️ DELETAR COLEÇÕES ANTIGAS (MANUAL)

### Opção 1: Firebase Console (Web)

1. **Acessar**: https://console.firebase.google.com/
2. **Projeto**: Selecionar "sushigen"
3. **Firestore Database**: Menu lateral esquerdo
4. **Deletar as coleções**:

   Para cada coleção abaixo:
   - `products`
   - `sales`
   - `sale_items`
   - `cash_flow`

   **Passos**:
   1. Clicar na coleção
   2. Clicar nos **3 pontinhos** (⋮) no topo
   3. Selecionar **"Delete collection"**
   4. Confirmar a deleção
   5. **AGUARDAR** conclusão (pode demorar se houver muitos documentos)

---

### Opção 2: Firebase CLI (Recomendado para muitos documentos)

```bash
# 1. Instalar Firebase CLI (se não tiver)
npm install -g firebase-tools

# 2. Login
firebase login

# 3. Deletar coleções
firebase firestore:delete products --recursive --yes
firebase firestore:delete sales --recursive --yes
firebase firestore:delete sale_items --recursive --yes
firebase firestore:delete cash_flow --recursive --yes
```

---

## ✅ VALIDAÇÃO

Após deletar, verificar no Firebase Console que:
1. ❌ Não existe mais `products` (raiz)
2. ❌ Não existe mais `sales` (raiz)
3. ❌ Não existe mais `sale_items` (raiz)
4. ❌ Não existe mais `cash_flow` (raiz)
5. ✅ Existe `customers/{customerId}/products`
6. ✅ Existe `customers/{customerId}/sales`
7. ✅ Existe `customers/{customerId}/sale_items`
8. ✅ Existe `customers/{customerId}/cash_flow`

---

## 🔄 PRÓXIMOS PASSOS

Após deletar as coleções antigas:

### 1. Todos os usuários devem fazer login novamente

### 2. Sincronizar dados (Upload):
- Ir em Dashboard
- Menu "⬆️ Upload para Nuvem"
- Aguardar conclusão

### 3. Validar multi-tenant:
```
Teste:
1. Login asu_admin → Cadastrar produto "Teste A"
2. Sincronizar
3. Logout
4. Login delceni → Baixar dados
5. Verificar que "Teste A" aparece (CORRETO ✅)
6. Logout
7. Login como usuário de outro cliente
8. Verificar que "Teste A" NÃO aparece (CORRETO ✅)
```

---

## 📊 ESTRUTURA ANTES VS DEPOIS

### ❌ ANTES (ERRADO):
```
products/
├─ prod1 (criado por asu_admin)
├─ prod2 (criado por delceni)
└─ prod3 (criado por cliente_b)

Resultado: TODOS compartilham TODOS os produtos
```

### ✅ DEPOIS (CORRETO):
```
customers/
├─ {cliente_asu}/
│  └─ products/
│     ├─ prod1 (asu_admin)
│     └─ prod2 (delceni)
└─ {cliente_b}/
   └─ products/
      └─ prod3 (cliente_b)

Resultado: Isolamento por cliente ✅
```

---

## 🚨 IMPORTANTE

- **Backup**: Se houver dados importantes, fazer backup antes de deletar
- **Teste**: Após deletar, testar sincronização com dados novos
- **Documentação**: Este guia está em `GUIA_LIMPAR_FIREBASE.md`

---

## ✅ CORREÇÕES APLICADAS NO CÓDIGO

**Arquivos modificados**:
1. `lib/core/database/database_helper.dart`
   - Adicionado `getCurrentCustomerId()`

2. `lib/core/services/sync_service.dart`
   - `syncProducts()`: `.collection('customers').doc(customerId).collection('products')`
   - `syncSales()`: `.collection('customers').doc(customerId).collection('sales')`
   - `syncCashFlow()`: `.collection('customers').doc(customerId).collection('cash_flow')`
   - `downloadProducts()`: Mesma estrutura
   - `downloadSales()`: Mesma estrutura

**Resultado**: Multi-tenant funcionando corretamente! 🎉
