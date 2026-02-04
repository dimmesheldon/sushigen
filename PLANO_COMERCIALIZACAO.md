# 💼 Plano de Comercialização - SushiGen

**Data**: 2026-02-03  
**Versão**: 1.0

---

## 🎯 Visão Geral

O SushiGen será comercializado como **software por licença** com sistema de assinatura mensal ou anual.

---

## 💰 Modelo de Negócio Sugerido

### Opção 1: Licença Perpétua
- **R$ 497,00** pagamento único
- Atualizações gratuitas por 1 ano
- Suporte técnico por 1 ano
- Renovação anual: R$ 97,00 (opcional)

### Opção 2: Assinatura Mensal
- **R$ 49,90/mês**
- Atualizações automáticas
- Suporte técnico ilimitado
- Cancela quando quiser

### Opção 3: Assinatura Anual (Recomendado)
- **R$ 497,00/ano** (R$ 41,42/mês)
- 2 meses grátis vs mensal
- Atualizações automáticas
- Suporte prioritário
- Backup na nuvem (Firebase)

---

## 🔑 Sistema de Licenciamento (ATUAL)

### Como Funciona Hoje:
1. **Gerar Licença**: Script `scripts/generate_license.dart`
2. **Chave gerada**: Baseada em username + dias de validade
3. **Validação**: Ao fazer login
4. **Bloqueio**: Após expiração

### Exemplo de Uso Atual:
```bash
# Gerar licença de 30 dias para cliente
dart scripts/generate_license.dart admin 30

# Output:
Username: admin
Dias: 30
Chave: ABC123XYZ789...
```

### Limitações Atuais:
- ❌ Geração manual via terminal
- ❌ Sem controle de quantas licenças foram geradas
- ❌ Sem histórico de clientes
- ❌ Sem renovação automática
- ❌ Sem painel administrativo

---

## 🚀 SOLUÇÃO: Sistema Administrativo Completo

Vou criar um **Painel Administrativo** no próprio SushiGen para você gerenciar tudo!

### Funcionalidades:

#### 1. **Tela de Admin (Nova)**
- Login especial de administrador
- Dashboard com estatísticas
- Gestão completa de licenças

#### 2. **Gestão de Clientes**
- Cadastrar novo cliente
- Editar dados do cliente
- Ver histórico de pagamentos
- Status da licença (ativa/expirada)

#### 3. **Gestão de Licenças**
- Gerar nova licença (30/90/365 dias)
- Renovar licença existente
- Revogar licença
- Ver todas as licenças ativas
- Exportar lista de clientes

#### 4. **Relatórios Administrativos**
- Total de licenças ativas
- Total de licenças expiradas
- Faturamento mensal
- Licenças a vencer (próximos 7 dias)
- Gráfico de crescimento

#### 5. **Geração Automática de Chaves**
- Interface gráfica (sem terminal!)
- Copiar chave com 1 clique
- Enviar chave por email (futuro)
- QR Code da licença (futuro)

---

## 🏗️ Arquitetura da Solução

### Banco de Dados (NOVO)

Adicionar tabelas:

```sql
-- Tabela de clientes (seus compradores)
CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT,
  business_name TEXT,
  cnpj TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Tabela de licenças vendidas
CREATE TABLE sold_licenses (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  license_key TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL,
  days INTEGER NOT NULL,
  start_date INTEGER NOT NULL,
  expiration_date INTEGER NOT NULL,
  status TEXT NOT NULL, -- 'active', 'expired', 'revoked'
  price REAL,
  payment_method TEXT,
  notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- Tabela de pagamentos
CREATE TABLE payments (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  license_id TEXT NOT NULL,
  amount REAL NOT NULL,
  payment_date INTEGER NOT NULL,
  payment_method TEXT,
  notes TEXT,
  FOREIGN KEY (customer_id) REFERENCES customers(id),
  FOREIGN KEY (license_id) REFERENCES sold_licenses(id)
);
```

### Estrutura de Pastas (NOVA)

```
lib/
  features/
    admin/              ← NOVO!
      data/
        models/
          customer_model.dart
          sold_license_model.dart
        repositories/
          admin_repository.dart
      domain/
        entities/
          customer.dart
      presentation/
        providers/
          admin_provider.dart
        screens/
          admin_login_screen.dart
          admin_dashboard_screen.dart
          customers_screen.dart
          licenses_screen.dart
          generate_license_screen.dart
        widgets/
          customer_card.dart
          license_card.dart
```

---

## 🎨 Fluxo de Uso

### Para VOCÊ (Administrador):

1. **Login Admin**
   - Username: `superadmin`
   - Senha: `sua-senha-forte`
   - Botão "Acesso Administrativo" na tela de login

2. **Dashboard Admin**
   - Ver resumo de licenças ativas/expiradas
   - Ver faturamento total
   - Alertas de licenças a vencer

3. **Cadastrar Cliente**
   - Nome, email, telefone, CNPJ
   - Escolher plano (30/90/365 dias)
   - Gerar licença automaticamente
   - Copiar chave para enviar ao cliente

4. **Gerenciar Licenças**
   - Ver todas as licenças
   - Renovar quando cliente pagar
   - Revogar se necessário

### Para o CLIENTE (Usuário Final):

1. **Recebe a Licença**
   - Você envia: Username + Senha + Chave de Licença

2. **Primeiro Acesso**
   - Digita username
   - Digita senha
   - Cola a chave de licença
   - Sistema valida e libera

