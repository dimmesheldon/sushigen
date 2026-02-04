# 🎯 Etapa 20: Relatórios Inteligentes e Análise de Custos

## ✅ IMPLEMENTAÇÃO COMPLETA

### O que foi solicitado:
1. ✅ **Análise de Custos**: "preciso saber quanto estou gastando para produzir"
2. ✅ **Lucro Real**: "valor total geral e o valor descontando o valor do custo de cada produto"
3. ✅ **Vendas iFood**: "Vendas pelo ifood"
4. ✅ **Entregas vs Retiradas**: "Vendas com entregas, Vendas com retirada no local"
5. ✅ **Produtos Top**: "qual o produto que vende mais"
6. ✅ **Produtos Fracos**: "qual o produto que menos vende"

## 📊 Novos Cards Implementados

### 1. 💰 Card: Análise de Custos e Lucro

**Localização**: Primeiro card da tela de relatórios

**Métricas**:
- **Faturamento Total**: Soma de todas as vendas do período
- **Custo Total**: Soma dos custos de produção (campo `cost` dos produtos)
- **Lucro Líquido**: Faturamento - Custo - Custo de Entregas
- **Margem de Lucro**: (Lucro Líquido / Faturamento) × 100
- **Custo de Entregas**: Total gasto com motoboy (apenas se houver entregas)

**Cores Inteligentes**:
- 🟢 Verde: Margem ≥ 30% (excelente)
- 🟠 Laranja: Margem entre 15-30% (atenção)
- 🔴 Vermelho: Margem < 15% (crítico)

**Cálculo**:
```sql
SELECT 
  SUM(si.quantity * si.unit_price) as total_revenue,
  SUM(si.quantity * p.cost) as total_cost,
  SUM(si.quantity * (si.unit_price - p.cost)) as total_profit,
  SUM(s.delivery_cost) as total_delivery_cost
FROM sale_items si
JOIN sales s ON si.sale_id = s.id
JOIN products p ON si.product_id = p.id
```

### 2. 🏪 Card: Vendas por Canal (iFood vs Local)

**Localização**: Segundo card

**Métricas**:
- **Vendas Locais**: Quantidade e faturamento de vendas diretas
- **Vendas iFood**: Quantidade e faturamento via iFood
- **% iFood**: Percentual de faturamento do iFood
- **Total Geral**: Soma de ambos os canais

**Visual**:
- Card azul: Vendas Locais (ícone de loja)
- Card vermelho: Vendas iFood (ícone de restaurante)
- Resumo cinza: Totais e percentual

**Cálculo**:
```sql
SELECT 
  CASE WHEN is_ifood = 1 THEN 'iFood' ELSE 'Local' END as channel,
  COUNT(*) as total_sales,
  SUM(final_amount) as total_revenue,
  AVG(final_amount) as avg_ticket
FROM sales
WHERE sale_date BETWEEN ? AND ?
GROUP BY is_ifood
```

### 3. 🛵 Card: Análise de Entregas

**Localização**: Terceiro card

**Métricas**:
- **Retiradas**: Quantidade e faturamento de pedidos retirados
- **Entregas**: Quantidade e faturamento de pedidos entregues
- **Custo Total de Entregas**: Soma dos custos com motoboy
- **Ticket Médio**: Separado por tipo de entrega

**Visual**:
- Verde: Retiradas (ícone de sacola)
- Laranja: Entregas (ícone de moto)
- Card laranja: Custo total de entregas

**Cálculo**:
```sql
SELECT 
  delivery_type,
  COUNT(*) as total,
  SUM(final_amount) as revenue,
  SUM(delivery_cost) as total_delivery_cost,
  AVG(final_amount) as avg_ticket
FROM sales
WHERE sale_date BETWEEN ? AND ?
GROUP BY delivery_type
```

### 4. 📈 Card: Produtos Mais Vendidos (ATUALIZADO)

**Localização**: Quarto card (já existia, mas melhorado)

**Novos Dados Adicionados**:
- ✅ **Custo do Produto**: Quanto custou produzir
- ✅ **Custo Total**: Custo × quantidade vendida
- ✅ **Lucro Total**: (Preço - Custo) × quantidade
- ✅ **Imagem do Produto**: URL da imagem

