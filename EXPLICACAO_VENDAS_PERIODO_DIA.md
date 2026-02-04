# Explicação: Relatório "Vendas por Período do Dia"

## O que é?

O relatório **"Vendas por Período do Dia"** é uma análise que divide as vendas em 4 períodos fixos:

```
┌──────────────┬─────────────────┬──────────┬────────────┐
│   Período    │     Horário     │  Vendas  │ Faturamento│
├──────────────┼─────────────────┼──────────┼────────────┤
│ Manhã        │ 06:00 - 11:59   │    15    │ R$ 450,00  │
│ Tarde        │ 12:00 - 17:59   │    32    │ R$ 1.280,00│
│ Noite        │ 18:00 - 22:59   │    48    │ R$ 2.400,00│
│ Madrugada    │ 23:00 - 05:59   │     5    │ R$ 125,00  │
└──────────────┴─────────────────┴──────────┴────────────┘
```

## Como Funciona?

### 1. Divisão dos Períodos

O dia é dividido em 4 períodos baseados no horário da venda:

| Período    | Horário Inicial | Horário Final | Típico de           |
|------------|----------------|---------------|---------------------|
| Manhã      | 06:00          | 11:59         | Café da manhã, almoço cedo |
| Tarde      | 12:00          | 17:59         | Almoço, lanche      |
| Noite      | 18:00          | 22:59         | Jantar, movimento principal |
| Madrugada  | 23:00          | 05:59         | Delivery tarde, festas |

### 2. Query SQL

```sql
SELECT 
  CASE 
    WHEN CAST(strftime('%H', sale_date) AS INTEGER) BETWEEN 6 AND 11 
      THEN 'Manhã'
    WHEN CAST(strftime('%H', sale_date) AS INTEGER) BETWEEN 12 AND 17 
      THEN 'Tarde'
    WHEN CAST(strftime('%H', sale_date) AS INTEGER) BETWEEN 18 AND 22 
      THEN 'Noite'
    ELSE 'Madrugada'
  END as period,
  COUNT(*) as total_sales,
  COALESCE(SUM(final_amount), 0) as total_revenue
FROM sales
WHERE sale_date BETWEEN ? AND ?
GROUP BY period
ORDER BY 
  CASE period
    WHEN 'Manhã' THEN 1
    WHEN 'Tarde' THEN 2
    WHEN 'Noite' THEN 3
    ELSE 4
  END
```

### 3. Extração da Hora

```dart
strftime('%H', sale_date)  // Extrai hora no formato 24h
// Exemplos:
// 2026-02-03 08:30:00 → "08"
// 2026-02-03 19:45:00 → "19"
// 2026-02-03 23:15:00 → "23"
```

## Para Que Serve?

### 📊 Análise de Pico de Movimento

**Objetivo**: Identificar quando o restaurante tem mais clientes

**Exemplo Prático**:
```
Noite: 48 vendas (60% do total)
Tarde: 32 vendas (40%)
Manhã: 15 vendas (18%)
Madrugada: 5 vendas (6%)
```

**Conclusão**: O movimento concentra-se no período noturno (jantar).

### 💰 Distribuição do Faturamento

**Objetivo**: Saber qual período gera mais receita

**Exemplo Prático**:
```
Noite:      R$ 2.400,00 (57%)  ← Maior faturamento
Tarde:      R$ 1.280,00 (30%)
Manhã:      R$   450,00 (11%)
Madrugada:  R$   125,00 (3%)
```

**Conclusão**: 87% da receita vem do almoço e jantar.

### 👥 Planejamento de Equipe

**Decisão**: Quantos funcionários escalar em cada período?

**Análise**:
- **Noite (18h-23h)**: 48 vendas → precisa de 3-4 atendentes
- **Tarde (12h-18h)**: 32 vendas → precisa de 2-3 atendentes
- **Manhã (6h-12h)**: 15 vendas → 1-2 atendentes suficiente
- **Madrugada (23h-6h)**: 5 vendas → 1 atendente ou fechar

**Economia**: Evita ter muitos funcionários em períodos vazios.

### 📦 Gestão de Estoque

**Decisão**: Quando preparar mais produtos?

**Análise**:
```
Noite = 48 vendas
Preparar mais sushi às 17h para o jantar
Preparar menos às 9h (manhã tem pouco movimento)
```

**Vantagem**: 
- Menos desperdício
- Produtos sempre frescos
- Evita faltar ingrediente no pico

### 💡 Estratégias de Marketing

#### 1. Promoções para Períodos Vazios

**Problema**: Manhã tem apenas 15 vendas
**Solução**: "Happy Hour da Manhã - 20% OFF até 12h"

**Resultado Esperado**:
- Aumentar vendas manhã de 15 → 25 (+66%)
- Distribuir melhor o movimento
- Usar capacidade ociosa

#### 2. Combos para Horários Específicos

**Tarde (12h-18h)**: "Combo Executivo" R$ 35,00
- Almoço rápido para quem trabalha
- Aumenta ticket médio

**Noite (18h-23h)**: "Rodízio Premium" R$ 79,90
- Aproveita movimento alto
- Maior margem de lucro