3. **Uso Diário**
   - Faz login apenas com username + senha
   - Vê dias restantes no dashboard
   - Aviso quando estiver perto de expirar

4. **Renovação**
   - Cliente paga você
   - Você renova no painel admin
   - Cliente continua usando (sem precisar reinstalar)

---

## 📦 Como Vender

### Opção 1: Venda Direta
1. Cliente te contata (WhatsApp, email, site)
2. Você acessa o Painel Admin
3. Cadastra o cliente
4. Gera a licença
5. Envia as credenciais por WhatsApp/Email
6. Cliente instala o app e faz login

### Opção 2: Site de Vendas (Futuro)
1. Cliente compra no site
2. Pagamento via Mercado Pago/Stripe
3. Sistema gera licença automaticamente
4. Email automático com credenciais
5. Cliente baixa o app e usa

### Opção 3: Revendedores (Futuro)
1. Você vende licenças em lote
2. Revendedor tem acesso limitado ao admin
3. Ele gerencia os clientes dele
4. Você recebe comissão

---

## 💳 Formas de Pagamento Sugeridas

### Para Receber:
- **PIX**: Instantâneo, sem taxas
- **Mercado Pago**: Cartão, boleto (taxa ~4%)
- **PagSeguro**: Similar ao Mercado Pago
- **Transferência Bancária**: Sem taxas
- **PayPal**: Para clientes internacionais

### Integração Futura:
- Webhook do Mercado Pago
- Renovação automática no sistema
- Notificação por email

---

## 📧 Comunicação com Clientes

### Email de Boas-Vindas (Modelo):
```
Olá [NOME],

Seja bem-vindo ao SushiGen! 🍣

Seu acesso foi liberado com sucesso!

📋 SUAS CREDENCIAIS:
- Username: [USERNAME]
- Senha: [SENHA]
- Chave de Licença: [CHAVE]
- Validade: [DIAS] dias (até [DATA])

📥 DOWNLOAD:
[Link para download do app]

📚 TUTORIAIS:
[Link para vídeos/manual]

💬 SUPORTE:
WhatsApp: [SEU WHATSAPP]
Email: [SEU EMAIL]

Qualquer dúvida, estamos à disposição!

Atenciosamente,
[SEU NOME]
```

---

## 🔒 Segurança

### Proteções Implementadas:
- ✅ Licença validada no login
- ✅ Data de expiração verificada
- ✅ Username único por licença
- ✅ Chave criptografada

### Proteções Futuras:
- 🔜 Binding por MAC Address (1 licença = 1 computador)
- 🔜 Validação online (verificar se licença não foi revogada)
- 🔜 Limite de dispositivos por licença
- 🔜 Ofuscação de código (anti-pirataria)

---

## 📊 Previsão de Faturamento

### Cenário Conservador:
- **10 clientes** × R$ 49,90/mês = **R$ 499,00/mês**
- **12 meses** = **R$ 5.988,00/ano**

### Cenário Otimista:
- **50 clientes** × R$ 49,90/mês = **R$ 2.495,00/mês**
- **12 meses** = **R$ 29.940,00/ano**

### Cenário Agressivo:
- **100 clientes** × R$ 49,90/mês = **R$ 4.990,00/mês**
- **12 meses** = **R$ 59.880,00/ano**

---

## 🚀 Próximos Passos

### Fase 1: Painel Admin (AGORA)
- [ ] Criar tela de login admin
- [ ] Criar dashboard administrativo
- [ ] Implementar CRUD de clientes
- [ ] Implementar gestão de licenças
- [ ] Gerar licença via interface gráfica

### Fase 2: Melhorias (Próximas Semanas)
- [ ] Relatórios administrativos
- [ ] Exportar dados para Excel
- [ ] Sistema de notificações (licenças a vencer)
- [ ] Backup automático do banco admin

### Fase 3: Automação (Futuro)
- [ ] Site de vendas
- [ ] Integração Mercado Pago
- [ ] Email automático
- [ ] Renovação automática

---

## 💡 Dica de Ouro

**Comece simples**:
1. Venda para 3-5 clientes teste
2. Cobre R$ 1,00 simbólico
3. Peça feedback
4. Ajuste o produto
5. Depois suba o preço real

**Marketing inicial**:
- Ofereça **7 dias grátis** para testar
- Faça um **vídeo demo** no YouTube
- Crie página no **Instagram**
- Entre em grupos de **donos de restaurantes** no Facebook
- Visite restaurantes pessoalmente

---

## ❓ Perguntas Frequentes

### "Quantas licenças posso vender?"
- **Ilimitadas!** O sistema suporta quantas você quiser.

### "E se o cliente não pagar a renovação?"
- A licença expira automaticamente.
- O app bloqueia o acesso.
- Você pode renovar quando ele pagar.

### "Posso vender planos diferentes?"
- Sim! 30 dias, 90 dias, 365 dias, ou personalizado.

### "Preciso de CNPJ para vender?"
- Inicialmente não (pode emitir recibo como autônomo).
- Para crescer, MEI é recomendado (R$ 70/mês).

---

## 🎯 Conclusão

Com o **Painel Administrativo**, você terá:
- ✅ Controle total das licenças
- ✅ Gestão profissional de clientes
- ✅ Geração rápida de chaves
- ✅ Relatórios de faturamento
- ✅ Escalabilidade para crescer

**Quer que eu implemente o Painel Admin agora?**

Posso começar criando:
1. Tela de login administrativo
2. Dashboard com estatísticas
3. CRUD de clientes
4. Geração de licenças via interface

**O que você acha? Vamos começar?** 🚀
