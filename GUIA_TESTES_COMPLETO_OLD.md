# 🧪 Guia de Testes Completo - SushiGen

**Data**: 03/02/2026  
**Versão**: 1.2 (Produtos + Relatórios)  
**Status**: ✅ App rodando no macOS

---

## 📋 **ROTEIRO DE TESTES**

### 🔐 **TESTE 1: Login com Licença Inteligente**

1. **Se estiver logado, faça logout:**
   - Abra o menu lateral (☰)
   - Clique em "Sair"

2. **Tela de Login:**
   - Digite: **admin**
   - Aguarde 1-2 segundos
   - ✅ Campo de licença deve preencher e bloquear automaticamente
   - ✅ Contador verde deve aparecer: "✅ Ativa - 364 dias restantes"
   - Digite a senha: **admin123**
   - Clique em **ENTRAR**

**✅ Resultado esperado:** Dashboard aparece

---

### 📊 **TESTE 2: Dashboard**

1. **Verifique os 4 cards de resumo:**
   - Vendas Hoje
   - Faturamento Hoje
   - Produtos
   - Ticket Médio

2. **Verifique os 6 botões de ação:**
   - Nova Venda
   - Produtos ← **NOVO!**
   - Relatórios ← **NOVO!**
   - Estoque
   - Fluxo de Caixa
   - Configurações

**✅ Todos devem estar visíveis**

---

### 📦 **TESTE 3: Gestão de Produtos** ⭐ **NOVO**

#### 3.1 - Acessar Produtos
1. No Dashboard, clique em **"Produtos"**
2. ✅ Deve abrir tela de produtos (provavelmente vazia)

#### 3.2 - Criar Primeiro Produto
1. Clique no botão flutuante **"+ Novo Produto"**
2. Preencha o formulário:
   ```
   Nome: Sushi Philadelphia
   Descrição: Salmão, cream cheese e cebolinha
   Categoria: Sushi (dropdown)
   Preço: 25.00
   Custo: 12.00
   Tempo de Preparo: 15
   URL da Imagem: (deixe vazio)
   ```
3. Clique em **"CRIAR PRODUTO"**
4. ✅ Mensagem: "✅ Produto criado com sucesso"
5. ✅ Produto aparece na lista

#### 3.3 - Criar Mais Produtos
Crie mais 5 produtos para testar melhor:

**Produto 2:**
```
Nome: Temaki de Salmão
Descrição: Cone de alga com arroz, salmão e gergelim
Categoria: Temaki
Preço: 18.00
Custo: 8.00
Tempo: 10
```

**Produto 3:**
```
Nome: Hot Roll Philadelphia
Descrição: Salmão empanado e cream cheese
Categoria: Hot Rolls
Preço: 28.00
Custo: 14.00
Tempo: 20
```

**Produto 4:**
```
Nome: Sashimi Salmão
Descrição: 10 fatias de salmão fresco
Categoria: Sashimi
Preço: 35.00
Custo: 18.00
Tempo: 5
```

**Produto 5:**
```
Nome: Yakisoba Misto
Descrição: Macarrão com legumes e carnes
Categoria: Yakisoba
Preço: 22.00
Custo: 10.00
Tempo: 25
```

**Produto 6:**
```
Nome: Coca-Cola Lata
Descrição: Refrigerante 350ml
Categoria: Bebidas
Preço: 5.00
Custo: 2.50
Tempo: 1
```

#### 3.4 - Testar Busca
1. No campo de busca, digite: **salmão**
2. ✅ Deve filtrar e mostrar apenas produtos com "salmão" no nome/descrição
3. Limpe a busca (X no campo)

#### 3.5 - Testar Filtros de Categoria
1. Observe os chips horizontais: **Todas | Sushi | Temaki | Hot Rolls | ...**
2. Clique em **"Sushi"**
3. ✅ Deve mostrar apenas produtos da categoria Sushi
4. Clique em **"Todas"** para voltar

#### 3.6 - Editar Produto
1. Clique nos **3 pontinhos (⋮)** de um produto
2. Clique em **"Editar"**
3. Altere o preço para **30.00**
4. Clique em **"SALVAR ALTERAÇÕES"**
5. ✅ Mensagem: "✅ Produto atualizado com sucesso"
6. ✅ Preço atualizado na lista

#### 3.7 - Excluir Produto (opcional)
1. Clique nos **3 pontinhos (⋮)** de um produto
2. Clique em **"Excluir"**
3. Confirme no dialog
4. ✅ Produto removido da lista

---

### 🛒 **TESTE 4: Fazer Vendas para Testar Relatórios**

Vamos fazer algumas vendas para ter dados nos relatórios!

#### 4.1 - Venda 1
1. No Dashboard, clique em **"Nova Venda"**
2. Adicione:
   - 2x Sushi Philadelphia
   - 1x Coca-Cola
3. ✅ Total deve calcular: R$ 55,00 (2×25 + 1×5)
4. Clique em **"FINALIZAR VENDA"**
5. ✅ Mensagem com número da venda

#### 4.2 - Venda 2
1. Volte para o Dashboard
2. Clique em **"Nova Venda"** novamente
3. Adicione:
   - 1x Hot Roll Philadelphia
   - 1x Temaki de Salmão
   - 1x Coca-Cola
4. ✅ Total: R$ 51,00 (28 + 18 + 5)
5. Finalize

#### 4.3 - Venda 3
1. Nova venda
2. Adicione:
   - 3x Sashimi Salmão
   - 2x Coca-Cola
4. ✅ Total: R$ 115,00 (3×35 + 2×5)
5. Finalize

#### 4.4 - Venda 4
1. Nova venda
2. Adicione:
   - 1x Yakisoba Misto
   - 1x Coca-Cola