**Métricas**:
- Quantidade vendida
- Faturamento total
- Lucro total por produto
- Número de pedidos

### 5. 📉 Card: Produtos Menos Vendidos (NOVO)

**Localização**: Quinto card

**Objetivo**: Identificar produtos que não estão vendendo bem

**Métricas**:
- Produtos ativos com menor quantidade vendida
- Faturamento baixo
- Alerta visual (vermelho)

**Visual**:
- Cards vermelhos com ícone de alerta
- Sugestão: "Considere promover estes produtos ou revisar o cardápio"

**Cálculo**:
```sql
SELECT 
  p.name,
  p.category,
  COALESCE(SUM(si.quantity), 0) as total_quantity,
  COALESCE(SUM(si.quantity * si.unit_price), 0) as total_revenue
FROM products p
LEFT JOIN sale_items si ON p.id = si.product_id
LEFT JOIN sales s ON si.sale_id = s.id
WHERE p.is_active = 1
GROUP BY p.id
ORDER BY total_quantity ASC
LIMIT 5
```

## 🔧 Arquivos Modificados

### 1. `lib/features/reports/data/repositories/reports_repository.dart`

**Novos Métodos**:
```dart
// Vendas por canal (iFood vs Local)
Future<Map<String, dynamic>> getSalesByChannel({
  required DateTime startDate,
  required DateTime endDate,
})

// Análise de entregas
Future<Map<String, dynamic>> getDeliveryAnalysis({
  required DateTime startDate,
  required DateTime endDate,
})

// Análise de custos e lucro
Future<Map<String, dynamic>> getCostAnalysis({
  required DateTime startDate,
  required DateTime endDate,
})

// Produtos menos vendidos
Future<List<Map<String, dynamic>>> getLeastSellingProducts({
  required DateTime startDate,
  required DateTime endDate,
  int limit = 5,
})
```

**Método Atualizado**:
```dart
// getTopSellingProducts: Adicionados campos de custo e lucro
Future<List<Map<String, dynamic>>> getTopSellingProducts({
  required DateTime startDate,
  required DateTime endDate,
  int limit = 10,
})
// Agora retorna: cost, total_cost, total_profit, image_url, num_orders
```

### 2. `lib/features/reports/presentation/providers/reports_provider.dart`

**Novos Campos no ReportsState**:
```dart
final Map<String, dynamic>? channelAnalysis;
final Map<String, dynamic>? deliveryAnalysis;
final Map<String, dynamic>? costAnalysis;
final List<Map<String, dynamic>> leastProducts;
```

**Método loadReports() Atualizado**:
- Agora carrega 10 queries em paralelo (antes eram 6)
- Inclui análises de canal, entrega, custos e produtos menos vendidos

### 3. `lib/features/reports/presentation/screens/reports_screen.dart`

**Novos Métodos Builders**:
```dart
// Card de análise de custos e lucro
Widget _buildCostAnalysisCard(
  BuildContext context,
  Map<String, dynamic> costData,
)

// Card de vendas por canal
Widget _buildChannelAnalysisCard(
  BuildContext context,
  Map<String, dynamic> channelData,
)

// Card de análise de entregas
Widget _buildDeliveryAnalysisCard(
  BuildContext context,
  Map<String, dynamic> deliveryData,
)

// Card de produtos menos vendidos
Widget _buildLeastProducts(BuildContext context, ReportsState state)

// Helper para colunas de métricas
Widget _buildMetricColumn(
  String label,
  String value,
  Color color,
  IconData icon,
)
```

**Nova Ordem dos Cards**:
1. Resumo (já existia)
2. Comparação com período anterior (já existia)
3. **🆕 Análise de Custos e Lucro**
4. **🆕 Vendas por Canal (iFood vs Local)**
5. **🆕 Análise de Entregas**
6. Produtos Mais Vendidos (atualizado)
7. **🆕 Produtos Menos Vendidos**
8. Vendas por Categoria (já existia)
9. Vendas por Período do Dia (já existia)

## 🎯 Como Usar

### 1. Configurar Custos dos Produtos

Antes de usar a análise de custos, cadastre o custo de cada produto:

