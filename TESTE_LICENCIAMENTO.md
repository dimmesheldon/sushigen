# 🧪 Como Testar o Novo Sistema de Licenciamento

## 📋 Pré-requisitos
- App SushiGen rodando
- Usuário já criado: `admin` / `admin123`
- Chave de licença: `1A56-0FD1-4814-E762`

---

## 🔍 TESTE 1: Primeiro Login com Licença Ativa

### Passos:
1. Abra o app (ele já está rodando)
2. Na tela de login, digite: **admin**
3. **Aguarde 1 segundo** (sistema busca licença automaticamente)
4. Observe o campo "Chave de Licença"

### ✅ Resultado Esperado:
- Campo preenchido com: `1A56-0FD1-4814-E762`
- Campo **desabilitado** (acinzentado, com ícone de cadeado 🔒)
- Aparece abaixo: **"✅ Ativa - 364 dias restantes"** (em verde)
- Você só precisa digitar a **senha**

### 📸 Visual:
```
┌─────────────────────────────────────┐
│ ID do Usuário: [admin           ]  │
│ Senha: [                        ]  │ ← Digite aqui
│ Chave de Licença: [1A56-0FD1... ]🔒│ ← Bloqueado
│ ┌──────────────────────────────┐   │
│ │ ✅ Ativa - 364 dias restantes│   │ ← Verde
│ └──────────────────────────────┘   │
│          [  ENTRAR  ]              │
└─────────────────────────────────────┘
```

5. Digite a senha: **admin123**
6. Clique em **ENTRAR**

### ✅ Resultado Final:
- Acesso ao **Dashboard** sem pedir a chave novamente

---

## 🔍 TESTE 2: Navegação no Dashboard

### Passos:
1. Após fazer login, você estará no Dashboard
2. Observe os **4 cards de resumo**:
   - Vendas Hoje
   - Faturamento Hoje
   - Produtos
   - Ticket Médio

3. Clique no **ícone do menu** (☰) no canto superior esquerdo

### ✅ Resultado Esperado:
Menu lateral com as opções:
```
Dashboard
Nova Venda
Produtos
Relatórios
─────────────────
🔑 Renovar Licença  ← Nova opção!
Sair
```

4. **NÃO CLIQUE** em "Renovar Licença" ainda

---

## 🔍 TESTE 3: Acessar Renovação pelo Dashboard

### Passos:
1. No Dashboard, role a tela para baixo
2. Encontre o card **"Configurações"** (ícone de engrenagem ⚙️)
3. Clique nele

### ✅ Resultado Esperado:
- Abre um **modal na parte inferior** da tela
- Com 2 opções:
  - 🔑 **Renovar Licença** - "Atualizar chave de acesso"
  - ℹ️ **Sobre o Sistema** - "Versão 1.0.0"

4. Clique em **"Renovar Licença"**

---

## 🔍 TESTE 4: Tela de Renovação de Licença

### Passos:
1. Você foi redirecionado para a **Tela de Renovação**
2. Observe a interface

### ✅ Resultado Esperado:
```
┌─────────────────────────────────────┐
│ ← Renovar Licença                   │
├─────────────────────────────────────┤
│ ℹ️ Status da Licença Atual           │
│ ─────────────────────────────────   │
│ 🔑 Chave: 1A56-0FD1-4814-E762       │
│ 📅 Expira em: 03/02/2027            │
│ ┌──────────────────────────────┐   │
│ │ ✅ Ativa - 364 dias restantes│   │ Verde
│ └──────────────────────────────┘   │
├─────────────────────────────────────┤
│ 💡 Digite a nova chave...           │
├─────────────────────────────────────┤
│ Nova Chave de Licença:              │
│ [                               ]   │
│          [🔄 RENOVAR LICENÇA]       │
└─────────────────────────────────────┘
```

3. **NÃO digite nada**, apenas observe
4. Clique na **seta voltar** (← no topo)

