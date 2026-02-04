# Reversão: Estoque Desvinculado de Produtos ✅

## Data: 03/02/2025

## Problema Identificado 🚨

### O que aconteceu:
1. Sistema de estoque foi integrado aos produtos (Fase 18-20)
2. Produtos passaram a ter controle de quantidade em estoque
3. Vendas eram bloqueadas quando `stock.quantity = 0`
4. **Modelo de negócio incompatível**: Restaurante prepara comida sob demanda

### Por que estava errado:
```
❌ ANTES (Incorreto):
- Products (California Roll, Temaki) → vinculados a Stock
- Validação: SE estoque = 0 ENTÃO bloqueia venda
- Problema: Produtos são feitos sob demanda, não há "estoque" de sushi

✅ DEPOIS (Correto):
- Products (California Roll, Temaki) → ILIMITADOS (preparados conforme pedido)
- Ingredients (Arroz, Salmão, Nori) → COM CONTROLE de estoque
- Lógica: Controlamos ingredientes, não produtos finais
```

## Reversão Executada ✅

### Arquivo: `product_form_screen.dart`

#### 1. Removido Import:
```dart
// REMOVIDO:
import '../../../stock/data/repositories/stock_repository.dart';
```

#### 2. Removidos Controllers:
```dart
// REMOVIDOS (4 controllers):
final _stockQuantityController = TextEditingController();
final _stockMinController = TextEditingController();
final _stockMaxController = TextEditingController();
final _stockUnitController = TextEditingController();
```

#### 3. Limpado initState:
```dart
// REMOVIDO:
_stockQuantityController.text = '0';
_stockMinController.text = '0';
_stockMaxController.text = '';
_stockUnitController.text = 'un';
```

#### 4. Limpado dispose:
```dart
// REMOVIDO:
_stockQuantityController.dispose();
_stockMinController.dispose();
_stockMaxController.dispose();
_stockUnitController.dispose();
```

#### 5. Simplificado _saveProduct:
```dart
// ANTES (Criava produto + estoque):
final productId = await ref.read(productsProvider.notifier).createProduct(product);
final stockRepo = StockRepository();
await stockRepo.createStockEntry(
  productId,
  quantity: double.tryParse(_stockQuantityController.text) ?? 0,
  unit: _stockUnitController.text.trim(),
  minQuantity: double.tryParse(_stockMinController.text) ?? 0,
  maxQuantity: maxQty,
);

// DEPOIS (Apenas cria produto):
await ref.read(productsProvider.notifier).createProduct(product);
```

#### 6. Removida Seção UI Completa:
```dart
// REMOVIDO (105 linhas):
if (widget.product == null) ...[
  const Divider(height: 32),
  const Text('📦 Estoque Inicial', ...),
  
  // 4 TextFormFields:
  - Quantidade Inicial
  - Unidade
  - Estoque Mínimo
  - Estoque Máximo
],
```

### Resultado:
- ✅ **0 erros de compilação**
- ✅ **Formulário de produtos limpo**
- ✅ **Vendas não são mais bloqueadas**
- ✅ **Produtos são ilimitados**

## Estado Atual do Código ✅

### Arquivos Limpos:
- `product_form_screen.dart`: SEM referências a estoque
- `quick_sale_screen.dart`: SEM validação de estoque
- `products_provider.dart`: Funcional

### Arquivos que Precisam Redesign:
- `stock_entry.dart`: Modelo com `productId` (FK)
- `stock_repository.dart`: Queries com JOIN em products
- `stock_screen.dart`: UI mostrando produtos
- `database_helper.dart`: Tabela `stock` com FK

## Próximo Passo: Redesign de Estoque 🔄

### Conceito: Ingredientes, não Produtos

#### Nova Tabela: `ingredients`
```sql
CREATE TABLE ingredients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,              -- Ex: "Arroz para Sushi"
  category TEXT NOT NULL,          -- "Grãos", "Peixes", "Condimentos", "Embalagens"
  quantity REAL NOT NULL,
  unit TEXT NOT NULL,              -- "kg", "L", "un", "pacote"
  min_quantity REAL,               -- Alerta de estoque baixo
  max_quantity REAL,               -- Capacidade máxima
  cost_per_unit REAL,              -- Custo por unidade
  supplier TEXT,                   -- Fornecedor
  last_purchase_date TEXT,
  notes TEXT,                      -- Observações
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Índices
CREATE INDEX idx_ingredients_category ON ingredients(category);
CREATE INDEX idx_ingredients_active ON ingredients(is_active);
CREATE INDEX idx_ingredients_low_stock ON ingredients(quantity, min_quantity);
```

#### Novo Modelo: `Ingredient`
```dart
class Ingredient {
  final String id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double? minQuantity;
  final double? maxQuantity;
  final double? costPerUnit;
  final String? supplier;
  final DateTime? lastPurchaseDate;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Métodos úteis
  bool get isLowStock => minQuantity != null && quantity <= minQuantity!;
  bool get isOutOfStock => quantity <= 0;
  String get stockStatus {
    if (isOutOfStock) return 'Esgotado';
    if (isLowStock) return 'Baixo';
    return 'Normal';
  }
}
```

#### Categorias de Ingredientes:
```dart
enum IngredientCategory {
  grains('Grãos'),           // Arroz, quinoa
  seafood('Peixes/Frutos'),  // Salmão, atum, camarão
  vegetables('Vegetais'),    // Pepino, cenoura, abacate
  seaweed('Algas'),          // Nori, wakame
  condiments('Condimentos'), // Shoyu, wasabi, gengibre
  oils('Óleos'),             // Óleo de gergelim
  packaging('Embalagens'),   // Saquê, hashis, caixas
  others('Outros');
  
  final String label;
  const IngredientCategory(this.label);
}
```

