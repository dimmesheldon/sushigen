# 📦 Onde Lançar Itens do Estoque?

## 🎯 3 Formas de Gerenciar Estoque

### **1️⃣ Ao Cadastrar um Novo Produto** ⭐ RECOMENDADO!

**Caminho:**
```
Dashboard → Produtos → Botão "+" → Preencher formulário
```

**Nova Seção no Formulário:** "📦 Estoque Inicial"

**Campos Disponíveis:**
1. **Quantidade Inicial** - Quanto você tem agora (ex: 100)
2. **Unidade** - un, kg, L, cx, etc
3. **Estoque Mínimo** - Quando deve alertar (ex: 20)
4. **Estoque Máximo** - Limite de armazenamento (opcional)

**Exemplo Prático:**
```
Produto: California Roll
Preço: R$ 35,00
Categoria: Sushi

📦 ESTOQUE INICIAL:
Quantidade: 50 unidades
Unidade: un
Mínimo: 10
Máximo: 200
```

**Vantagens:**
✅ Tudo em um único lugar
✅ Não precisa ir em 2 telas diferentes
✅ Estoque já configurado ao criar produto
✅ Economiza tempo

---

### **2️⃣ Na Tela de Estoque** (Gestão Completa)

**Caminho:**
```
Dashboard → Estoque
```

**Operações Disponíveis:**

#### ➕ Adicionar Estoque (Entrada/Compra)
```
Produto → Menu (⋮) → Adicionar
```
- **Quando usar**: Recebeu nova mercadoria
- **Campos**: Quantidade + Preço de compra
- **Resultado**: Soma ao estoque atual

**Exemplo:**
```
Estoque atual: 20
Adicionar: 50 (R$ 12,50/un)
Novo estoque: 70
Último custo: R$ 12,50
```

#### ➖ Remover Estoque (Saída Manual)
```
Produto → Menu (⋮) → Remover
```
- **Quando usar**: Perda, avaria, uso interno
- **Validação**: Não permite remover mais que disponível
- **Resultado**: Subtrai do estoque

**Exemplo:**
```
Estoque atual: 70
Remover: 5 (produtos vencidos)
Novo estoque: 65
```

#### ✏️ Ajustar Estoque (Inventário)
```
Produto → Menu (⋮) → Ajustar
```
- **Quando usar**: Contagem física, correção de erro
- **Funciona**: Define quantidade exata
- **Ignora**: Valor anterior

**Exemplo:**
```
Estoque sistema: 65
Contagem física: 58
Ajustar para: 58
Novo estoque: 58
```

#### ⚙️ Configurações
```
Produto → Menu (⋮) → Configurações
```
- **Alterar unidade**: un → kg
- **Ajustar mínimo**: 10 → 20
- **Definir máximo**: vazio → 200

---

### **3️⃣ Automático via Vendas** (Futuro)

**Status**: 🚧 Em desenvolvimento

**Como funcionará:**
```
Cliente compra 5 California Rolls
↓
Sistema remove automaticamente do estoque
↓
Estoque atualizado: 53 un
```

**Implementação futura** - Integração venda → estoque

---

## 📊 Comparação das Formas

| Forma | Quando Usar | Vantagem | Onde |
|-------|-------------|----------|------|
| **Cadastro de Produto** | Produto novo | Tudo em um lugar | Produtos → Novo |
| **Adicionar Estoque** | Recebeu compra | Registra custo | Estoque → ⋮ → Adicionar |
| **Remover Estoque** | Perda/Avaria | Controle saídas | Estoque → ⋮ → Remover |
| **Ajustar Estoque** | Inventário | Corrige erros | Estoque → ⋮ → Ajustar |
| **Configurações** | Mudar regras | Altera min/max | Estoque → ⋮ → Config |

---

## 🎬 Fluxo Completo Recomendado

### **Para Produto NOVO:**