#### 3. Delivery Estratégico

**Análise**:
```
Madrugada: 5 vendas (baixo)
```

**Decisão**: 
- Oferecer delivery 24h?
- Ou fechar após 23h para economizar?

**Cálculo**:
```
Receita madrugada: R$ 125,00
Custo funcionário noturno: R$ 200,00
Prejuízo: -R$ 75,00
```

**Conclusão**: Fechar às 23h e reabrir às 6h.

### 📈 Comparação com Metas

**Meta mensal**: Aumentar vendas noturnas em 20%

**Acompanhamento**:
```
Semana 1:
Noite atual: 48 vendas
Noite meta: 58 vendas (48 × 1.20)
Faltam: 10 vendas para bater meta
```

**Ação**: Promoção "Sextas à Noite - Sobremesa Grátis"

### 🍣 Cardápio Otimizado

**Análise de Produtos por Período**:

**Manhã**: 
- Nigiri simples
- Temaki pequeno
- Combo café da manhã

**Tarde**: 
- Combo executivo
- Sushi tradicional
- Rápido de preparar

**Noite**: 
- Rodízio completo
- Pratos especiais
- Sobremesas premium

**Madrugada**: 
- Apenas delivery
- Produtos fáceis de preparar
- Menor variedade

## Visualização no Sistema

### Card do Relatório

```dart
Card(
  child: Column(
    children: [
      // Cabeçalho
      Text('VENDAS POR PERÍODO DO DIA'),
      
      // Linha por período
      _buildPeriodRow('Manhã', 15, 450.00, totalSales),
      _buildPeriodRow('Tarde', 32, 1280.00, totalSales),
      _buildPeriodRow('Noite', 48, 2400.00, totalSales),
      _buildPeriodRow('Madrugada', 5, 125.00, totalSales),
      
      // Total
      Divider(),
      _buildTotalRow('TOTAL', 100, 4255.00),
    ],
  ),
)
```

### Cada Linha Mostra

```
┌──────────────────────────────────────┐
│ 🌙 Noite                       48%   │
│ 48 vendas • R$ 2.400,00              │
│ ████████████████████████░░░░░░░░░░   │ ← Barra de progresso
└──────────────────────────────────────┘
```

**Informações**:
- Ícone do período (☀️ 🌤️ 🌙 🌑)
- Nome do período
- Percentual do total
- Quantidade de vendas
- Faturamento
- Barra visual de proporção

## Exemplo Real de Uso

### Cenário: Restaurante de Sushi

**Situação Inicial** (sem análise):
```
Aberto: 10h às 23h (13 horas)
Equipe: 3 pessoas o dia todo
Faturamento: R$ 4.000,00/dia
```

**Após Análise do Relatório**:
```
Descoberta:
- 60% vendas entre 18h-23h
- 30% vendas entre 12h-18h
- 10% vendas entre 10h-12h
```

**Mudanças Implementadas**:

1. **Horário Otimizado**
   - Abrir às 11h (não 10h)
   - Fechar às 23h (mantém)
   - Economia: 1 hora de funcionamento

2. **Escala de Equipe**
   - 11h-18h: 2 pessoas (não precisa 3)
   - 18h-23h: 4 pessoas (pico precisa mais)
   - Economia: Salário mais eficiente

3. **Promoção Manhã/Tarde**
   - "Almoço Express" 11h-14h: R$ 29,90
   - Aumento vendas tarde: 32 → 40 (+25%)

4. **Foco no Jantar**
   - Menu premium 18h-23h
   - Ticket médio noite: R$ 50 → R$ 65
   - Aumento faturamento: R$ 720,00

**Resultado Final**:
```
Faturamento novo: R$ 5.220,00/dia (+30%)
Custos mantidos (equipe otimizada)
Lucro aumentou significativamente
```

## Perguntas que o Relatório Responde

1. **Qual o melhor horário para fazer promoção?**
   → Períodos com menos movimento (manhã/madrugada)

2. **Quantos funcionários preciso em cada período?**
   → Proporcionalmente às vendas

3. **Vale a pena abrir 24 horas?**
   → Se madrugada tem < 5% vendas, não vale

4. **Quando devo preparar mais comida?**
   → 1-2 horas antes do pico (preparar às 17h para jantar)

5. **Qual período dá mais lucro?**
   → Compare faturamento com custos de cada período

6. **Devo focar almoço ou jantar?**
   → O que tem maior % de faturamento

7. **Quanto custa cada período para mim?**
   → Faturamento ÷ custos operacionais

8. **Posso reduzir horário sem perder dinheiro?**
   → Sim, se períodos extremos têm < 5% faturamento

## Conclusão

O relatório **"Vendas por Período do Dia"** é essencial para:

✅ **Otimizar recursos** (funcionários, estoque, energia)
✅ **Aumentar lucro** (focar nos horários certos)
✅ **Reduzir desperdício** (preparar comida na hora certa)
✅ **Melhorar atendimento** (equipe certa no pico)
✅ **Planejar marketing** (promoções estratégicas)

**É como um raio-X do seu dia**, mostrando exatamente quando você vende mais e onde pode melhorar! 📊🍣