1. Ir em **Produtos**
2. Editar produto
3. Preencher campo **"Custo"** (quanto você gasta para produzir)
4. Exemplo:
   - Hot Roll: Preço R$ 15,00 / Custo R$ 6,00 → Lucro R$ 9,00 (60%)
   - Temaki: Preço R$ 20,00 / Custo R$ 8,00 → Lucro R$ 12,00 (60%)

### 2. Fazer Vendas com Informações Completas

Na tela de **Lançamento Rápido**:
- ✅ Marcar "Venda iFood" se for pedido do iFood
- ✅ Escolher tipo: "Retirada" ou "Entrega"
- ✅ Se entrega, informar taxa do motoboy (ex: R$ 5,00)

### 3. Visualizar Relatórios

Ir em **Relatórios** e escolher período:
- **Hoje**: Vendas do dia atual
- **7 dias**: Última semana
- **Mês**: Último mês
- **Personalizado**: Escolher datas específicas

### 4. Interpretar os Dados

**Card de Custos**:
- 🟢 Margem > 30%: Ótimo! Continue assim
- 🟠 Margem 15-30%: Pode melhorar (negociar fornecedores, ajustar preços)
- 🔴 Margem < 15%: Crítico! Revisar custos urgente

**Card de Canais**:
- Se iFood > 40%: Você depende muito do app (taxas altas)
- Se iFood < 10%: Oportunidade de crescer no app
- Ideal: 70% local + 30% iFood

**Card de Entregas**:
- Compare: Faturamento entrega vs custo de motoboy
- Se custo > 20% do faturamento de entregas: Taxa de entrega está baixa

**Produtos Menos Vendidos**:
- Se aparecer: Criar promoções
- Ou: Remover do cardápio (limpar estoque de ingredientes)

## 📈 Exemplo de Análise Completa

**Cenário: Restaurante em 1 semana**

### Card 1: Custos e Lucro
```
Faturamento: R$ 3.500,00
Custo Total: R$ 1.400,00 (40%)
Lucro Líquido: R$ 1.980,00
Margem: 56,6% 🟢
Custo de Entregas: R$ 120,00
```

**Interpretação**: Excelente margem! Continue controlando custos.

### Card 2: Vendas por Canal
```
Local: 45 vendas (R$ 2.450,00) - 70%
iFood: 18 vendas (R$ 1.050,00) - 30%
```

**Interpretação**: Balanceado. iFood representa 30%, ideal.

### Card 3: Entregas
```
Retiradas: 52 pedidos (R$ 2.900,00)
Entregas: 11 pedidos (R$ 600,00)
Custo de Entregas: R$ 120,00 (20% do faturamento)
```

**Interpretação**: Taxa de entrega está adequada (R$ 10-12/entrega).

### Card 4: Top Produtos
```
1. Hot Roll - 45 unidades (R$ 675,00 / Lucro R$ 405,00)
2. Temaki Salmão - 32 unidades (R$ 640,00 / Lucro R$ 384,00)
3. Combo Sushi - 18 unidades (R$ 720,00 / Lucro R$ 360,00)
```

**Interpretação**: Hot Roll é campeão de vendas. Sempre ter ingredientes.

### Card 5: Produtos Fracos
```
1. Sashimi Premium - 2 unidades (R$ 90,00)
2. Yakisoba Vegetariano - 3 unidades (R$ 75,00)
3. Sunomono - 4 unidades (R$ 40,00)
```

**Interpretação**: Criar combo "Sashimi + Temaki" para impulsionar. Considerar remover Sunomono.

## ✅ Status da Implementação

- ✅ Queries SQL criadas e testadas
- ✅ ReportsProvider atualizado
- ✅ 4 novos cards na UI
- ✅ Cores e ícones inteligentes
- ✅ Sem erros de compilação
- ✅ Pronto para uso

## 🚀 Próximos Passos Sugeridos

1. **Testar com Dados Reais**:
   - Cadastrar custos dos produtos
   - Fazer 10-15 vendas variadas
   - Verificar relatórios

2. **Possíveis Melhorias Futuras**:
   - Gráficos de pizza (vendas por canal)
   - Linha do tempo (evolução diária)
   - Exportar relatórios em PDF
   - Comparar lucro por período
   - Alertas automáticos (margem baixa)

3. **Firebase (próxima etapa)**:
   - Sincronizar dados entre dispositivos
   - Backup automático
   - Acesso web (visualizar de qualquer lugar)