```mermaid
Dashboard 
  → Produtos 
  → Botão "+"
  → Preencher dados básicos
  → Preencher estoque inicial ⭐
  → Salvar
  → ✅ Produto + Estoque criados!
```

### **Para Produto EXISTENTE:**

#### Entrada de Mercadoria:
```
Dashboard 
  → Estoque
  → Escolher produto
  → Menu (⋮) → Adicionar
  → Quantidade: 50
  → Preço: R$ 10,00
  → Confirmar
  → ✅ Estoque atualizado!
```

#### Inventário Mensal:
```
Dashboard 
  → Estoque
  → Para cada produto:
    → Contar fisicamente
    → Menu (⋮) → Ajustar
    → Informar quantidade exata
    → Confirmar
  → ✅ Estoque ajustado!
```

---

## 💡 Dicas Práticas

### 🆕 Produto Novo
**Use o cadastro de produto!**
```
Ao criar "Sashimi de Salmão":
- Nome, preço, categoria ✅
- Estoque inicial: 30 unidades ✅
- Mínimo: 10 ✅
Tudo configurado de uma vez!
```

### 📦 Recebeu Mercadoria
**Use adicionar estoque!**
```
Fornecedor entregou 100 peças:
Estoque → California Roll → ⋮ → Adicionar
Quantidade: 100
Preço: R$ 8,50
✅ Registra entrada + custo
```

### 🗑️ Produto Avariado
**Use remover estoque!**
```
5 peças venceram:
Estoque → Produto → ⋮ → Remover
Quantidade: 5
✅ Desconta do estoque
```

### 📊 Fazer Inventário
**Use ajustar estoque!**
```
Sistema: 50 unidades
Contei: 47 unidades
Estoque → Produto → ⋮ → Ajustar
Nova quantidade: 47
✅ Corrigido!
```

### ⚠️ Alerta de Estoque Baixo
**Configure o mínimo!**
```
Estoque → Produto → ⋮ → Configurações
Mínimo: 20
✅ Sistema alerta quando ≤ 20
```

---

## 🔄 Cenários de Uso

### **Cenário 1: Abertura do Restaurante**
```
Situação: Primeiro dia, cadastrando cardápio

Ação:
1. Dashboard → Produtos → Novo
2. Criar "Sushi Philadelphia"
3. Preencher seção "Estoque Inicial":
   - Quantidade: 40
   - Unidade: un
   - Mínimo: 15
4. Salvar

Resultado: ✅ Produto criado + Estoque configurado
```

### **Cenário 2: Chegou Fornecedor**
```
Situação: Recebeu 200 peças de California Roll

Ação:
1. Dashboard → Estoque
2. Buscar "California Roll"
3. Menu (⋮) → Adicionar
4. Quantidade: 200
5. Preço compra: R$ 9,50
6. Confirmar

Resultado: 
✅ Estoque: 50 → 250
✅ Último custo: R$ 9,50
✅ Data compra registrada
```

### **Cenário 3: Perda de Produtos**
```
Situação: 8 temakis estragaram na geladeira

Ação:
1. Dashboard → Estoque
2. Buscar "Temaki"
3. Menu (⋮) → Remover
4. Quantidade: 8
5. Confirmar

Resultado: ✅ Estoque: 65 → 57
```

### **Cenário 4: Inventário Mensal**
```
Situação: Fim do mês, conferir estoque

Ação:
1. Dashboard → Estoque
2. Pegar papel e caneta
3. Para cada produto:
   a) Contar fisicamente
   b) Menu (⋮) → Ajustar
   c) Informar quantidade real
   d) Confirmar

Resultado: ✅ Todos estoques conferidos e ajustados
```

### **Cenário 5: Mudou Fornecedor**
```
Situação: Novo fornecedor usa kg, não unidades

Ação:
1. Dashboard → Estoque
2. Buscar produto
3. Menu (⋮) → Configurações
4. Unidade: un → kg
5. Salvar

Resultado: ✅ Produto agora em kg
```

