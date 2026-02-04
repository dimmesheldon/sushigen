# Remoção do Sistema de Estoque + Análise de Divergências

## Data: 03/02/2026

## ✅ 1. Sistema de Estoque REMOVIDO

### **Arquivos/Pastas Deletados:**
- ✅ `/lib/features/stock/` - **Pasta completa deletada**
  - Todos os modelos, repositories, providers e telas

### **Referências Removidas:**

#### **main.dart:**
```dart
// ❌ REMOVIDO:
import 'features/stock/presentation/screens/stock_screen.dart';
'/stock': (context) => const StockScreen(),
```

#### **dashboard_screen.dart:**
```dart
// ❌ REMOVIDO:
_buildActionCard(
  'Estoque',
  Icons.inventory_2,
  Colors.orange.shade700,
  () => Navigator.pushNamed(context, '/stock'),
),
```

### **Estado Atual:**
- ✅ App compila sem erros
- ✅ Rota `/stock` removida
- ✅ Card "Estoque" removido do dashboard
- ✅ Menu do dashboard ajustado

---

## 🔍 2. Análise da Divergência: Dashboard vs Fluxo de Caixa

### **Problema Reportado:**
- Dashboard mostra: **R$ 313,60** (Faturamento Hoje)
- Fluxo de Caixa mostra: **R$ 169,60** (Receitas de Hoje)

### **Causa Identificada:**

#### **Dashboard busca da tabela `sales`:**
```dart
// lib/features/sales/data/repositories/sale_repository.dart (linha 159)
Future<double> getTodayTotal() async {
  final result = await db.rawQuery(
    'SELECT SUM(final_amount) as total 
     FROM sales 
     WHERE sale_date >= ? AND sale_date < ? 
     AND status = ?',
    [startDate, endDate, 'completed'],
  );
  return (result.first['total'] as double?) ?? 0.0;
}
```

**✅ Busca:** Tabela `sales` → Todas as vendas estão aqui  
**✅ Resultado:** R$ 313,60 (11 vendas)

#### **Fluxo de Caixa busca da tabela `cash_flow`:**
```dart
// lib/features/cashflow/data/repositories/cash_flow_repository.dart (linha 79)
Future<Map<String, double>> getBalanceByPeriod(...) async {
  final incomeResult = await db.rawQuery(
    'SELECT COALESCE(SUM(amount), 0) as total
     FROM cash_flow
     WHERE type = 'income'
     AND date >= ? AND date <= ?',
    [startDate, endDate],
  );
  return income; // Retorna apenas o que está em cash_flow
}
```

**⚠️ Busca:** Tabela `cash_flow` → Apenas 6 vendas registradas  
**⚠️ Resultado:** R$ 169,60 (6 vendas)

---

## 📊 Por Que a Divergência?

### **Timeline do Problema:**

```
┌─────────────────────────────────────────────────────────┐
│ ANTES (Bug no Código)                                   │
├─────────────────────────────────────────────────────────┤
│ Vendas 1-11 criadas com código BUGADO:                 │
│ - Salvava em 'sales' ✅                                 │
│ - Tentava salvar em 'cash_flow' com colunas erradas ❌ │
│ - Resultado: Apenas algumas foram registradas          │
│                                                         │
│ Tabela sales:       11 vendas = R$ 313,60 ✅           │
│ Tabela cash_flow:    6 vendas = R$ 169,60 ❌           │
│                                                         │
│ Faltando: 5 vendas = R$ 144,00                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ AGORA (Código Corrigido)                                │
├─────────────────────────────────────────────────────────┤
│ Vendas futuras com código CORRETO:                     │
│ - Salva em 'sales' ✅                                   │
│ - Salva em 'cash_flow' corretamente ✅                 │
│ - Resultado: Vendas novas funcionam perfeitamente      │
│                                                         │
│ MAS... vendas antigas ainda divergentes:               │
│ Tabela sales:       11 vendas = R$ 313,60 ✅           │
│ Tabela cash_flow:    6 vendas = R$ 169,60 ❌           │
└─────────────────────────────────────────────────────────┘
```

---

## 💡 Soluções para a Divergência