---

## 🔍 TESTE 5: Fazer Logout e Logar Novamente

### Passos:
1. Abra o **menu lateral** (☰)
2. Clique em **"Sair"**
3. Você voltará para a **tela de login**

### ✅ Resultado Esperado:
- Campos vazios
- Campo de licença **habilitado**

4. Digite novamente: **admin**
5. **Aguarde 1 segundo**

### ✅ Resultado Esperado:
- Campo de licença **preenchido automaticamente**
- Campo **desabilitado** novamente
- Contador de dias aparece

6. Digite a senha: **admin123**
7. Faça login

### ✅ Resultado Final:
- **Não precisou digitar a chave** novamente!

---

## 🔍 TESTE 6: Código de Cores (Simulação)

**Este teste é visual - apenas para entender o funcionamento**

### Cenários:

#### 🟢 **Mais de 30 dias** (seu caso atual)
```
┌──────────────────────────────┐
│ ✅ Ativa - 364 dias restantes│ Verde
└──────────────────────────────┘
```

#### 🟡 **Entre 8 e 30 dias**
```
┌──────────────────────────────┐
│ ⏰ Expira em 15 dias         │ Amarelo
└──────────────────────────────┘
```

#### 🟠 **7 dias ou menos**
```
┌──────────────────────────────┐
│ ⚠️ Expira em 3 dias          │ Laranja
└──────────────────────────────┘
```

#### 🔴 **Expirada**
```
┌──────────────────────────────┐
│ ⚠️ Licença expirada!         │ Vermelho
└──────────────────────────────┘
```

---

## 🔍 TESTE 7: Nova Venda Rápida (já funcionando)

### Passos:
1. No Dashboard, clique em **"Nova Venda"**
2. Adicione alguns produtos
3. Clique em **"FINALIZAR VENDA"**

### ✅ Resultado Esperado:
- Mensagem: "✅ Venda #X finalizada com sucesso!"
- Carrinho zerado
- Venda salva no banco

---

## 📝 Checklist de Testes

Marque conforme for testando:

- [ ] **TESTE 1**: Campo de licença desabilitado ao digitar "admin"
- [ ] **TESTE 1**: Contador de dias verde aparece
- [ ] **TESTE 1**: Login bem-sucedido apenas com senha
- [ ] **TESTE 2**: Menu lateral exibe "🔑 Renovar Licença"
- [ ] **TESTE 3**: Modal de configurações abre corretamente
- [ ] **TESTE 4**: Tela de renovação exibe status completo
- [ ] **TESTE 4**: Dados da licença estão corretos
- [ ] **TESTE 5**: Após logout, login não pede chave novamente
- [ ] **TESTE 7**: Nova venda funciona normalmente

---

## ❌ Problemas Encontrados?

### Se o campo de licença não desabilitar:
1. Certifique-se de ter digitado **admin** (exatamente)
2. Aguarde pelo menos **1-2 segundos**
3. Se não funcionar, tente fechar e abrir o app

### Se aparecer erro ao abrir Dashboard:
- Já foi corrigido! Se aparecer, me avise.

### Se a tela de renovação não abrir:
1. Verifique se clicou na opção correta
2. Tente pelo menu lateral em vez do card de configurações

---

## ✅ Tudo Funcionando?

**Se todos os testes passaram:**
- Sistema de licenciamento está **100% funcional**!
- Você pode usar o app normalmente
- A chave **nunca mais** será pedida (enquanto válida)

**Próximos passos:**
- Implementar gestão de produtos (criar/editar/deletar)
- Criar telas de relatórios
- Implementar gestão de estoque

---

## 📞 Dúvidas?

Se algo não funcionou como esperado, anote:
1. Qual teste falhou
2. O que aconteceu
3. Qual era o resultado esperado

---

**Data**: 03/02/2026  
**Versão**: 1.0  
**Status do App**: ✅ Rodando no macOS