---

## ⚡ Perguntas Frequentes

### **P: Tenho que criar estoque para todos os produtos?**
R: Não é obrigatório, mas recomendado. Se não criar, pode adicionar depois pela tela de Estoque.

### **P: Posso mudar a unidade depois?**
R: Sim! Menu (⋮) → Configurações → Unidade

### **P: O que acontece se estoque ficar negativo?**
R: O sistema não permite. Bloqueia a remoção se não houver quantidade suficiente.

### **P: Como sei quando reabastecer?**
R: Configure o "Estoque Mínimo". Quando chegar nele, aparece alerta "ESTOQUE BAIXO" em laranja.

### **P: Preciso sempre colocar o preço de compra?**
R: Não é obrigatório, mas ajuda a controlar custos e calcular margem de lucro.

### **P: Posso ter produtos sem estoque (serviços)?**
R: Sim! Deixe estoque inicial vazio ou zero. Produto aparecerá na lista mas sem controle de quantidade.

---

## 📱 Interface Visual

### **Formulário de Produto (Novo)**
```
┌─────────────────────────────────────┐
│ 🍱 Novo Produto                     │
├─────────────────────────────────────┤
│ Nome: California Roll               │
│ Descrição: ...                      │
│ Categoria: Sushi                    │
│ Preço: R$ 35,00                     │
│ Custo: R$ 12,00                     │
├─────────────────────────────────────┤
│ 📦 ESTOQUE INICIAL                  │
│ ┌─────────┬─────────┐               │
│ │Qtd: 50  │Un: un   │               │
│ └─────────┴─────────┘               │
│ ┌─────────┬─────────┐               │
│ │Mín: 10  │Máx: 200 │               │
│ └─────────┴─────────┘               │
├─────────────────────────────────────┤
│      [Cancelar]  [Salvar]           │
└─────────────────────────────────────┘
```

### **Tela de Estoque**
```
┌─────────────────────────────────────┐
│ 📦 Gestão de Estoque         🔄     │
├─────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────┐         │
│ │ 15   │ │  3   │ │  1   │         │
│ │Total │ │Baixo │ │ Sem  │         │
│ └──────┘ └──────┘ └──────┘         │
├─────────────────────────────────────┤
│ [Todos] [Estoque Baixo] [Sem Esto.]│
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐   │
│ │ 50  │ California Roll         │⋮│ │
│ │ un  │ ● ESTOQUE BAIXO         │  │
│ │     │ Mín: 100                │  │
│ └───────────────────────────────┘   │
│                                     │
│ ┌───────────────────────────────┐   │
│ │ 120 │ Sashimi Salmão          │⋮│ │
│ │ un  │ ● OK                    │  │
│ │     │ Mín: 50                 │  │
│ └───────────────────────────────┘   │
└─────────────────────────────────────┘
```

### **Menu de Ações (⋮)**
```
┌────────────────────┐
│ ➕ Adicionar       │
│ ➖ Remover         │
│ ✏️ Ajustar         │
│ ⚙️ Configurações   │
└────────────────────┘
```

---

## ✅ Resumo Rápido

| Situação | O Que Fazer |
|----------|-------------|
| **Produto novo** | Preencher estoque inicial no cadastro |
| **Chegou mercadoria** | Estoque → ⋮ → Adicionar |
| **Produto estragou** | Estoque → ⋮ → Remover |
| **Fazer inventário** | Estoque → ⋮ → Ajustar |
| **Mudar min/max** | Estoque → ⋮ → Configurações |
| **Ver estoque baixo** | Estoque → Chip "Estoque Baixo" |

---

**🎉 Agora você sabe exatamente onde e como lançar itens do estoque!**

A forma mais prática é usar o **formulário de produtos** para novos itens, e a **tela de estoque** para gerenciar o dia a dia! 📦✨