3. ✅ Total: R$ 27,00
4. Finalize

**✅ Agora temos 4 vendas para analisar nos relatórios!**

---

### 📊 **TESTE 5: Relatórios e Analytics** ⭐ **NOVO**

#### 5.1 - Acessar Relatórios
1. Volte ao Dashboard
2. Clique em **"Relatórios"**
3. ✅ Tela de relatórios deve abrir

#### 5.2 - Verificar Seletor de Período
1. No topo, veja os 3 botões: **[Hoje] [7 dias] [30 dias]**
2. ✅ "Hoje" deve estar selecionado (vermelho)

#### 5.3 - Verificar Cards de Resumo
Você deve ver 4 cards com:
```
┌────────────────┐  ┌────────────────┐
│ 📦 Vendas      │  │ 💰 Faturamento │
│    4           │  │  R$ 248,00     │
└────────────────┘  └────────────────┘
┌────────────────┐  ┌────────────────┐
│ 📊 Ticket      │  │ ⭐ Maior       │
│  R$ 62,00      │  │  R$ 115,00     │
└────────────────┘  └────────────────┘
```

**✅ Valores devem corresponder às vendas que você fez**

#### 5.4 - Verificar Comparação
Logo abaixo, deve ter um card:
```
🔄 Comparação com Período Anterior
Vendas: ↑ 100%    Faturamento: ↑ 100%
```
(Se ontem você não vendeu nada, crescimento é 100%)

#### 5.5 - Verificar Produtos Mais Vendidos
Você deve ver uma lista ranqueada:
```
🏆 Produtos Mais Vendidos
1️⃣ Sashimi Salmão       3 un • R$ 105,00
2️⃣ Coca-Cola Lata       5 un • R$ 25,00
3️⃣ Sushi Philadelphia   2 un • R$ 50,00
...
```

**✅ Verifique se as quantidades batem**

#### 5.6 - Verificar Vendas por Categoria
Barras de progresso mostrando:
```
🎯 Vendas por Categoria
Sashimi  ████████████ 100%  R$ 105,00
Sushi    ████████░░░░  48%  R$ 50,00
Hot Rolls ████████░░░░  27%  R$ 28,00
...
```

#### 5.7 - Verificar Período do Dia
Ícones temáticos mostrando quando você vendeu:
```
🌅 Vendas por Período do Dia
☀️ Manhã   0 vendas  R$ 0,00
☁️ Tarde    4 vendas  R$ 248,00  ← Você vendeu à tarde
🌙 Noite    0 vendas  R$ 0,00
```

#### 5.8 - Testar Filtro de Período
1. Clique em **"7 dias"**
2. ✅ Dados devem recarregar (mesmos valores se vendeu só hoje)
3. Clique em **"30 dias"**
4. ✅ Idem
5. Volte para **"Hoje"**

#### 5.9 - Testar Pull to Refresh
1. Arraste a tela para baixo
2. ✅ Indicador de loading aparece
3. ✅ Dados recarregam

---

### 🎯 **TESTE 6: Navegação Completa**

#### 6.1 - Menu Lateral
1. Abra o menu (☰)
2. Teste cada opção:
   - Dashboard → ✅
   - Nova Venda → ✅
   - Produtos → ✅
   - Relatórios → ✅
   - Renovar Licença → ✅

#### 6.2 - Botão Voltar
1. De qualquer tela, clique na seta ← do topo
2. ✅ Deve voltar para a tela anterior

---

## 📝 **CHECKLIST FINAL**

Marque conforme for testando:

### Sistema de Licenciamento
- [ ] Campo de licença desabilitado ao digitar "admin"
- [ ] Contador de dias verde aparece
- [ ] Login funciona apenas com senha

### Dashboard
- [ ] 4 cards de resumo exibidos corretamente
- [ ] 6 botões de ação funcionam
- [ ] Menu lateral abre

### Gestão de Produtos
- [ ] Criar produto funciona
- [ ] Lista de produtos aparece
- [ ] Busca filtra corretamente
- [ ] Filtros por categoria funcionam
- [ ] Editar produto atualiza
- [ ] Excluir produto remove da lista
- [ ] Cards mostram imagem/ícone corretamente

### Sistema de Vendas
- [ ] Adicionar produtos ao carrinho
- [ ] Quantidade incrementa/decrementa
- [ ] Total calcula corretamente
- [ ] Finalizar venda salva no banco
- [ ] Mensagem de sucesso aparece
- [ ] Carrinho limpa após venda

### Relatórios
- [ ] Cards de resumo mostram valores corretos
- [ ] Comparação com período anterior funciona
- [ ] Produtos mais vendidos listados corretamente
- [ ] Vendas por categoria com barras de progresso
- [ ] Vendas por período do dia com ícones
- [ ] Seletor de período (Hoje/7d/30d) funciona
- [ ] Pull to refresh recarrega dados

---

## 🐛 **ENCONTROU ALGUM PROBLEMA?**

Anote aqui:
1. **O que você estava fazendo?**
2. **O que aconteceu?**
3. **O que deveria ter acontecido?**

---

## ✅ **TUDO FUNCIONANDO?**

Se todos os testes passaram, temos:
- ✅ Sistema de licenciamento inteligente
- ✅ Gestão completa de produtos (CRUD)
- ✅ Sistema de vendas rápidas
- ✅ Relatórios e analytics completos
- ✅ 12 etapas concluídas!

**Próximos passos sugeridos:**
1. Implementar formas de pagamento
2. Sistema de descontos
3. Gestão de estoque
4. Fluxo de caixa avançado

---

**Divirta-se testando! 🎉**