### **Solução 1: Executar Script de Migração** ⭐ RECOMENDADO

**Já criado:** `scripts/migrate_sales_to_cashflow.dart`

**Como executar:**
```bash
# Terminal:
dart run scripts/migrate_sales_to_cashflow.dart

# Vai mostrar as 5 vendas faltantes
# Digite "SIM" para confirmar
# Pronto! Divergência corrigida
```

**Resultado esperado:**
```
ANTES:
Dashboard:      R$ 313,60 (11 vendas)
Fluxo de Caixa: R$ 169,60 (6 vendas)
❌ Divergente

DEPOIS:
Dashboard:      R$ 313,60 (11 vendas)
Fluxo de Caixa: R$ 313,60 (11 vendas)
✅ Sincronizado
```

### **Solução 2: Ignorar Divergência** ⚠️ Não Recomendado

Você pode simplesmente ignorar e:
- Continuar usando o sistema
- Vendas novas funcionam corretamente
- Mas os valores históricos continuarão divergentes

### **Solução 3: Mudar Dashboard para Buscar de cash_flow**

Fazer o Dashboard buscar apenas de `cash_flow`, igual ao fluxo de caixa:

**Prós:**
- ✅ Resolve divergência imediatamente
- ✅ Centraliza fonte de dados

**Contras:**
- ❌ Mostrará valores incorretos até executar migração
- ❌ Dashboard mostraria R$ 169,60 (o valor errado)

---

## 📋 3. Preparação para Sincronização de Dados

### **Arquitetura Proposta:**

```
┌──────────────────────────────────────────────────────────┐
│               SUSHIGEN - LOCAL (SQLite)                  │
├──────────────────────────────────────────────────────────┤
│  • Vendas                                                │
│  • Produtos                                              │
│  • Fluxo de Caixa                                        │
│  • Usuários                                              │
│  • Licenças                                              │
│                                                          │
│  [Sync Service] ← → [API REST] ← → [Servidor Cloud]     │
│                                                          │
│  Sincroniza:                                             │
│  ✓ A cada X minutos (automático)                        │
│  ✓ Ao abrir o app                                       │
│  ✓ Botão manual "Sincronizar Agora"                     │
│                                                          │
│  Estratégia:                                             │
│  • Timestamps (created_at, updated_at)                  │
│  • Flag 'synced' (0 = pendente, 1 = sincronizado)       │
│  • Resolução de conflitos (último vence)                │
│  • Queue de sincronização (retry automático)            │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│               SERVIDOR CLOUD (Backend)                   │
├──────────────────────────────────────────────────────────┤
│  Opções:                                                 │
│  1. Firebase (Realtime Database / Firestore) ⭐          │
│  2. Supabase (PostgreSQL + Realtime)                    │
│  3. API REST customizada (Node.js / Laravel)            │
│  4. Appwrite (Backend as a Service)                     │
│                                                          │
│  Requisitos:                                             │
│  ✓ Multi-tenant (múltiplos restaurantes)                │
│  ✓ Autenticação por licença                             │
│  ✓ Backup automático                                    │
│  ✓ Histórico de sincronizações                          │
│  ✓ Rollback em caso de erro                             │
└──────────────────────────────────────────────────────────┘
```

### **Fluxo de Sincronização:**

```
1. UPLOAD (Local → Servidor)
   ┌─────────────────────────────────────┐
   │ SELECT * FROM sales                 │
   │ WHERE synced = 0                    │
   │ ORDER BY created_at ASC             │
   ├─────────────────────────────────────┤
   │ Para cada registro:                 │
   │ → POST /api/sync/sales              │
   │ → Se sucesso: UPDATE synced = 1     │
   │ → Se erro: Mantém synced = 0 (retry)│
   └─────────────────────────────────────┘

2. DOWNLOAD (Servidor → Local)
   ┌─────────────────────────────────────┐
   │ GET /api/sync/sales?since=timestamp │
   ├─────────────────────────────────────┤
   │ Para cada registro recebido:        │
   │ → Verifica se existe localmente     │
   │ → Se não existe: INSERT             │
   │ → Se existe: Compara updated_at     │
   │   - Se servidor mais novo: UPDATE   │
   │   - Se local mais novo: SKIP        │
   └─────────────────────────────────────┘

3. RESOLUÇÃO DE CONFLITOS
   ┌─────────────────────────────────────┐
   │ Estratégias:                        │
   │ • Last Write Wins (último vence)    │
   │ • Manual (usuário decide)           │
   │ • Merge inteligente (por campo)     │
   └─────────────────────────────────────┘
```