#### Nova Tela: `ingredients_screen.dart`
```dart
// Substituir stock_screen.dart por ingredients_screen.dart

- Título: "Gestão de Ingredientes"
- Filtros: Por categoria
- Cards: 
  - Foto do ingrediente (opcional)
  - Nome
  - Quantidade atual
  - Unidade
  - Status (Normal/Baixo/Esgotado)
  - Última compra
  
- Formulário:
  - Nome do ingrediente
  - Categoria (dropdown)
  - Quantidade inicial
  - Unidade
  - Estoque mínimo
  - Estoque máximo
  - Custo por unidade
  - Fornecedor
  - Observações
```

#### Funcionalidades Avançadas (Futuro):
```dart
1. Movimentações de Estoque:
   - Entrada (compra)
   - Saída (uso na produção)
   - Ajuste (correção)
   - Histórico completo

2. Alertas Automáticos:
   - Notificação quando ingrediente fica abaixo do mínimo
   - Sugestão de compra com base no consumo médio

3. Relatórios:
   - Ingredientes mais usados
   - Custo de ingredientes por período
   - Previsão de compras

4. Integração (opcional):
   - Descontar ingredientes automaticamente nas vendas
   - Ex: Venda de California Roll → desconta arroz, salmão, nori
   - Requer tabela de "receitas" (ingredients_per_product)
```

## Migração de Dados (Se Necessário)

### Se existir dados na tabela `stock`:
```sql
-- 1. Renomear tabela antiga
ALTER TABLE stock RENAME TO stock_old;

-- 2. Criar nova tabela ingredients
CREATE TABLE ingredients (...);

-- 3. Migrar dados (ajustar conforme necessário)
INSERT INTO ingredients (id, name, category, quantity, unit, min_quantity, max_quantity, created_at, updated_at)
SELECT 
  s.id,
  p.name,
  'Outros' as category,  -- Classificar manualmente depois
  s.quantity,
  s.unit,
  s.min_quantity,
  s.max_quantity,
  s.created_at,
  s.updated_at
FROM stock_old s
INNER JOIN products p ON s.product_id = p.id;

-- 4. Verificar migração
SELECT * FROM ingredients;

-- 5. Deletar tabela antiga (CUIDADO!)
-- DROP TABLE stock_old;
```

## Checklist de Implementação 📋

### Fase 1: Limpeza (✅ CONCLUÍDO)
- [x] Remover integração de estoque do formulário de produtos
- [x] Remover validação de estoque em vendas
- [x] Garantir que produtos são ilimitados
- [x] Compilar sem erros

### Fase 2: Redesign de Banco (⏳ PRÓXIMO)
- [ ] Criar tabela `ingredients` no database_helper.dart
- [ ] Migrar dados existentes (se houver)
- [ ] Criar índices
- [ ] Testar queries

### Fase 3: Models e Repositories
- [ ] Criar modelo `Ingredient`
- [ ] Criar enum `IngredientCategory`
- [ ] Criar `IngredientsRepository` com CRUD
- [ ] Adicionar métodos de busca e filtros

### Fase 4: State Management
- [ ] Criar `IngredientsProvider` com Riverpod
- [ ] Estados: loading, success, error, empty

### Fase 5: Interface
- [ ] Criar `ingredients_screen.dart`
- [ ] Criar `ingredient_form_screen.dart`
- [ ] Adicionar ao menu do dashboard
- [ ] Upload de imagens de ingredientes

### Fase 6: Funcionalidades Avançadas
- [ ] Histórico de movimentações
- [ ] Alertas de estoque baixo
- [ ] Relatórios de consumo
- [ ] (Opcional) Integração com receitas

## Como Testar as Mudanças ✅

### 1. Testar Cadastro de Produtos:
```bash
flutter run -d macos
```
1. Login com usuário `admin` / senha `admin`
2. Ir em "Gestão de Produtos"
3. Clicar em "Novo Produto"
4. Preencher dados do produto
5. **Verificar**: NÃO deve haver seção "Estoque Inicial"
6. Salvar produto
7. **Resultado**: Produto criado sem erros

### 2. Testar Vendas:
1. Ir em "Lançamento Rápido"
2. Adicionar qualquer produto ao carrinho (mesmo sem estoque)
3. **Verificar**: Deve permitir adicionar normalmente
4. Finalizar venda
5. **Resultado**: Venda concluída sem bloqueios

### 3. Verificar Sistema de Estoque Antigo:
1. Ir em "Gestão de Estoque" (se ainda existir)
2. **Observar**: Ainda mostra produtos vinculados
3. **Nota**: Esta tela será substituída por "Gestão de Ingredientes"

## Conclusão

### ✅ Problema Resolvido:
- Vendas não são mais bloqueadas por estoque zerado
- Produtos são ilimitados (modelo de negócio correto)
- Código limpo e sem erros

### 🔄 Próxima Etapa:
- Redesenhar sistema de estoque como "Ingredientes"
- Ingredientes serão independentes de produtos
- Controlar arroz, salmão, nori, óleo, etc.

### 📚 Lições Aprendidas:
- Sempre validar modelo de negócio antes de implementar
- Em restaurantes: produtos finais ≠ ingredientes
- Produtos sob demanda não têm "estoque"
- Estoque é para matéria-prima, não produtos acabados

---

**Autor**: GitHub Copilot  
**Data**: 03/02/2025  
**Status**: ✅ Reversão Completa | ⏳ Aguardando Redesign