### **Tabelas a Sincronizar:**

| Tabela | Prioridade | Estratégia |
|--------|-----------|------------|
| `sales` | 🔴 Alta | Bidirecional (multi-device) |
| `sale_items` | 🔴 Alta | Bidirecional (vinculado a sales) |
| `cash_flow` | 🔴 Alta | Bidirecional |
| `products` | 🟡 Média | Download (central → dispositivos) |
| `users` | 🟡 Média | Download (gerenciado no servidor) |
| `licenses` | 🟢 Baixa | Download (apenas leitura) |

### **Schema Adicional Necessário:**

```sql
-- Tabela de log de sincronização
CREATE TABLE sync_history (
  id TEXT PRIMARY KEY,
  sync_type TEXT NOT NULL,        -- 'upload' ou 'download'
  table_name TEXT NOT NULL,
  records_count INTEGER NOT NULL,
  success INTEGER NOT NULL,       -- 0 ou 1
  error_message TEXT,
  started_at TEXT NOT NULL,
  finished_at TEXT NOT NULL
);

-- Índice
CREATE INDEX idx_sync_history_date ON sync_history(started_at);

-- Adicionar coluna 'last_sync' nas tabelas principais
ALTER TABLE sales ADD COLUMN last_sync TEXT;
ALTER TABLE products ADD COLUMN last_sync TEXT;
ALTER TABLE cash_flow ADD COLUMN last_sync TEXT;
```

---

## 🚀 Próximos Passos Sugeridos

### **Fase 1: Correção de Dados (AGORA)** ⏰ 5 minutos
```bash
# 1. Executar script de migração
dart run scripts/migrate_sales_to_cashflow.dart

# 2. Confirmar com "SIM"

# 3. Verificar no app:
#    Dashboard e Fluxo de Caixa devem mostrar mesmos valores
```

### **Fase 2: Definir Backend para Sincronização** 📋 Decisão
**Escolha uma opção:**

1. **Firebase** ⭐ RECOMENDADO
   - ✅ Fácil de configurar
   - ✅ Realtime automático
   - ✅ Autenticação integrada
   - ✅ Gratuito até 10GB
   - ❌ Vendor lock-in

2. **Supabase**
   - ✅ PostgreSQL (familiar)
   - ✅ Open source
   - ✅ Realtime subscriptions
   - ✅ Auth + Storage inclusos
   - ⚠️ Precisa hospedar

3. **API REST Customizada**
   - ✅ Controle total
   - ✅ Qualquer linguagem
   - ❌ Mais trabalho
   - ❌ Infraestrutura necessária

**Qual você prefere?**

### **Fase 3: Implementação da Sincronização** 🛠️ 2-3 dias
1. Configurar backend escolhido
2. Criar service de sincronização
3. Implementar upload de dados
4. Implementar download de dados
5. Tela de status de sincronização
6. Botão "Sincronizar Agora"
7. Sincronização automática em background
8. Testes multi-device

---

## 📊 Resumo Executivo

### **✅ Concluído:**
- Sistema de Estoque **REMOVIDO** completamente
- Bug de sincronização vendas/caixa **IDENTIFICADO**
- Script de migração **CRIADO** e pronto para uso

### **⏳ Pendente:**
- Executar script de migração (5 min)
- Escolher backend para sincronização
- Implementar sistema de sincronização

### **❓ Decisões Necessárias:**
1. Executar script de migração agora? (SIM/NÃO)
2. Qual backend usar? (Firebase/Supabase/Custom)
3. Sincronização automática ou manual?

---

**Autor**: GitHub Copilot  
**Data**: 03/02/2026  
**Status**: ✅ Estoque removido | ⏳ Aguardando migração | 📋 Pronto para sincronização
